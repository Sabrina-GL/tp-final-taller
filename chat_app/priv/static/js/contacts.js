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
        </div>
    `;

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

// Hacer funciones disponibles globalmente
window.getContacts = getContacts;
window.addContact = addContact;
window.renderContacts = renderContacts;
window.updateContactStatus = updateContactStatus;