#!/usr/bin/env bash
# ==============================================================================
# display-menu.sh — Switcher dinámico de layouts de pantalla
# Detecta outputs conectados y filtra opciones según disponibilidad
# Qtile + Dunst + Rofi — Arch Linux
# ==============================================================================

DUNST_TIMEOUT=4000
STACK_TAG="displaylayout"

notify() {
    dunstify -u normal -t "$DUNST_TIMEOUT" \
        -h string:x-dunst-stack-tag:"$STACK_TAG" \
        "$1" "$2"
}

# ── Detección de outputs ──────────────────────────────────────────────────────

# Outputs físicamente conectados (excluye disconnected)
is_connected() {
    xrandr --query | grep -q "^$1 connected"
}

# Output virtual existe en xrandr (aunque no esté activo)
virtual_exists() {
    xrandr --query | grep -q "^$1 "
}

HAVE_HDMI=false
HAVE_VIRTUAL=false

is_connected "HDMI1" && HAVE_HDMI=true
virtual_exists "VIRTUAL1" && HAVE_VIRTUAL=true

# ── Definición de layouts ─────────────────────────────────────────────────────

apply_laptop_only() {
    xrandr \
        --output eDP1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
        --output HDMI1 --off \
        --output VIRTUAL1 --off 2>/dev/null || true

    notify " Solo laptop" "eDP1: activo\nHDMI1: apagado\nVIRTUAL1: apagado"
}

apply_extend_hdmi() {
    xrandr \
        --output eDP1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
        --output HDMI1 --mode 1920x1080 --pos 1920x0 --rotate normal \
        --output VIRTUAL1 --off 2>/dev/null || true

    notify "󰍹 Extendido → HDMI" "eDP1: principal (izq)\nHDMI1: extendido (der)"
}

apply_mirror_hdmi() {
    xrandr \
        --output eDP1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
        --output HDMI1 --mode 1920x1080 --same-as eDP1 \
        --output VIRTUAL1 --off 2>/dev/null || true

    notify "󰍹 Duplicado → HDMI" "eDP1 + HDMI1: misma imagen"
}

apply_seminario() {
    # Layout: VIRTUAL1 izq | eDP1 centro | HDMI1 der
    # Asegura que el modo del virtual exista
    MODELINE=$(cvt 1920 1080 60 | grep "Modeline" | cut -d' ' -f2-)
    MODENAME=$(echo $MODELINE | cut -d' ' -f1)

    # Crear modo si no existe aún
    xrandr --newmode $MODELINE 2>/dev/null || true
    xrandr --addmode VIRTUAL1 $MODENAME 2>/dev/null || true

    xrandr \
        --output VIRTUAL1 --mode "$MODENAME" --pos 0x0 --rotate normal \
        --output eDP1 --primary --mode 1920x1080 --pos 1920x0 --rotate normal \
        --output HDMI1 --mode 1920x1080 --pos 3840x0 --rotate normal

    notify "󰒇 Modo Seminario" "VIRTUAL1 → eDP1 → HDMI1\nTotal: 5760x1080"
}

# ── Construir menú dinámico ───────────────────────────────────────────────────

# Siempre disponible
OPTIONS=" Solo laptop"

# HDMI solo si está conectado
if $HAVE_HDMI; then
    OPTIONS="$OPTIONS\n󰍹 Extendido → HDMI\n󰍹 Duplicado → HDMI"
fi

# Modo seminario solo si existe VIRTUAL1 Y hay HDMI conectado
if $HAVE_VIRTUAL && $HAVE_HDMI; then
    OPTIONS="$OPTIONS\n󰒇 Modo Seminario"
fi

# ── Menú Rofi ────────────────────────────────────────────────────────────────

SELECTED=$(echo -e "$OPTIONS" | rofi \
    -dmenu \
    -i \
    -p "󰍹" \
    -theme ~/.config/rofi/power-profile.rasi \
    -mesg "Selecciona un layout de pantalla" \
    -no-custom \
    -selected-row 0)

case "$SELECTED" in
    " Solo laptop")       apply_laptop_only ;;
    "󰍹 Extendido → HDMI") apply_extend_hdmi ;;
    "󰍹 Duplicado → HDMI") apply_mirror_hdmi ;;
    "󰒇 Modo Seminario")   apply_seminario ;;
    *) exit 0 ;;
esac
