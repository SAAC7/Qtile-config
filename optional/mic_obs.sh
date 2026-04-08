#!/bin/bash
# Crea el virtual mic de OBS si no existe
SINK_NAME="VirtualMic"

# Verifica si ya existe
if ! pactl list short sinks | grep -q "$SINK_NAME"; then
    pactl load-module module-null-sink sink_name=$SINK_NAME sink_properties=device.description="${SINK_NAME}_OBS"
fi

# Crear source (mic virtual)
if ! pactl list short sources | grep -q "${SINK_NAME}_source"; then
    pactl load-module module-remap-source master=${SINK_NAME}.monitor source_name=${SINK_NAME}_source source_properties=device.description="${SINK_NAME}_Mic"
fi
