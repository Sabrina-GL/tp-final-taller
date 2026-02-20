// chatrooms.js
let searchResults = [];
let currentSearchIndex = -1;
let selectedFile = null;

// ========== Initialization ===========

function initFileUpload() {
    const attachBtn = document.getElementById('attach-file-btn');
    const fileInput = document.getElementById('file-input');

    attachBtn?.addEventListener('click', () => {
        fileInput.click();
    });
    fileInput?.addEventListener('change', (e) => {
        selectedFile = e.target.files[0];
    });
}

function initSearch() {
    const searchBtn = document.getElementById('search-btn');
    const searchInput = document.getElementById('search-input');
    const prevBtn = document.getElementById('prev-result');
    const nextBtn = document.getElementById('next-result');

    searchBtn?.addEventListener('click', performSearch);
    searchInput?.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') { performSearch(); }
    });
    prevBtn?.addEventListener('click', prevSearchResult);
    nextBtn?.addEventListener('click', nextSearchResult);
}

function initGroupModal() {
    groupModal = document.getElementById('group-modal');
    document.querySelector('.close-modal')?.addEventListener('click', closeGroupModal);
    document.getElementById('create-group-btn')?.addEventListener('click', createGroup);
    window.addEventListener('click', (e) => e.target === groupModal && closeGroupModal());
}

// ========== Chat Rooms ===========

function getChatRooms() { window.ws.send(JSON.stringify({ action: "get_chatrooms" })); }

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

// ========== Messages ===========

function getChatRoomMessages(chat_id) {
    window.ws.send(JSON.stringify({ action: "get_messages", chat_id }));
}

function renderChatRoomMessages(messages) {
    const messagesContainer = document.getElementById("chat-messages");
    messagesContainer.innerHTML = "";
    messages.slice().reverse().forEach(msg => renderMessage(msg));
}

function renderMessage(message) {
    if (message.file_name) return renderFileMessage(message);

    const messagesContainer = document.getElementById("chat-messages");
    const msgDiv = document.createElement("div");
    msgDiv.classList.add("chat-message", message.from === window.currentUser ? "chat-message-sent" : "chat-message-received");
    msgDiv.setAttribute("data-message-id", message.id);

    const deleteBtn = message.from === window.currentUser ?
        '<button class="delete-message-btn" title="Eliminar mensaje">🗑️</button>' : '';

    msgDiv.innerHTML = `
        <div class="message-bubble">
            <div class="message-author">${message.from}</div>
            <div class="message-content">${message.msg_content}</div>
            <div class="message-footer">
                ${deleteBtn}
                <div class="message-timestamp">${new Date(message.timestamp).toLocaleTimeString()}</div>
            </div>
        </div>
    `;

    if (message.from === window.currentUser) {
        const btn = msgDiv.querySelector('.delete-message-btn');
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            if (confirm('¿Eliminar este mensaje?')) {
                window.ws.send(JSON.stringify({
                    action: "delete_message",
                    message_id: message.id,
                    chat_id: window.currentChatRoom
                }));
            }
        });
    }

    messagesContainer.appendChild(msgDiv);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
}

function sendMessage() {
    const input = document.getElementById("message-input");
    const message = input.value.trim();

    if (selectedFile) return sendFile();
    if (!message || !window.currentChatRoom) return;

    window.ws.send(JSON.stringify({ action: "send_message", chat_id: window.currentChatRoom, msg_content: message }));
    renderMessage({ from: window.currentUser, msg_content: message, timestamp: Date.now() });
    input.value = "";
}

// ========== File Upload ===========

function sendFile() {
    if (!selectedFile || !window.currentChatRoom) return;

    const reader = new FileReader();
    reader.onload = function (e) {
        const base64Content = e.target.result.split(',')[1];

        window.ws.send(JSON.stringify({
            action: "send_file",
            chat_id: window.currentChatRoom,
            file_name: selectedFile.name,
            file_type: selectedFile.type,
            file_content: base64Content
        }));

        document.getElementById('file-input').value = '';
        document.getElementById('message-input').placeholder = 'Escribí un mensaje...';
        document.getElementById('message-input').value = '';

        selectedFile = null;
    };
    reader.readAsDataURL(selectedFile);
}

function renderFileMessage(fileData) {
    const messagesContainer = document.getElementById("chat-messages");
    const msgDiv = document.createElement("div");
    msgDiv.classList.add("chat-message", fileData.from === window.currentUser ? "chat-message-sent" : "chat-message-received");
    msgDiv.setAttribute("data-message-id", fileData.id || Date.now());

    const fileSize = fileData.file_size ? formatFileSize(fileData.file_size) : '';

    const deleteBtn = fileData.from === window.currentUser ?
        '<button class="delete-message-btn" title="Eliminar mensaje">🗑️</button>' : '';

    msgDiv.innerHTML = `
        <div class="message-bubble">
            <div class="message-author">${fileData.from}</div>
            <div class="file-attachment">
                <span class="file-icon">📄</span>
                <div class="file-info">
                    <div class="file-name">${fileData.file_name}</div>
                    ${fileSize ? `<div class="file-size">${fileSize}</div>` : ''}
                </div>
                ${fileData.file_path ?
            `<a href="/${fileData.file_path}" class="download-link" download="${fileData.file_name}">📥</a>` :
            ''}
            </div>
            <div class="message-timestamp">${new Date(fileData.timestamp).toLocaleTimeString()}</div>
            ${deleteBtn}
        </div>
    `;

    if (fileData.from === window.currentUser) {
        const btn = msgDiv.querySelector('.delete-message-btn');
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            if (confirm('¿Eliminar este mensaje?')) {
                window.ws.send(JSON.stringify({
                    action: "delete_message",
                    message_id: fileData.id,
                    chat_id: window.currentChatRoom
                }));
            }
        });
    }

    messagesContainer.appendChild(msgDiv);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
}

function formatFileSize(bytes) {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}

// ========== Group Chat Modal ===========

let groupModal = null;
let selectedParticipants = new Set();


function showCreateGroupModal() {
    loadContactsForModal();
    groupModal.classList.add('show');
    selectedParticipants.clear();
    document.getElementById('group-name').value = '';
}

function closeGroupModal() { groupModal.classList.remove('show'); }
function loadContactsForModal() { window.ws.send(JSON.stringify({ action: "get_contacts" })); }

function updateContactsModal(contacts) {
    const contactsList = document.getElementById('contacts-list-modal');
    if (!contactsList) return;

    contactsList.innerHTML = '';

    contacts.forEach(contact => {
        const div = document.createElement('div');
        div.className = 'contact-checkbox';

        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = `contact-${contact}`;
        checkbox.value = contact;
        checkbox.addEventListener('change', (e) => e.target.checked ? selectedParticipants.add(contact) : selectedParticipants.delete(contact));

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
    if (!groupName) return alert('Por favor ingresa un nombre para el grupo');
    if (selectedParticipants.size === 0) return alert('Por favor selecciona al menos un participante');

    window.ws.send(JSON.stringify({
        action: "create_group_chat",
        group_name: groupName,
        participants: [window.currentUser, ...Array.from(selectedParticipants)]
    }));

    closeGroupModal();
}

/* ========== Search in Chat =========== */

function performSearch() {
    const query = document.getElementById('search-input').value.trim();
    if (!query || !window.currentChatRoom) return alert('Ingresá un término para buscar');

    clearHighlights();
    window.ws.send(JSON.stringify({ action: "search_messages", chat_id: window.currentChatRoom, query: query }));
}

function renderSearchResults(messages) {
    if (!messages || messages.length === 0) return alert('No se encontraron mensajes');

    searchResults = messages.slice().reverse();
    currentSearchIndex = searchResults.length - 1; // Empezar por el último

    clearHighlights();
    highlightCurrentMessage();
    goToSearchResult(currentSearchIndex);
}

function highlightCurrentMessage() {
    if (searchResults.length === 0 || currentSearchIndex < 0) return;

    const messageId = searchResults[currentSearchIndex].id;
    document.querySelector(`.chat-message[data-message-id="${messageId}"]`)?.classList.add('highlight');
}

function clearHighlights() {
    document.querySelectorAll('.chat-message').forEach(el => { el.classList.remove('highlight'); });
}

function goToSearchResult(index) {
    if (searchResults.length === 0) return;
    // Asegurar índice válido
    index = index < 0 ? searchResults.length - 1 : (index >= searchResults.length ? 0 : index);

    clearHighlights();
    currentSearchIndex = index;
    highlightCurrentMessage();

    const messageId = searchResults[currentSearchIndex].id;
    const messageElement = document.querySelector(`.chat-message[data-message-id="${messageId}"]`);

    if (messageElement) { messageElement.scrollIntoView({ behavior: 'smooth', block: 'center' }); }

    updateSearchCounter();
}

function updateSearchCounter() {
    const counter = document.getElementById('search-counter');
    if (counter) { counter.textContent = `${currentSearchIndex + 1}/${searchResults.length}`; }
}

function nextSearchResult() { goToSearchResult(currentSearchIndex + 1); }

function prevSearchResult() { goToSearchResult(currentSearchIndex - 1); }

document.addEventListener('DOMContentLoaded', () => {
    initSearch();
    initFileUpload();
});

// Hacer funciones disponibles globalmente
window.getChatRooms = getChatRooms;
window.openChatRoom = openChatRoom;
window.sendMessage = sendMessage;
window.renderMessage = renderMessage;
window.initGroupModal = initGroupModal;
window.showCreateGroupModal = showCreateGroupModal;
window.updateContactsModal = updateContactsModal;