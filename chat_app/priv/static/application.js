const ws = new WebSocket(`ws://localhost:4000/ws`);

ws.onmessage = e => {
    document.getElementById("out").textContent += e.data + "\n";
}

function register() {
    ws.send(JSON.stringify({
        action: "register",
        username: username.value,
        password: password.value
    }));
}

function login() {
    ws.send(JSON.stringify({
        action: "login",
        username: username.value,
        password: password.value
    }));
}