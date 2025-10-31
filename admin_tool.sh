#!/bin/bash
# [cite: 69]
# Proyecto Final de Sistemas Operacionales - Herramienta BASH

# --- Definición de Funciones (vacías por ahora) ---
# [cite: 391, 401, 403]

# Opción 1: Desplegar usuarios y último login
funcion_usuarios() {
    echo "Opción 1: (En desarrollo) Desplegar usuarios y último login..."
    # Aquí irán los comandos 'who', 'last' y 'awk'
}

# Opción 2: Desplegar discos
funcion_discos() {
    echo "Opción 2: (En desarrollo) Desplegar filesystems o discos..."
    # Aquí irán los comandos 'df'
}

# Opción 3: Ver 10 archivos más grandes
funcion_10_mas_grandes() {
    echo "Opción 3: (En desarrollo) Ver 10 archivos más grandes..."
    # Aquí irán los comandos 'find', 'du', 'sort', 'head'
}

# Opción 4: Ver memoria libre y swap
funcion_memoria() {
    echo "Opción 4: (En desarrollo) Ver memoria libre y swap..."
    # Aquí irá el comando 'free' y 'awk'
}

# Opción 5: Hacer copia de seguridad
funcion_backup() {
    echo "Opción 5: (En desarrollo) Hacer copia de seguridad a USB..."
    # Aquí irán los comandos 'tar' o 'rsync', 'find'
}

# --- Función para Mostrar el Menú ---
mostrar_menu() {
    # Usamos 'echo' para imprimir en la salida estándar (stdout) [cite: 278]
    echo ""
    echo "================================================="
    echo "   Herramienta de Administración de Data Center (BASH)"
    echo "================================================="
    echo "1. Desplegar usuarios y último login "
    echo "2. Desplegar discos (filesystems) [cite: 506]"
    echo "3. Ver 10 archivos más grandes [cite: 508]"
    echo "4. Ver memoria libre y swap [cite: 510]"
    echo "5. Hacer copia de seguridad (Backup) a USB [cite: 511]"
    echo "S. Salir"
    echo "================================================="
}

# --- Cuerpo Principal del Script ---
# [cite: 86]
while true # Bucle de repetición 
do
    mostrar_menu
    echo -n "Seleccione una opción: " # [cite: 282, 335]
    read opcion # 

    case $opcion in # [cite: 325, 337]
        1) 
            funcion_usuarios ;; # [cite: 327]
        2) 
            funcion_discos ;;
        3) 
            funcion_10_mas_grandes ;;
        4) 
            funcion_memoria ;;
        5) 
            funcion_backup ;;
        's' | 'S') # [cite: 338, 346]
            echo "Saliendo del script. ¡Hasta pronto!"
            exit 0 ;; # [cite: 348]
        *) # [cite: 349]
            echo "Opción inválida. Por favor, intente de nuevo." ;; # [cite: 350]
    esac # [cite: 351]

    echo ""
    echo -n "Presione Enter para continuar..."
    read # Pausa para que el usuario pueda leer la salida
done