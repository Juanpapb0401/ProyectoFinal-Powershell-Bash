# Proyecto Final de Sistemas Operacionales - Herramienta PowerShell

# Opcion 1: Desplegar usuarios y ultimo login
function Get-UsuariosLogin {
    # Linea 1: Imprime mensaje informativo en la consola para el usuario
    Write-Output "Opcion 1: Desplegando usuarios y ultimo login..."

    # Linea 2: Imprime una linea en blanco para que se vea mejor visualmente
    Write-Output ""

    # Linea 3: Inicia bloque try para capturar errores que puedan ocurrir
    try {
        # Consulta WMI/CIM para obtener perfiles de login

        # Get-CimInstance: cmdlet que consulta clases WMI/CIM
        # -ClassName Win32_NetworkLoginProfile: clase que contiene informacion de perfiles de acceso
        # Esta clase SI tiene la propiedad LastLogon (fecha/hora del ultimo ingreso)
        # Resultado: coleccion (array) de objetos con propiedades Name, LastLogon, etc.
        $loginProfiles = Get-CimInstance -ClassName Win32_NetworkLoginProfile

        # Consulta WMI/CIM para obtener solo cuentas locales

        # Get-CimInstance: mismo cmdlet de consulta WMI/CIM
        # -ClassName Win32_UserAccount: clase que representa cuentas de usuario
        # -Filter "LocalAccount = $True": filtro WQL (WMI Query Language) que selecciona
        #         solo cuentas locales (excluye cuentas de dominio, cuentas del sistema remoto)
        # Resultado: coleccion de cuentas locales con propiedades Name, SID, etc.
        $localUsers = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = $True"
        
        # Linea 8: Imprime encabezado de la tabla que vamos a mostrar
        Write-Output "Usuarios locales y su ultimo ingreso conocido:"
        
        # Linea 9: Imprime linea separadora visual
        Write-Output "-----------------------------------------------"

        # Linea 10: Inicia un bucle foreach que recorre cada cuenta local
        # Para cada objeto en la coleccion $localUsers, asigna el objeto actual a la variable $user y ejecuta el bloque { }
        # $results = foreach (...) { ... }: el foreach DEVUELVE una coleccion de objetos
        # que se almacena en la variable $results
        $results = foreach ($user in $localUsers) {
            
            # Busca el perfil de login correspondiente al usuario actual

            # $loginProfiles | Where-Object { ... }: filtra la coleccion $loginProfiles
            # Where-Object: cmdlet que selecciona objetos que cumplan una condicion
            # $_.Name: propiedad Name del objeto actual en el pipeline (el perfil)
            # "$env:COMPUTERNAME\$($user.Name)": construye el patron de nombre esperado
            #     - $env:COMPUTERNAME: variable de entorno con el nombre del equipo
            #     - \: separador entre nombre de equipo y usuario
            #     - $($user.Name): nombre del usuario actual (expansion de variable)
            # -eq: operador de igualdad (equals)
            # Resultado: objeto perfil que coincide, o $null si no hay coincidencia
            $profile = $loginProfiles | Where-Object { $_.Name -eq "$env:COMPUTERNAME\$($user.Name)" }
            
            # Linea 13-14: Crea un objeto personalizado con propiedades especificas
            # [PSCustomObject]@{ ... }: sintaxis para crear un objeto con propiedades
            # @{ ... }: hashtable que define las propiedades y sus valores
            # Este objeto sera agregado automaticamente a la coleccion $results
            [PSCustomObject]@{
                # Linea 15: Define la propiedad 'Usuario' con el nombre de la cuenta
                # $user.Name: propiedad Name del objeto usuario actual
                Usuario = $user.Name
                
                # Linea 16-22: Define la propiedad 'Ultimo Ingreso' con logica condicional
                # if ($profile -and $profile.LastLogon) { ... } else { ... }:
                #     - $profile: verifica si existe el perfil (no es $null)
                #     - -and: operador logico Y (ambas condiciones deben ser verdaderas)
                #     - $profile.LastLogon: verifica si existe la propiedad LastLogon
                #     - Si ambas son verdaderas: asigna $profile.LastLogon (fecha/hora)
                #     - Si alguna es falsa: asigna el string "Nunca o Desconocido"
                # Get-CimInstance convierte automaticamente la fecha WMI a objeto DateTime
                'Ultimo Ingreso' = if ($profile -and $profile.LastLogon) {
                                    # Linea 17: Asigna la fecha/hora del ultimo ingreso
                                    $profile.LastLogon 
                                } else {
                                    # Linea 18: Asigna texto cuando no hay fecha disponible
                                    "Nunca o Desconocido"
                                }
            }
        }

        # Formatea y muestra la coleccion de resultados como tabla
        # $results | Format-Table: envia la coleccion al cmdlet Format-Table
        # |: operador pipeline (pipe) que pasa la salida de un comando al siguiente
        # Format-Table: cmdlet que formatea objetos como tabla con columnas
        # -AutoSize: ajusta automaticamente el ancho de las columnas segun el contenido
        $results | Format-Table -AutoSize

    } catch {
        # Linea 25: Muestra mensaje de error en la consola
        # Write-Error: cmdlet que escribe en el stream de errores (stderr)
        # $_: variable automatica que contiene el objeto de excepcion actual
        Write-Error "Error al obtener la informacion de usuarios: $_"
    }
}

# Opcion 2: Desplegar discos
function Get-DiscosEspacio {
    Write-Output "Opcion 2: Desplegando discos (filesystems)..."
    Write-Output ""

    # Usamos Get-CimInstance para consultar WMI/CIM
    # La clase Win32_LogicalDisk es especifica para esto
    # El filtro "DriveType=3" significa "Discos Fijos Locales" 
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | `
    
        # Usamos Format-Table 
        Format-Table -Property DeviceID,
                                # Creamos una columna calculada
                                @{n='Tamano Total (Bytes)'; e={$_.Size}},
                                # Creamos otra columna calculada 
                                @{n='Espacio Libre (Bytes)'; e={$_.FreeSpace}} -AutoSize
}

# Opcion 3: Ver 10 archivos mas grandes
function Get-10MasGrandes {
    Write-Output "OpCión 3: Desplegar los 10 archivos más grandes..."
    Write-Output ""

    # 1. Pedir al usuario el disco a escanear
    $path = Read-Host "Ingrese la ruta o disco a escanear (ej: C:\ o C:\Users)"
    
    # Validar que la ruta exista
    if (-not (Test-Path $path)) {
        Write-Warning "La ruta '$path' no existe. Volviendo al menú."
        return
    }

    Write-Output "Buscando en '$path'... Esto puede tardar varios minutos."

    try {        
        # Get-ChildItem - Obtiene todos los archivos de la ruta especificada
        # -Path $path: ruta proporcionada por el usuario (ej: C:\Users)
        # -Recurse: busca recursivamente en todos los subdirectorios (como 'ls -R' en Linux)
        # -File: filtra solo archivos (excluye directorios)
        # -ErrorAction SilentlyContinue: suprime errores (ej: permisos denegados) y continua
        # Salida: coleccion de objetos FileInfo con propiedades Name, Length, FullName, etc.
        Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | `
            
            # Sort-Object - Ordena los archivos por tamaño
            # |: operador pipeline que pasa la coleccion del comando anterior a este
            # -Property Length: ordena segun la propiedad Length (tamaño en bytes)
            # -Descending: orden descendente (del mas grande al mas pequeño)
            # Salida: misma coleccion pero ordenada de mayor a menor tamaño
            Sort-Object -Property Length -Descending | `
            
            # Select-Object - Selecciona los primeros N objetos
            # -First 10: toma solo los primeros 10 objetos de la coleccion ordenada
            # Resultado: los 10 archivos mas grandes
            # Salida: coleccion reducida a 10 objetos FileInfo
            Select-Object -First 10 | `
            
            # Format-Table - Formatea la salida como tabla con columnas personalizadas
            # -Property: define las columnas a mostrar
            # @{n='...'; e={...}}: sintaxis de columna calculada (computed column)
            #     n='nombre': nombre de la columna en el encabezado
            #     e={expresion}: expresion/script que calcula el valor de la columna
            #     $_: variable automatica que representa el objeto actual en el pipeline
            Format-Table -Property @{n='Ruta Completa'; e={$_.FullName}},
                                   @{n='Tamaño (Bytes)'; e={$_.Length}},
                                   @{n='Tamaño (MB)'; e={[math]::Round($_.Length / 1MB, 2)}} -AutoSize
            # Columna 1: 'Ruta Completa' - muestra $_.FullName (ruta completa del archivo)
            # Columna 2: 'Tamaño (Bytes)' - muestra $_.Length (tamaño en bytes)
            # Columna 3: 'Tamaño (MB)' - calcula tamaño en MB:
            #     $_.Length / 1MB: divide bytes entre 1 megabyte (1048576 bytes)
            #     [math]::Round(..., 2): redondea a 2 decimales usando clase .NET Math
            # -AutoSize: ajusta automaticamente el ancho de las columnas
            # Salida final: tabla formateada impresa en consola
            
    } catch {
        # $_: variable automatica que contiene el objeto de excepcion con detalles del error
        Write-Error "Ocurrió un error al buscar archivos: $_"
    }
}

# Opcion 4: Ver memoria libre y swap
function Get-MemoriaSwap {
    Write-Output "Opcion 4: Desplegando Memoria Libre y Swap en Uso..."
    
    Write-Output ""

    # Inicia bloque try para capturar errores durante la consulta WMI
    try {

        # Imprime encabezado de la seccion de memoria RAM
        Write-Output "--- MEMORIA RAM ---"
        
        # Get-CimInstance - Consulta informacion del sistema operativo
        # -ClassName Win32_OperatingSystem: clase WMI que contiene datos del SO
        # Esta clase tiene propiedades importantes:
        #   - FreePhysicalMemory: memoria RAM libre en KB (kilobytes)
        #   - TotalVisibleMemorySize: memoria RAM total visible en KB
        # Salida: un objeto con propiedades del sistema operativo
        Get-CimInstance -ClassName Win32_OperatingSystem | `
            
            # Format-List - Formatea la salida como lista (no tabla)
            # -Property: define las propiedades a mostrar como lista
            # @{n='nombre'; e={expresion}}: sintaxis de propiedad calculada
            #     n='nombre': etiqueta que se muestra
            #     e={script}: expresion que calcula el valor
            Format-List -Property @{n='Memoria Libre (Bytes)'; e={$_.FreePhysicalMemory * 1024}},
                                  @{n='Porcentaje Libre (%)'; e={
                                      # Calculo del porcentaje de memoria libre:
                                      # (memoria libre / memoria total) * 100
                                      # $_.FreePhysicalMemory: KB de RAM libre
                                      # $_.TotalVisibleMemorySize: KB de RAM total
                                      $freePercent = ($_.FreePhysicalMemory / $_.TotalVisibleMemorySize) * 100
                                      # [math]::Round(..., 2): redondea a 2 decimales usando clase .NET Math
                                      [math]::Round($freePercent, 2)
                                  }}
            # Propiedad 1: 'Memoria Libre (Bytes)'
            #   - Toma FreePhysicalMemory (que esta en KB)
            #   - Multiplica por 1024 para convertir KB a Bytes
            # Propiedad 2: 'Porcentaje Libre (%)'
            #   - Calcula el porcentaje de memoria disponible
            #   - Redondea a 2 decimales para mejor legibilidad
        
        # Imprime encabezado de la seccion de swap
        Write-Output "--- SWAP (Page File) ---"
        
        # Get-CimInstance - Consulta informacion del archivo de paginacion
        # -ClassName Win32_PageFileUsage: clase WMI que contiene datos del page file
        # Esta clase tiene propiedades importantes:
        #   - CurrentUsage: espacio del page file actualmente en uso (en MB)
        #   - AllocatedBaseSize: tamaño total asignado al page file (en MB)
        # Salida: objeto(s) con informacion de archivos de paginacion activos
        Get-CimInstance -ClassName Win32_PageFileUsage | `
        
            # Format-List - Formatea como lista
            # Sintaxis similar a la seccion de RAM pero con datos de swap
            Format-List -Property @{n='Swap en Uso (Bytes)'; e={$_.CurrentUsage * 1MB}},
                                  @{n='Porcentaje en Uso (%)'; e={
                                      # Validacion: verifica que el tamaño asignado sea mayor que 0
                                      # para evitar division por cero
                                      # -gt: operador "greater than" (mayor que)
                                      if ($_.AllocatedBaseSize -gt 0) {
                                          # Calculo del porcentaje de swap en uso:
                                          # (uso actual / tamaño total) * 100
                                          # $_.CurrentUsage: MB de swap en uso
                                          # $_.AllocatedBaseSize: MB de swap total asignado
                                          $usedPercent = ($_.CurrentUsage / $_.AllocatedBaseSize) * 100
                                          # Redondea a 2 decimales
                                          [math]::Round($usedPercent, 2)
                                      } else {
                                          # Si no hay swap configurado o tamaño es 0, retorna 0
                                          0
                                      }
                                  }}
            # Propiedad 1: 'Swap en Uso (Bytes)'
            #   - Toma CurrentUsage (que esta en MB)
            #   - Multiplica por 1MB (constante de PowerShell = 1048576) para convertir a Bytes
            # Propiedad 2: 'Porcentaje en Uso (%)'
            #   - Calcula el porcentaje de swap utilizado
            #   - Incluye validacion para evitar division por cero
            #   - Si no hay swap configurado, muestra 0

    } catch {
        # $_: variable automatica con el objeto de excepcion y detalles del error
        Write-Error "Ocurrio un error al obtener la informacion de memoria: $_"
    }
}

# Opcion 5: Hacer copia de seguridad (Backup) a USB
function Start-BackupUSB {
    Write-Output "Opcion 5: Hacer copia de seguridad (Backup) a USB..."
    
    Write-Output ""

    try {
        # PASO 1: SOLICITAR Y VALIDAR DIRECTORIO ORIGEN
        # Read-Host: cmdlet que solicita entrada del usuario y devuelve un string
        # Muestra el mensaje y espera que el usuario escriba la ruta
        # El resultado se almacena en la variable $sourceDir
        $sourceDir = Read-Host "Ingrese la ruta del directorio a respaldar (ej: C:\Datos)"
        
        # Validacion de la ruta ingresada:
        # Test-Path: cmdlet que verifica si existe una ruta en el sistema de archivos
        # -PathType Container: verifica especificamente que sea un directorio (no archivo)
        # -not: operador de negacion logica (invierte true/false)
        # Si la ruta NO existe o NO es un directorio, ejecuta el bloque if
        if (-not (Test-Path $sourceDir -PathType Container)) {
            # Write-Warning: imprime mensaje de advertencia en color amarillo
            Write-Warning "La ruta '$sourceDir' no existe o no es un directorio. Volviendo al menu."
            # return: sale de la funcion inmediatamente (no continua el backup)
            return
        }

        # PASO 2: BUSCAR Y MOSTRAR UNIDADES USB DISPONIBLES
        # Mensaje informativo
        Write-Output "Buscando unidades USB..."
        
        # Get-CimInstance: consulta WMI/CIM
        # -ClassName Win32_LogicalDisk: clase que representa discos logicos
        # -Filter "DriveType=2": filtra solo discos removibles
        #   DriveType valores: 2=Removible, 3=Fijo, 4=Red, 5=CD-ROM
        # Resultado: coleccion de objetos que representan unidades USB conectadas
        $usbDrives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=2"
        
        # Validacion: verifica si se encontraron unidades USB
        # -not $usbDrives: true si la variable es $null o vacia
        if (-not $usbDrives) {
            # Si no hay USB conectados, muestra advertencia y sale de la funcion
            Write-Warning "No se encontro ninguna unidad USB (disco removible). Volviendo al menu."
            return
        }

        # Mensaje informativo antes de mostrar la tabla
        Write-Output "Unidades USB detectadas:"
        
        # Muestra tabla con informacion de las unidades USB encontradas:

        # $usbDrives | Format-Table: formatea la coleccion como tabla
        # DeviceID: letra de la unidad (ej: E:, F:)
        # VolumeName: nombre/etiqueta del USB
        # @{n='Espacio Libre (MB)'; e={...}}: columna calculada
        #   $_.FreeSpace: espacio libre en bytes
        #   / 1MB: convierte bytes a megabytes (1MB = 1048576 bytes)
        #   [math]::Round(..., 2): redondea a 2 decimales
        # -AutoSize: ajusta ancho de columnas automaticamente
        $usbDrives | Format-Table DeviceID, VolumeName, @{n='Espacio Libre (MB)'; e={[math]::Round($_.FreeSpace / 1MB, 2)}} -AutoSize
        
        # PASO 3: SOLICITAR Y VALIDAR UNIDAD USB DESTINO
        # Read-Host: solicita al usuario que ingrese la letra de la unidad
        $destLetter = Read-Host "Ingrese la letra de la unidad USB para el backup (ej: E)"
        
        # Busca la unidad USB correspondiente a la letra ingresada:

        # $usbDrives | Where-Object: filtra la coleccion de USB
        # $_.DeviceID: letra del dispositivo (ej: "E:")
        # -eq: operador de igualdad
        # "$($destLetter.ToUpper()):": construye el formato esperado
        #   $destLetter.ToUpper(): convierte a mayusculas (e -> E)
        #   Agrega ":" al final (E -> E:)
        # Resultado: objeto USB que coincide, o $null si no existe
        $destDrive = $usbDrives | Where-Object { $_.DeviceID -eq "$($destLetter.ToUpper()):" }

        # Validacion: verifica que la letra ingresada corresponda a un USB valido
        if (-not $destDrive) {
            # Si la letra no corresponde a ningun USB detectado, muestra advertencia
            Write-Warning "La unidad '$destLetter' no es un USB valido. Volviendo al menu."
            return
        }

        # PASO 4: CREAR CARPETA DE BACKUP CON TIMESTAMP

        # Get-Date: obtiene la fecha/hora actual
        # -Format "yyyyMMdd_HHmmss": formatea como año-mes-dia_hora-minuto-segundo
        # Ejemplo: 20251106_143025 (6 de nov 2025, 14:30:25)
        # Esto asegura nombres unicos y ordenables cronologicamente
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        
        # Join-Path: combina partes de una ruta de manera segura
        # -Path $destDrive.DeviceID: unidad destino (ej: E:)
        # -ChildPath "Backup_$timestamp": nombre de carpeta (ej: Backup_20251106_143025)
        # Resultado: ruta completa (ej: E:\Backup_20251106_143025)
        $backupPath = Join-Path -Path $destDrive.DeviceID -ChildPath "Backup_$timestamp"
        
        # New-Item: crea un nuevo item en el sistema de archivos
        # -ItemType Directory: especifica que es un directorio (carpeta)
        # -Path $backupPath: ruta completa donde crear la carpeta
        # | Out-Null: descarta la salida (evita mostrar info de la carpeta creada)
        New-Item -ItemType Directory -Path $backupPath | Out-Null

        # Mensaje informativo con la ruta donde se guardara el backup
        Write-Output "Iniciando copia en '$backupPath'..."
        
´        # PASO 5: COPIAR ARCHIVOS RECURSIVAMENTE

        # Copy-Item: cmdlet para copiar archivos y directorios
        # -Path $sourceDir: origen (directorio a respaldar)
        # -Destination $backupPath: destino (carpeta creada en USB)
        # -Recurse: copia recursivamente todo el contenido incluyendo subdirectorios
        # -Force: sobrescribe archivos existentes sin preguntar
        # Este comando puede tardar dependiendo del tamaño del directorio
        Copy-Item -Path $sourceDir -Destination $backupPath -Recurse -Force
        
        # Mensaje confirmando que la copia termino
        Write-Output "Copia de archivos finalizada."

        # PASO 6: CREAR CATALOGO CSV (INVENTARIO DE ARCHIVOS)
        Write-Output "Creando catalogo de archivos..."
        
        # Join-Path: construye la ruta del archivo catalogo
        # -ChildPath "catalogo_backup.csv": nombre del archivo CSV
        # Resultado: ruta completa (ej: E:\Backup_20251106_143025\catalogo_backup.csv)
        $catalogPath = Join-Path -Path $backupPath -ChildPath "catalogo_backup.csv"

        
        #  Get-ChildItem - Obtiene todos los archivos del directorio ORIGEN
        # -Path $sourceDir: directorio origen (no el backup, sino el original)
        # -Recurse: busca recursivamente en todos los subdirectorios
        # -File: solo archivos (excluye carpetas)
        # Salida: coleccion de objetos FileInfo
        Get-ChildItem -Path $sourceDir -Recurse -File | `
            
            # Select-Object - Selecciona/crea propiedades especificas
            # -Property: define las columnas del catalogo CSV
            # Cada @{n='nombre'; e={expresion}} crea una columna calculada
            Select-Object -Property @{n='NombreArchivo'; e={$_.Name}},
                                    @{n='RutaRelativa'; e={$_.FullName.Substring($sourceDir.Length)}},
                                    @{n='FechaUltimaModificacion'; e={$_.LastWriteTime}},
                                    @{n='Tamaño (Bytes)'; e={$_.Length}} | `
            # Columna 1: 'NombreArchivo' - $_.Name (nombre del archivo con extension)
            # Columna 2: 'RutaRelativa' - quita el prefijo del directorio origen
            #   $_.FullName: ruta completa (ej: C:\Datos\carpeta\archivo.txt)
            #   .Substring($sourceDir.Length): quita los primeros N caracteres
            #   Resultado: ruta relativa (\carpeta\archivo.txt)
            # Columna 3: 'FechaUltimaModificacion' - $_.LastWriteTime (DateTime)
            # Columna 4: 'Tamaño (Bytes)' - $_.Length (tamaño en bytes)
            
            # Export-Csv - Exporta los objetos a archivo CSV
            # -Path $catalogPath: ruta donde guardar el CSV
            # -NoTypeInformation: omite la linea de tipo de objeto (mas limpio)
            # -Encoding UTF8: codificacion Unicode (soporta caracteres especiales)
            # Resultado: archivo CSV con inventario completo de archivos respaldados
            Export-Csv -Path $catalogPath -NoTypeInformation -Encoding UTF8
        
        # PASO 7: MENSAJES FINALES DE EXITO
        Write-Output ""
        
        # Mensaje de exito con color verde
        # -ForegroundColor Green: cambia el color del texto a verde
        Write-Output "Backup completado exitosamente!" -ForegroundColor Green
        
        # Muestra la ruta donde se guardo el backup
        Write-Output "Directorio: $backupPath"
        
        # Muestra la ruta del archivo catalogo
        Write-Output "Catalogo: $catalogPath"

    # Bloque catch: captura cualquier error durante el proceso completo
    } catch {
        # Write-Error: muestra mensaje de error en rojo
        # $_: variable automatica con detalles de la excepcion
        Write-Error "Ocurrio un error durante el backup: $_"
    }
# Cierra la definicion de la funcion
}

# --- Funcion para Mostrar el Menu ---
function Show-Menu {
    # Usamos 'Write-Output' para imprimir en la consola
    Write-Output ""
    Write-Output "================================================="
    Write-Output "   Herramienta de Administracion de Data Center (PowerShell)"
    Write-Output "================================================="
    Write-Output "1. Desplegar usuarios y ultimo login "
    Write-Output "2. Desplegar discos (filesystems) [cite: 506]"
    Write-Output "3. Ver 10 archivos mas grandes [cite: 508]"
    Write-Output "4. Ver memoria libre y swap [cite: 510]"
    Write-Output "5. Hacer copia de seguridad (Backup) a USB [cite: 511]"
    Write-Output "S. Salir"
    Write-Output "================================================="
}

# --- Cuerpo Principal del Script ---
while ($true) { # Bucle de repeticion
    Show-Menu
    # Usamos 'Read-Host' para pedir informacion al usuario
    $opcion = Read-Host "Seleccione una opcion"

    switch ($opcion.ToUpper()) {
        '1' {
            Get-UsuariosLogin
        }
        '2' {
            Get-DiscosEspacio
        }
        '3' {
            Get-10MasGrandes
        }
        '4' {
            Get-MemoriaSwap
        }
        '5' {
            Start-BackupUSB
        }
        'S' {
            Write-Output "Saliendo del script. Hasta pronto!"
            return # Sale completamente del script
        }
        default {
            Write-Warning "Opcion '$opcion' invalida. Por favor, intente de nuevo."
        }
    }

    Write-Output ""
    Read-Host "Presione Enter para continuar..." # Pausa
}