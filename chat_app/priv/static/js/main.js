let activeSection = null;

window.App = window.App || {};
window.ws = null;
window.currentUser = null;
window.currentToken = null;
window.currentChatRoom = null;
window.wsReconnectAttempts = 0;
window.wsReconnectTimer = null;
window.wsManualClose = false;

const WS_RECONNECT_BASE_DELAY = 1000;
const WS_RECONNECT_MAX_DELAY = 30000;

function updateConnectionStatus(status) {
    const indicator = document.getElementById("connection-status");
    if (!indicator) return;

    indicator.classList.remove("online", "connecting", "offline");
    indicator.classList.add(status);

    if (status === "online") {
        indicator.textContent = "Conectado";
    } else if (status === "connecting") {
        indicator.textContent = "Reconectando...";
    } else {
        indicator.textContent = "Sin conexión";
    }
}

function safeNotify(message) {
    (window.showToast || fallbackToast)(message);
}

function escapeHtml(value) {
    return String(value ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function initConfirmModal() {
    const modal = document.getElementById("confirm-modal");
    if (!modal) return;

    const cancelBtn = document.getElementById("confirm-cancel-btn");
    const okBtn = document.getElementById("confirm-ok-btn");

    const close = (result) => {
        if (typeof window.App.confirmResolver === "function") {
            window.App.confirmResolver(result);
        }
        window.App.confirmResolver = null;
        modal.classList.remove("show");
    };

    cancelBtn?.addEventListener("click", () => close(false));
    okBtn?.addEventListener("click", () => close(true));
    modal.addEventListener("click", (event) => {
        if (event.target === modal) {
            close(false);
        }
    });

    window.addEventListener("keydown", (event) => {
        if (event.key === "Escape" && modal.classList.contains("show")) {
            close(false);
        }
    });
}

function confirmAction(message) {
    const modal = document.getElementById("confirm-modal");
    const messageEl = document.getElementById("confirm-modal-message");
    const okBtn = document.getElementById("confirm-ok-btn");

    if (!modal || !messageEl || !okBtn) {
        return Promise.resolve(window.confirm(message));
    }

    messageEl.textContent = message || "¿Confirmar acción?";
    modal.classList.add("show");

    requestAnimationFrame(() => {
        okBtn.focus();
    });

    return new Promise((resolve) => {
        window.App.confirmResolver = resolve;
    });
}

function sendWs(payload, options = {}) {
    const { silent = false } = options;

    if (!window.ws || window.ws.readyState !== WebSocket.OPEN) {
        if (!silent) safeNotify("WebSocket no está conectado");
        return false;
    }

    try {
        window.ws.send(JSON.stringify(payload));
        return true;
    } catch (_error) {
        if (!silent) safeNotify("No se pudo enviar la acción por WebSocket");
        return false;
    }
}

function fallbackToast(message) {
    if (!message) return;

    let container = document.getElementById("toast-container");
    if (!container) {
        container = document.createElement("div");
        container.id = "toast-container";
        container.className = "toast-container";
        document.body.appendChild(container);
    }

    const toast = document.createElement("div");
    toast.className = "toast-notification";
    toast.textContent = message;
    container.appendChild(toast);

    requestAnimationFrame(() => toast.classList.add("show"));

    setTimeout(() => {
        toast.classList.remove("show");
        setTimeout(() => toast.remove(), 250);
    }, 3000);
}

document.addEventListener('DOMContentLoaded', function () {
    console.log("DOM cargado");

    const sidebar = document.getElementById("sidebar");

    const username = sessionStorage.getItem("chat_user");
    const token = sessionStorage.getItem("chat_token");

    if (!username || !token) {
        window.location = "/login";
        return;
    }

    console.log("Usuario:", username);
    window.currentUser = username;
    window.currentToken = token;

    // Inicializar módulos
    initSidebar();
    initGroupModal();
    initNotifications();
    initConfirmModal();

    // Iniciar WebSocket
    connectWebSocket(username, token);

    // Event listeners de botones principales
    document.getElementById('add-contact-btn')?.addEventListener('click', addContact);
    document.getElementById('send-message-btn')?.addEventListener('click', sendMessage);
    document.getElementById('new-group-chat-btn')?.addEventListener('click', showCreateGroupModal);
    document.getElementById('logout-btn')?.addEventListener('click', logout);

});

// =========== WebSocket ===========

function connectWebSocket(username, token) {
    window.wsManualClose = false;

    if (window.ws && (window.ws.readyState === WebSocket.OPEN || window.ws.readyState === WebSocket.CONNECTING)) {
        window.wsManualClose = true;
        window.ws.close();
    }

    console.log("Conectando al usuario:", username);
    updateConnectionStatus("connecting");

    const protocol = window.location.protocol === "https:" ? "wss" : "ws";
    const WS_URL = `${protocol}://${window.location.host}`;
    window.ws = new WebSocket(`${WS_URL}/ws?token=${encodeURIComponent(token)}`);

    window.ws.onopen = function () {
        console.log("WebSocket conectado");
        window.wsReconnectAttempts = 0;
        if (window.wsReconnectTimer) {
            clearTimeout(window.wsReconnectTimer);
            window.wsReconnectTimer = null;
        }
        updateConnectionStatus("online");
        // Pido los datos al conectar
        getContacts();
        getChatRooms();
    };

    window.ws.onmessage = function (e) {
        console.log("Recibido:", e.data);
        let msg = null;

        try {
            msg = JSON.parse(e.data);
        } catch (_error) {
            safeNotify("Llegó un mensaje inválido del servidor");
            return;
        }

        if (msg.status === "message_deleted" && window.currentChatRoom) {
            getChatRoomMessages(window.currentChatRoom);
        }
        else if (msg.status === "contact_blocked") {
            if (msg.contacts) {
                console.log("Cantidad de contactos:", msg.contacts.length);
                renderContacts(msg.contacts);
            } else {
                getContacts();
            }
        }
        else if (msg.status === "contact_unblocked") {
            safeNotify(`Contacto ${msg.contact} desbloqueado`);
            msg.blocked_contacts && window.renderBlockedContacts(msg.blocked_contacts);
            getContacts();
        }
        else if (msg.status === "contact_deleted") {
            safeNotify(`Contacto ${msg.contact} eliminado`);
            msg.contacts && renderContacts(msg.contacts);
        }
        else if (msg.status === "chat_opened") {
            openChatRoom(msg.chat_id);
        }
        else if (msg.status === "new_message") {
            const messageData = msg.message || {};
            const isActiveChat = window.currentChatRoom === msg.chat_id;
            const preview = messageData.file_name
                ? `📎 ${messageData.file_name}`
                : (messageData.msg_content || "Nuevo mensaje");

            const toastMessage = `💬 ${messageData.from || "Desconocido"}: ${preview}`;
            (window.showToast || fallbackToast)(toastMessage);

            if (isActiveChat) {
                if (messageData.file_name) {
                    renderFileMessage(messageData);
                } else {
                    renderMessage(messageData);
                }
            } else {
                window.upsertLiveNotification?.({
                    type: "new_message",
                    from: messageData.from || "desconocido",
                    chat_id: msg.chat_id,
                    timestamp: messageData.timestamp || Date.now(),
                    message_preview: messageData.file_name
                        ? `Archivo: ${messageData.file_name}`
                        : (messageData.msg_content || "Nuevo mensaje")
                });
            }
        } else if (msg.status === "group_chat_created") {
            window.addChatRoomToList(msg.chat_id);
            openChatRoom(msg.chat_id);
        }
        else if (msg.type === "initial_notifications" && msg.notifications) {
            window.renderNotifications(msg.notifications);
        }
        else if (msg.contacts) {
            renderContacts(msg.contacts);
        }
        else if (msg.blocked_contacts) {
            renderBlockedContacts(msg.blocked_contacts);
        }
        else if (msg.chatrooms) {
            renderChatRooms(msg.chatrooms);
        }
        else if (msg.messages) {
            renderChatRoomMessages(msg.messages);
        }
        else if (msg.search_results) {
            window.renderSearchResults?.(msg.search_results);
        }
        else if (msg.type === "new_chatroom") {
            addChatRoomToList(msg.chat_id);
        }
        else if (msg.type === "contact_status" && msg.username) {
            window.updateContactStatus?.(msg.username, msg.online);
        } else if (msg.status === "ok" && msg.message) {
            if (msg.message.file_name || msg.type === "file") {
                renderFileMessage(msg.message);
            } else {
                renderMessage(msg.message);
            }
        }
        else if (msg.error) {
            safeNotify(`Error: ${msg.error}`);
        }
    };

    window.ws.onerror = function (e) {
        console.log("Error WebSocket:", e);
        updateConnectionStatus("offline");
    };

    window.ws.onclose = function (e) {
        console.log("WebSocket cerrado:", e);
        updateConnectionStatus("offline");

        if (window.wsManualClose || !window.currentUser || !window.currentToken) {
            return;
        }

        window.wsReconnectAttempts += 1;
        const delay = Math.min(
            WS_RECONNECT_BASE_DELAY * Math.pow(2, window.wsReconnectAttempts - 1),
            WS_RECONNECT_MAX_DELAY
        );

        safeNotify(`Reconectando en ${Math.round(delay / 1000)}s...`);
        updateConnectionStatus("connecting");

        window.wsReconnectTimer = setTimeout(() => {
            console.log("Reconectando...");
            connectWebSocket(window.currentUser, window.currentToken);
        }, delay);
    };
}



// Hacer función disponible globalmente
window.connectWebSocket = connectWebSocket;
window.sendWs = sendWs;
window.safeNotify = safeNotify;
window.escapeHtml = escapeHtml;
window.confirmAction = confirmAction;