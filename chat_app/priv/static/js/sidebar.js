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
    const contactsSection = document.getElementById("contacts-section");
    const chatRoomsSection = document.getElementById("chatrooms-section");

    sidebar.classList.add("open");

    contactsSection.classList.add("hidden");
    chatRoomsSection.classList.add("hidden");

    if (section === "contacts") {
        contactsSection.classList.remove("hidden");
    } else if (section === "chatrooms") {
        chatRoomsSection.classList.remove("hidden");
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

// Hacer funciones disponibles globalmente
window.openSection = openSection;
window.closeSidebar = closeSidebar;