let activeSection = null;

window.App = window.App || {};
window.ws = null;
window.currentUser = null;
window.currentToken = null;
window.currentChatRoom = null;

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
    if (window.ws && (window.ws.readyState === WebSocket.OPEN || window.ws.readyState === WebSocket.CONNECTING)) {
        window.ws.close();
    }

    console.log("Conectando al usuario:", username);
    const protocol = window.location.protocol === "https:" ? "wss" : "ws";
    const WS_URL = `${protocol}://${window.location.host}`;
    window.ws = new WebSocket(`${WS_URL}/ws?token=${encodeURIComponent(token)}`);

    window.ws.onopen = function () {
        console.log("WebSocket conectado");
        // Pido los datos al conectar
        getContacts();
        getChatRooms();
    };

    window.ws.onmessage = function (e) {
        console.log("Recibido:", e.data);
        const msg = JSON.parse(e.data);

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
            alert(`Contacto ${msg.contact} desbloqueado`);
            msg.blocked_contacts && window.renderBlockedContacts(msg.blocked_contacts);
            getContacts();
        }
        else if (msg.status === "contact_deleted") {
            alert(`Contacto ${msg.contact} eliminado`);
            msg.contacts && renderContacts(msg.contacts);
        }
        else if (msg.status === "chat_opened") {
            openChatRoom(msg.chat_id);
        }
        else if (msg.status === "new_message" && window.currentChatRoom === msg.chat_id) {
            renderMessage(msg.message);
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
        } else if (msg.status === "ok" && msg.type === "file") {
            renderFileMessage(msg.message);
        }
        else if (msg.error) {
            alert(`Error: ${msg.error}`);
        }
    };

    window.ws.onerror = function (e) {
        console.log("Error WebSocket:", e);
    };

    window.ws.onclose = function (e) {
        console.log("WebSocket cerrado:", e);
        if (!window.currentUser || !window.currentToken) {
            return;
        }
        // Intentar reconectar después de 1 segundo
        setTimeout(() => {
            console.log("Reconectando...");
            connectWebSocket(window.currentUser, window.currentToken);
        }, 1000);
    };
}



// Hacer función disponible globalmente
window.connectWebSocket = connectWebSocket;