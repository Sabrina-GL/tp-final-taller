// blocked_contacts.js
window.App = window.App || {};

function loadBlockedContacts() {
    window.sendWs?.({ action: "get_blocked_contacts" }, { silent: true });
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

        const info = document.createElement("div");
        info.className = "contact-info";

        const name = document.createElement("span");
        name.className = "contact-name";
        name.textContent = username;

        const actions = document.createElement("div");
        actions.className = "contact-actions";

        const unblockBtn = document.createElement("button");
        unblockBtn.className = "action-btn unblock-btn";
        unblockBtn.type = "button";
        unblockBtn.title = "Desbloquear contacto";
        unblockBtn.textContent = "🔓";

        actions.appendChild(unblockBtn);
        info.appendChild(name);
        info.appendChild(actions);
        li.appendChild(info);

        // Evento para desbloquear
        unblockBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            unblockContact(username);
        });

        list.appendChild(li);
    });
}

async function unblockContact(username) {
    if (!window.sendWs) {
        return;
    }

    const confirmed = await (window.confirmAction?.(`¿Desbloquear a ${username}?`) ?? Promise.resolve(true));
    if (confirmed) {
        window.sendWs({
            action: "unblock_contact",
            contact: username
        });
    }
}

// Hacer funciones globales
window.loadBlockedContacts = loadBlockedContacts;
window.renderBlockedContacts = renderBlockedContacts;
window.unblockContact = unblockContact;