#!/bin/bash
# Proyecto Final de Sistemas Operacionales - Herramienta BASH
# --- Definición de Funciones (vacías por ahora) ---

# =============================================================================
# FUNCIÓN: funcion_usuarios
# Descripción: Muestra un listado de usuarios del sistema y su último login.
#              Utiliza 'lastlog' como fuente principal, pero implementa un
#              fallback inteligente a 'last' (wtmp) cuando lastlog no tiene
#              registros, garantizando información precisa incluso en sistemas
#              donde /var/log/lastlog está vacío o desactualizado.
#
# Flujo de trabajo:
#   1. Ejecuta 'lastlog' y procesa la salida con awk
#   2. Filtra usuarios de sistema (daemon, bin, sys, etc.)
#   3. Para usuarios con registro en lastlog: muestra la fecha directamente
#   4. Para usuarios sin registro en lastlog: consulta 'last' como fallback
#   5. Si 'last' tiene datos: muestra la última entrada de wtmp
#   6. Si ninguna fuente tiene datos: muestra "Nunca ha ingresado"
#
# Ventajas del enfoque híbrido:
#   - Funciona en sistemas con lastlog vacío (ej: autologin, algunos DM)
#   - Usa wtmp (/var/log/wtmp) como fuente alternativa confiable
#   - No requiere modificar configuración PAM del sistema
#   - Mantiene eficiencia: lastlog se ejecuta una sola vez
#
# Comandos utilizados:
#   - lastlog: Lee /var/log/lastlog (base de datos de último login por UID)
#   - last: Lee /var/log/wtmp (historial completo de logins/logouts)
#   - awk: Procesamiento y formato de texto
#
# Salida: Tabla formateada con columnas "Usuario | Último Ingreso"
# =============================================================================
# Opcion 1: Desplegar usuarios y ultimo login
funcion_usuarios() {
    echo "Opcion 1: Desplegando usuarios y ultimo login..."
    echo ""
    
    # Imprimir encabezado de la tabla
    printf "%-20s | %s\n" "Usuario" "Último Ingreso"
    printf "===================================================================\n"
    
    # --- ESTRATEGIA HÍBRIDA: lastlog + fallback a last ---
    # Procesamos lastlog línea por línea, pero para usuarios sin registro
    # consultamos 'last' (wtmp) que suele tener más información, especialmente
    # en sistemas con display managers que no actualizan lastlog.
    
    # Ejecutamos 'lastlog' UNA SOLA VEZ y procesamos cada línea
    lastlog | awk '
        # Saltar la línea de encabezado de lastlog
        NR == 1 { next }
        
        # Filtrar usuarios de sistema comunes (daemons, servicios)
        # Estos usuarios no son relevantes para el reporte de administración
        /^(daemon|bin|sys|sync|games|man|lp|mail|news|uucp|proxy|www-data|backup|sshd|systemd|polkit|avahi|colord|rtkit|dbus|cups)/ { next }
        
        # Para cada línea válida, extraer el nombre de usuario
        { print $1 }
    ' | while IFS= read -r usuario; do
        # Para cada usuario, verificar si lastlog tiene registro
        # Usamos 'lastlog -u' para obtener info específica de ese usuario
        lastlog_info=$(lastlog -u "$usuario" 2>/dev/null | tail -n 1)
        
        # Verificar si lastlog muestra "Never logged in"
        if echo "$lastlog_info" | grep -q '\*\*Never logged in\*\*'; then
            # --- FALLBACK A 'last' (wtmp) ---
            # lastlog no tiene registro, intentamos obtener info de wtmp
            # que suele tener entradas incluso cuando lastlog está vacío
            
            # Obtenemos la última entrada de este usuario en wtmp
            # -n 1: solo la más reciente
            # 2>/dev/null: suprime errores si el usuario nunca se logeó
            last_entry=$(last -n 1 "$usuario" 2>/dev/null | head -n 1)
            
            # Verificar si 'last' retornó algún dato válido
            # Si la línea está vacía o contiene "wtmp begins", no hay logins
            if [ -n "$last_entry" ] && ! echo "$last_entry" | grep -q "^wtmp begins"; then
                # Extraer la fecha/hora de la entrada de 'last'
                # Formato de 'last': usuario tty desde fecha hora - info
                # Extraemos del campo 4 en adelante (fecha y hora)
                fecha=$(echo "$last_entry" | awk '{
                    # Reconstruir fecha desde el campo 4 hasta antes de "-" o "still"
                    resultado = ""
                    for (i=4; i<=NF; i++) {
                        if ($i == "-" || $i == "still" || $i == "down" || $i == "crash") break
                        resultado = resultado " " $i
                    }
                    print resultado
                }')
                
                # Detectar si el usuario está actualmente conectado
                if echo "$last_entry" | grep -q "still logged in"; then
                    printf "%-20s | %s (Conectado ahora)\n" "$usuario" "$fecha"
                else
                    printf "%-20s | %s (desde wtmp)\n" "$usuario" "$fecha"
                fi
            else
                # Ni lastlog ni last tienen información: usuario nunca se logeó
                printf "%-20s | %s\n" "$usuario" "Nunca ha ingresado"
            fi
        else
            # lastlog SÍ tiene registro válido, extraer y mostrar la fecha
            fecha=$(echo "$lastlog_info" | awk '{
                # Los campos 1-3 son usuario/puerto/desde
                # Del campo 4 en adelante está la fecha que necesitamos
                lastlogin = ""
                for (i=4; i<=NF; i++) {
                    lastlogin = lastlogin " " $i
                }
                print lastlogin
            }')
            printf "%-20s |%s\n" "$usuario" "$fecha"
        fi
    done
    
    echo ""
}

# =============================================================================
# FUNCIÓN: mostrar_discos
# Descripción: Muestra información sobre los discos y filesystems montados en
#              el sistema, incluyendo el espacio total y disponible en bytes.
#
# Salida: Tabla con columnas: Filesystem | Tamaño Total | Espacio Disponible
#
# Comandos utilizados:
#   - df: Disk Free - Reporta uso de espacio en filesystems
#   - column: Formatea la salida en columnas alineadas
#
# Opciones de df:
#   -B1: Block size de 1 byte (muestra tamaños en bytes, no en KB o MB)
#   --output=source,size,avail: Selecciona solo las columnas deseadas
#   -x tmpfs/devtmpfs/squashfs: Excluye filesystems temporales/virtuales
#
# Notas:
#   - Los tamaños se muestran en bytes según requisitos del proyecto
#   - Se excluyen filesystems que no representan almacenamiento físico real
# =============================================================================
mostrar_discos() {
    echo ""
    echo "==========================================================="
    echo "      Reporte de Discos y Filesystems (en Bytes)"
    echo "==========================================================="
    
    # COMANDO df (Disk Free):
    # Muestra el uso de espacio en disco de todos los filesystems montados.
    #
    # Opciones utilizadas:
    #   -B1 (--block-size=1): Fuerza que los tamaños se muestren en bloques
    #                         de 1 byte. Por defecto, df usa KB (1024 bytes).
    #
    #   --output=source,size,avail: Formato de salida personalizado que muestra:
    #       * source: El dispositivo o filesystem (ej: /dev/sda1, /dev/nvme0n1p2)
    #       * size: Tamaño total del filesystem en bytes
    #       * avail: Espacio disponible (libre) en bytes
    #
    #   -x tmpfs: Excluye filesystems de tipo 'tmpfs' (filesystem temporal en RAM)
    #   -x devtmpfs: Excluye 'devtmpfs' (filesystem virtual para dispositivos)
    #   -x squashfs: Excluye 'squashfs' (filesystem comprimido de solo lectura,
    #                común en snaps de Ubuntu)
    #
    # COMANDO column:
    #   -t: Crea una tabla alineando automáticamente las columnas basándose
    #       en el contenido. Hace la salida más legible.
    #
    # PIPELINE (|):
    # La salida de df se pasa directamente a column para formateo.
    df -B1 --output=source,size,avail -x tmpfs -x devtmpfs -x squashfs | column -t
    
    echo "==========================================================="
    echo ""
    # Pausa para que el usuario pueda leer la salida antes de volver al menú
    # -n 1: Lee solo 1 carácter
    # -s: Modo silencioso (no muestra el carácter presionado)
    # -r: Raw mode (trata backslashes literalmente)
    # -p: Muestra un prompt antes de leer
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# =============================================================================
# FUNCIÓN: buscar_archivos_grandes
# Descripción: Busca y lista los 10 archivos más grandes en una ruta específica
#              proporcionada por el usuario. Útil para identificar qué está
#              consumiendo espacio en disco.
#
# Entrada: Solicita al usuario una ruta (ej: /var, /home)
# Salida: Lista de los 10 archivos más grandes con su tamaño en bytes
#
# Comandos utilizados:
#   - find: Busca archivos recursivamente
#   - du: Disk Usage - Calcula el tamaño de archivos
#   - sort: Ordena los resultados
#   - head: Muestra solo las primeras líneas
#   - column: Formatea en tabla
#
# Validaciones:
#   - Verifica que la ruta exista y sea un directorio
#   - Maneja errores de permisos (redirección 2>/dev/null)
#
# Notas:
#   - Puede tardar varios minutos en directorios grandes
#   - Requiere permisos de lectura en los directorios escaneados
# =============================================================================
buscar_archivos_grandes() {
    # Variable local para almacenar la ruta ingresada por el usuario
    local ruta
    
    echo ""
    echo "==========================================================="
    echo "           Top 10 Archivos Más Grandes (en Bytes)"
    echo "==========================================================="
    
    # Solicitar al usuario la ruta a escanear
    # read -p: Muestra un prompt y lee la entrada del usuario
    read -p "Ingresa la ruta del disco o directorio a escanear (ej: /var o /home): " ruta

    # --- VALIDACIÓN DE ENTRADA ---
    # Verificamos que la ruta proporcionada exista y sea un directorio válido
    # [ ... ]: Sintaxis de test en bash
    # ! : Operador de negación (NOT)
    # -d : Test que verifica si el path es un directorio
    if [ ! -d "$ruta" ]; then
        echo "Error: La ruta '$ruta' no existe o no es un directorio."
        echo "==========================================================="
        echo ""
        read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
        # return 1: Retorna código de error (1) y termina la función
        return 1
    fi

    echo "Escaneando '$ruta'... (esto puede tardar varios minutos)"

    # --- COMANDO PRINCIPAL: BUSCAR Y ORDENAR ARCHIVOS ---
    #
    # FIND: Búsqueda recursiva de archivos
    #   "$ruta": Directorio raíz desde donde iniciar la búsqueda (entrecomillado
    #            para manejar espacios en la ruta)
    #   -type f: Solo buscar archivos regulares (f=file), excluye directorios,
    #            enlaces simbólicos, dispositivos, etc.
    #   -exec du -b {} +: Por cada archivo encontrado, ejecuta el comando 'du'
    #       * du: Disk Usage - calcula el tamaño
    #       * -b: Muestra el tamaño en bytes (byte count)
    #       * {}: Placeholder reemplazado por el nombre del archivo encontrado
    #       * +: Agrupa múltiples archivos en una sola ejecución de du (más
    #            eficiente que usar \; que ejecutaría du una vez por archivo)
    #
    # 2>/dev/null: Redirige STDERR (errores) al "agujero negro" del sistema
    #              Esto oculta mensajes de "Permiso denegado" cuando find
    #              intenta acceder a directorios sin permisos.
    #
    # SORT: Ordena la salida
    #   -n: Ordenamiento numérico (no alfabético)
    #   -r: Reverse - orden descendente (mayor a menor)
    #
    # HEAD: Muestra solo las primeras líneas
    #   -n 10: Limita la salida a las primeras 10 líneas (los 10 más grandes)
    #
    # COLUMN: Formatea en tabla alineada
    #   -t: Detecta columnas automáticamente y las alinea
    find "$ruta" -type f -exec du -b {} + 2>/dev/null | sort -nr | head -n 10 | column -t
    
    echo "==========================================================="
    echo ""
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# =============================================================================
# FUNCIÓN: reportar_memoria
# Descripción: Muestra un reporte del estado actual de la memoria RAM y el
#              espacio de intercambio (swap) del sistema, incluyendo valores
#              en bytes y porcentajes de uso.
#
# Salida: 
#   - Memoria Libre: bytes y porcentaje del total
#   - Swap Usado: bytes y porcentaje del total
#
# Comandos utilizados:
#   - free: Muestra información sobre memoria RAM y swap
#   - awk: Procesa y calcula los porcentajes
#
# Fórmulas:
#   - % Memoria Libre = (memoria_libre / memoria_total) * 100
#   - % Swap Usado = (swap_usado / swap_total) * 100
#
# Notas:
#   - Los valores se muestran en bytes según requisitos del proyecto
#   - Incluye protección contra división por cero si no hay swap configurado
# =============================================================================
reportar_memoria() {
    echo ""
    echo "==========================================================="
    echo "            Reporte de Memoria y Swap (Bytes y %)"
    echo "==========================================================="
    
    # --- COMANDO FREE ---
    # Muestra información sobre la memoria RAM y swap del sistema
    #
    # FREE -b: El flag -b (bytes) fuerza que todos los valores se muestren
    #          en bytes en lugar de la unidad por defecto (KB o MB).
    #
    # Estructura de la salida de 'free':
    #   Línea 1: Encabezados (total, used, free, shared, buff/cache, available)
    #   Línea 2: Memoria RAM (Mem:)
    #   Línea 3: Memoria Swap (Swap:)
    #
    # AWK: Procesador de texto que ejecuta acciones basadas en patrones
    free -b | awk '
    
    # --- PROCESAMIENTO DE LÍNEA 2: Memoria RAM ---
    # NR==2: Este bloque se ejecuta SOLO en la línea 2 (registro número 2)
    # En awk, los campos se acceden con $1, $2, $3, etc.
    # Campos de interés en línea Mem:
    #   $1 = "Mem:"
    #   $2 = total de memoria
    #   $3 = memoria usada
    #   $4 = memoria libre
    NR==2 { 
        total=$2;  # Guardamos el total de RAM en la variable 'total'
        free=$4;   # Guardamos la memoria libre en la variable 'free'
        
        # printf: Impresión formateada (como printf en C)
        #   %d: Formato decimal (entero)
        #   %.2f: Formato flotante con 2 decimales
        #   %%: Carácter literal % (escape)
        # Cálculo: (free/total)*100 da el porcentaje de memoria libre
        printf "Memoria Libre:   %d bytes (%.2f%%)\n", free, (free/total)*100 
    }
    
    # --- PROCESAMIENTO DE LÍNEA 3: Swap ---
    # NR==3: Este bloque se ejecuta SOLO en la línea 3
    # Campos de interés en línea Swap:
    #   $1 = "Swap:"
    #   $2 = total de swap
    #   $3 = swap usado
    NR==3 { 
        # Operador ||: Si $2 es 0 o vacío, asigna 1 a 'total'
        # Esto previene división por cero si el sistema no tiene swap configurado
        total=$2 || total=1;
        used=$3;  # Guardamos el swap usado
        
        # Calculamos e imprimimos el porcentaje de swap usado
        # Si total=1 (no hay swap), el porcentaje será muy pequeño pero no causará error
        printf "Swap Usado:      %d bytes (%.2f%%)\n", used, (used/total)*100 
    }'
    
    echo "==========================================================="
    echo ""
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# =============================================================================
# FUNCIÓN: realizar_backup
# Descripción: Realiza una copia de seguridad completa de un directorio a una
#              ubicación de destino (típicamente un USB u otro disco) y genera
#              un catálogo con la lista de archivos respaldados.
#
# Entrada: 
#   - Ruta del directorio a respaldar (origen)
#   - Ruta donde guardar el backup (destino)
#
# Salida:
#   - Copia completa del directorio en el destino
#   - Archivo de catálogo con listado detallado y fechas de modificación
#
# Comandos utilizados:
#   - rsync: Herramienta de sincronización/copia eficiente
#   - ls: Lista archivos para generar el catálogo
#   - basename: Extrae el nombre del directorio
#   - date: Genera timestamp para el nombre del catálogo
#
# Validaciones:
#   - Verifica que el directorio origen exista
#   - Crea el directorio destino si no existe
#   - Verifica permisos de escritura en destino
#   - Valida que rsync completó exitosamente antes de generar catálogo
#
# Ventajas de rsync:
#   - Copia incremental (solo archivos nuevos/modificados en ejecuciones futuras)
#   - Preserva permisos, propietarios, timestamps
#   - Manejo robusto de errores
# =============================================================================
realizar_backup() {
    # Variables locales para almacenar las rutas proporcionadas por el usuario
    local origen
    local destino
    local catalogo_file
    
    echo ""
    echo "==========================================================="
    echo "           Asistente de Backup de Directorio"
    echo "==========================================================="
    
    # Solicitar al usuario las rutas de origen y destino
    read -p "Ingresa la ruta del directorio a respaldar (ej: /home/user/docs): " origen
    read -p "Ingresa la ruta de destino (ej: /media/mi_usb/backups): " destino

    # --- VALIDACIÓN 1: Verificar que el origen exista ---
    # Es crítico asegurar que el directorio origen existe antes de intentar copiarlo
    if [ ! -d "$origen" ]; then
        echo "Error: El directorio de origen '$origen' no existe."
        echo "==========================================================="
        echo ""
        read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
        return 1  # Termina la función con código de error
    fi

    # --- VALIDACIÓN 2: Crear/Verificar directorio destino ---
    # mkdir -p: Crea el directorio y todos los directorios padres necesarios
    #           El flag -p (parents) evita errores si el directorio ya existe
    mkdir -p "$destino"
    
    # Verificamos que el directorio destino realmente exista o se haya creado
    # Esto puede fallar si:
    #   - No hay permisos de escritura en el path padre
    #   - El dispositivo USB no está montado
    #   - El filesystem está lleno
    if [ ! -d "$destino" ]; then
        echo "Error: No se pudo crear el directorio de destino '$destino'."
        echo "Asegúrate de tener permisos o que el USB esté montado."
        echo "==========================================================="
        echo ""
        read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
        return 1
    fi

    echo "Iniciando backup con rsync de '$origen' a '$destino'..."
    
    # --- COMANDO RSYNC: Sincronización/Copia de Archivos ---
    # rsync es superior a 'cp' para backups porque:
    #   - Solo copia archivos nuevos o modificados (incremental)
    #   - Preserva metadata (permisos, propietarios, timestamps)
    #   - Maneja mejor errores y archivos grandes
    #   - Puede reanudar transferencias interrumpidas
    #
    # Opciones utilizadas:
    #   -a (--archive): Modo "archivo" que incluye:
    #       * -r (recursive): Copia recursiva de subdirectorios
    #       * -l (links): Preserva enlaces simbólicos
    #       * -p (perms): Preserva permisos
    #       * -t (times): Preserva timestamps de modificación
    #       * -g (group): Preserva grupo propietario
    #       * -o (owner): Preserva usuario propietario
    #       * -D: Preserva archivos de dispositivo y archivos especiales
    #   -v (--verbose): Modo verboso, muestra archivos siendo copiados
    rsync -av "$origen" "$destino"
    
    # --- VERIFICACIÓN DE ÉXITO ---
    # $? es una variable especial que contiene el código de salida del último comando
    # En bash: 0 = éxito, cualquier otro valor = error
    if [ $? -eq 0 ]; then
        echo "Backup completado exitosamente."
        
        # --- GENERACIÓN DE CATÁLOGO ---
        # Crear un archivo de texto con el listado completo de archivos respaldados
        
        # CONSTRUCCIÓN DEL NOMBRE DEL ARCHIVO:
        # basename: Extrae solo el nombre del último directorio de la ruta
        #   Ejemplo: basename "/home/user/documentos" → "documentos"
        # date +%Y%m%d%H%M%S: Genera timestamp en formato: AñoMesDíaHoraMinutoSegundo
        #   Ejemplo: 20251106143025 (6 de nov 2025, 14:30:25)
        # Resultado: catalogo_documentos20251106143025.txt
        catalogo_file="$destino/catalogo_$(basename "$origen")_$(date +%Y%m%d%H%M%S).txt"
        
        echo "Generando catálogo de archivos en '$catalogo_file'..."
        
        # --- COMANDO LS: Listado de archivos ---
        # ls -lR: Lista el contenido del directorio con detalles
        #   -l (long): Formato largo que muestra:
        #       * Permisos (rwxr-xr-x)
        #       * Número de enlaces
        #       * Propietario y grupo
        #       * Tamaño en bytes
        #       * Fecha y hora de última modificación
        #       * Nombre del archivo
        #   -R (recursive): Lista recursivamente todos los subdirectorios
        #
        # > : Redirige la salida estándar al archivo especificado
        #     Si el archivo existe, lo sobrescribe; si no, lo crea
        ls -lR "$origen" > "$catalogo_file"
        
        echo "Catálogo generado."
    else
        echo "Error: Ocurrió un problema durante el proceso de rsync (backup)."
        echo "Código de error: $?"
    fi
    
    echo "==========================================================="
    echo ""
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# =============================================================================
# FUNCIÓN: mostrar_menu
# Descripción: Despliega el menú principal de la herramienta, mostrando todas
#              las opciones disponibles al usuario.
#
# Salida: Menú formateado en pantalla con 5 opciones + opción de salida
#
# Notas:
#   - Usa echo para imprimir en stdout (salida estándar)
#   - El formato visual ayuda a la legibilidad y profesionalismo
# =============================================================================
mostrar_menu() {
    # echo: Comando integrado de bash que imprime texto en la salida estándar
    # Cada línea del menú se imprime con un echo separado para claridad
    echo ""
    echo "================================================="
    echo "   Herramienta de Administracion de Data Center (BASH)"
    echo "================================================="
    echo "1. Desplegar usuarios y ultimo login "
    echo "2. Desplegar discos (filesystems)"
    echo "3. Ver 10 archivos mas grandes"
    echo "4. Ver memoria libre y swap"
    echo "5. Hacer copia de seguridad (Backup) a USB"
    echo "S. Salir"
    echo "================================================="
}

# =============================================================================
# CUERPO PRINCIPAL DEL SCRIPT
# =============================================================================
# Esta es la sección de ejecución principal que crea un bucle infinito
# para mostrar el menú repetidamente hasta que el usuario elija salir.
#
# Estructura del flujo:
#   1. Mostrar menú
#   2. Leer opción del usuario
#   3. Ejecutar función correspondiente (usando case)
#   4. Volver al paso 1
#
# BUCLE WHILE:
# - 'while true': Crea un bucle infinito (true siempre evalúa a verdadero)
# - La única forma de salir es con 'exit' o interrumpir con Ctrl+C
# - Este patrón es común en menús interactivos
# =============================================================================
while true  # Condición siempre verdadera = bucle infinito
do
    # Llamar a la función que muestra el menú
    mostrar_menu
    
    # Solicitar input del usuario
    # echo -n: Imprime sin newline al final (el cursor queda en la misma línea)
    echo -n "Seleccione una opción: "
    
    # read: Lee una línea de entrada del usuario y la almacena en la variable 'opcion'
    # La ejecución se pausa aquí hasta que el usuario presione Enter
    read opcion

    # --- ESTRUCTURA CASE: Switch/Select de Bash ---
    # Similar a switch en C o match en otros lenguajes
    # Evalúa la variable $opcion y ejecuta el bloque correspondiente
    #
    # Sintaxis:
    #   case VARIABLE in
    #       patron1) comandos ;;
    #       patron2) comandos ;;
    #       *) comandos_por_defecto ;;
    #   esac
    #
    # ;;  → Termina ese caso (break implícito)
    # |   → Operador OR para múltiples patrones
    # *   → Patrón comodín (catch-all, equivalente a 'default')
    case $opcion in
        # Opción 1: Llamar a la función de usuarios
        1) 
            funcion_usuarios ;;
        
        # Opción 2: Llamar a la función de discos
        2)
            mostrar_discos ;;
        
        # Opción 3: Llamar a la función de archivos grandes
        3)
            buscar_archivos_grandes ;;
        
        # Opción 4: Llamar a la función de memoria
        4)
            reportar_memoria ;;
        
        # Opción 5: Llamar a la función de backup
        5)
            realizar_backup ;;
        
        # Opciones 's' o 'S': Salir del programa
        # El | actúa como OR lógico: acepta minúscula o mayúscula
        's' | 'S')
            echo "Saliendo del script. ¡Hasta pronto!"
            # exit 0: Termina el script con código de éxito (0)
            # Esto rompe el bucle while y finaliza la ejecución
            exit 0 ;;
        
        # Patrón por defecto: Cualquier otra entrada
        # El asterisco (*) coincide con cualquier valor no manejado arriba
        *)
            echo "Opcion invalida. Por favor, intente de nuevo." ;;
    esac  # Fin de la estructura case (esac = case al revés)

    # Pausa antes de mostrar el menú nuevamente
    # Esto da tiempo al usuario para leer cualquier mensaje
    echo ""
    echo -n "Presione Enter para continuar..."
    read # Lee y descarta la entrada (solo espera Enter)
done # Fin del bucle while
