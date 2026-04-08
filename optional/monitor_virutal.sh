#!/bin/bash

# 1. Definir variables
OUTPUT="VIRTUAL1"
WIDTH=1920
HEIGHT=1080
REFRESH=60

# 2. Generar el modeline automáticamente con cvt
# Extraemos solo la parte del modeline (lo que va después de "Modeline ")
MODELINE=$(cvt $WIDTH $HEIGHT $REFRESH | grep "Modeline" | cut -d' ' -f2-)

# 3. Extraer el nombre del modo (normalmente "1920x1080_60.00")
MODENAME=$(echo $MODELINE | cut -d' ' -f1)

# 4. Ejecutar comandos de xrandr
echo "Configurando resolución $MODENAME para $OUTPUT..."

# Crear el nuevo modo
xrandr --newmode $MODELINE

# Añadir el modo a la salida virtual
xrandr --addmode $OUTPUT $MODENAME

# Activar la resolución
xrandr --output $OUTPUT --mode $MODENAME

echo "¡Listo! La resolución ha sido aplicada."
