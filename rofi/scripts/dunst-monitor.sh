#!/usr/bin/env bash
#######################################################
# Dunst monitor switcher
# Alterna entre pantalla principal (eDP1) y todas
# Qtile + Dunst — Arch Linux
# Monitores:
#   0: eDP1     1920x1080  +1920+0  <- principal (*)
#   1: HDMI1    1920x1080  +3840+0
#   2: VIRTUAL1 1920x1080  +0+0
#######################################################

DUNST_CONF="$HOME/.config/dunst/dunstrc"
NOTIFY_TIMEOUT=3000
STACK_TAG="dunst-monitor"

notify() {
    dunstify -u normal -t "$NOTIFY_TIMEOUT" \
        -h string:x-dunst-stack-tag:"$STACK_TAG" \
        "$1" "$2"
}

# Verificar que el archivo existe
if [ ! -f "$DUNST_CONF" ]; then
    notify "Error" "No se encontró $DUNST_CONF"
    exit 1
fi

# Leer estado actual
CURRENT_FOLLOW=$(grep "^    follow = " "$DUNST_CONF" | awk '{print $3}')

if [ "$CURRENT_FOLLOW" = "none" ]; then
    # ── Modo principal → cambiar a todas las pantallas ──
    sed -i 's/^    monitor = .*/    monitor = 0/' "$DUNST_CONF"
    sed -i 's/^    follow = .*/    follow = mouse/' "$DUNST_CONF"
    MODE=" Todas las pantallas"
    BODY="Mueve el cursor a la pantalla deseada\npara recibir notificaciones ahí"
else
    # ── Modo todas → volver a pantalla principal ──
    sed -i 's/^    monitor = .*/    monitor = 0/' "$DUNST_CONF"
    sed -i 's/^    follow = .*/    follow = none/' "$DUNST_CONF"
    MODE=" Solo pantalla principal"
    BODY=" Solo en Monitor Primario"
fi

# Recargar dunst limpiamente
pkill -x dunst
sleep 0.3
dunst &
disown

# Esperar a que dunst arranque antes de notificar
sleep 0.4
notify "Dunst: $MODE" "$BODY"
