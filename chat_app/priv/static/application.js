let ws = null;
let currentUser = null;
let currentChatRoom = null;

document.addEventListener('DOMContentLoaded', function () {
    console.log("DOM cargado");

    // Obtener usuario de la URL
    const urlParams = new URLSearchParams(window.location.search);
    const username = urlParams.get('user');

    if (!username) {
        window.location = "/login";
        return;
    }

    console.log("Usuario:", username);

    const addButton = document.getElementById('add-contact-btn');
    if (addButton) {
        addButton.addEventListener('click', function () {
            if (typeof window.addContact === 'function') {
                window.addContact();

            }
        });
    }

    const sendButton = document.getElementById('send-message-btn');
    if (sendButton) {
        sendButton.addEventListener('click', function () {
            if (typeof window.sendMessage === 'function') {
                window.sendMessage();
            }
        });
    }

    // Iniciar WebSocket
    connectWebSocket(username);
});

function connectWebSocket(username) {
    if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
        ws.close();
    }

    currentUser = username
    console.log("Conectando al usuario:", username)
    ws = new WebSocket(`ws://localhost:4000/ws?user=${username}`);

    ws.onopen = function () {
        console.log("WebSocket conectado")
        // Pido los datos al conectar
        getContacts()
        getChatRooms()
    }

    ws.onmessage = function (e) {
        console.log("Recibido:", e.data)
        const msg = JSON.parse(e.data);


        if (msg.contacts) renderContacts(msg.contacts);
        if (msg.chatrooms) renderChatRooms(msg.chatrooms);
        if (msg.status == "chat_opened") openChatRoom(msg.chat_id);
        if (msg.status == "new_message") renderMessage(msg.msg_content);
        if (msg.type == "new_chatroom") addChatRoomToList(msg.chat_id);
        if (msg.error) {
            alert(`Error: ${msg.error}`);
        }
    }

    ws.onerror = function (e) {
        console.log("Error WebSocket:", e)
    }

    ws.onclose = function (e) {
        console.log("WebSocket cerrado:", e);
    }
}



function getContacts() {
    ws.send(JSON.stringify({
        action: "get_contacts"
        // username: username.value
    }));
}

function addContact() {
    if (!ws || ws.readyState !== WebSocket.OPEN) {
        alert("WebSocket no está conectado");
        return;
    }

    const contact = document.getElementById("contact");
    if (!contact.value) {
        alert("Por favor ingrese un nombre de contacto");
        return;
    }

    ws.send(JSON.stringify({
        action: "add_contact",
        // username: username.value,
        contact: contact.value
    }));

    openChatRoom(`${[currentUser, contact.value].sort().join(":")}`);

    // Limpio el campo de contacto
    contact.value = "";
}

function renderContacts(contacts) {
    const list = document.getElementById("contacts-list");
    list.innerHTML = "";

    contacts.forEach(c => {
        const ul = document.createElement("ul");
        ul.textContent = c;
        list.appendChild(ul);
    });
}

function getChatRooms() {
    ws.send(JSON.stringify({
        action: "get_chatrooms"
    }));
}

function openChatRoom(chat_id) {
    console.log("Abriendo chat room:", chat_id)
    currentChatRoom = chat_id;

    document.getElementById("chat-container").style.display = "block";
    document.getElementById("chat-title").textContent = `Chatroom: ${chat_id}`;
    document.getElementById("chat-messages").innerHTML = "";

    //cargar mensajes
}

function renderChatRooms(chatrooms) {
    chatrooms.forEach(c => {
        addChatRoomToList(c);
    });
}

function addChatRoomToList(chat_id) {
    const list = document.getElementById("chatrooms-list");
    list.innerHTML = "";

    const ul = document.createElement("ul");
    ul.textContent = chat_id;
    ul.addEventListener('click', function () {
        openChatRoom(chat_id);
    });
    list.appendChild(ul);
}

function renderMessage(message) {
    const messagesContainer = document.getElementById("chat-messages");
    const msgDiv = document.createElement("div");
    msgDiv.textContent = `${message.from}: ${message.msg_content}`;
    messagesContainer.appendChild(msgDiv);
    //messagesContainer.scrollTop = messagesContainer.scrollHeight;
}

function sendMessage() {
    const input = document.getElementById("message-input");
    const message = input.value.trim();
    if (!message) return;

    ws.send(JSON.stringify({
        action: "send_message",
        chat_id: currentChatRoom,
        msg_content: message
    }));

    input.value = "";
}




