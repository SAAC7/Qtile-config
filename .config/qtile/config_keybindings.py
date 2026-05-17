# ==============================================================================
# FRAGMENTO para ~/.config/qtile/config.py
# Agrega estos keybindings a tu lista keys = [ ... ]
# Reemplaza los Key([mod], "F9") y Key([mod], "F10") que ya tienes
# ==============================================================================

# --- Imports necesarios (ya los tienes, solo verifica que estén) ---
import os

# --- Keybindings a agregar / reemplazar en tu lista keys ---

# F9  → Gaming profile switcher (rendimiento + TLP + gamemode + idle)
Key([mod], "F9",
    lazy.spawn(os.path.expanduser("~/.config/rofi/scripts/gaming-profile.sh")),
    desc="Gaming profile switcher"),

# F10 → Dunst monitor switcher (notificaciones en pantalla principal o todas)
Key([mod], "F10",
    lazy.spawn(os.path.expanduser("~/.config/rofi/scripts/dunst-monitor.sh")),
    desc="Toggle dunst monitor: principal / todas"),

# F11 → Idle profile switcher (control de DPMS y suspensión)
Key([mod], "F11",
    lazy.spawn(os.path.expanduser("~/.config/rofi/scripts/idle-profile.sh")),
    desc="Idle profile: normal / descarga / película"),


# ==============================================================================
# CONFIGURACIÓN ADICIONAL para /etc/systemd/logind.conf
# Necesario para que la suspensión automática en modo Normal funcione
# Edita con: sudo nano /etc/systemd/logind.conf
# Y asegúrate de tener estas líneas descomentadas:
# ==============================================================================

# [Login]
# HandleSuspendKey=suspend
# HandleHibernateKey=hibernate
# HandleLidSwitch=suspend
# HandleLidSwitchDocked=ignore
# IdleAction=ignore          ← dejar en ignore, la suspensión la controla idle-profile.sh
# IdleActionSec=30min

# Después de editar logind.conf:
# sudo systemctl restart systemd-logind


# ==============================================================================
# SUDOERS — Agrega esto con: sudo visudo
# Permite que los scripts corran sin pedir contraseña
# Reemplaza "tuusuario" con tu usuario real
# ==============================================================================

# tuusuario ALL=(ALL) NOPASSWD: \
#     /usr/bin/cpupower, \
#     /usr/bin/sysctl, \
#     /usr/bin/tlp, \
#     /usr/bin/systemctl suspend

# ==============================================================================
# ESTRUCTURA DE ARCHIVOS esperada
# ==============================================================================

# ~/.config/rofi/scripts/
# ├── gaming-profile.sh     ← perfil de rendimiento + TLP + idle
# ├── idle-profile.sh       ← control DPMS / suspensión
# └── dunst-monitor.sh      ← toggle monitor de notificaciones

# ~/.config/rofi/
# └── power-profile.rasi    ← tema compartido por los tres menús rofi
