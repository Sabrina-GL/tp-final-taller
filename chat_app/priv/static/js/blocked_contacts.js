// blocked_contacts.js
window.App = window.App || {};

function loadBlockedContacts() {
    if (window.ws && window.ws.readyState === WebSocket.OPEN) {
        window.ws.send(JSON.stringify({ action: "get_blocked_contacts" }));
    }
}

function renderBlockedContacts(contacts) {
    const list = document.getElementById("blocked-contacts-list");
    if (!list) return;

    list.innerHTML = "";

    if (!contacts || contacts.length === 0) {
        list.innerHTML = '<li class="empty-list">No hay contactos bloqueados</li>';
        return;
    }

    contacts.forEach(contact => {
        let username = contact;
        if (typeof contact === 'object') {
            username = contact.username;
        }

        const li = document.createElement("li");
        li.className = "contact-item";
        li.setAttribute("data-username", username);

        li.innerHTML = `
            <div class="contact-info">
                <span class="contact-name">${username}</span>
                <div class="contact-actions">
                    <button class="action-btn unblock-btn" title="Desbloquear contacto">🔓</button>
                </div>
            </div>
        `;

        // Evento para desbloquear
        const unblockBtn = li.querySelector('.unblock-btn');
        unblockBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            unblockContact(username);
        });

        list.appendChild(li);
    });
}

function unblockContact(username) {
    if (!window.ws || window.ws.readyState !== WebSocket.OPEN) {
        alert("WebSocket no está conectado");
        return;
    }

    if (confirm(`¿Desbloquear a ${username}?`)) {
        window.ws.send(JSON.stringify({
            action: "unblock_contact",
            contact: username
        }));
    }
}

// Hacer funciones globales
window.loadBlockedContacts = loadBlockedContacts;
window.renderBlockedContacts = renderBlockedContacts;
window.unblockContact = unblockContact;