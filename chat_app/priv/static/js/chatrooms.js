// chatrooms.js
function getChatRooms() {
    window.ws.send(JSON.stringify({ action: "get_chatrooms" }));
}

function openChatRoom(chat_id) {
    console.log("Abriendo chat room:", chat_id);
    window.currentChatRoom = chat_id;

    document.getElementById("chat-title").textContent = `Chatroom: ${chat_id}`;
    document.getElementById("chat-messages").innerHTML = "";

    closeSidebar();
    getChatRoomMessages(chat_id);
}

function renderChatRooms(chatrooms) {
    const list = document.getElementById("chatrooms-list");
    list.innerHTML = "";
    chatrooms.forEach(c => addChatRoomToList(c));
}

function addChatRoomToList(chat_id) {
    const list = document.getElementById("chatrooms-list");
    const li = document.createElement("li");
    li.textContent = chat_id;
    li.addEventListener('click', () => openChatRoom(chat_id));
    list.appendChild(li);

    if (!chat_id.includes(':')) {
        li.innerHTML = '👥 ' + li.textContent;
    }
}

function getChatRoomMessages(chat_id) {
    window.ws.send(JSON.stringify({
        action: "get_messages",
        chat_id: chat_id
    }));
}

function renderChatRoomMessages(messages) {
    const messagesContainer = document.getElementById("chat-messages");
    messagesContainer.innerHTML = "";
    messages.slice().reverse().forEach(msg => renderMessage(msg));
}

function renderMessage(message) {
    const messagesContainer = document.getElementById("chat-messages");
    const msgDiv = document.createElement("div");
    msgDiv.classList.add("chat-message");

    if (message.from === window.currentUser) {
        msgDiv.classList.add("chat-message-sent");
    } else {
        msgDiv.classList.add("chat-message-received");
    }

    msgDiv.innerHTML = `
        <div class="message-bubble">
            <div class="message-author">${message.from}</div>
            <div class="message-content">${message.msg_content}</div>
            <div class="message-timestamp">${new Date(message.timestamp).toLocaleTimeString()}</div>
        </div>
    `;

    messagesContainer.appendChild(msgDiv);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
}

function sendMessage() {
    const input = document.getElementById("message-input");
    const message = input.value.trim();
    if (!message || !window.currentChatRoom) return;

    window.ws.send(JSON.stringify({
        action: "send_message",
        chat_id: window.currentChatRoom,
        msg_content: message
    }));

    renderMessage({
        from: window.currentUser,
        msg_content: message,
        timestamp: Date.now()
    });

    input.value = "";
}

// ========== Group Chat Modal ===========

let groupModal = null;
let selectedParticipants = new Set();

function initGroupModal() {
    groupModal = document.getElementById('group-modal');

    document.querySelector('.close-modal')?.addEventListener('click', closeGroupModal);
    document.getElementById('create-group-btn')?.addEventListener('click', createGroup);

    window.addEventListener('click', (e) => {
        if (e.target === groupModal) closeGroupModal();
    });
}

function showCreateGroupModal() {
    loadContactsForModal();
    groupModal.classList.add('show');
    selectedParticipants.clear();
    document.getElementById('group-name').value = '';
}

function closeGroupModal() {
    groupModal.classList.remove('show');
}

function loadContactsForModal() {
    window.ws.send(JSON.stringify({ action: "get_contacts" }));
}

function updateContactsModal(contacts) {
    const contactsList = document.getElementById('contacts-list-modal');
    if (!contactsList) return;

    contactsList.innerHTML = '';

    if (!contacts || contacts.length === 0) {
        contactsList.innerHTML = '<p style="color: #666;">No tienes contactos aún</p>';
        return;
    }

    contacts.forEach(contact => {
        const div = document.createElement('div');
        div.className = 'contact-checkbox';

        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = `contact-${contact}`;
        checkbox.value = contact;
        checkbox.addEventListener('change', (e) => {
            if (e.target.checked) {
                selectedParticipants.add(contact);
            } else {
                selectedParticipants.delete(contact);
            }
        });

        const label = document.createElement('label');
        label.htmlFor = `contact-${contact}`;
        label.textContent = contact;

        div.appendChild(checkbox);
        div.appendChild(label);
        contactsList.appendChild(div);
    });
}

function createGroup() {
    const groupName = document.getElementById('group-name').value.trim();

    if (!groupName) {
        alert('Por favor ingresa un nombre para el grupo');
        return;
    }

    if (selectedParticipants.size === 0) {
        alert('Por favor selecciona al menos un participante');
        return;
    }

    const participants = [window.currentUser, ...Array.from(selectedParticipants)];

    window.ws.send(JSON.stringify({
        action: "create_group_chat",
        group_name: groupName,
        participants: participants
    }));

    closeGroupModal();
}

// Hacer funciones disponibles globalmente
window.getChatRooms = getChatRooms;
window.openChatRoom = openChatRoom;
window.sendMessage = sendMessage;
window.renderMessage = renderMessage;
window.initGroupModal = initGroupModal;
window.showCreateGroupModal = showCreateGroupModal;
window.updateContactsModal = updateContactsModal;