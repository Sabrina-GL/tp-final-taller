// notifications.js
window.App = window.App || {};
window.App.notifications = [];
window.App.unreadCount = 0;

function initNotifications() {

    if (window.ws && window.ws.readyState === WebSocket.OPEN) {
        window.ws.send(JSON.stringify({ action: "get_notifications" }));
    }
}

function renderNotifications(notifications) {
    window.App.notifications = notifications;
    window.App.unreadCount = notifications.length;

    // Actualizar indicador en el botón
    updateNotificationBadge();

    const list = document.getElementById("notifications-list");
    if (!list) return;

    list.innerHTML = "";

    if (!notifications || notifications.length === 0) {
        list.innerHTML = '<li class="empty-list">No hay notificaciones</li>';
        return;
    }

    notifications.forEach(notif => {
        const li = document.createElement("li");
        li.className = `notification-item unread`;
        li.setAttribute("data-id", notif.id);

        let content = '';
        if (notif.type === 'new_message') {
            content = `Nuevo mensaje de ${notif.from} en ${notif.chat_id}`;
        } else if (notif.type === 'new_chatroom' && notif.chat_id.startsWith('group:')) {
            const groupName = notif.chat_id.replace('group:', '');
            content = `Te agregaron al grupo "${groupName}"`;
        } else if (notif.type === 'added_as_contact') {
            content = `${notif.from} te ha añadido a sus contactos`;
        }

        li.innerHTML = `
            <div class="notification-content">${content}</div>
            <div class="notification-time">${new Date(notif.timestamp).toLocaleString()}</div>
        `;

        li.addEventListener('click', () => {
            if (notif.type === 'new_chatroom' && notif.chat_id) {
                openChatRoom(notif.chat_id);
            } else if (notif.type === 'new_message' && notif.chat_id) {
                openChatRoom(notif.chat_id);
            } else if (notif.type === 'added_as_contact' && notif.from) {
                openChatRoom(`${[window.currentUser, notif.from].sort().join(":")}`);
            }

            if (typeof window.removeNotification === 'function') {
                window.removeNotification(notif.id);
            }
        });

        list.appendChild(li);
    });
}

function removeNotification(id) {
    window.App.notifications = window.App.notifications.filter(n => n.id !== id);

    // Eliminar del DOM
    const notifElement = document.querySelector(`.notification-item[data-id="${id}"]`);
    if (notifElement) notifElement.remove();
    window.App.unreadCount = window.App.notifications.length;;
    updateNotificationBadge();
}


function updateNotificationBadge() {
    const notifBtn = document.querySelector('.icon-btn[data-target="notifications"]');
    if (notifBtn) {
        if (window.App.unreadCount > 0) {
            notifBtn.classList.add('has-notifications');
            notifBtn.setAttribute('title', `${window.App.unreadCount} notificaciones no leídas`);
        } else {
            notifBtn.classList.remove('has-notifications');
            notifBtn.setAttribute('title', 'Notificaciones');
        }
    }
}


// Hacer funciones globales
window.initNotifications = initNotifications;
window.renderNotifications = renderNotifications;
window.removeNotification = removeNotification;
