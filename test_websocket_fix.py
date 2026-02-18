#!/usr/bin/env python3
"""
Test rápido para verificar que el WebSocket se mantiene conectado
"""
import sys
import time

# Importar el cliente
from client import ChatClient

def main():
    print("🧪 TEST: Verificando conexión WebSocket persistente\n")
    
    # Crear cliente
    client = ChatClient()
    
    # Registrar usuario de prueba (puede fallar si ya existe, ok)
    username = f"test_user_{int(time.time())}"
    password = "test123456"
    
    print(f"1️⃣ Registrando usuario: {username}")
    client.register(username, password)
    
    # Login
    print(f"\n2️⃣ Haciendo login como: {username}")
    if not client.login(username, password):
        print("❌ Login falló")
        return 1
    
    # Esperar a que se establezca la conexión
    time.sleep(1)
    
    # Verificar estado de la conexión
    print(f"\n3️⃣ Estado de conexión WebSocket:")
    print(f"   - Conectado: {client.connected}")
    print(f"   - Username: {client.username}")
    print(f"   - WebSocket: {client.ws is not None}")
    
    if not client.connected:
        print("\n❌ FALLO: WebSocket no está conectado después del login")
        return 1
    
    # Intentar una acción simple
    print(f"\n4️⃣ Probando acción: get_contacts")
    client.get_contacts()
    
    time.sleep(1)
    
    # Verificar que sigue conectado
    print(f"\n5️⃣ Verificando que la conexión persiste:")
    print(f"   - Aún conectado: {client.connected}")
    
    if client.connected:
        print("\n✅ ÉXITO: La conexión WebSocket persiste correctamente")
        return 0
    else:
        print("\n❌ FALLO: La conexión se cerró después de la acción")
        return 1

if __name__ == "__main__":
    sys.exit(main())
