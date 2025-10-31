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
    Write-Output "Opcion 3: (En desarrollo) Ver 10 archivos mas grandes..."
    # Aqui iran 'Get-ChildItem', 'Sort-Object' y 'Select-Object'
}

# Opcion 4: Ver memoria libre y swap
function Get-MemoriaSwap {
    Write-Output "Opcion 4: (En desarrollo) Ver memoria libre y swap..."
    # Aqui ira 'Get-WmiObject Win32_OperatingSystem' o 'Get-CimInstance'
}

# Opcion 5: Hacer copia de seguridad
function Start-BackupUSB {
    Write-Output "Opcion 5: (En desarrollo) Hacer copia de seguridad a USB..."
    # Aqui iran 'Copy-Item', 'Get-ChildItem' y 'Export-Csv'
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