#!/bin/bash
# [cite: 69]
# Proyecto Final de Sistemas Operacionales - Herramienta BASH

# --- Definición de Funciones (vacías por ahora) ---
# [cite: 391, 401, 403]

# Opción 1: Desplegar usuarios y último login
# Opción 1: Desplegar usuarios y último login 
# Opción 1: Desplegar usuarios y último login (Versión Eficiente)
funcion_usuarios() {
    echo "OpCión 1: Desplegando usuarios y último login..."
    echo ""
    
    # Ejecutamos 'lastlog' UNA SOLA VEZ y 'awk' UNA SOLA VEZ
    # (Asegúrate de tener la ruta correcta si 'sudo' no es una opción)
    lastlog | awk '
    
    # 1. Se ejecuta antes que nada
    BEGIN { 
        printf "%-20s | %s\n", "Usuario", "Último Ingreso"
        printf "===================================================================\n"
    }
    
    # 2. PATRÓN DE BÚSQUEDA: Saltar el encabezado original
    # (NR es el Número de Registro, 'next' salta al siguiente)
    NR == 1 { next }

    # 3. PATRÓN DE BÚSQUEDA: Saltar usuarios de sistema
    # Usamos una expresión regular para saltar líneas que EMPIECEN (^)
    # con nombres de servicio comunes.
    /^(daemon|bin|sys|sync|games|man|lp|mail|news|uucp|proxy|www-data|backup|sshd)/ { next }

    # 4. ACCIÓN: Se ejecuta para todas las líneas que SÍ pasaron
    {
        if ($0 ~ /\*\*Never logged in\*\*/) {
            printf "%-20s | %s\n", $1, "Nunca ha ingresado"
        } else {
            # Reconstruye la fecha desde el campo 4 hasta el final (NF)
            lastlogin = ""
            for (i=4; i<=NF; i++) { 
                lastlogin = lastlogin " " $i
            }
            printf "%-20s |%s\n", $1, lastlogin
        }
    }'
}

# Opción 2: Desplegar discos
# Opción 2: Desplegar discos (filesystems)
funcion_discos() {
    echo "OpCión 2: Desplegando discos (filesystems)..."
    echo ""
    
    # Usamos df -B1 para que la salida sea en bloques de 1 byte
    # | (pipe) para enviar la salida a awk
    df -B1 | awk '
    
    # 1. (BEGIN) Imprimir el encabezado
    BEGIN {
        printf "%-25s | %-18s | %-18s\n", "Disco (Filesystem)", "Tamaño Total (Bytes)", "Espacio Libre (Bytes)"
        printf "============================================================================\n"
    }
    
    # 2. (PATRÓN) Saltar la primera línea (que es el encabezado de df)
    # NR (Número de Registro) > 1
    NR > 1 {
        # 3. (ACCIÓN) Imprimir los campos formateados
        # $1 = Filesystem, $2 = Tamaño Total, $4 = Espacio Libre
        printf "%-25s | %-18s | %-18s\n", $1, $2, $4
    }'
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