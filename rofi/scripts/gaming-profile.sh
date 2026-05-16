#!/usr/bin/env bash
# ==============================================================================
# gaming-profile.sh — Switcher de perfiles de rendimiento
# Qtile + Dunst + TLP — Arch Linux
#
# Perfiles:
#   gaming      → TLP AC forzado, governor performance, gamemode ON,  idle OFF
#   performance → TLP AC forzado, governor performance, gamemode OFF, idle normal
#   balanced    → TLP automático, governor powersave + EPP balance,   idle normal
#   powersave   → TLP BAT forzado, governor powersave + EPP power,    idle agresivo
#
# Nota sobre governors:
#   Con intel_pstate (activo) solo existen: performance / powersave
#   Con amd-pstate-epp igual: performance / powersave
#   Con acpi-cpufreq / intel_pstate pasivo: schedutil, ondemand, etc.
#   El script detecta el driver y elige el governor correcto automáticamente.
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

get_cpu_driver() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "unknown"
}

is_gamemode_active() {
    gamemoded --status 2>/dev/null | grep -q "is active" && echo "activo" || echo "inactivo"
}

# ── Helpers ──────────────────────────────────────────────────────────────────

# Devuelve el governor "balanceado" según el driver activo
get_balanced_governor() {
    local driver
    driver=$(get_cpu_driver)
    case "$driver" in
        intel_pstate|amd-pstate-epp)
            # En modo activo solo hay performance/powersave
            # powersave aquí es inteligente (equivalente a schedutil en otros drivers)
            echo "powersave"
            ;;
        *)
            # acpi-cpufreq, intel_pstate pasivo, amd-pstate pasivo
            if cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors \
               2>/dev/null | grep -q "schedutil"; then
                echo "schedutil"
            else
                echo "ondemand"
            fi
            ;;
    esac
}

set_governor() {
    sudo cpupower frequency-set -g "$1" &>/dev/null || true
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

restore_idle_normal() {
    echo "normal" > /tmp/idle-profile-current
    xset +dpms
    xset dpms 300 300 310
    xset s 300 10
}

# ── Perfiles ─────────────────────────────────────────────────────────────────

apply_gaming() {
    sudo tlp ac &>/dev/null
    set_governor performance
    set_vm_map
    start_gamemode

    # Idle: desactivar todo (pantallas y suspensión)
    echo "gaming" > /tmp/idle-profile-current
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
    restore_idle_normal

    echo "performance" > "$STATE_FILE"
    notify " Modo Performance" \
        "TLP: AC forzado\nCPU: performance\nGamemode: manual\nIdle: normal"
}

apply_balanced() {
    sudo tlp start &>/dev/null

    local gov
    gov=$(get_balanced_governor)
    set_governor "$gov"
    stop_gamemode
    restore_idle_normal

    echo "balanced" > "$STATE_FILE"
    notify " Modo Balanced" \
        "TLP: automático\nCPU: $gov\nGamemode: inactivo\nIdle: normal"
}

apply_powersave() {
    sudo tlp bat &>/dev/null
    set_governor powersave
    stop_gamemode

    # Idle más agresivo en powersave
    echo "normal" > /tmp/idle-profile-current
    xset +dpms
    xset dpms 120 120 130
    xset s 120 10

    echo "powersave" > "$STATE_FILE"
    notify " Modo Power Save" \
        "TLP: BAT forzado\nCPU: powersave\nGamemode: inactivo\nIdle: 2min"
}

show_status() {
    local gov gm driver balanced_gov idle
    gov=$(get_governor)
    gm=$(is_gamemode_active)
    driver=$(get_cpu_driver)
    balanced_gov=$(get_balanced_governor)
    idle=$(cat /tmp/idle-profile-current 2>/dev/null || echo "unknown")

    notify "󰕾 Estado actual" \
        "CPU driver: $driver\nGovernor: $gov\nGamemode: $gm\nIdle: $idle\nBalanced gov: $balanced_gov"
}

# ── Argumento directo (para llamadas desde otros scripts) ─────────────────────
if [[ "$1" == "--apply" ]]; then
    case "$2" in
        gaming)      apply_gaming ;;
        performance) apply_performance ;;
        balanced)    apply_balanced ;;
        powersave)   apply_powersave ;;
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
