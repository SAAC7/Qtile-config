#!/usr/bin/env bash
# ==============================================================================
# gaming-profile.sh — Switcher de perfiles de rendimiento
# Qtile + Dunst + TLP — Arch Linux
#
# Perfiles:
#   gaming      → TLP AC forzado, governor performance, gamemode, idle off
#   performance → TLP AC forzado, governor performance, gamemode manual
#   balanced    → TLP normal, governor schedutil, gamemode off
#   powersave   → TLP BAT forzado, governor powersave, gamemode off
#
# Integración: llama a idle-profile.sh para gestionar DPMS/suspensión
# ==============================================================================

DUNST_TIMEOUT=4000
STACK_TAG="gameprofile"
STATE_FILE="/tmp/gaming-profile-current"
IDLE_SCRIPT="$HOME/.config/rofi/scripts/idle-profile.sh"

notify() {
    dunstify -u normal -t "$DUNST_TIMEOUT" \
        -h string:x-dunst-stack-tag:"$STACK_TAG" \
        "$1" "$2"
}

get_current() {
    cat "$STATE_FILE" 2>/dev/null || echo "balanced"
}

get_governor() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown"
}

is_gamemode_active() {
    gamemoded --status 2>/dev/null | grep -q "is active" && echo "activo" || echo "inactivo"
}

# ── Helpers ──────────────────────────────────────────────────────────────────

set_governor() {
    sudo cpupower frequency-set -g "$1" &>/dev/null
}

set_vm_map() {
    sudo sysctl -w vm.max_map_count=2147483642 &>/dev/null
}

stop_gamemode() {
    pkill gamemoded 2>/dev/null || true
}

start_gamemode() {
    pkill gamemoded 2>/dev/null || true
    gamemoded -r &>/dev/null &
    disown
}

# ── Perfiles ─────────────────────────────────────────────────────────────────

apply_gaming() {
    # TLP: forzar modo AC (máximo rendimiento, ignora batería)
    sudo tlp ac &>/dev/null

    set_governor performance
    set_vm_map
    start_gamemode

    # Idle: desactivar todo (no queremos que la pantalla se apague jugando)
    bash "$IDLE_SCRIPT" --apply pelicula 2>/dev/null || true
    echo "gaming" > /tmp/idle-profile-current

    # Desactivar DPMS directamente como respaldo
    xset -dpms
    xset s off
    xset s noblank

    echo "gaming" > "$STATE_FILE"
    notify " Modo Gaming" \
        "TLP: AC forzado\nCPU: performance\nGamemode: activado\nIdle: desactivado"
}

apply_performance() {
    sudo tlp ac &>/dev/null
    set_governor performance
    set_vm_map
    stop_gamemode

    # Idle: restaurar normal (las pantallas sí pueden apagarse)
    echo "normal" > /tmp/idle-profile-current
    xset +dpms
    xset dpms 300 300 310
    xset s 300 10

    echo "performance" > "$STATE_FILE"
    notify " Modo Performance" \
        "TLP: AC forzado\nCPU: performance\nGamemode: manual\nIdle: normal"
}

apply_balanced() {
    # TLP: devolver control automático según fuente de alimentación
    sudo tlp start &>/dev/null

    set_governor schedutil
    stop_gamemode

    echo "normal" > /tmp/idle-profile-current
    xset +dpms
    xset dpms 300 300 310
    xset s 300 10

    echo "balanced" > "$STATE_FILE"
    notify " Modo Balanced" \
        "TLP: automático\nCPU: schedutil\nGamemode: inactivo\nIdle: normal"
}

apply_powersave() {
    # TLP: forzar modo batería
    sudo tlp bat &>/dev/null

    set_governor powersave
    stop_gamemode

    echo "normal" > /tmp/idle-profile-current
    xset +dpms
    xset dpms 120 120 130
    xset s 120 10

    echo "powersave" > "$STATE_FILE"
    notify " Modo Power Save" \
        "TLP: BAT forzado\nCPU: powersave\nGamemode: inactivo\nIdle: agresivo (2min)"
}

show_status() {
    local gov gm tlp_mode idle
    gov=$(get_governor)
    gm=$(is_gamemode_active)
    tlp_mode=$(tlp-stat -s 2>/dev/null | grep "Mode" | head -1 | awk '{print $NF}' || echo "unknown")
    idle=$(cat /tmp/idle-profile-current 2>/dev/null || echo "unknown")

    notify "󰕾 Estado actual" \
        "CPU governor: $gov\nGamemode: $gm\nTLP: $tlp_mode\nIdle: $idle"
}

# ── Manejo de argumento directo (para idle-profile.sh) ───────────────────────
# Permite llamadas como: gaming-profile.sh --apply gaming
if [[ "$1" == "--apply" ]]; then
    case "$2" in
        gaming)     apply_gaming ;;
        performance) apply_performance ;;
        balanced)   apply_balanced ;;
        powersave)  apply_powersave ;;
    esac
    exit 0
fi

# ── Menú Rofi ────────────────────────────────────────────────────────────────

CURRENT=$(get_current)
case "$CURRENT" in
    gaming)      CURRENT_LABEL="Gaming" ;;
    performance) CURRENT_LABEL="Performance" ;;
    balanced)    CURRENT_LABEL="Balanced" ;;
    powersave)   CURRENT_LABEL="Power Save" ;;
    *)           CURRENT_LABEL="Desconocido" ;;
esac

OPTIONS=" Gaming\n Performance\n Balanced\n Power Save\n󰕾 Ver estado"

SELECTED=$(echo -e "$OPTIONS" | rofi \
    -dmenu \
    -i \
    -p "" \
    -theme ~/.config/rofi/power-profile.rasi \
    -mesg "Perfil actual: $CURRENT_LABEL" \
    -no-custom \
    -selected-row 0)

case "$SELECTED" in
    " Gaming")      apply_gaming ;;
    " Performance") apply_performance ;;
    " Balanced")    apply_balanced ;;
    " Power Save")  apply_powersave ;;
    "󰕾 Ver estado") show_status ;;
    *) exit 0 ;;
esac
