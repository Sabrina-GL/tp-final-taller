#!/usr/bin/env python3
"""
Smoke test automático de demo:
- Levanta backend Elixir en puerto aislado
- Registra/loguea dos usuarios
- Abre dos conexiones WebSocket autenticadas por token
- Valida add_contact, send_message, send_file y notificación offline al reconectar
- Apaga backend al finalizar
"""

from __future__ import annotations

import base64
import json
import os
import signal
import subprocess
import sys
import tempfile
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

import requests
import websocket


ROOT_DIR = Path(__file__).resolve().parent.parent
CHAT_APP_DIR = ROOT_DIR / "chat_app"
PORT = int(os.getenv("DEMO_SMOKE_PORT", "4010"))
BASE_URL = f"http://localhost:{PORT}"
WS_URL = f"ws://localhost:{PORT}/ws"
TIMEOUT = 20


class SmokeError(RuntimeError):
    pass


@dataclass
class WsClient:
    name: str
    token: str
    events: list[dict[str, Any]]
    lock: threading.Lock

    def __post_init__(self) -> None:
        self._connected = threading.Event()
        self._app = websocket.WebSocketApp(
            f"{WS_URL}?token={self.token}",
            on_open=self._on_open,
            on_message=self._on_message,
            on_error=self._on_error,
            on_close=self._on_close,
        )
        self._thread = threading.Thread(
            target=lambda: self._app.run_forever(
                ping_interval=20,
                ping_timeout=10,
                ping_payload="demo-smoke",
            ),
            daemon=True,
        )

    def connect(self) -> None:
        self._thread.start()
        if not self._connected.wait(timeout=TIMEOUT):
            raise SmokeError(f"{self.name}: no se pudo abrir WebSocket")

    def send(self, payload: dict[str, Any]) -> None:
        self._app.send(json.dumps(payload))

    def close(self) -> None:
        self._app.close()
        self._thread.join(timeout=2)

    def _on_open(self, _ws: websocket.WebSocketApp) -> None:
        self._connected.set()

    def _on_message(self, _ws: websocket.WebSocketApp, msg: str) -> None:
        try:
            data = json.loads(msg)
        except json.JSONDecodeError:
            data = {"raw": msg}

        with self.lock:
            self.events.append({"client": self.name, "data": data, "ts": time.time()})

    def _on_error(self, _ws: websocket.WebSocketApp, error: Any) -> None:
        with self.lock:
            self.events.append({"client": self.name, "data": {"ws_error": str(error)}, "ts": time.time()})

    def _on_close(self, _ws: websocket.WebSocketApp, status: Any, reason: Any) -> None:
        with self.lock:
            self.events.append(
                {
                    "client": self.name,
                    "data": {"ws_close": True, "status": status, "reason": reason},
                    "ts": time.time(),
                }
            )


def run_cmd(command: list[str], cwd: Path) -> None:
    result = subprocess.run(command, cwd=str(cwd), capture_output=True, text=True)
    if result.returncode != 0:
        raise SmokeError(
            f"Fallo comando: {' '.join(command)}\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
        )


def wait_until(predicate: Callable[[], bool], timeout: float, step: float = 0.2) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        if predicate():
            return True
        time.sleep(step)
    return False


def event_exists(
    events: list[dict[str, Any]],
    lock: threading.Lock,
    check: Callable[[dict[str, Any]], bool],
) -> bool:
    with lock:
        return any(check(e) for e in events)


def ensure_backend_ready() -> subprocess.Popen[str]:
    run_cmd(["mix", "deps.get"], CHAT_APP_DIR)
    run_cmd(["mix", "ecto.create"], CHAT_APP_DIR)
    run_cmd(["mix", "ecto.migrate"], CHAT_APP_DIR)

    log_file = tempfile.NamedTemporaryFile(prefix="demo_smoke_", suffix=".log", delete=False)
    env = os.environ.copy()
    env["WEBSOCKET_PORT"] = str(PORT)

    process = subprocess.Popen(
        ["mix", "run", "--no-halt"],
        cwd=str(CHAT_APP_DIR),
        env=env,
        stdout=log_file,
        stderr=subprocess.STDOUT,
        text=True,
    )

    def backend_up() -> bool:
        try:
            response = requests.get(f"{BASE_URL}/api/status?user=smoke_probe", timeout=1)
            return response.status_code in (200, 400)
        except Exception:
            return False

    if not wait_until(backend_up, timeout=30):
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()

        raise SmokeError(
            f"Backend no respondió en puerto {PORT}. Log: {log_file.name}"
        )

    print(f"✅ Backend listo en {BASE_URL} (log: {log_file.name})")
    return process


def stop_backend(process: subprocess.Popen[str]) -> None:
    if process.poll() is not None:
        return

    process.send_signal(signal.SIGTERM)
    try:
        process.wait(timeout=8)
    except subprocess.TimeoutExpired:
        process.kill()


def main() -> int:
    print("🚦 Iniciando demo-smoke automático...")
    backend = None
    alice_ws = None
    bob_ws = None

    now = int(time.time())
    alice = f"demoalice_{now}"
    bob = f"demobob_{now}"
    password = "demo123456"

    events: list[dict[str, Any]] = []
    lock = threading.Lock()

    try:
        backend = ensure_backend_ready()

        for username in (alice, bob):
            response = requests.post(
                f"{BASE_URL}/api/register",
                json={"username": username, "password": password},
                timeout=5,
            )
            if response.status_code != 200:
                raise SmokeError(f"Registro falló para {username}: {response.text}")

        login_alice = requests.post(
            f"{BASE_URL}/api/login",
            json={"username": alice, "password": password},
            timeout=5,
        )
        login_bob = requests.post(
            f"{BASE_URL}/api/login",
            json={"username": bob, "password": password},
            timeout=5,
        )

        if login_alice.status_code != 200 or login_bob.status_code != 200:
            raise SmokeError("Login falló en demo-smoke")

        token_alice = login_alice.json().get("token")
        token_bob = login_bob.json().get("token")

        if not token_alice or not token_bob:
            raise SmokeError("Login no devolvió token en uno de los usuarios")

        alice_ws = WsClient("alice", token_alice, events, lock)
        bob_ws = WsClient("bob", token_bob, events, lock)
        alice_ws.connect()
        bob_ws.connect()

        chat_id = ":".join(sorted([alice, bob]))

        alice_ws.send({"action": "add_contact", "contact": bob})

        ok_add = wait_until(
            lambda: event_exists(
                events,
                lock,
                lambda e: e["client"] == "alice"
                and e["data"].get("status") == "contact_added",
            ),
            timeout=8,
        )
        if not ok_add:
            raise SmokeError("No llegó respuesta contact_added")

        alice_ws.send({"action": "send_message", "chat_id": chat_id, "msg_content": "hola demo smoke"})

        ok_msg = wait_until(
            lambda: event_exists(
                events,
                lock,
                lambda e: e["client"] == "bob"
                and e["data"].get("status") == "new_message"
                and e["data"].get("chat_id") == chat_id,
            ),
            timeout=8,
        )
        if not ok_msg:
            raise SmokeError("Bob no recibió new_message")

        file_content = base64.b64encode(b"demo-smoke-file-content").decode("utf-8")
        alice_ws.send(
            {
                "action": "send_file",
                "chat_id": chat_id,
                "file_content": file_content,
                "file_name": "demo_smoke.txt",
                "file_type": "text/plain",
            }
        )

        ok_file = wait_until(
            lambda: event_exists(
                events,
                lock,
                lambda e: e["client"] == "bob"
                and e["data"].get("status") == "new_message"
                and isinstance(e["data"].get("message"), dict)
                and e["data"]["message"].get("file_name") == "demo_smoke.txt",
            ),
            timeout=10,
        )
        if not ok_file:
            raise SmokeError("Bob no recibió notificación de archivo")

        bob_ws.close()
        bob_ws = None

        alice_ws.send(
            {
                "action": "send_message",
                "chat_id": chat_id,
                "msg_content": "mensaje offline demo smoke",
            }
        )
        time.sleep(1.0)

        bob_ws = WsClient("bob", token_bob, events, lock)
        bob_ws.connect()

        ok_offline = wait_until(
            lambda: event_exists(
                events,
                lock,
                lambda e: e["client"] == "bob"
                and e["data"].get("type") == "initial_notifications"
                and any(
                    isinstance(n, dict) and n.get("type") == "new_message"
                    for n in e["data"].get("notifications", [])
                ),
            ),
            timeout=10,
        )
        if not ok_offline:
            raise SmokeError("Bob no recibió notificaciones offline al reconectar")

        print("✅ Demo smoke OK: login + WS token + chat + archivo + offline")
        return 0

    except Exception as exc:
        print(f"❌ Demo smoke FAILED: {exc}")
        return 1

    finally:
        if alice_ws is not None:
            alice_ws.close()
        if bob_ws is not None:
            bob_ws.close()
        if backend is not None:
            stop_backend(backend)


if __name__ == "__main__":
    raise SystemExit(main())
