let ws = null;
let currentUser = null;


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

        // if (msg.contacts) {
        //     const list = document.getElementById("contacts-list");
        //     list.innerHTML = "";
        //     msg.contacts.forEach(contact => {
        //         const item = document.createElement("li");
        //         item.textContent = contact;
        //         list.appendChild(item);
        //     });
        // } else if (msg.error) {
        if (msg.error) {
            alert(`Error: ${msg.error}`);
        } else {
            console.log("Received:", msg);
        }
    }

    //ws.onerror
    //ws.onclose
}



function getContacts() {
    ws.send(JSON.stringify({
        action: "get_contacts"
        // username: username.value
    }));
}

function addContact() {
    ws.send(JSON.stringify({
        action: "add_contact",
        // username: username.value,
        contact: contact.value
    }));
}