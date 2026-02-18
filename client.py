#!/usr/bin/env python3
"""
Cliente por consola para el sistema de chat
Conecta vía WebSocket al servidor Elixir
"""
import websocket
import threading
import json
import sys
import requests
import time
from datetime import datetime

class ChatClient:
    def __init__(self, server_url="http://localhost:4000", ws_url="ws://localhost:4000/ws"):
        self.server_url = server_url
        self.ws_url = ws_url
        self.ws = None
        self.username = None
        self.running = False
        self.connected = False
        
    def register(self, username, password):
        """Registra un nuevo usuario"""
        try:
            response = requests.post(
                f"{self.server_url}/api/register",
                json={"username": username, "password": password},
                timeout=5
            )
            data = response.json()
            if response.status_code == 200:
                print(f"✅ Usuario '{username}' registrado exitosamente")
                return True
            else:
                print(f"❌ Error: {data.get('error', 'Error desconocido')}")
                return False
        except Exception as e:
            print(f"❌ Error de conexión: {e}")
            return False
    
    def login(self, username, password):
        """Inicia sesión y establece conexión WebSocket"""
        try:
            response = requests.post(
                f"{self.server_url}/api/login",
                json={"username": username, "password": password},
                timeout=5
            )
            data = response.json()
            if response.status_code == 200:
                print(f"✅ Login exitoso. Bienvenido {username}!")
                self.username = username
                self.connect_websocket()
                return True
            else:
                print(f"❌ Error: {data.get('error', 'Error desconocido')}")
                return False
        except Exception as e:
            print(f"❌ Error de conexión: {e}")
            return False
    
    def connect_websocket(self):
        """Establece conexión WebSocket"""
        try:
            ws_url = f"{self.ws_url}?user={self.username}"
            self.ws = websocket.WebSocketApp(
                ws_url,
                on_message=self.on_message,
                on_error=self.on_error,
                on_close=self.on_close,
                on_open=self.on_open
            )
            
            # Iniciar WebSocket en un thread separado
            ws_thread = threading.Thread(target=self.ws.run_forever)
            ws_thread.daemon = True
            ws_thread.start()
            
            # Esperar a que se establezca la conexión
            for _ in range(10):
                if self.connected:
                    break
                time.sleep(0.1)
                
        except Exception as e:
            print(f"❌ Error al conectar WebSocket: {e}")
    
    def on_open(self, ws):
        """Callback cuando se abre la conexión WebSocket"""
        self.connected = True
        # El servidor ya identifica al usuario desde ?user=username en la URL
    
    def on_message(self, ws, message):
        """Callback cuando llega un mensaje del servidor"""
        try:
            data = json.loads(message)
            
            # Manejar diferentes tipos de mensajes
            if data.get("type") == "notification":
                print(f"\n🔔 NOTIFICACIÓN: {data.get('message', 'Sin mensaje')}")
                print(f"   De: {data.get('from', 'Desconocido')}")
                if data.get('room_id'):
                    print(f"   Chat: {data.get('room_id')}")
                print()
                
            elif data.get("type") == "new_message" or data.get("status") == "new_message":
                message_data = data.get("message", {})
                print(f"\n💬 MENSAJE NUEVO:")
                print(f"   De: {message_data.get('from', 'Desconocido')}")
                print(f"   Chat: {data.get('chat_id', 'Desconocido')}")
                
                # Check if it's a file message
                if message_data.get('file_name'):
                    print(f"   📎 ARCHIVO: {message_data.get('file_name')}")
                    print(f"      Tipo: {message_data.get('file_type', 'desconocido')}")
                    print(f"      Tamaño: {message_data.get('file_size', 0)} bytes")
                    if message_data.get('file_path'):
                        print(f"      URL: http://localhost:4000/{message_data.get('file_path')}")
                else:
                    print(f"   Contenido: {message_data.get('msg_content', '')}")
                print()
                
            elif data.get("status") == "ok" or data.get("status") == "success":
                # Respuestas exitosas se manejan en send_action con timeout
                pass
            elif data.get("status") == "error":
                print(f"❌ Error del servidor: {data.get('error', 'Error desconocido')}")
                
        except json.JSONDecodeError:
            print(f"⚠️  Mensaje no JSON: {message}")
        except Exception as e:
            print(f"⚠️  Error procesando mensaje: {e}")
    
    def on_error(self, ws, error):
        """Callback cuando hay un error"""
        print(f"❌ Error WebSocket: {error}")
    
    def on_close(self, ws, close_status_code, close_msg):
        """Callback cuando se cierra la conexión"""
        self.connected = False
        print("\n🔌 Conexión WebSocket cerrada")
    
    def send_action(self, action, params=None):
        """Envía una acción al servidor"""
        if not self.ws or not self.connected:
            print("❌ No hay conexión WebSocket activa")
            return None
        
        payload = {
            "action": action,
            "username": self.username
        }
        if params:
            payload.update(params)
        
        try:
            self.ws.send(json.dumps(payload))
            return True
        except Exception as e:
            print(f"❌ Error enviando mensaje: {e}")
            return False
    
    def get_contacts(self):
        """Obtiene la lista de contactos"""
        print("\n📋 Obteniendo contactos...")
        self.send_action("get_contacts")
        time.sleep(0.5)  # Dar tiempo para recibir respuesta
    
    def add_contact(self, contact_username):
        """Agrega un contacto"""
        print(f"\n👤 Agregando contacto: {contact_username}")
        self.send_action("add_contact", {"contact": contact_username})
        time.sleep(0.5)
    
    def get_chatrooms(self):
        """Obtiene la lista de chats"""
        print("\n💭 Obteniendo lista de chats...")
        self.send_action("get_chatrooms")
        time.sleep(0.5)
    
    def create_group_chat(self, name, participants):
        """Crea un chat grupal"""
        print(f"\n👥 Creando chat grupal: {name}")
        print(f"   Participantes: {', '.join(participants)}")
        self.send_action("create_group_chat", {
            "group_name": name,
            "participants": participants
        })
        time.sleep(0.5)
    
    def send_message(self, room_id, content):
        """Envía un mensaje a un chat"""
        print(f"\n📤 Enviando mensaje a {room_id}...")
        self.send_action("send_message", {
            "chat_id": room_id,
            "msg_content": content
        })
        time.sleep(0.3)
    
    def get_messages(self, room_id):
        """Obtiene los últimos mensajes de un chat"""
        print(f"\n📬 Obteniendo mensajes de {room_id}...")
        self.send_action("get_messages", {"chat_id": room_id})
        time.sleep(0.5)
    
    def search_messages(self, room_id, query):
        """Busca mensajes por palabra clave en un chat"""
        print(f"\n🔍 Buscando '{query}' en {room_id}...")
        self.send_action("search_messages", {
            "chat_id": room_id,
            "query": query
        })
        time.sleep(0.5)
    
    def get_status(self, target_username):
        """Obtiene el estado de un usuario"""
        print(f"\n📊 Obteniendo estado de {target_username}...")
        self.send_action("get_status", {"user": target_username})
        time.sleep(0.5)
    
    def block_contact(self, contact_username):
        """Bloquea a un usuario (bidireccional)"""
        print(f"\n🚫 Bloqueando a: {contact_username}")
        self.send_action("block_contact", {"contact": contact_username})
        time.sleep(0.5)
    
    def delete_message(self, room_id, message_id):
        """Elimina un mensaje por ID"""
        print(f"\n🗑️  Eliminando mensaje {message_id} de {room_id}...")
        self.send_action("delete_message", {
            "chat_id": room_id,
            "message_id": message_id
        })
        time.sleep(0.3)
    
    def delete_messages(self, room_id, message_ids):
        """Elimina múltiples mensajes"""
        print(f"\n🗑️  Eliminando {len(message_ids)} mensajes de {room_id}...")
        self.send_action("delete_messages", {
            "chat_id": room_id,
            "message_ids": message_ids
        })
        time.sleep(0.3)
    
    def send_file(self, room_id, file_path):
        """Envía un archivo a un chat"""
        import base64
        import mimetypes
        import os
        
        # Verificar que el archivo existe
        if not os.path.exists(file_path):
            print(f"❌ Error: El archivo '{file_path}' no existe")
            return False
        
        # Obtener tamaño del archivo
        file_size = os.path.getsize(file_path)
        max_size = 5 * 1024 * 1024  # 5MB
        
        if file_size > max_size:
            print(f"❌ Error: El archivo es muy grande ({file_size} bytes). Máximo permitido: {max_size} bytes (5MB)")
            return False
        
        # Detectar tipo MIME
        mime_type, _ = mimetypes.guess_type(file_path)
        if not mime_type:
            mime_type = "application/octet-stream"
        
        # Leer y codificar archivo en base64
        try:
            with open(file_path, "rb") as f:
                file_content = f.read()
                base64_content = base64.b64encode(file_content).decode('utf-8')
            
            filename = os.path.basename(file_path)
            
            print(f"\n📤 Enviando archivo '{filename}' ({file_size} bytes, {mime_type})...")
            
            self.send_action("send_file", {
                "chat_id": room_id,
                "file_content": base64_content,
                "file_name": filename,
                "file_type": mime_type
            })
            time.sleep(0.5)
            return True
            
        except Exception as e:
            print(f"❌ Error al leer el archivo: {e}")
            return False
    
    def disconnect(self):
        """Cierra la conexión"""
        if self.ws:
            self.ws.close()
        self.connected = False
        print("\n👋 Desconectado")

def print_menu():
    """Muestra el menú principal"""
    print("\n" + "="*50)
    print("           MENU PRINCIPAL")
    print("="*50)
    print("1.  Ver contactos")
    print("2.  Agregar contacto")
    print("3.  Bloquear contacto")
    print("4.  Ver chats")
    print("5.  Crear chat grupal")
    print("6.  Enviar mensaje")
    print("7.  Ver mensajes de un chat")
    print("8.  Buscar mensajes en un chat")
    print("9.  Eliminar un mensaje")
    print("10. Eliminar múltiples mensajes")
    print("11. Ver estado de un usuario")
    print("12. Enviar archivo/imagen")
    print("13. Salir")
    print("="*50)

def print_welcome():
    """Muestra el banner de bienvenida"""
    print("\n" + "="*50)
    print("     🚀 CLIENTE DE CHAT - ELIXIR OTP 🚀")
    print("="*50)
    print("1. Registrarse")
    print("2. Iniciar sesión")
    print("3. Salir")
    print("="*50)

def main():
    client = ChatClient()
    
    while True:
        print_welcome()
        opcion = input("\nSeleccione una opción: ").strip()
        
        if opcion == "1":
            print("\n📝 REGISTRO DE USUARIO")
            username = input("Usuario (mínimo 3 caracteres): ").strip()
            password = input("Contraseña (mínimo 6 caracteres): ").strip()
            
            if len(username) < 3:
                print("❌ El usuario debe tener al menos 3 caracteres")
                continue
            if len(password) < 6:
                print("❌ La contraseña debe tener al menos 6 caracteres")
                continue
                
            client.register(username, password)
            
        elif opcion == "2":
            print("\n🔐 INICIO DE SESIÓN")
            username = input("Usuario: ").strip()
            password = input("Contraseña: ").strip()
            
            if client.login(username, password):
                # Sesión activa
                while True:
                    print_menu()
                    menu_opcion = input("\nSeleccione una opción: ").strip()
                    
                    if menu_opcion == "1":
                        client.get_contacts()
                        
                    elif menu_opcion == "2":
                        contact = input("Usuario a agregar: ").strip()
                        client.add_contact(contact)
                        
                    elif menu_opcion == "3":
                        contact = input("Usuario a bloquear: ").strip()
                        client.block_contact(contact)
                        
                    elif menu_opcion == "4":
                        client.get_chatrooms()
                        
                    elif menu_opcion == "5":
                        name = input("Nombre del grupo: ").strip()
                        participants_str = input("Participantes (separados por coma): ").strip()
                        participants = [p.strip() for p in participants_str.split(",")]
                        client.create_group_chat(name, participants)
                        
                    elif menu_opcion == "6":
                        room_id = input("ID del chat: ").strip()
                        content = input("Mensaje: ").strip()
                        client.send_message(room_id, content)
                        
                    elif menu_opcion == "7":
                        room_id = input("ID del chat: ").strip()
                        client.get_messages(room_id)
                        
                    elif menu_opcion == "8":
                        room_id = input("ID del chat: ").strip()
                        query = input("Palabra clave a buscar: ").strip()
                        client.search_messages(room_id, query)
                        
                    elif menu_opcion == "9":
                        room_id = input("ID del chat: ").strip()
                        try:
                            message_id = int(input("ID del mensaje a eliminar: ").strip())
                            client.delete_message(room_id, message_id)
                        except ValueError:
                            print("❌ El ID del mensaje debe ser un número")
                        
                    elif menu_opcion == "10":
                        room_id = input("ID del chat: ").strip()
                        ids_str = input("IDs de mensajes a eliminar (separados por coma): ").strip()
                        try:
                            message_ids = [int(id.strip()) for id in ids_str.split(",")]
                            client.delete_messages(room_id, message_ids)
                        except ValueError:
                            print("❌ Los IDs deben ser números separados por coma")
                        
                    elif menu_opcion == "11":
                        target_user = input("Usuario: ").strip()
                        client.get_status(target_user)
                        
                    elif menu_opcion == "12":
                        room_id = input("ID del chat: ").strip()
                        file_path = input("Ruta del archivo: ").strip()
                        client.send_file(room_id, file_path)
                        
                    elif menu_opcion == "13":
                        client.disconnect()
                        break
                    else:
                        print("❌ Opción inválida")
                
        elif opcion == "3":
            print("\n👋 ¡Hasta luego!")
            sys.exit(0)
        else:
            print("❌ Opción inválida")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Interrumpido por el usuario. ¡Hasta luego!")
        sys.exit(0)
