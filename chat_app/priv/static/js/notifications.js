// notifications.js
window.App = window.App || {};
window.App.notifications = [];
window.App.unreadCount = 0;

function initNotifications() {
    renderNotifications(window.App.notifications || []);
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

function upsertLiveNotification(notif) {
    if (!notif) return;

    const normalized = {
        id: notif.id || `live_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
        type: notif.type || "new_message",
        from: notif.from || "desconocido",
        chat_id: notif.chat_id || "",
        timestamp: notif.timestamp || Date.now(),
        message_preview: notif.message_preview || ""
    };

    const notifications = window.App.notifications || [];
    const exists = notifications.some(n => n.id === normalized.id);

    if (!exists) {
        notifications.unshift(normalized);
        renderNotifications(notifications);
    }
}

function showToast(message) {
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

    requestAnimationFrame(() => {
        toast.classList.add("show");
    });

    setTimeout(() => {
        toast.classList.remove("show");
        setTimeout(() => toast.remove(), 250);
    }, 3000);
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
window.upsertLiveNotification = upsertLiveNotification;
window.showToast = showToast;
