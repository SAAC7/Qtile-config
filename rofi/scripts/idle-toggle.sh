#!/usr/bin/env bash
# ==============================================================================
# idle-profile.sh — Control de idle: pantallas, bloqueo y suspensión
# Qtile + Dunst + xss-lock + systemd — Arch Linux
#
# Modos:
#   normal    → pantallas apagan a 5min, bloqueo, suspensión a 30min
#   descarga  → pantallas apagan a 15min, bloqueo, sin suspensión
#   pelicula  → nada automático (inhibit total)
#
# Estado persistido en: /tmp/idle-profile-current
# ==============================================================================

DUNST_TIMEOUT=4000
STACK_TAG="idle-profile"
STATE_FILE="/tmp/idle-profile-current"

# Tiempos en segundos
NORMAL_SCREEN_OFF=300      # 5 min  → apaga pantallas
NORMAL_LOCK_DELAY=10       # 10 seg después del apagado → bloquea
NORMAL_SUSPEND=1800        # 30 min → suspende

DESCARGA_SCREEN_OFF=900    # 15 min → apaga pantallas
DESCARGA_LOCK_DELAY=10     # 10 seg después → bloquea
# Sin suspensión

notify() {
    dunstify -u normal -t "$DUNST_TIMEOUT" \
        -h string:x-dunst-stack-tag:"$STACK_TAG" \
        "$1" "$2"
}

get_current() {
    cat "$STATE_FILE" 2>/dev/null || echo "normal"
}

# ── Inhibidores activos ──────────────────────────────────────────────────────

kill_inhibitors() {
    # Matar xidlehook o xautolock si los hubiera
    pkill -x xidlehook 2>/dev/null
    pkill -x xautolock 2>/dev/null
    # Restaurar DPMS a valores activos (por si estaba desactivado)
    xset dpms 0 0 0   # reset timeouts antes de reconfigurar
    xset +dpms
    xset s on
}

stop_suspend_inhibit() {
    # Matar cualquier systemd-inhibit que hayamos lanzado
    pkill -f "systemd-inhibit.*sleep" 2>/dev/null || true
}

# ── Modos ────────────────────────────────────────────────────────────────────

apply_normal() {
    kill_inhibitors
    stop_suspend_inhibit

    # DPMS: standby=5min, suspend=5min, off=5min+10seg
    xset dpms $NORMAL_SCREEN_OFF $NORMAL_SCREEN_OFF $((NORMAL_SCREEN_OFF + NORMAL_LOCK_DELAY))
    xset s $NORMAL_SCREEN_OFF $NORMAL_LOCK_DELAY

    # xss-lock ya está corriendo desde autostart y dispara i3lock automáticamente
    # Suspensión via systemd-logind — configuramos el timeout con loginctl
    # (requiere que HandleIdleAction=suspend esté en /etc/systemd/logind.conf)
    sudo systemctl restart systemd-logind-idle-helper 2>/dev/null || true

    # Alternativa portable: systemd-inhibit invertido — dejamos que logind actúe
    # Si tienes IdleAction=suspend en logind.conf esto funciona solo
    # Si no, lanzamos un script que suspenda tras NORMAL_SUSPEND segundos de inactividad
    {
        sleep $NORMAL_SUSPEND
        # Solo suspende si el modo sigue siendo normal
        if [[ "$(get_current)" == "normal" ]]; then
            systemctl suspend
        fi
    } &
    disown

    echo "normal" > "$STATE_FILE"
    notify " Idle: Normal" "Pantallas: 5min → bloqueo → suspensión a 30min"
}

apply_descarga() {
    kill_inhibitors
    stop_suspend_inhibit

    # DPMS: apaga pantallas a 15min
    xset dpms $DESCARGA_SCREEN_OFF $DESCARGA_SCREEN_OFF $((DESCARGA_SCREEN_OFF + DESCARGA_LOCK_DELAY))
    xset s $DESCARGA_SCREEN_OFF $DESCARGA_LOCK_DELAY

    # Inhibir suspensión mientras el modo sea descarga
    systemd-inhibit --what=sleep --who="idle-profile" \
        --why="Modo descarga activo" --mode=block \
        bash -c "while [[ \"\$(cat $STATE_FILE 2>/dev/null)\" == 'descarga' ]]; do sleep 10; done" &
    disown

    echo "descarga" > "$STATE_FILE"
    notify " Idle: Descarga" "Pantallas: 15min → bloqueo\nSuspensión: desactivada"
}

apply_pelicula() {
    kill_inhibitors
    stop_suspend_inhibit

    # Desactivar DPMS completamente
    xset -dpms
    xset s off
    xset s noblank

    # Inhibir suspensión
    systemd-inhibit --what=sleep:idle --who="idle-profile" \
        --why="Modo película activo" --mode=block \
        bash -c "while [[ \"\$(cat $STATE_FILE 2>/dev/null)\" == 'pelicula' ]]; do sleep 10; done" &
    disown

    echo "pelicula" > "$STATE_FILE"
    notify "󰿎 Idle: Película" "Pantallas y suspensión desactivadas"
}

# Función pública para que gaming-profile.sh la llame directamente
apply_gaming_idle() {
    apply_pelicula
    echo "gaming" > "$STATE_FILE"   # sobreescribe para distinguir del modo película manual
}

apply_restaurar_desde_gaming() {
    apply_normal
}

# ── Menú Rofi ────────────────────────────────────────────────────────────────

CURRENT=$(get_current)
case "$CURRENT" in
    normal)    CURRENT_LABEL="Normal" ;;
    descarga)  CURRENT_LABEL="Descarga" ;;
    pelicula)  CURRENT_LABEL="Película" ;;
    gaming)    CURRENT_LABEL="Gaming (sin idle)" ;;
    *)         CURRENT_LABEL="Desconocido" ;;
esac

OPTIONS=" Normal (bloqueo + suspensión)\n Descarga (bloqueo, sin suspensión)\n󰿎 Película (sin nada)"

SELECTED=$(echo -e "$OPTIONS" | rofi \
    -dmenu \
    -i \
    -p "" \
    -theme ~/.config/rofi/power-profile.rasi \
    -mesg "Idle actual: $CURRENT_LABEL" \
    -no-custom \
    -selected-row 0)

case "$SELECTED" in
    " Normal (bloqueo + suspensión)")        apply_normal ;;
    " Descarga (bloqueo, sin suspensión)")   apply_descarga ;;
    "󰿎 Película (sin nada)")                  apply_pelicula ;;
    *) exit 0 ;;
esac
