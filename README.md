# ProyectoFinal-Powershell-Bash

Este repositorio contiene dos herramientas para facilitar las labores de un administrador de un data center:

- `admin_tool.ps1` : Implementación en PowerShell.
- `admin_tool.sh`  : Implementación en BASH.

Requisitos y notas:

- Ejecutar en un sistema tipo Linux (o WSL) con Bash.
- Algunas funciones usan `rsync`, `find`, `stat`, `free`. Asegúrate de que estén instaladas.
- Para realizar backups en una memoria USB, la unidad debe estar montada y el usuario debe tener permisos de escritura en el punto de montaje.

Cómo ejecutar la herramienta BASH:

1. Dar permiso de ejecución (si aún no lo tiene):

```powershell
# En PowerShell o en bash
chmod +x admin_tool.sh
```

2. Ejecutar el script:

```powershell
./admin_tool.sh
```

Opciones del menú (resumido):

1. Desplegar los usuarios creados en el sistema y la fecha/hora de su último ingreso.
2. Desplegar los filesystems/discos conectados, tamaño total y espacio libre (en bytes).
3. Mostrar los 10 archivos más grandes en la ruta indicada por el usuario (muestra ruta completa y tamaño en bytes).
4. Mostrar cantidad de memoria libre y espacio de swap en uso (bytes y porcentaje).
5. Hacer copia de seguridad de un directorio a una memoria USB. Además crea un catálogo (`catalogo.txt`) con los nombres de los archivos y su fecha de última modificación.

Notas de entrega:

- Documentar el equipo y el repositorio en GitHub antes de la fecha de presentación (13-NOV-2025).
- El profesor actuará como usuario en horas de oficina y podrá solicitar demostraciones.


