// chatrooms.js
let searchResults = [];
let currentSearchIndex = -1;
let selectedFile = null;
let currentBlockTarget = null;

// ========== Initialization ===========

function initFileUpload() {
    const attachBtn = document.getElementById('attach-file-btn');
    const fileInput = document.getElementById('file-input');
    const clearFileBtn = document.getElementById('clear-selected-file-btn');

    attachBtn?.addEventListener('click', () => {
        fileInput.click();
    });
    fileInput?.addEventListener('change', (e) => {
        const file = e.target.files?.[0] ?? null;
        selectedFile = file;
        updateSelectedFileUI();
    });

    clearFileBtn?.addEventListener('click', () => {
        clearSelectedFile({ notify: true });
    });
}

function updateSelectedFileUI() {
    const indicator = document.getElementById('selected-file-indicator');
    const fileLabel = document.getElementById('selected-file-name');
    const messageInput = document.getElementById('message-input');

    if (!indicator || !fileLabel || !messageInput) return;

    if (!selectedFile) {
        indicator.classList.add('hidden');
        fileLabel.textContent = '';
        messageInput.placeholder = 'Escribí un mensaje...';
        return;
    }

    const sizeLabel = formatFileSize(selectedFile.size || 0);
    fileLabel.textContent = `📎 ${selectedFile.name} (${sizeLabel}) listo para enviar`;
    messageInput.placeholder = 'Presioná Enter o Enviar para adjuntar';
    indicator.classList.remove('hidden');
}

function clearSelectedFile(options = {}) {
    const { notify = false } = options;
    selectedFile = null;

    const fileInput = document.getElementById('file-input');
    if (fileInput) {
        fileInput.value = '';
    }

    updateSelectedFileUI();

    if (notify) {
        window.safeNotify?.('Adjunto cancelado');
    }
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

function initMessageInput() {
    const messageInput = document.getElementById('message-input');

    messageInput?.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            sendMessage();
        }
    });
}

function initGroupModal() {
    groupModal = document.getElementById('group-modal');
    document.querySelector('.close-modal')?.addEventListener('click', closeGroupModal);
    document.getElementById('create-group-btn')?.addEventListener('click', createGroup);
    window.addEventListener('click', (e) => e.target === groupModal && closeGroupModal());
}

function initChatHeaderActions() {
    const blockBtn = document.getElementById('block-chat-user-btn');

    blockBtn?.addEventListener('click', async () => {
        if (!currentBlockTarget) return;

        const targetToBlock = currentBlockTarget;
        const confirmed = await (window.confirmAction?.(`¿Bloquear a ${currentBlockTarget}?`) ?? Promise.resolve(true));
        if (!confirmed) return;

        const sent = window.sendWs?.({ action: "block_contact", contact: targetToBlock });
        if (sent) {
            window.safeNotify?.(`${targetToBlock} fue bloqueado`);

            if (window.currentChatRoom && getPrivateChatPeer(window.currentChatRoom) === targetToBlock) {
                window.currentChatRoom = null;
                clearSelectedFile();
                updateChatHeaderActions(null);

                const title = document.getElementById('chat-title');
                const messages = document.getElementById('chat-messages');

                if (title) title.textContent = 'Chat';
                if (messages) messages.innerHTML = '';
            }

            window.getContacts?.();
            window.getChatRooms?.();
            window.loadBlockedContacts?.();
        }
    });
}

function getPrivateChatPeer(chatId) {
    if (!chatId || chatId.startsWith('group:')) return null;

    const parts = chatId.split(':');
    if (parts.length !== 2) return null;
    if (!parts.includes(window.currentUser)) return null;

    return parts.find((name) => name !== window.currentUser) || null;
}

function updateChatHeaderActions(chatId) {
    const actions = document.getElementById('chat-header-actions');
    if (!actions) return;

    currentBlockTarget = getPrivateChatPeer(chatId);

    if (currentBlockTarget) {
        actions.classList.remove('hidden');
    } else {
        actions.classList.add('hidden');
    }
}

// ========== Chat Rooms ===========

function getChatRooms() { window.sendWs?.({ action: "get_chatrooms" }, { silent: true }); }

function openChatRoom(chat_id) {
    console.log("Abriendo chat room:", chat_id);
    window.currentChatRoom = chat_id;
    clearSelectedFile();
    updateChatHeaderActions(chat_id);

    let title;
    if (chat_id.startsWith("group:")) {
        title = "Grupo: " + chat_id.slice("group:".length);
    } else {
        const users = chat_id.split(":");
        const otherUser = users.find(u => u !== window.currentUser);
        title = otherUser || chat_id;
    }

    document.getElementById("chat-title").textContent = title;
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
    let chatTitle;
    if (chat_id.startsWith("group:")) {
        chatTitle = "Grupo: " + chat_id.slice("group:".length);
    } else {
        const users = chat_id.split(":");
        const otherUser = users.find(u => u !== window.currentUser);
        chatTitle = otherUser || chat_id;
    }

    li.textContent = chatTitle
    li.addEventListener('click', () => openChatRoom(chat_id));
    list.appendChild(li);
}

// ========== Messages ===========

function getChatRoomMessages(chat_id) {
    window.sendWs?.({ action: "get_messages", chat_id }, { silent: true });
}

function renderChatRoomMessages(messages) {
    const messagesContainer = document.getElementById("chat-messages");
    messagesContainer.innerHTML = "";
    messages
        .slice()
        .sort(compareMessagesByChronology)
        .forEach(msg => renderMessage(msg));
}

function parseTimestampToDate(rawTimestamp) {
    if (rawTimestamp === null || rawTimestamp === undefined || rawTimestamp === "") return null;

    if (typeof rawTimestamp === "number") {
        const millis = rawTimestamp > 1e12 ? rawTimestamp : rawTimestamp * 1000;
        const date = new Date(millis);
        return Number.isNaN(date.getTime()) ? null : date;
    }

    if (typeof rawTimestamp === "string") {
        const trimmed = rawTimestamp.trim();
        if (!trimmed) return null;

        if (/^\d+$/.test(trimmed)) {
            const num = Number(trimmed);
            const millis = num > 1e12 ? num : num * 1000;
            const date = new Date(millis);
            return Number.isNaN(date.getTime()) ? null : date;
        }

        const normalized = trimmed.includes("T") && !trimmed.endsWith("Z") && !/[+-]\d{2}:\d{2}$/.test(trimmed)
            ? `${trimmed}Z`
            : trimmed;

        const parsed = new Date(normalized);
        if (!Number.isNaN(parsed.getTime())) return parsed;

        const fallback = new Date(trimmed);
        return Number.isNaN(fallback.getTime()) ? null : fallback;
    }

    return null;
}

function formatMessageTimestamp(rawTimestamp) {
    const date = parseTimestampToDate(rawTimestamp);
    if (!date) return "--:--:--";
    return date.toLocaleTimeString();
}

function compareMessagesByChronology(messageA, messageB) {
    const dateA = parseTimestampToDate(messageA?.timestamp);
    const dateB = parseTimestampToDate(messageB?.timestamp);

    if (dateA && dateB) {
        const timeDiff = dateA.getTime() - dateB.getTime();
        if (timeDiff !== 0) return timeDiff;
    } else if (dateA && !dateB) {
        return -1;
    } else if (!dateA && dateB) {
        return 1;
    }

    const idA = Number(messageA?.id);
    const idB = Number(messageB?.id);

    if (!Number.isNaN(idA) && !Number.isNaN(idB) && idA !== idB) {
        return idA - idB;
    }

    const rawA = String(messageA?.id ?? "");
    const rawB = String(messageB?.id ?? "");
    return rawA.localeCompare(rawB);
}

function renderMessage(message) {
    if (message.file_name) return renderFileMessage(message);

    const messagesContainer = document.getElementById("chat-messages");
    const msgDiv = document.createElement("div");
    msgDiv.classList.add("chat-message", message.from === window.currentUser ? "chat-message-sent" : "chat-message-received");
    msgDiv.setAttribute("data-message-id", message.id);

    const deleteBtn = message.from === window.currentUser ?
        '<button class="delete-message-btn" title="Eliminar mensaje">🗑️</button>' : '';

    const safeFrom = window.escapeHtml?.(message.from) ?? "";
    const safeContent = window.escapeHtml?.(message.msg_content) ?? "";
    const safeTimestamp = window.escapeHtml?.(formatMessageTimestamp(message.timestamp)) ?? "";

    msgDiv.innerHTML = `
        <div class="message-bubble">
            <div class="message-author">${safeFrom}</div>
            <div class="message-content">${safeContent}</div>
            <div class="message-footer">
                ${deleteBtn}
                <div class="message-timestamp">${safeTimestamp}</div>
            </div>
        </div>
    `;

    if (message.from === window.currentUser) {
        const btn = msgDiv.querySelector('.delete-message-btn');
        btn.addEventListener('click', async (e) => {
            e.stopPropagation();
            const confirmed = await (window.confirmAction?.('¿Eliminar este mensaje?') ?? Promise.resolve(true));
            if (confirmed) {
                window.sendWs?.({
                    action: "delete_message",
                    message_id: message.id,
                    chat_id: window.currentChatRoom
                });
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

    window.sendWs?.({ action: "send_message", chat_id: window.currentChatRoom, msg_content: message });
    input.value = "";
}

// ========== File Upload ===========

function sendFile() {
    if (!selectedFile || !window.currentChatRoom) return;

    const fileToSend = selectedFile;

    const maxFileSizeBytes = 5 * 1024 * 1024;
    if (fileToSend.size > maxFileSizeBytes) {
        window.safeNotify?.("El archivo supera el límite de 5MB");
        clearSelectedFile();
        return;
    }

    if (!fileToSend.type) {
        window.safeNotify?.("No se pudo detectar el tipo de archivo");
        clearSelectedFile();
        return;
    }

    const reader = new FileReader();
    reader.onload = function (e) {
        const base64Content = e.target.result.split(',')[1];

        window.sendWs?.({
            action: "send_file",
            chat_id: window.currentChatRoom,
            file_name: fileToSend.name,
            file_type: fileToSend.type,
            file_content: base64Content
        });

        document.getElementById('message-input').value = '';
        clearSelectedFile();
    };
    reader.readAsDataURL(fileToSend);
}

function renderFileMessage(fileData) {
    const messagesContainer = document.getElementById("chat-messages");
    const msgDiv = document.createElement("div");
    msgDiv.classList.add("chat-message", fileData.from === window.currentUser ? "chat-message-sent" : "chat-message-received");
    msgDiv.setAttribute("data-message-id", fileData.id || Date.now());

    const fileSize = fileData.file_size ? formatFileSize(fileData.file_size) : '';

    const deleteBtn = fileData.from === window.currentUser ?
        '<button class="delete-message-btn" title="Eliminar mensaje">🗑️</button>' : '';

    const safeFrom = window.escapeHtml?.(fileData.from) ?? "";
    const safeFileName = window.escapeHtml?.(fileData.file_name) ?? "archivo";
    const safeFileSize = window.escapeHtml?.(fileSize) ?? "";
    const safeTimestamp = window.escapeHtml?.(formatMessageTimestamp(fileData.timestamp)) ?? "";
    const safeDownload = window.escapeHtml?.(`/${fileData.file_path || ""}`) ?? "";

    msgDiv.innerHTML = `
        <div class="message-bubble">
            <div class="message-author">${safeFrom}</div>
            <div class="file-attachment">
                <span class="file-icon">📄</span>
                <div class="file-info">
                    <div class="file-name">${safeFileName}</div>
                    ${fileSize ? `<div class="file-size">${safeFileSize}</div>` : ''}
                </div>
                ${fileData.file_path ?
            `<a href="${safeDownload}" class="download-link" download="${safeFileName}">📥</a>` :
            ''}
            </div>
            <div class="message-timestamp">${safeTimestamp}</div>
            ${deleteBtn}
        </div>
    `;

    if (fileData.from === window.currentUser) {
        const btn = msgDiv.querySelector('.delete-message-btn');
        btn.addEventListener('click', async (e) => {
            e.stopPropagation();
            const confirmed = await (window.confirmAction?.('¿Eliminar este mensaje?') ?? Promise.resolve(true));
            if (confirmed) {
                window.sendWs?.({
                    action: "delete_message",
                    message_id: fileData.id,
                    chat_id: window.currentChatRoom
                });
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
function loadContactsForModal() { window.sendWs?.({ action: "get_contacts" }, { silent: true }); }

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
    if (!groupName) return window.safeNotify?.('Por favor ingresa un nombre para el grupo');
    if (selectedParticipants.size === 0) return window.safeNotify?.('Por favor selecciona al menos un participante');

    window.sendWs?.({
        action: "create_group_chat",
        group_name: groupName,
        participants: [window.currentUser, ...Array.from(selectedParticipants)]
    });

    closeGroupModal();
}

/* ========== Search in Chat =========== */

function performSearch() {
    const query = document.getElementById('search-input').value.trim();
    if (!query || !window.currentChatRoom) return window.safeNotify?.('Ingresá un término para buscar');

    clearHighlights();
    window.sendWs?.({ action: "search_messages", chat_id: window.currentChatRoom, query: query });
}

function renderSearchResults(messages) {
    if (!messages || messages.length === 0) return window.safeNotify?.('No se encontraron mensajes');

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
    initMessageInput();
    initChatHeaderActions();
});

// Hacer funciones disponibles globalmente
window.getChatRooms = getChatRooms;
window.openChatRoom = openChatRoom;
window.sendMessage = sendMessage;
window.renderMessage = renderMessage;
window.initGroupModal = initGroupModal;
window.showCreateGroupModal = showCreateGroupModal;
window.updateContactsModal = updateContactsModal;