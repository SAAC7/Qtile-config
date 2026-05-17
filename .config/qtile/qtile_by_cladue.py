# Qtile Cyberpunk Config
# Otimizado por Claude Code

from libqtile import bar, layout, qtile, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy

# Ajustes cíberpunk
COLOR_PRIMARY = "#00ffcc"
COLOR_SECONDARY = "#ff00ff"
COLOR_BACKGROUND = "#020202"
COLOR_FOREGROUND = "#00ffff"
FONT_CYBER = "FiraCode Nerd Font Mono"

# Importes
import os
import subprocess
import signals
import keys

# Notificaciones
@hook.subscribe.startup_once
def start_notifications():
    os.system('notify-osd &')

# Widgets cíberpunk
widgets = [
    widget.Notification(foreground=COLOR_SECONDARY, background=COLOR_BACKGROUND),
    widget.GroupBox(
        highlight_method="block",
        highlight_color=COLOR_PRIMARY,
        foreground=COLOR_FOREGROUND,
        background=COLOR_BACKGROUND,
        font=FONT_CYBER,
        fontsize=13
    ),
    widget.WindowName(foreground=COLOR_SECONDARY, font=FONT_CYBER),
    widget.Scrot(sys_tray=True, foreground=COLOR_FOREGROUND),
    widget.PulseVolume(foreground=COLOR_SECONDARY),
    widget.Calendar(foreground=COLOR_FOREGROUND, font=FONT_CYBER),
]

# Layouts
layouts = [
    layout.Columns(
        border_focus=COLOR_SECONDARY,
        border_focus_stack=COLOR_SECONDARY,
        foreground=COLOR_FOREGROUND,
        background=COLOR_BACKGROUND
    ),
    layout.Max(height_factor=0.7)
]

# Teclado
mod = "mod4"
keys = [
    # Notificaciones
    Key([mod], "n", lazy.spawn("notify-osd"), desc="Mostrar notificaciones"),
    # Bluetooth
    Key([mod], "b", lazy.spawn("bluetoothctl"), desc="Gestionar Bluetooth"),
    # SSH
    Key([mod], "s", lazy.spawn("ssh-agent bash -c 'ssh %s'"], desc="SSH con agente")
]

# Barra principal
screens = [
    Screen(
        top=bar.Bar(
            [
                widget.Prompt(),
                widget.KbdLayout(),
                widget.TextBox(text="Cyberpunk", foreground=COLOR_FOREGROUND, background=COLOR_BACKGROUND, font=FONT_CYBER),
                widget.Clock(foreground=COLOR_SECONDARY, format="%Y-%m-%d %H:%M")
            ],
            24,
            background=COLOR_BACKGROUND
        ),
    )
]
