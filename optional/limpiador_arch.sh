#!/bin/bash

# Asegurar que se ejecuta con privilegios para ciertas consultas
if [ "$EUID" -ne 0 ]; then
  echo "=> Por favor, ejecuta este script con sudo: sudo bash $0"
  exit 1
fi

# Obtener el usuario real que invocó sudo para las tareas del /home y yay
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
  REAL_USER=$(logname)
fi
USER_HOME=$(eval echo "~$REAL_USER")

# Colores para que sea fácil de leer
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
RESET='\033[0m'

mostrar_menu() {
    clear
    echo -e "${AZUL}==================================================${RESET}"
    echo -e "${AZUL}      MANTENIMIENTO Y LIMPIEZA DE ARCH LINUX      ${RESET}"
    echo -e "${AZUL}==================================================${RESET}"
    echo "1) Analizar y limpiar caché de Pacman"
    echo "2) Buscar y eliminar paquetes huérfanos"
    echo "3) Analizar y reducir logs del sistema (Journald)"
    echo "4) Analizar y limpiar caché de YAY (AUR)"
    echo "5) Limpiar cachés de aplicaciones del HOME (Navegadores, .NET, Stremio, etc.)"
    echo "6) Ver carpetas más pesadas de la raíz (/)"
    echo "7) Salir"
    echo -e "${AZUL}==================================================${RESET}"
    echo -n "Elige una opción [1-7]: "
}

pausa() {
    echo ""
    echo -n "Presiona [Enter] para volver al menú..."
    read -r
}

while true; do
    mostrar_menu
    read -r opcion
    case $opcion in
        1)
            echo -e "\n${AMARILLO}--- CACHÉ DE PACMAN ---${RESET}"
            echo -n "Espacio actual ocupado por el caché: "
            du -sh /var/cache/pacman/pkg/ 2>/dev/null || echo "0B"
            
            echo -e "\n¿Qué deseas hacer?"
            echo "1. Dejar solo las últimas 2 versiones de cada paquete (Recomendado/Seguro)"
            echo "2. Borrar TODO el caché de paquetes desinstalados"
            echo "3. No hacer nada y regresar"
            echo -n "Opción: "
            read -r opc_pac
            
            if [ "$opc_pac" == "1" ]; then
                if command -v paccache &> /dev/null; then
                    paccache -r
                else
                    echo "Instalando pacman-contrib para usar paccache..."
                    pacman -S --noconfirm pacman-contrib && paccache -r
                fi
            elif [ "$opc_pac" == "2" ]; then
                if command -v paccache &> /dev/null; then
                    paccache -rk0
                else
                    echo "Instalando pacman-contrib..."
                    pacman -S --noconfirm pacman-contrib && paccache -rk0
                fi
            fi
            
            echo -e "\n${VERDE}Espacio actual después de la acción:${RESET}"
            du -sh /var/cache/pacman/pkg/ 2>/dev/null
            pausa
            ;;
            
        2)
            echo -e "\n${AMARILLO}--- PAQUETES HUÉRFANOS ---${RESET}"
            huerfanos=$(pacman -Qtdq)
            if [ -z "$huerfanos" ]; then
                echo -e "${VERDE}¡Felicidades! No tienes paquetes huérfanos en el sistema.${RESET}"
            else
                echo "Los siguientes paquetes son dependencias olvidadas y ya no se necesitan:"
                echo "$huerfanos" | tr '\n' ' ' 
                echo -e "\n"
                echo -n "¿Deseas eliminarlos todos de forma segura? (s/n): "
                read -r resp
                if [[ "$resp" =~ ^[Ss]$ ]]; then
                    pacman -Rns $huerfanos
                    echo -e "${VERDE}Paquetes eliminados.${RESET}"
                else
                    echo "No se realizó ningún cambio."
                fi
            fi
            pausa
            ;;
            
        3)
            echo -e "\n${AMARILLO}--- LOGS DEL SISTEMA (JOURNALD) ---${RESET}"
            echo -n "Espacio actual ocupado por los registros: "
            journalctl --disk-usage
            
            echo ""
            echo -n "¿Deseas reducir el tamaño de los logs para que ocupen máximo 100 Megas? (s/n): "
            read -r resp
            if [[ "$resp" =~ ^[Ss]$ ]]; then
                journalctl --vacuum-size=100M
                echo -e "\n${VERDE}Logs reducidos.${RESET}"
                echo -n "Nuevo espacio ocupado: "
                journalctl --disk-usage
            else
                echo "No se realizó ningún cambio."
            fi
            pausa
            ;;

        4)
            echo -e "\n${AMARILLO}--- CACHÉ DE YAY (AUR) ---${RESET}"
            echo -n "Espacio actual ocupado por el caché de YAY: "
            du -sh "$USER_HOME/.cache/yay" 2>/dev/null || echo "0B"
            
            echo ""
            echo -n "¿Deseas limpiar los archivos fuentes antiguos de AUR de forma segura? (s/n): "
            read -r resp
            if [[ "$resp" =~ ^[Ss]$ ]]; then
                # Se ejecuta como el usuario real para evitar problemas de root con yay
                sudo -u "$REAL_USER" yay -Sc --aur --noconfirm
                echo -e "\n${VERDE}Caché de YAY limpiado.${RESET}"
                echo -n "Nuevo espacio ocupado: "
                du -sh "$USER_HOME/.cache/yay" 2>/dev/null
            else
                echo "No se realizó ningún cambio."
            fi
            pausa
            ;;

        5)
            echo -e "\n${AMARILLO}--- LIMPIEZA DE APLICACIONES EN EL HOME ($REAL_USER) ---${RESET}"
            echo "Calculando espacio actual..."
            echo -n "Caché de Chromium: " && du -sh "$USER_HOME/.cache/chromium" 2>/dev/null || echo "0B"
            echo -n "Caché de Mozilla: " && du -sh "$USER_HOME/.cache/mozilla" 2>/dev/null || echo "0B"
            echo -n "Datos de Stremio Server: " && du -sh "$USER_HOME/.stremio-server" 2>/dev/null || echo "0B"
            echo -n "Librerías de .NET (.nuget): " && du -sh "$USER_HOME/.nuget" 2>/dev/null || echo "0B"
            
            echo ""
            echo -n "¿Deseas proceder a limpiar los cachés de estas aplicaciones de forma segura? (s/n): "
            read -r resp
            if [[ "$resp" =~ ^[Ss]$ ]]; then
                echo "Limpiando cachés generales..."
                rm -rf "$USER_HOME/.cache/chromium/*" "$USER_HOME/.cache/mozilla/*" "$USER_HOME/.stremio-server/*"
                
                echo "Limpiando Service Workers y cachés internos pesados en .config..."
                find "$USER_HOME/.config/chromium/" -type d \( -name "Cache" -o -name "Code Cache" -o -name "Service Worker" \) -exec rm -rf {} + 2>/dev/null
                find "$USER_HOME/.config/Stationv2/" -type d \( -name "Cache" -o -name "Code Cache" -o -name "Service Worker" \) -exec rm -rf {} + 2>/dev/null
                
                if command -v dotnet &> /dev/null; then
                    echo "Limpiando caché de paquetes de desarrollo .NET..."
                    sudo -u "$REAL_USER" dotnet nuget locals all --clear
                fi
                
                echo -e "\n${VERDE}¡Limpieza del HOME completada con éxito!${RESET}"
            else
                echo "No se realizó ningún cambio."
            fi
            pausa
            ;;
            
        6)
            echo -e "\n${AMARILLO}--- ANÁLISIS DE LA RAÍZ (/) ---${RESET}"
            echo "Calculando el tamaño de las carpetas principales..."
            echo "Esto puede tardar unos segundos, por favor espera..."
            echo "--------------------------------------------------"
            du -ah --max-depth=1 / 2>/dev/null | sort -hr | head -n 15
            echo "--------------------------------------------------"
            echo -e "${AMARILLO}Nota:${RESET} Si /var es muy grande, suele ser pacman o logs (opciones 1 y 3)."
            echo -e "${AMARILLO}Nota:${RESET} Si /home es muy grande, usa las opciones 4 y 5 para limpiar tu usuario."
            pausa
            ;;
            
        7)
            echo -e "\n${VERDE}¡Saliendo! Que tengas un excelente día administrando tu Arch Linux.${RESET}\n"
            exit 0
            ;;
            
        *)
            echo -e "\nOpción no válida. Intenta de nuevo."
            sleep 1
            ;;
    esac
done
