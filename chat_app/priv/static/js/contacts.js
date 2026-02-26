// contacts.js
function getContacts() {
    window.sendWs?.({ action: "get_contacts" }, { silent: true });
}

function addContact() {
    if (!window.sendWs) {
        return;
    }

    const contact = document.getElementById("contact");
    if (!contact.value) {
        window.safeNotify?.("Por favor ingrese un nombre de contacto");
        return;
    }

    const sent = window.sendWs({
        action: "add_contact",
        contact: contact.value
    });

    if (!sent) {
        return;
    }

    openChatRoom(`${[window.currentUser, contact.value].sort().join(":")}`);
    // Limpio el campo de contacto
    contact.value = "";
}

function renderContacts(contacts) {
    const list = document.getElementById("contacts-list");
    list.innerHTML = "";

    contacts.forEach(c => {
        // Determinar username y isOnline
        let username = c;
        let isOnline = false;

        if (typeof c === 'object') {
            username = c.username;
            isOnline = c.online;
        }

        const li = document.createElement("li");
        li.className = "contact-item";
        li.setAttribute("data-username", username);

        const info = document.createElement("div");
        info.className = "contact-info";

        const name = document.createElement("span");
        name.className = "contact-name";
        name.textContent = username;

        const indicator = document.createElement("span");
        indicator.className = `online-indicator ${isOnline ? "online" : "offline"}`;
        indicator.title = isOnline ? "Online" : "Offline";
        indicator.textContent = "●";

        const actions = document.createElement("div");
        actions.className = "contact-actions";

        const blockBtn = document.createElement("button");
        blockBtn.className = "action-btn block-btn";
        blockBtn.type = "button";
        blockBtn.title = "Bloquear contacto";
        blockBtn.textContent = "🚫";

        const deleteBtn = document.createElement("button");
        deleteBtn.className = "action-btn delete-btn";
        deleteBtn.type = "button";
        deleteBtn.title = "Eliminar contacto";
        deleteBtn.textContent = "❌";

        actions.appendChild(blockBtn);
        actions.appendChild(deleteBtn);

        info.appendChild(name);
        info.appendChild(indicator);
        info.appendChild(actions);
        li.appendChild(info);

        // Evento para abrir chat al hacer click en el contacto (excepto en los botones)
        li.addEventListener('click', (e) => {
            if (!e.target.classList.contains('action-btn')) {
                openChatRoom(`${[window.currentUser, username].sort().join(":")}`);
            }
        });

        // Evento para bloquear contacto
        blockBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            blockContact(username);
        });

        // Evento para eliminar contacto
        deleteBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            deleteContact(username);
        });

        list.appendChild(li);
    });

    // Actualizar modal si existe la función
    if (typeof window.updateContactsModal === 'function') {
        const contactNames = contacts.map(c => typeof c === 'object' ? c.username : c);
        window.updateContactsModal(contactNames);
    }
}

function updateContactStatus(username, isOnline) {
    const contactItem = document.querySelector(`.contact-item[data-username="${username}"] .online-indicator`);
    if (contactItem) {
        contactItem.className = `online-indicator ${isOnline ? 'online' : 'offline'}`;
        contactItem.title = isOnline ? 'Online' : 'Offline';
    }
}

// Funciones para bloquear y eliminar contacto
async function blockContact(username) {
    if (!window.sendWs) {
        return;
    }

    const confirmed = await (window.confirmAction?.(`¿Bloquear a ${username}?`) ?? Promise.resolve(true));
    if (confirmed) {
        window.sendWs({
            action: "block_contact",
            contact: username
        });
    }
}

async function deleteContact(username) {
    if (!window.sendWs) {
        return;
    }

    const confirmed = await (window.confirmAction?.(`¿Eliminar a ${username} de tus contactos?`) ?? Promise.resolve(true));
    if (confirmed) {
        window.sendWs({
            action: "delete_contact",
            contact: username
        });
    }
}

// Hacer funciones disponibles globalmente
window.getContacts = getContacts;
window.addContact = addContact;
window.renderContacts = renderContacts;
window.updateContactStatus = updateContactStatus;
window.blockContact = blockContact;
window.deleteContact = deleteContact;