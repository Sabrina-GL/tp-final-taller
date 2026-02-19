let activeSection = null;

window.App = window.App || {};
window.ws = null;
window.currentUser = null;
window.currentChatRoom = null;

document.addEventListener('DOMContentLoaded', function () {
    console.log("DOM cargado");

    const sidebar = document.getElementById("sidebar");

    // Obtener usuario de la URL
    const urlParams = new URLSearchParams(window.location.search);
    const username = urlParams.get('user');

    if (!username) {
        window.location = "/login";
        return;
    }

    console.log("Usuario:", username);
    window.currentUser = username;

    // Inicializar módulos
    initSidebar();
    initGroupModal();
    initNotifications();

    // Iniciar WebSocket
    connectWebSocket(username);

    // Event listeners de botones principales
    document.getElementById('add-contact-btn')?.addEventListener('click', addContact);
    document.getElementById('send-message-btn')?.addEventListener('click', sendMessage);
    document.getElementById('new-group-chat-btn')?.addEventListener('click', showCreateGroupModal);
    document.getElementById('logout-btn')?.addEventListener('click', logout);
});

// =========== WebSocket ===========

function connectWebSocket(username) {
    if (window.ws && (window.ws.readyState === WebSocket.OPEN || window.ws.readyState === WebSocket.CONNECTING)) {
        window.ws.close();
    }

    console.log("Conectando al usuario:", username);
    const WS_URL = `ws://${window.location.host}`;
    window.ws = new WebSocket(`${WS_URL}/ws?user=${username}`);

    window.ws.onopen = function () {
        console.log("WebSocket conectado");
        // Pido los datos al conectar
        getContacts();
        getChatRooms();
    };

    window.ws.onmessage = function (e) {
        console.log("Recibido:", e.data);
        const msg = JSON.parse(e.data);

        if (msg.type === "initial_notifications" && msg.notifications) window.renderNotifications(msg.notifications);
        if (msg.contacts) renderContacts(msg.contacts);
        if (msg.chatrooms) renderChatRooms(msg.chatrooms);
        if (msg.messages) renderChatRoomMessages(msg.messages);
        // if (msg.notifications) renderNotifications(msg.notifications);
        if (msg.status == "chat_opened") openChatRoom(msg.chat_id);
        if (msg.status == "new_message" && window.currentChatRoom === msg.chat_id) {
            renderMessage(msg.message);
        }
        if (msg.type == "new_chatroom") addChatRoomToList(msg.chat_id);
        if (msg.type === "contact_status" && msg.username) {
            if (typeof window.updateContactStatus === 'function') {
                window.updateContactStatus(msg.username, msg.online);
            }
        }
        if (msg.error) alert(`Error: ${msg.error}`);
    };

    window.ws.onerror = function (e) {
        console.log("Error WebSocket:", e);
    };

    window.ws.onclose = function (e) {
        console.log("WebSocket cerrado:", e);
        // Intentar reconectar después de 1 segundo
        setTimeout(() => {
            console.log("Reconectando...");
            connectWebSocket(window.currentUser);
        }, 1000);
    };
}



// Hacer función disponible globalmente
window.connectWebSocket = connectWebSocket;