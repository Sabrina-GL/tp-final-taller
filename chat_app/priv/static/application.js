let ws = null;
let currentUser = null;

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

            } else {
                alert("Función no disponible aún");
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
        //getChatRooms()
    }

    ws.onmessage = function (e) {
        console.log("Recibido:", e.data)
        const msg = JSON.parse(e.data);


        if (msg.contacts) renderContacts(msg.contacts);
        if (msg.chatrooms) renderChatRooms(msg.chatrooms);
        if (msg.chat_opened) openChatRoom(msg.chat_id);
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

function openChatRoom(chat_id) {
    console.log("Abriendo chat room:", chat_id)

    document.getElementById("chat-container").style.display = "block";
    document.getElementById("chat-title").textContent = `Chatroom: ${chat_id}`;
    document.getElementById("chat-messages").innerHTML = "";

    //cargar mensajes
}

function renderChatRooms(chatrooms) {
    const list = document.getElementById("chatrooms-list");
    list.innerHTML = "";

    chatrooms.forEach(c => {
        const ul = document.createElement("ul");
        ul.textContent = c;
        ul.addEventListener('click', function () {
            openChatRoom(c);
        });
        list.appendChild(ul);
    });
}


