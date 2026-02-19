// contacts.js
function getContacts() {
    window.ws.send(JSON.stringify({ action: "get_contacts" }));
}

function addContact() {
    if (!window.ws || window.ws.readyState !== WebSocket.OPEN) {
        alert("WebSocket no está conectado");
        return;
    }

    const contact = document.getElementById("contact");
    if (!contact.value) {
        alert("Por favor ingrese un nombre de contacto");
        return;
    }

    window.ws.send(JSON.stringify({
        action: "add_contact",
        contact: contact.value
    }));

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

        li.innerHTML = `
        <div class="contact-info">
            <span class="contact-name">${username}</span>
            <span class="online-indicator ${isOnline ? 'online' : 'offline'}" 
                  title="${isOnline ? 'Online' : 'Offline'}">●</span>
            <div class="contact-actions">
                <button class="action-btn block-btn" title="Bloquear contacto">🚫</button>
                <button class="action-btn delete-btn" title="Eliminar contacto">❌</button>
            </div>
        </div>
    `;

        // Evento para abrir chat al hacer click en el contacto (excepto en los botones)
        li.addEventListener('click', (e) => {
            if (!e.target.classList.contains('action-btn')) {
                openChatRoom(`${[window.currentUser, username].sort().join(":")}`);
            }
        });

        // Evento para bloquear contacto
        const blockBtn = li.querySelector('.block-btn');
        blockBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            blockContact(username);
        });

        // Evento para eliminar contacto
        const deleteBtn = li.querySelector('.delete-btn');
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
function blockContact(username) {
    if (!window.ws || window.ws.readyState !== WebSocket.OPEN) {
        alert("WebSocket no está conectado");
        return;
    }

    if (confirm(`¿Bloquear a ${username}?`)) {
        window.ws.send(JSON.stringify({
            action: "block_contact",
            contact: username
        }));
    }
}

function deleteContact(username) {
    if (!window.ws || window.ws.readyState !== WebSocket.OPEN) {
        alert("WebSocket no está conectado");
        return;
    }

    if (confirm(`¿Eliminar a ${username} de tus contactos?`)) {
        window.ws.send(JSON.stringify({
            action: "delete_contact",
            contact: username
        }));
    }
}

// Hacer funciones disponibles globalmente
window.getContacts = getContacts;
window.addContact = addContact;
window.renderContacts = renderContacts;
window.updateContactStatus = updateContactStatus;
window.blockContact = blockContact;
window.deleteContact = deleteContact;