# Proyecto Final de Sistemas Operacionales - Herramienta PowerShell
#

# --- Definicion de Funciones (vacias por ahora) ---

# Opcion 1: Desplegar usuarios y ultimo login
function Get-UsuariosLogin {
    Write-Output "Opcion 1: Desplegando usuarios y ultimo login..."
    Write-Output ""

    try {
        # 1. Obtenemos los perfiles de login, que SI tienen la fecha
        # Esta clase es mas fiable para la fecha que Win32_UserAccount
        $loginProfiles = Get-CimInstance -ClassName Win32_NetworkLoginProfile

        # 2. Obtenemos los usuarios locales para filtrar
        $localUsers = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = $True"
        
        Write-Output "Usuarios locales y su ultimo ingreso conocido:"
        Write-Output "-----------------------------------------------"

        # 3. Cruzamos la información
        $results = foreach ($user in $localUsers) {
            
            # Buscamos el perfil del usuario local
            # El formato del nombre es "COMPUTADORA\Usuario"
            $profile = $loginProfiles | Where-Object { $_.Name -eq "$env:COMPUTERNAME\$($user.Name)" }
            
            # Creamos un objeto con los datos
            # Esto nos permite usar Format-Table al final
            [PSCustomObject]@{
                Usuario = $user.Name
                'Ultimo Ingreso' = if ($profile -and $profile.LastLogon) {
                                    # Get-CimInstance ya convierte la fecha por nosotros
                                    $profile.LastLogon 
                                } else {
                                    "Nunca o Desconocido"
                                }
            }
        }

        $results | Format-Table -AutoSize # Pipe final para formatear la tabla

    } catch {
        Write-Error "Error al obtener la informacion de usuarios: $_"
    }
}

# Opcion 2: Desplegar discos
function Get-DiscosEspacio {
    Write-Output "Opcion 2: Desplegando discos (filesystems)..."
    Write-Output ""

    # Usamos Get-CimInstance (clase5.md) para consultar WMI/CIM
    # La clase Win32_LogicalDisk (clase7.md) es especifica para esto
    # El filtro "DriveType=3" significa "Discos Fijos Locales" (clase7.md)
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | `
    
        # Usamos Format-Table (clase4.md)
        Format-Table -Property DeviceID,
                                # Creamos una columna calculada (clase4.md)
                                @{n='Tamano Total (Bytes)'; e={$_.Size}},
                                # Creamos otra columna calculada (clase4.md)
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
        # 2. La cadena de comandos (pipeline)
        Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | `
            Sort-Object -Property Length -Descending | `
            Select-Object -First 10 | `
            Format-Table -Property @{n='Ruta Completa'; e={$_.FullName}},
                                   @{n='Tamaño (Bytes)'; e={$_.Length}},
                                   @{n='Tamaño (MB)'; e={[math]::Round($_.Length / 1MB, 2)}} -AutoSize
    } catch {
        Write-Error "Ocurrió un error al buscar archivos: $_"
    }
}

# Opción 4: Ver memoria libre y swap (CORREGIDO)
function Get-MemoriaSwap {
    Write-Output "OpCión 4: Desplegando Memoria Libre y Swap en Uso..."
    Write-Output ""

    try {
        # --- 1. MEMORIA RAM ---
        Write-Output "--- MEMORIA RAM ---"
        
        Get-CimInstance -ClassName Win32_OperatingSystem | `
            
            # Arreglo: Las propiedades empiezan en la misma línea que -Property
            Format-List -Property @{n='Memoria Libre (Bytes)'; e={$_.FreePhysicalMemory * 1024}},
                                  @{n='Porcentaje Libre (%)'; e={
                                      $freePercent = ($_.FreePhysicalMemory / $_.TotalVisibleMemorySize) * 100
                                      [math]::Round($freePercent, 2)
                                  }}
        
        # --- 2. SWAP (Page File) ---
        Write-Output "--- SWAP (Page File) ---"
        
        Get-CimInstance -ClassName Win32_PageFileUsage | `
        
            # Arreglo: Las propiedades empiezan en la misma línea que -Property
            Format-List -Property @{n='Swap en Uso (Bytes)'; e={$_.CurrentUsage * 1MB}},
                                  @{n='Porcentaje en Uso (%)'; e={
                                      if ($_.AllocatedBaseSize -gt 0) {
                                          $usedPercent = ($_.CurrentUsage / $_.AllocatedBaseSize) * 100
                                          [math]::Round($usedPercent, 2)
                                      } else {
                                          0
                                      }
                                  }}

    } catch {
        # El error "$_" ahora debería mostrar un error diferente si algo más falla
        Write-Error "Ocurrió un error al obtener la información de memoria: $_"
    }
}

# Opción 5: Hacer copia de seguridad (Backup) a USB
function Start-BackupUSB {
    Write-Output "OpCión 5: Hacer copia de seguridad (Backup) a USB..."
    Write-Output ""

    try {
        # 1. Pedir el directorio fuente
        $sourceDir = Read-Host "Ingrese la ruta del directorio a respaldar (ej: C:\Datos)"
        if (-not (Test-Path $sourceDir -PathType Container)) {
            Write-Warning "La ruta '$sourceDir' no existe o no es un directorio. Volviendo al menú."
            return
        }

        # 2. Buscar y mostrar unidades USB
        Write-Output "Buscando unidades USB..."
        # Usamos WMI/CIM (clase5.md) para encontrar discos removibles (DriveType=2)
        $usbDrives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=2"
        
        if (-not $usbDrives) {
            Write-Warning "No se encontró ninguna unidad USB (disco removible). Volviendo al menú."
            return
        }

        Write-Output "Unidades USB detectadas:"
        $usbDrives | Format-Table DeviceID, VolumeName, @{n='Espacio Libre (MB)'; e={[math]::Round($_.FreeSpace / 1MB, 2)}} -AutoSize
        
        # 3. Pedir el destino
        $destLetter = Read-Host "Ingrese la letra de la unidad USB para el backup (ej: E)"
        $destDrive = $usbDrives | Where-Object { $_.DeviceID -eq "$($destLetter.ToUpper()):" }

        if (-not $destDrive) {
            Write-Warning "La unidad '$destLetter' no es un USB válido. Volviendo al menú."
            return
        }

        # 4. Crear carpeta de backup
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = Join-Path -Path $destDrive.DeviceID -ChildPath "Backup_$timestamp"
        New-Item -ItemType Directory -Path $backupPath | Out-Null

        Write-Output "Iniciando copia en '$backupPath'..."
        
        # 5. Copiar archivos
        # -Recurse: copia todo. -Force: sobrescribe si es necesario.
        Copy-Item -Path $sourceDir -Destination $backupPath -Recurse -Force
        
        Write-Output "Copia de archivos finalizada."

        # 6. Crear catálogo (Requisito del proyecto)
        Write-Output "Creando catálogo de archivos..."
        $catalogPath = Join-Path -Path $backupPath -ChildPath "catalogo_backup.csv"

        # Obtenemos todos los archivos del ORIGEN
        Get-ChildItem -Path $sourceDir -Recurse -File | `
            
            # Usamos Select-Object para crear las columnas del catálogo
            Select-Object -Property @{n='NombreArchivo'; e={$_.Name}},
                                    @{n='RutaRelativa'; e={$_.FullName.Substring($sourceDir.Length)}},
                                    @{n='FechaUltimaModificacion'; e={$_.LastWriteTime}},
                                    @{n='Tamaño (Bytes)'; e={$_.Length}} | `
            
            # Exportamos a CSV
            Export-Csv -Path $catalogPath -NoTypeInformation -Encoding UTF8
        
        Write-Output ""
        Write-Output "¡Backup completado exitosamente!" -ForegroundColor Green
        Write-Output "Directorio: $backupPath"
        Write-Output "Catálogo: $catalogPath"

    } catch {
        Write-Error "Ocurrió un error durante el backup: $_"
    }
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