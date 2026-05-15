# Arch Linux Gaming Setup — Qtile + LightDM

Setup completo de gaming sobre una instalación limpia de Arch Linux con LightDM y Qtile.
Incluye Steam, Heroic Games Launcher, Proton-GE y un switcher de perfiles de rendimiento con Rofi y Dunst.

---

## Requisitos previos

- Arch Linux instalado con LightDM y Qtile funcionando
- Conexión a internet
- Usuario con privilegios sudo

---

## 1. Sistema base y AUR helper

```bash
# Actualizar el sistema
sudo pacman -Syu

# Herramientas base
sudo pacman -S base-devel git wget curl nano vim

# Instalar yay (AUR helper)
git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
```

### Habilitar repositorio multilib

Edita `/etc/pacman.conf` y descomenta estas dos líneas:

```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Luego sincroniza:

```bash
sudo pacman -Sy
```

---

## 2. Drivers de GPU

### AMD (recomendado para Linux gaming)

```bash
sudo pacman -S mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
    libva-mesa-driver lib32-libva-mesa-driver \
    mesa-vdpau lib32-mesa-vdpau
```

### NVIDIA

```bash
sudo pacman -S nvidia nvidia-utils lib32-nvidia-utils \
    nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader
```

> Reinicia después de instalar drivers NVIDIA antes de continuar.

### Intel (iGPU o Intel Arc)

```bash
sudo pacman -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel
```

---

## 3. Audio con PipeWire

```bash
sudo pacman -S pipewire pipewire-alsa pipewire-pulse pipewire-jack \
    wireplumber gst-plugin-pipewire

systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

---

## 4. Dependencias y herramientas de gaming

```bash
# GameMode — optimizador de rendimiento en tiempo real
sudo pacman -S gamemode lib32-gamemode

# Agregar tu usuario al grupo gamemode
sudo usermod -aG gamemode $USER

# MangoHud — overlay de FPS/GPU/CPU en juego
sudo pacman -S mangohud lib32-mangohud

# Dependencias Wine/Proton
sudo pacman -S wine-staging wine-gecko wine-mono winetricks \
    lib32-gnutls lib32-libldap lib32-libgpg-error \
    lib32-sqlite lib32-libpulse

# DXVK y soporte DirectX
sudo pacman -S dxvk-bin lib32-vulkan-icd-loader

# Vulkan tools (para verificar que Vulkan funciona)
sudo pacman -S vulkan-tools
vulkaninfo | head -20
```

---

## 5. Steam

```bash
sudo pacman -S steam
```

### Proton-GE (mejor compatibilidad que el Proton oficial)

```bash
yay -S proton-ge-custom-bin
```

En Steam: **Configuración → Steam Play → Activar Steam Play para todos los títulos** y selecciona Proton-GE o Proton Experimental.

### Opciones de lanzamiento recomendadas por juego

En cada juego: clic derecho → Propiedades → Opciones de lanzamiento:

```
MANGOHUD=1 GAMEMODE=1 %command%
```

---

## 6. Heroic Games Launcher

Soporta Epic Games, GOG y Amazon Gaming.

```bash
# Desde AUR
yay -S heroic-games-launcher-bin

# Alternativa via Flatpak
sudo pacman -S flatpak
flatpak install flathub com.heroicgameslauncher.hgl
```

En Heroic: Configuración de juego → selecciona **Proton-GE** o **Wine-GE** como runtime.

---

## 7. Gestión de versiones Proton/Wine

```bash
# ProtonUp-QT — gestor visual de runners
yay -S protonup-qt-bin
```

Para instalar Proton-GE manualmente:

```bash
mkdir -p ~/.steam/root/compatibilitytools.d
# Descarga el .tar.gz desde github.com/GloriousEggroll/proton-ge-custom
# Extrae en esa carpeta y reinicia Steam
```

---

## 8. Optimización del sistema

```bash
# CPUPower — control del governor de CPU
sudo pacman -S cpupower

# Activar modo performance manualmente
sudo cpupower frequency-set -g performance

# Aumentar vm.max_map_count (necesario para muchos juegos)
echo "vm.max_map_count=2147483642" | sudo tee /etc/sysctl.d/80-gamecompatibility.conf
sudo sysctl --system

# Power Profiles Daemon (opcional pero recomendado para el switcher)
sudo pacman -S power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon
```

### Governors disponibles

| Governor    | Uso recomendado                        |
|-------------|----------------------------------------|
| `performance` | Gaming, cargas de trabajo intensas   |
| `schedutil`   | Uso diario balanceado                |
| `powersave`   | Batería / bajo consumo               |

---

## 9. Switcher de perfiles con Rofi y Dunst

Permite cambiar entre perfiles de rendimiento desde un menú flotante con notificaciones.

### Dependencias

```bash
sudo pacman -S rofi dunst
# Fuente con íconos (recomendado)
sudo pacman -S ttf-nerd-fonts-symbols
# o una fuente completa:
yay -S ttf-jetbrains-mono-nerd
```

### Estructura de archivos

```
~/.config/rofi/
├── power-profile.rasi          # Tema del menú
└── scripts/
    └── gaming-profile.sh       # Script del switcher
```

### Instalación

```bash
mkdir -p ~/.config/rofi/scripts

# Copia los archivos power-profile.rasi y gaming-profile.sh a sus rutas
cp power-profile.rasi ~/.config/rofi/
cp gaming-profile.sh ~/.config/rofi/scripts/
chmod +x ~/.config/rofi/scripts/gaming-profile.sh
```

### Permitir cpupower sin contraseña

```bash
sudo visudo
# Agrega al final del archivo:
tuusuario ALL=(ALL) NOPASSWD: /usr/bin/cpupower, /usr/bin/sysctl
```

### Integración en Qtile

En `~/.config/qtile/config.py`:

```python
import os

keys = [
    # ... tus keys existentes ...
    Key([mod], "F9",
        lazy.spawn(os.path.expanduser("~/.config/rofi/scripts/gaming-profile.sh")),
        desc="Gaming profile switcher"),
]
```

> Usa `os.path.expanduser()` — el `~` no se expande directamente en `lazy.spawn()`.

Recarga Qtile tras guardar:

```bash
qtile cmd-obj -o cmd -f reload_config
```

### Perfiles disponibles

| Perfil        | Governor      | GameMode  | Descripción                          |
|---------------|---------------|-----------|--------------------------------------|
| Gaming        | performance   | activado  | Máximo rendimiento para jugar        |
| Performance   | performance   | manual    | CPU al máximo, gamemode libre        |
| Balanced      | schedutil     | detenido  | Balance energía/rendimiento          |
| Power Save    | powersave     | detenido  | Consumo mínimo                       |

### Notas sobre el `.rasi`

- `border` en rofi **no acepta shorthand** tipo `1px solid color`. Debe separarse:
  ```rasi
  border:       1;
  border-color: @border-color;
  ```
- Si tienes un `@import "~/.config/rofi/config.rasi"` y ese archivo no existe, rofi falla silenciosamente. Comenta la línea si no tienes ese archivo.

---

## Verificación final

```bash
# Vulkan funcionando
vulkaninfo | grep "GPU id"

# GameMode disponible
gamemoded --status

# PipeWire activo
pactl info | grep "Server Name"

# Governor actual
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

---

## Resumen de paquetes instalados

| Paquete                    | Fuente   | Función                              |
|----------------------------|----------|--------------------------------------|
| `steam`                    | pacman   | Plataforma de juegos                 |
| `heroic-games-launcher-bin`| AUR      | Epic / GOG / Amazon Gaming           |
| `proton-ge-custom-bin`     | AUR      | Capa de compatibilidad Windows       |
| `protonup-qt-bin`          | AUR      | Gestor de versiones Proton/Wine      |
| `gamemode`                 | pacman   | Optimizador de rendimiento           |
| `mangohud`                 | pacman   | Overlay de métricas en juego         |
| `wine-staging`             | pacman   | Compatibilidad Windows               |
| `dxvk-bin`                 | pacman   | DirectX sobre Vulkan                 |
| `cpupower`                 | pacman   | Control de governor de CPU           |
| `power-profiles-daemon`    | pacman   | Gestión de perfiles de energía       |
| `pipewire`                 | pacman   | Sistema de audio moderno             |
| `rofi`                     | pacman   | Lanzador / menú para el switcher     |
| `dunst`                    | pacman   | Notificaciones del switcher          |
