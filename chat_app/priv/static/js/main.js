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

        // if (msg.type === "initial_notifications" && msg.notifications) window.renderNotifications(msg.notifications);
        // if (msg.contacts) renderContacts(msg.contacts);
        // if (msg.chatrooms) renderChatRooms(msg.chatrooms);
        // if (msg.messages) renderChatRoomMessages(msg.messages);
        // if (msg.search_results) {
        //     if (typeof window.renderSearchResults === 'function') {
        //         window.renderSearchResults(msg.search_results);
        //     }
        // }
        // if (msg.blocked_contacts) renderBlockedContacts(msg.blocked_contacts);
        // if (msg.status == "chat_opened") openChatRoom(msg.chat_id);
        // if (msg.status == "new_message" && window.currentChatRoom === msg.chat_id) {
        //     renderMessage(msg.message);
        // }
        // if (msg.type == "new_chatroom") addChatRoomToList(msg.chat_id);
        // if (msg.type === "contact_status" && msg.username) {
        //     if (typeof window.updateContactStatus === 'function') {
        //         window.updateContactStatus(msg.username, msg.online);
        //     }
        // }
        // if (msg.status === "contact_blocked") {
        //     if (msg.contacts) {
        //         console.log("Cantidad de contactos:", msg.contacts.length);
        //         renderContacts(msg.contacts);
        //     } else {
        //         console.log("No se recibieron contactos, llamando a getContacts()");
        //         getContacts();
        //     }
        // }
        // if (msg.status === "contact_unblocked") {
        //     alert(`Contacto ${msg.contact} desbloqueado`);
        //     if (msg.blocked_contacts) {
        //         window.renderBlockedContacts(msg.blocked_contacts);
        //     }
        //     getContacts();
        // }

        // if (msg.status === "contact_deleted") {
        //     alert(`Contacto ${msg.contact} eliminado`);
        //     if (msg.contacts) renderContacts(msg.contacts);
        // }
        // if (msg.status === "message_deleted") {
        //     if (window.currentChatRoom) {
        //         getChatRoomMessages(window.currentChatRoom);
        //     }
        // }
        // if (msg.error) alert(`Error: ${msg.error}`);
        // Primero manejar acciones específicas que podrían tener campos compartidos
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
        }
        // Luego manejar datos
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
        // Intentar reconectar después de 1 segundo
        setTimeout(() => {
            console.log("Reconectando...");
            connectWebSocket(window.currentUser);
        }, 1000);
    };
}



// Hacer función disponible globalmente
window.connectWebSocket = connectWebSocket;