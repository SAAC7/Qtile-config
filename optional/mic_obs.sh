#!/bin/bash
# Crea el virtual mic de OBS si no existe
SINK_NAME="VirtualMic"

# Verifica si ya existe
if ! pactl list short sinks | grep -q "$SINK_NAME"; then
    pactl load-module module-null-sink sink_name=$SINK_NAME sink_properties=device.description="${SINK_NAME}_OBS"
fi
