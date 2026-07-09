#!/usr/bin/env bash
# ==============================================================================
# display-menu-dynamic.sh — Switcher UNIVERSAL de layouts de pantalla
# Detecta cualquier cantidad/tipo de puertos (HDMI, DP, VGA, eDP) y crea
# opciones al vuelo.
# ==============================================================================

DUNST_TIMEOUT=4000
STACK_TAG="displaylayout"

notify() {
    dunstify -u normal -t "$DUNST_TIMEOUT" -h string:x-dunst-stack-tag:"$STACK_TAG" "$1" "$2"
}

# ── 1. Detección Dinámica de Hardware ─────────────────────────────────────────

# Leer todos los monitores físicamente conectados en un Array (lista)
mapfile -t CONNECTED_MONITORS < <(xrandr --query | grep " connected" | cut -d" " -f1)
NUM_MONITORS=${#CONNECTED_MONITORS[@]}

if [ "$NUM_MONITORS" -eq 0 ]; then
    notify "Error de Pantalla" "No se detectaron monitores conectados."
    exit 1
fi

# Detectar el monitor principal actual (si existe la flag 'primary')
PRIMARY_MONITOR=$(xrandr --query | grep " connected primary" | cut -d" " -f1)

# Si el sistema no tiene uno marcado como principal, tomamos el primero de la lista
if [ -z "$PRIMARY_MONITOR" ]; then
    PRIMARY_MONITOR="${CONNECTED_MONITORS[0]}"
fi

# ── 2. Construcción Dinámica del Menú ─────────────────────────────────────────

OPTIONS=""

# A) Opción de usar SOLO una pantalla (crea una opción por cada monitor conectado)
for mon in "${CONNECTED_MONITORS[@]}"; do
    if [ "$mon" == "$PRIMARY_MONITOR" ]; then
        OPTIONS+="󰍹 Solo $mon (Principal)\n"
    else
        OPTIONS+="󰍹 Solo $mon\n"
    fi
done

# B) Opciones Multi-monitor (solo si hay 2 o más pantallas)
if [ "$NUM_MONITORS" -gt 1 ]; then
    OPTIONS+="󰒇 Extender todas (Derecha)\n"
    OPTIONS+="󰍹 Duplicar principal en todas\n"
fi

# Limpiar saltos de línea extra para Rofi
OPTIONS=$(echo -e "$OPTIONS" | sed '/^$/d')

# ── 3. Menú Rofi ─────────────────────────────────────────────────────────────

SELECTED=$(echo -e "$OPTIONS" | rofi \
    -dmenu \
    -i \
    -p "󰍹" \
    -theme ~/.config/rofi/power-profile.rasi \
    -mesg "Layouts ($NUM_MONITORS detectados | Principal: $PRIMARY_MONITOR)" \
    -no-custom)

# Si el usuario presiona Esc
if [ -z "$SELECTED" ]; then
    exit 0
fi

# ── 4. Ejecución Dinámica de xrandr ──────────────────────────────────────────

# Preparamos el comando base
XRANDR_CMD="xrandr"

if [[ "$SELECTED" == *"Solo "* ]]; then
    # Extraemos el nombre exacto del monitor elegido limpiando el texto de la opción
    TARGET_MON=$(echo "$SELECTED" | awk '{print $3}') # Toma la 3ra palabra (ej: eDP1)
    
    # Encendemos el elegido y apagamos el resto
    for mon in "${CONNECTED_MONITORS[@]}"; do
        if [ "$mon" == "$TARGET_MON" ]; then
            XRANDR_CMD+=" --output $mon --auto --primary"
        else
            XRANDR_CMD+=" --output $mon --off"
        fi
    done
    
    eval "$XRANDR_CMD"
    notify "Pantalla" "Activado únicamente: $TARGET_MON"

elif [[ "$SELECTED" == *"Extender todas"* ]]; then
    # El primario va primero, los demás se ponen a su derecha secuencialmente
    XRANDR_CMD+=" --output $PRIMARY_MONITOR --auto --primary"
    PREV_MON="$PRIMARY_MONITOR"
    
    for mon in "${CONNECTED_MONITORS[@]}"; do
        if [ "$mon" != "$PRIMARY_MONITOR" ]; then
            XRANDR_CMD+=" --output $mon --auto --right-of $PREV_MON"
            PREV_MON="$mon" # Actualizamos para que el siguiente vaya a la derecha de este
        fi
    done
    
    eval "$XRANDR_CMD"
    notify "󰒇 Modo Extendido" "$NUM_MONITORS monitores activos"

elif [[ "$SELECTED" == *"Duplicar"* ]]; then
    # El primario manda, todos los demás copian su imagen (--same-as)
    XRANDR_CMD+=" --output $PRIMARY_MONITOR --auto --primary"
    
    for mon in "${CONNECTED_MONITORS[@]}"; do
        if [ "$mon" != "$PRIMARY_MONITOR" ]; then
            XRANDR_CMD+=" --output $mon --auto --same-as $PRIMARY_MONITOR"
        fi
    done
    
    eval "$XRANDR_CMD"
    notify "󰍹 Modo Duplicado" "Clonando $PRIMARY_MONITOR en el resto"
fi
