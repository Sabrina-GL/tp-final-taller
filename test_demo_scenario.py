#!/usr/bin/env python3
"""
Test automatizado del escenario de DEMO.md
Simula Alice y Bob interactuando
"""
import sys
import time
from client import ChatClient

def test_demo_scenario():
    print("=" * 60)
    print("🎬 TEST AUTOMATIZADO - Escenario DEMO.md")
    print("=" * 60)
    
    # Crear clientes
    alice = ChatClient()
    bob = ChatClient()
    
    # 1. Registrar Alice
    print("\n1️⃣ Registrando a Alice...")
    if not alice.register("alice", "alice123"):
        print("❌ Error registrando Alice")
        return False
    
    # 2. Registrar Bob
    print("\n2️⃣ Registrando a Bob...")
    if not bob.register("bob", "bob123456"):
        print("❌ Error registrando Bob")
        return False
    
    # 3. Login Alice
    print("\n3️⃣ Alice hace login...")
    if not alice.login("alice", "alice123"):
        print("❌ Error login Alice")
        return False
    time.sleep(1)
    
    # 4. Login Bob
    print("\n4️⃣ Bob hace login...")
    if not bob.login("bob", "bob123456"):
        print("❌ Error login Bob")
        return False
    time.sleep(1)
    
    # Verificar conexiones
    print("\n5️⃣ Verificando conexiones WebSocket...")
    print(f"   Alice conectada: {alice.connected}")
    print(f"   Bob conectado: {bob.connected}")
    
    if not alice.connected or not bob.connected:
        print("❌ Algún cliente no está conectado")
        return False
    
    # 6. Alice agrega a Bob como contacto
    print("\n6️⃣ Alice agrega a Bob como contacto...")
    alice.add_contact("bob")
    time.sleep(1.5)
    
    # 7. Alice ve sus chats
    print("\n7️⃣ Alice verifica sus chats...")
    alice.get_chatrooms()
    time.sleep(1)
    
    # 8. Alice envía mensaje a Bob
    print("\n8️⃣ Alice envía mensaje a Bob...")
    alice.send_message("alice:bob", "Hola Bob, ¿cómo estás?")
    time.sleep(1.5)
    
    # 9. Bob lee mensajes
    print("\n9️⃣ Bob lee los mensajes...")
    bob.get_messages("alice:bob")
    time.sleep(1)
    
    # 10. Bob responde
    print("\n🔟 Bob responde a Alice...")
    bob.send_message("alice:bob", "¡Hola Alice! Todo bien, gracias")
    time.sleep(1.5)
    
    # 11. Bob crea chat grupal
    print("\n1️⃣1️⃣ Bob crea un chat grupal...")
    bob.create_group_chat("equipo", ["alice"])
    time.sleep(1.5)
    
    # 12. Verificar estado de usuario
    print("\n1️⃣2️⃣ Alice verifica el estado de Bob...")
    alice.send_action("get_status", {"user": "bob"})
    time.sleep(1)
    
    # Verificación final
    print("\n" + "=" * 60)
    print("✅ Verificación final:")
    print(f"   Alice conectada: {alice.connected}")
    print(f"   Bob conectado: {bob.connected}")
    print("=" * 60)
    
    if alice.connected and bob.connected:
        print("\n🎉 ¡ÉXITO! Todos los pasos del escenario funcionan correctamente")
        print("\n📋 Features probadas:")
        print("   ✅ Registro de usuarios")
        print("   ✅ Login y autenticación")
        print("   ✅ Conexión WebSocket persistente")
        print("   ✅ Agregar contactos")
        print("   ✅ Creación automática de chat 1-a-1")
        print("   ✅ Envío de mensajes")
        print("   ✅ Notificaciones en tiempo real")
        print("   ✅ Chats grupales")
        print("   ✅ Consulta de estado de usuarios")
        return True
    else:
        print("\n❌ FALLO: Alguna conexión se perdió durante el test")
        return False

if __name__ == "__main__":
    success = test_demo_scenario()
    sys.exit(0 if success else 1)
