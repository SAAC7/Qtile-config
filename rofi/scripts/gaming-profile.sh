#!/usr/bin/env bash
#######################################################
# Gaming profile switcher — Rofi + Dunst
# Qtile / Arch Linux
# Perfiles: performance, balanced, powersave, gaming
#######################################################

DUNST_ICON_OK="dialog-information"
DUNST_ICON_WARN="dialog-warning"
NOTIFY_TIMEOUT=4000

notify() {
    local title="$1"
    local body="$2"
    local icon="${3:-$DUNST_ICON_OK}"
    dunstify -u normal -t "$NOTIFY_TIMEOUT" -i "$icon" \
        -h string:x-dunst-stack-tag:gameprofile \
        "$title" "$body"
}

get_current_governor() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown"
}

get_current_profile() {
    powerprofilesctl get 2>/dev/null || echo "unknown"
}

is_gamemode_active() {
    gamemoded --status 2>/dev/null | grep -q "is active" && echo "activo" || echo "inactivo"
}

apply_performance() {
    # CPU governor
    sudo cpupower frequency-set -g performance &>/dev/null
    # power-profiles-daemon si está disponible
    powerprofilesctl set performance 2>/dev/null
    # vm.max_map_count por si no está persistente
    sudo sysctl -w vm.max_map_count=2147483642 &>/dev/null
    notify " Modo Performance" \
        "CPU: performance\nGamemode: manual\nLatencia mínima activada" \
        "$DUNST_ICON_OK"
}

apply_gaming() {
    sudo cpupower frequency-set -g performance &>/dev/null
    powerprofilesctl set performance 2>/dev/null
    sudo sysctl -w vm.max_map_count=2147483642 &>/dev/null
    # Activar gamemode explícitamente
    gamemoded -r &>/dev/null &
    notify " Modo Gaming" \
        "CPU: performance\nGamemode: activado\nProton-GE listo" \
        "$DUNST_ICON_OK"
}

apply_balanced() {
    sudo cpupower frequency-set -g schedutil &>/dev/null
    powerprofilesctl set balanced 2>/dev/null
    # Detener gamemode si estaba corriendo
    pkill gamemoded 2>/dev/null
    notify " Modo Balanced" \
        "CPU: schedutil\nGamemode: detenido\nBalance energía/rendimiento" \
        "$DUNST_ICON_OK"
}

apply_powersave() {
    sudo cpupower frequency-set -g powersave &>/dev/null
    powerprofilesctl set power-saver 2>/dev/null
    pkill gamemoded 2>/dev/null
    notify " Modo Power Save" \
        "CPU: powersave\nGamemode: detenido\nConsumo mínimo" \
        "$DUNST_ICON_WARN"
}

show_status() {
    local gov
    gov=$(get_current_governor)
    local gm
    gm=$(is_gamemode_active)
    notify "󰕾 Estado actual" \
        "Governor: $gov\nGamemode: $gm" \
        "$DUNST_ICON_OK"
}

# ── Menú rofi ────────────────────────────────────────
OPTIONS=" Gaming\n Performance\n Balanced\n Power Save\n󰕾 Ver estado"

SELECTED=$(echo -e "$OPTIONS" | rofi \
    -dmenu \
    -i \
    -p "" \
    -theme ~/.config/rofi/power-profile.rasi \
    -mesg "Perfil de rendimiento" \
    -no-custom \
    -selected-row 0)

case "$SELECTED" in
    " Gaming")       apply_gaming ;;
    " Performance")  apply_performance ;;
    " Balanced")     apply_balanced ;;
    " Power Save")   apply_powersave ;;
    "󰕾 Ver estado")  show_status ;;
    *)               exit 0 ;;
esac
