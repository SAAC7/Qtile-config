#!/bin/sh
# ==============================================================================
# autostart.sh — Qtile autostart
# Arch Linux | LightDM + Qtile
# ==============================================================================

# ── Compositor ────────────────────────────────────────────────────────────────
picom --config ~/.config/picom/picom.conf &

# ── Polkit (permisos para montar unidades en Thunar) ─────────────────────────
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# ── Gestor de archivos en daemon (para apertura rápida) ──────────────────────
thunar --daemon &

# ── Montaje automático de unidades ───────────────────────────────────────────
udiskie -t &

# ── Bandeja del sistema ───────────────────────────────────────────────────────
nm-applet &
blueman-applet &

# ── Portapapeles ─────────────────────────────────────────────────────────────
copyq &

# ── Notificaciones ───────────────────────────────────────────────────────────
dunst &

# ── DPMS y screensaver ───────────────────────────────────────────────────────
# Configuración inicial: modo Normal
#   - Pantallas se apagan a los 5 minutos de inactividad
#   - xss-lock dispara i3lock cuando el screensaver se activa
#   - La suspensión la gestiona gaming-profile / idle-profile
#
# Para cambiar el comportamiento en caliente: mod+F11 → idle-profile.sh
#
# xset s <timeout> <cycle>
#   timeout: segundos de inactividad antes de activar screensaver
#   cycle:   segundos adicionales antes de apagar la pantalla
#
xset s 300 10          # screensaver activo a los 5min; 10s después apaga pantalla
xset dpms 310 310 310  # standby/suspend/off = 5min10s (por detrás del screensaver)
xset +dpms             # activar DPMS

# xss-lock: cuando el screensaver se activa, bloquea con i3lock
# --transfer-sleep-lock: bloquea ANTES de que el sistema suspenda (seguro)
xss-lock --transfer-sleep-lock -- i3lock -c 000000 &

# ── Layout de monitores ───────────────────────────────────────────────────────
/home/absar/.screenlayout/desktop_ryzen.sh &

# ── Fondo de pantalla ────────────────────────────────────────────────────────
# Espera un momento a que xrandr aplique el layout antes de poner el fondo
# sleep 0.5
# feh --bg-fill ~/Pictures/optimus-prime-4k-3840-x-2160-u52qw8a3d555o7mt.webp
nitrogen --restore
