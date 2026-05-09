#!/bin/sh
#picom -b
picom --config ~/.config/picom/picom.conf &
# agente para permisos para montar unidades y asi en thunar con el poolkit 
#   sudo pacman -S polkit polkit-gnome
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
thunar --daemon &
udiskie -t &

#   iconos
#   redes
nm-applet &
#   bluetooth
blueman-applet &

#   clipboard
copyq &
#   schreenshots
#flameshot &
#   notifications
#killall dunst 2>/dev/null
dunst &
#   fondo de pantalla y bloqueo de pantalla
#nitrogen --restore &
xss-lock -- i3lock -c 000000 &
/home/absar/.screenlayout/desktop_ryzen.sh &
feh --bg-fill Pictures/optimus-prime-4k-3840-x-2160-u52qw8a3d555o7mt.webp
