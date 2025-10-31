# Proyecto Final de Sistemas Operacionales - Herramienta PowerShell
#

# --- Definición de Funciones (vacías por ahora) ---

# Opción 1: Desplegar usuarios y último login
function Get-UsuariosLogin {
    Write-Output "OpCión 1: Desplegando usuarios y último login..."
    Write-Output ""

    try {
        # 1. Obtenemos los perfiles de login, que SÍ tienen la fecha
        # Esta clase es más fiable para la fecha que Win32_UserAccount
        $loginProfiles = Get-CimInstance -ClassName Win32_NetworkLoginProfile

        # 2. Obtenemos los usuarios locales para filtrar
        $localUsers = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = $True"
        
        Write-Output "Usuarios locales y su último ingreso conocido:"
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
                'Último Ingreso' = if ($profile -and $profile.LastLogon) {
                                    # Get-CimInstance ya convierte la fecha por nosotros
                                    $profile.LastLogon 
                                } else {
                                    "Nunca o Desconocido"
                                }
            }
        }

        $results | Format-Table -AutoSize # Pipe final para formatear la tabla

    } catch {
        Write-Error "Error al obtener la información de usuarios: $_"
    }
}

# Opción 2: Desplegar discos
function Get-DiscosEspacio {
    Write-Output "OpCión 2: Desplegando discos (filesystems)..."
    Write-Output ""

    # Usamos Get-CimInstance (clase5.md) para consultar WMI/CIM
    # La clase Win32_LogicalDisk (clase7.md) es específica para esto
    # El filtro "DriveType=3" significa "Discos Fijos Locales" (clase7.md)
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | `
    
        # Usamos Format-Table (clase4.md)
        Format-Table -Property DeviceID,
                                # Creamos una columna calculada (clase4.md)
                                @{n='Tamaño Total (Bytes)'; e={$_.Size}},
                                # Creamos otra columna calculada (clase4.md)
                                @{n='Espacio Libre (Bytes)'; e={$_.FreeSpace}} -AutoSize
}

# Opción 3: Ver 10 archivos más grandes
function Get-10MasGrandes {
    Write-Output "Opción 3: (En desarrollo) Ver 10 archivos más grandes..."
    # Aquí irán 'Get-ChildItem', 'Sort-Object' y 'Select-Object'
}

# Opción 4: Ver memoria libre y swap
function Get-MemoriaSwap {
    Write-Output "Opción 4: (En desarrollo) Ver memoria libre y swap..."
    # Aquí irá 'Get-WmiObject Win32_OperatingSystem' o 'Get-CimInstance'
}

# Opción 5: Hacer copia de seguridad
function Start-BackupUSB {
    Write-Output "Opción 5: (En desarrollo) Hacer copia de seguridad a USB..."
    # Aquí irán 'Copy-Item', 'Get-ChildItem' y 'Export-Csv'
}

# --- Función para Mostrar el Menú ---
function Show-Menu {
    # Usamos 'Write-Output' para imprimir en la consola
    Write-Output ""
    Write-Output "================================================="
    Write-Output "   Herramienta de Administración de Data Center (PowerShell)"
    Write-Output "================================================="
    Write-Output "1. Desplegar usuarios y último login "
    Write-Output "2. Desplegar discos (filesystems) [cite: 506]"
    Write-Output "3. Ver 10 archivos más grandes [cite: 508]"
    Write-Output "4. Ver memoria libre y swap [cite: 510]"
    Write-Output "5. Hacer copia de seguridad (Backup) a USB [cite: 511]"
    Write-Output "S. Salir"
    Write-Output "================================================="
}

# --- Cuerpo Principal del Script ---
while ($true) { # Bucle de repetición
    Show-Menu
    # Usamos 'Read-Host' para pedir información al usuario
    $opcion = Read-Host "Seleccione una opción"

    switch ($opcion) {
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
            Write-Output "Saliendo del script. ¡Hasta pronto!"
            break # Rompe el bucle 'while'
        }
        default {
            Write-Warning "Opción '$opcion' inválida. Por favor, intente de nuevo." #
        }
    }

    Write-Output ""
    Read-Host "Presione Enter para continuar..." # Pausa
}