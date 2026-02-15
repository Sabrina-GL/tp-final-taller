#!/bin/bash
# Script para demostrar el cliente por consola del chat

echo "=================================================="
echo "   DEMO - Cliente por consola (Python)"  
echo "=================================================="
echo ""
echo "Este script te guiará para probar el cliente."
echo ""

# Verificar si el servidor está corriendo
echo "🔍 Verificando servidor..."
if curl -s http://localhost:4000 > /dev/null 2>&1; then
    echo "✅ Servidor corriendo en http://localhost:4000"
else
    echo "❌ El servidor NO está corriendo"
    echo ""
    echo "Por favor, inicia el servidor primero:"
    echo "  cd chat_app && iex -S mix"
    echo ""
    exit 1
fi

# Verificar dependencias de Python
echo ""
echo "🔍 Verificando dependencias Python..."
if python3 -c "import websocket; import requests" 2>/dev/null; then
    echo "✅ Dependencias instaladas"
else
    echo "❌ Faltan dependencias"
    echo ""
    echo "Instalando dependencias..."
    pip install -r requirements.txt
fi

echo ""
echo "=================================================="
echo "  🚀 Iniciando cliente..."
echo "=================================================="
echo ""
echo "INSTRUCCIONES:"
echo "1. Primero REGISTRA un usuario (opción 1)"
echo "2. Luego INICIA SESIÓN (opción 2)"  
echo "3. Usa el menú para probar las features"
echo ""
echo "Presiona Enter para continuar..."
read

# Ejecutar el cliente
python3 client.py
