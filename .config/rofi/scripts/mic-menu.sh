#!/usr/bin/env bash
# ==============================================================================
# mic-menu.sh — Control de micrófonos (físico + VirtualMic OBS)
# Qtile + Dunst + Rofi + PulseAudio — Arch Linux
# ==============================================================================

DUNST_TIMEOUT=4000
STACK_TAG="miccontrol"
SINK_NAME="VirtualMic"

notify() {
    dunstify -u normal -t "$DUNST_TIMEOUT" \
        -h string:x-dunst-stack-tag:"$STACK_TAG" \
        "$1" "$2"
}

# ── Estado del VirtualMic ─────────────────────────────────────────────────────

virtual_mic_loaded() {
    pactl list short sources | grep -q "${SINK_NAME}_source"
}

virtual_mic_enable() {
    # Crear el sink (null sink = sumidero de audio)
    if ! pactl list short sinks | grep -q "$SINK_NAME"; then
        pactl load-module module-null-sink \
            sink_name=$SINK_NAME \
            sink_properties=device.description="${SINK_NAME}_OBS"
    fi

    # Crear el source (mic virtual que OBS puede capturar)
    if ! pactl list short sources | grep -q "${SINK_NAME}_source"; then
        pactl load-module module-remap-source \
            master=${SINK_NAME}.monitor \
            source_name=${SINK_NAME}_source \
            source_properties=device.description="${SINK_NAME}_Mic"
    fi

    notify "󰍬 VirtualMic OBS" "Activado\nOBS puede capturar: ${SINK_NAME}_Mic"
}

virtual_mic_disable() {
    # Descargar módulos en orden (source primero, luego sink)
    local source_module sink_module

    source_module=$(pactl list short modules | grep "module-remap-source" | \
        grep "${SINK_NAME}_source" | awk '{print $1}')
    sink_module=$(pactl list short modules | grep "module-null-sink" | \
        grep "sink_name=$SINK_NAME" | awk '{print $1}')

    [[ -n "$source_module" ]] && pactl unload-module "$source_module"
    [[ -n "$sink_module" ]] && pactl unload-module "$sink_module"

    notify "󰍭 VirtualMic OBS" "Desactivado\nMódulos descargados"
}

# ── Estado del micrófono físico ───────────────────────────────────────────────

# Busca la fuente de entrada por defecto (micrófono físico integrado)
get_physical_mic_source() {
    # Prioriza fuentes que contengan "input" o "Internal" o "Microphone"
    pactl list short sources | \
        grep -v "\.monitor" | \
        grep -v "$SINK_NAME" | \
        awk '{print $2}' | head -1
}

physical_mic_muted() {
    local source
    source=$(get_physical_mic_source)
    [[ -z "$source" ]] && return 1
    pactl get-source-mute "$source" 2>/dev/null | grep -q "yes"
}

physical_mic_toggle() {
    local source
    source=$(get_physical_mic_source)
    if [[ -z "$source" ]]; then
        notify "󰍭 Micrófono físico" "No se encontró ningún micrófono"
        return 1
    fi

    pactl set-source-mute "$source" toggle

    if physical_mic_muted; then
        notify "󰍭 Micrófono físico" "SILENCIADO\n$source"
    else
        notify "󰍬 Micrófono físico" "ACTIVO\n$source"
    fi
}

# ── Construir etiquetas de estado ─────────────────────────────────────────────

if virtual_mic_loaded; then
    VMIC_STATUS="activo"
    VMIC_ICON="󰍬"
    VMIC_LABEL="$VMIC_ICON VirtualMic OBS → Desactivar"
else
    VMIC_STATUS="inactivo"
    VMIC_ICON="󰍭"
    VMIC_LABEL="$VMIC_ICON VirtualMic OBS → Activar"
fi

if physical_mic_muted; then
    PMIC_STATUS="silenciado"
    PMIC_ICON="󰍭"
else
    PMIC_STATUS="activo"
    PMIC_ICON="󰍬"
fi
PMIC_LABEL="$PMIC_ICON Mic físico ($PMIC_STATUS) → Toggle"

# ── Menú Rofi ────────────────────────────────────────────────────────────────

OPTIONS="$VMIC_LABEL\n$PMIC_LABEL\n󰕾 Ver estado de audio"

SELECTED=$(echo -e "$OPTIONS" | rofi \
    -dmenu \
    -i \
    -p "󰍬" \
    -theme ~/.config/rofi/power-profile.rasi \
    -mesg "VirtualMic: $VMIC_STATUS  |  Mic físico: $PMIC_STATUS" \
    -no-custom \
    -selected-row 0)

case "$SELECTED" in
    *"VirtualMic OBS"*)
        if virtual_mic_loaded; then
            virtual_mic_disable
        else
            virtual_mic_enable
        fi
        ;;
    *"Mic físico"*)
        physical_mic_toggle
        ;;
    "󰕾 Ver estado de audio")
        SOURCE=$(get_physical_mic_source)
        notify "󰕾 Estado de audio" \
            "VirtualMic: $VMIC_STATUS\nMic físico: $PMIC_STATUS\nFuente: ${SOURCE:-ninguna}"
        ;;
    *) exit 0 ;;
esac
