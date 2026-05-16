#!/usr/bin/env bash
# ==============================================================================
# install-tlp.sh — Instalador automático de TLP gaming
# Arch Linux | Intel / AMD | Laptop / Desktop
# ==============================================================================
# Uso:
#   chmod +x install-tlp.sh
#   ./install-tlp.sh
# ==============================================================================

set -e

RED='\033[0;91m'
GRN='\033[0;92m'
YLW='\033[0;93m'
BLU='\033[0;94m'
RST='\033[0m'
BLD='\033[1m'

info()    { echo -e "${BLU}${BLD}[INFO]${RST}  $*"; }
ok()      { echo -e "${GRN}${BLD}[ OK ]${RST}  $*"; }
warn()    { echo -e "${YLW}${BLD}[WARN]${RST}  $*"; }
err()     { echo -e "${RED}${BLD}[ERR ]${RST}  $*"; exit 1; }
section() { echo -e "\n${BLD}━━━ $* ━━━${RST}"; }

# ------------------------------------------------------------------------------
section "Verificaciones previas"
# ------------------------------------------------------------------------------

[[ $EUID -eq 0 ]] && err "No ejecutes este script como root. Usa tu usuario normal con sudo disponible."
command -v sudo &>/dev/null || err "sudo no está disponible."
command -v pacman &>/dev/null || err "Este script es solo para Arch Linux."

ok "Usuario: $USER"

# ------------------------------------------------------------------------------
section "Detectando hardware"
# ------------------------------------------------------------------------------

CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}')
CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)
info "CPU: $CPU_MODEL"

if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
    CPU_BRAND="Intel"
    ok "Arquitectura: Intel detectado"
elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
    CPU_BRAND="AMD"
    ok "Arquitectura: AMD detectado"
else
    CPU_BRAND="Unknown"
    warn "CPU no reconocido: $CPU_VENDOR — se usará configuración genérica"
fi

# ¿Es laptop o desktop?
IS_LAPTOP=false
if ls /sys/class/power_supply/BAT* &>/dev/null; then
    IS_LAPTOP=true
    BAT_NAME=$(ls /sys/class/power_supply/ | grep -i bat | head -1)
    ok "Laptop detectada — batería: $BAT_NAME"
else
    warn "No se detectó batería — modo desktop. Los parámetros de BAT serán ignorados por TLP."
fi

# Discos
DISKS=$(lsblk -dno NAME,TYPE | awk '$2=="disk"{print $1}' | tr '\n' ' ')
info "Discos detectados: $DISKS"

# Driver CPU activo
CPU_DRIVER=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "desconocido")
info "Driver CPU activo: $CPU_DRIVER"

# Governors disponibles
GOVERNORS=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "desconocido")
info "Governors disponibles: $GOVERNORS"

# ------------------------------------------------------------------------------
section "Limpiando servicios conflictivos"
# ------------------------------------------------------------------------------

# Desenmascarar TLP por si quedó enmascarado de una instalación anterior
sudo systemctl unmask tlp.service 2>/dev/null && ok "tlp.service desnenmascarado" || true

# Detener y deshabilitar conflictos antes de instalar
for svc in power-profiles-daemon thermald; do
    if systemctl list-unit-files | grep -q "^${svc}.service"; then
        warn "$svc detectado — conflictúa con TLP. Deshabilitando..."
        sudo systemctl disable --now "$svc" 2>/dev/null || true
        # Desinstalar si está instalado
        if pacman -Q "$svc" &>/dev/null; then
            sudo pacman -Rns --noconfirm "$svc" 2>/dev/null || true
            ok "$svc desinstalado"
        else
            ok "$svc deshabilitado"
        fi
    fi
done

# Limpiar unit files residuales
sudo systemctl daemon-reload
sudo systemctl reset-failed 2>/dev/null || true

# ------------------------------------------------------------------------------
section "Instalando TLP"
# ------------------------------------------------------------------------------

if pacman -Q thermald &>/dev/null; then
    warn "thermald aún presente — eliminando..."
    sudo pacman -Rns --noconfirm thermald
    ok "thermald eliminado"
fi

info "Instalando paquetes TLP..."
sudo pacman -S --needed --noconfirm tlp tlp-rdw

if command -v yay &>/dev/null; then
    read -rp "$(echo -e "${YLW}¿Instalar tlpui (interfaz gráfica para TLP)? [s/N]: ${RST}")" INSTALL_TLPUI
    if [[ "$INSTALL_TLPUI" =~ ^[sS]$ ]]; then
        yay -S --needed tlpui
        ok "tlpui instalado"
    fi
fi

ok "TLP instalado"

# ------------------------------------------------------------------------------
section "Aplicando configuración"
# ------------------------------------------------------------------------------

CONF_SRC="$(dirname "$(realpath "$0")")/tlp.conf"
CONF_DST="/etc/tlp.conf"

if [[ ! -f "$CONF_SRC" ]]; then
    err "No se encontró tlp.conf junto a este script. Asegúrate de que ambos archivos estén en la misma carpeta."
fi

if [[ -f "$CONF_DST" ]]; then
    BACKUP="/etc/tlp.conf.bak.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$CONF_DST" "$BACKUP"
    warn "Backup guardado en: $BACKUP"
fi

sudo cp "$CONF_SRC" "$CONF_DST"
ok "Configuración copiada a $CONF_DST"

# ------------------------------------------------------------------------------
section "Ajustes automáticos según hardware detectado"
# ------------------------------------------------------------------------------

# Desktop: desactivar parámetros de batería
if [[ "$IS_LAPTOP" == false ]]; then
    sudo sed -i 's/^START_CHARGE_THRESH/# [desktop] START_CHARGE_THRESH/' "$CONF_DST"
    sudo sed -i 's/^STOP_CHARGE_THRESH/# [desktop] STOP_CHARGE_THRESH/' "$CONF_DST"
    sudo sed -i 's/^CPU_MIN_PERF_ON_BAT/# [desktop] CPU_MIN_PERF_ON_BAT/' "$CONF_DST"
    sudo sed -i 's/^CPU_MAX_PERF_ON_BAT/# [desktop] CPU_MAX_PERF_ON_BAT/' "$CONF_DST"
    ok "Parámetros de batería desactivados (desktop)"
fi

# Governor fallback según driver y governors disponibles
#
# intel_pstate activo (amd-pstate-epp o intel_pstate):
#   Solo tiene 'performance' y 'powersave'. schedutil y ondemand NO existen.
#   En este modo, powersave + EPP balance_power ya es equivalente a schedutil.
#
# acpi-cpufreq / intel_pstate pasivo:
#   Tiene schedutil, ondemand, etc.

if ! echo "$GOVERNORS" | grep -q "schedutil"; then
    if [[ "$CPU_DRIVER" == "intel_pstate" ]] || [[ "$CPU_DRIVER" == "amd-pstate-epp" ]]; then
        # Con estos drivers, powersave es el governor inteligente en BAT
        sudo sed -i 's/^CPU_SCALING_GOVERNOR_ON_BAT=schedutil/CPU_SCALING_GOVERNOR_ON_BAT=powersave/' "$CONF_DST"
        ok "Driver $CPU_DRIVER detectado — governor BAT: powersave (con EPP balance_power)"
    elif echo "$GOVERNORS" | grep -q "ondemand"; then
        sudo sed -i 's/^CPU_SCALING_GOVERNOR_ON_BAT=schedutil/CPU_SCALING_GOVERNOR_ON_BAT=ondemand/' "$CONF_DST"
        warn "schedutil no disponible — usando ondemand para BAT"
    else
        # Último fallback: usar powersave
        sudo sed -i 's/^CPU_SCALING_GOVERNOR_ON_BAT=schedutil/CPU_SCALING_GOVERNOR_ON_BAT=powersave/' "$CONF_DST"
        warn "schedutil no disponible — usando powersave para BAT (fallback)"
    fi
else
    ok "Governor BAT: schedutil"
fi

# ------------------------------------------------------------------------------
section "Habilitando servicios"
# ------------------------------------------------------------------------------

# Asegurarse de que tlp no esté enmascarado antes de habilitar
sudo systemctl unmask tlp.service 2>/dev/null || true

# Habilitar TLP
sudo systemctl enable --now tlp
ok "TLP habilitado y corriendo"

# NetworkManager-dispatcher (para tlp-rdw)
sudo systemctl enable --now NetworkManager-dispatcher 2>/dev/null || true
ok "NetworkManager-dispatcher habilitado"

# Enmascarar rfkill para que tlp-rdw tome el control
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>/dev/null || true
ok "systemd-rfkill enmascarado (tlp-rdw tomará el control)"

# ------------------------------------------------------------------------------
section "Verificación final"
# ------------------------------------------------------------------------------

echo ""
info "Estado de TLP:"
sudo tlp-stat -s | head -20

echo ""
info "Governor activo:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

echo ""
ok "Instalación completada."
echo ""
echo -e "${BLD}Comandos útiles:${RST}"
echo -e "  ${BLU}sudo tlp-stat -p${RST}   → estado CPU / governors / EPP"
echo -e "  ${BLU}sudo tlp-stat -b${RST}   → estado batería y thresholds"
echo -e "  ${BLU}sudo tlp-stat -s${RST}   → estado general"
echo -e "  ${BLU}sudo tlp ac${RST}        → forzar modo AC (gaming/performance)"
echo -e "  ${BLU}sudo tlp bat${RST}       → forzar modo BAT (powersave)"
echo -e "  ${BLU}sudo tlp start${RST}     → devolver control automático a TLP"
echo ""
if [[ "$IS_LAPTOP" == true ]]; then
    echo -e "${YLW}Verifica soporte de thresholds de batería con:${RST}"
    echo -e "  ${BLU}sudo tlp-stat -b${RST}"
    echo -e "Si no aparecen thresholds, comenta START/STOP_CHARGE_THRESH en /etc/tlp.conf"
fi
