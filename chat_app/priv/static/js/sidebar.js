// sidebar.js
function initSidebar() {
    document.querySelectorAll(".icon-btn").forEach(btn => {
        btn.addEventListener("click", () => {
            const target = btn.getAttribute("data-target");
            const sidebar = document.getElementById("sidebar");

            sidebar.classList.remove("hidden");

            if (window.activeSection === target) {
                closeSidebar();
                return;
            }

            openSection(target);
        });
    });
}

function openSection(section) {
    const sidebar = document.getElementById("sidebar");
    const notificationsSection = document.getElementById("notifications-section");
    const contactsSection = document.getElementById("contacts-section");
    const chatRoomsSection = document.getElementById("chatrooms-section");
    const blockedContactsSection = document.getElementById("blocked-contacts-section");

    sidebar.classList.add("open");

    notificationsSection.classList.add("hidden");
    contactsSection.classList.add("hidden");
    chatRoomsSection.classList.add("hidden");
    blockedContactsSection.classList.add("hidden");

    if (section === "notifications") {
        notificationsSection.classList.remove("hidden");
    } else if (section === "contacts") {
        contactsSection.classList.remove("hidden");
    } else if (section === "chatrooms") {
        chatRoomsSection.classList.remove("hidden");
    } else if (section === "blocked-contacts") {
        blockedContactsSection.classList.remove("hidden");
        loadBlockedContacts();
    }

    window.activeSection = section;
    setActiveSection(section);
}

function closeSidebar() {
    const sidebar = document.getElementById("sidebar");
    sidebar.classList.remove("open");
    clearActiveSection();
    window.activeSection = null;
}

function setActiveSection(section) {
    clearActiveSection();
    document.querySelector(`.icon-btn[data-target="${section}"]`)?.classList.add("active");
}

function clearActiveSection() {
    document.querySelectorAll(".icon-btn").forEach(btn => {
        btn.classList.remove("active");
    });
}

function logout() {
    console.log("Cerrando sesión...");
    if (window.ws && window.ws.readyState === WebSocket.OPEN) {
        window.ws.close();
    }
    window.location = "/login";
}

// Hacer funciones disponibles globalmente
window.openSection = openSection;
window.closeSidebar = closeSidebar;
window.logout = logout;