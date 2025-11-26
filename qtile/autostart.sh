#!/bin/bash
#picom -b
thunar --daemon &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
nm-applet &
blueman-applet &
udiskie -t &
copyq &
flameshot &
killall dunst 2>/dev/null
dunst &
nitrogen --restore &
xss-lock -- i3lock -c 000000 &
