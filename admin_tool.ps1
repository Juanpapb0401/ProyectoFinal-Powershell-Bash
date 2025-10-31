# Proyecto Final de Sistemas Operacionales - Herramienta PowerShell
#

# --- Definición de Funciones (vacías por ahora) ---

# Opción 1: Desplegar usuarios y último login
function Get-UsuariosLogin {
    Write-Output "Opción 1: (En desarrollo) Desplegar usuarios y último login..."
    # Aquí irán los cmdlets 'Get-LocalUser' o WMI
}

# Opción 2: Desplegar discos
function Get-DiscosEspacio {
    Write-Output "Opción 2: (En desarrollo) Desplegar discos (filesystems)..."
    # Aquí irá el cmdlet 'Get-WmiObject Win32_LogicalDisk' o 'Get-PSDrive'
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