#!/bin/bash
# [cite: 69]
# Proyecto Final de Sistemas Operacionales - Herramienta BASH

# --- Definición de Funciones (vacías por ahora) ---
# [cite: 391, 401, 403]

# Opcion 1: Desplegar usuarios y ultimo login
funcion_usuarios() {
    echo "Opcion 1: Desplegando usuarios y ultimo login..."
    echo ""
    
    # Ejecutamos 'lastlog' UNA SOLA VEZ y 'awk' UNA SOLA VEZ
    # (Asegúrate de tener la ruta correcta si 'sudo' no es una opción)
    lastlog | awk '
    
    # 1. Se ejecuta antes que nada
    BEGIN { 
        printf "%-20s | %s\n", "Usuario", "Último Ingreso"
        printf "===================================================================\n"
    }
    
    # 2. PATRON DE BUSQUEDA: Saltar el encabezado original
    # (NR es el Numero de Registro, 'next' salta al siguiente)
    NR == 1 { next }

    # 3. PATRON DE BUSQUEDA: Saltar usuarios de sistema
    # Usamos una expresion regular para saltar lineas que EMPIECEN (^)
    # con nombres de servicio comunes.
    /^(daemon|bin|sys|sync|games|man|lp|mail|news|uucp|proxy|www-data|backup|sshd)/ { next }

    # 4. ACCION: Se ejecuta para todas las lineas que SI pasaron
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

# Opcion 2: Desplegar discos
# Opcion 2: Desplegar discos (filesystems)
mostrar_discos() {
    echo ""
    echo "==========================================================="
    echo "      Reporte de Discos y Filesystems (en Bytes)"
    echo "==========================================================="
    
    # df: Muestra espacio en disco
    # -B1: Muestra tamaños en bloques de 1 Byte (requisito)
    # --output=...: Selecciona columnas específicas
    # -x: Excluye tipos de filesystem irrelevantes (temporales, etc.)
    # column -t: Formatea la salida como una tabla
    df -B1 --output=source,size,avail -x tmpfs -x devtmpfs -x squashfs | column -t
    
    echo "==========================================================="
    echo ""
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Opcion 3: Ver 10 archivos mas grandes
buscar_archivos_grandes() {
    local ruta
    
    echo ""
    echo "==========================================================="
    echo "           Top 10 Archivos Más Grandes (en Bytes)"
    echo "==========================================================="
    
    read -p "Ingresa la ruta del disco o directorio a escanear (ej: /var o /home): " ruta

    # Validamos que la ruta exista y sea un directorio
    if [ ! -d "$ruta" ]; then
        echo "Error: La ruta '$ruta' no existe o no es un directorio."
        echo "==========================================================="
        echo ""
        read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
        return 1 # Retorna un código de error
    fi

    echo "Escaneando '$ruta'... (esto puede tardar varios minutos)"

    # find: Busca archivos (-type f)
    # -exec du -b {} +: Obtiene el tamaño en bytes de forma eficiente
    # 2>/dev/null: Oculta errores de "Permiso denegado"
    # sort -nr: Ordena numéricamente en reverso
    # head -n 10: Muestra los primeros 10
    # column -t: Formatea en tabla
    find "$ruta" -type f -exec du -b {} + 2>/dev/null | sort -nr | head -n 10 | column -t
    
    echo "==========================================================="
    echo ""
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Opcion 4: Ver memoria libre y swap
reportar_memoria() {
    echo ""
    echo "==========================================================="
    echo "            Reporte de Memoria y Swap (Bytes y %)"
    echo "==========================================================="
    
    # free -b: Muestra memoria en bytes
    # awk: Procesa la salida de 'free'
    # NR==2: Se ejecuta en la línea 2 (Memoria)
    # NR==3: Se ejecuta en la línea 3 (Swap)
    # '%.2f%%': Formatea el número flotante (porcentaje) a 2 decimales
    # 'total=$2 || total=1': Previene división por cero si el swap total es 0
    
    free -b | awk '
    NR==2 { 
        total=$2; free=$4; 
        printf "Memoria Libre:   %d bytes (%.2f%%)\n", free, (free/total)*100 
    }
    NR==3 { 
        total=$2 || total=1; used=$3; 
        printf "Swap Usado:      %d bytes (%.2f%%)\n", used, (used/total)*100 
    }'
    
    echo "==========================================================="
    echo ""
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Opcion 5: Hacer copia de seguridad
realizar_backup() {
    local origen
    local destino
    local catalogo_file
    
    echo ""
    echo "==========================================================="
    echo "           Asistente de Backup de Directorio"
    echo "==========================================================="
    
    read -p "Ingresa la ruta del directorio a respaldar (ej: /home/user/docs): " origen
    read -p "Ingresa la ruta de destino (ej: /media/mi_usb/backups): " destino

    # Validación de origen
    if [ ! -d "$origen" ]; then
        echo "Error: El directorio de origen '$origen' no existe."
        echo "==========================================================="
        echo ""
        read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
        return 1
    fi

    # Validación/Creación de destino
    mkdir -p "$destino"
    if [ ! -d "$destino" ]; then
        echo "Error: No se pudo crear el directorio de destino '$destino'."
        echo "Asegúrate de tener permisos o que el USB esté montado."
        echo "==========================================================="
        echo ""
        read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
        return 1
    fi

    echo "Iniciando backup con rsync de '$origen' a '$destino'..."
    
    # rsync -av: Modo 'archive' (recursivo, preserva fechas/permisos) y 'verbose'
    rsync -av "$origen" "$destino"
    
    # Verificamos si rsync (backup) fue exitoso
    if [ $? -eq 0 ]; then
        echo "Backup completado exitosamente."
        
        # Generar el catálogo
        # basename: extrae el último nombre de la ruta (ej: 'docs' de '/home/user/docs')
        catalogo_file="$destino/catalogo_$(basename "$origen")$(date +%Y%m%d%H%M%S).txt"
        
        echo "Generando catálogo de archivos en '$catalogo_file'..."
        
        # ls -lR: Lista recursivamente (-R) con formato largo (-l)
        # El formato largo incluye las fechas de modificación
        ls -lR "$origen" > "$catalogo_file"
        
        echo "Catálogo generado."
    else
        echo "Error: Ocurrió un problema durante el proceso de rsync (backup)."
    fi
    
    echo "==========================================================="
    echo ""
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# --- Función para Mostrar el Menú ---
mostrar_menu() {
    # Usamos 'echo' para imprimir en la salida estándar (stdout) [cite: 278]
    echo ""
    echo "================================================="
    echo "   Herramienta de Administracion de Data Center (BASH)"
    echo "================================================="
    echo "1. Desplegar usuarios y ultimo login "
    echo "2. Desplegar discos (filesystems) [cite: 506]"
    echo "3. Ver 10 archivos mas grandes [cite: 508]"
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
            mostrar_discos ;;
        3)
            buscar_archivos_grandes ;;
        4)
            reportar_memoria ;;
        5)
            realizar_backup ;;
        's' | 'S') # [cite: 338, 346]
            echo "Saliendo del script. ¡Hasta pronto!"
            exit 0 ;; # [cite: 348]
        *) # [cite: 349]
            echo "Opcion invalida. Por favor, intente de nuevo." ;; # [cite: 350]
    esac # [cite: 351]

    echo ""
    echo -n "Presione Enter para continuar..."
    read # Pausa para que el usuario pueda leer la salida
done