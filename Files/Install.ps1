# Obtener la ubicaci�n del script actual
$ScriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition

# Definir las posibles rutas para DeploymentScriptTool
$DeploymentScriptToolExe = Join-Path -Path $ScriptPath -ChildPath "DeploymentScriptTool.exe"
$DeploymentScriptToolPy = Join-Path -Path $ScriptPath -ChildPath "DeploymentScriptTool.py"

# Verificar si al menos uno de los archivos DeploymentScriptTool existe
if (Test-Path -Path $DeploymentScriptToolExe) {
    $DeploymentScriptTool = $DeploymentScriptToolExe
    $Command = $DeploymentScriptTool  # Especificamos el ejecutable
} elseif (Test-Path -Path $DeploymentScriptToolPy) {
    $DeploymentScriptTool = $DeploymentScriptToolPy
    $Command = "python"  # El comando de python es "python"
    $ArgumentList = $DeploymentScriptTool  # Pasamos la ruta del script Python como argumento
} else {
    Write-Error "No se encontr� DeploymentScriptTool.exe ni DeploymentScriptTool.py en el directorio $ScriptPath"
    exit 1
}

# Preguntar si desea detectar versiones de Office instaladas
$DetectOffice = Read-Host "�Desea detectar las versiones de Office instaladas? (S/N)"
if ($DetectOffice -eq "S" -or $DetectOffice -eq "s") {
    # Descargar Get-OfficeVersion.ps1 directamente desde GitHub
    Write-Host "Descargando Get-OfficeVersion.ps1 desde GitHub..."

    # URL para obtener la informaci�n del archivo
    $url = "https://api.github.com/repos/OfficeDev/Office-IT-Pro-Deployment-Scripts/contents/Office-ProPlus-Management/Get-OfficeVersion/Get-OfficeVersion.ps1"

    # Realizar la solicitud a la API
    $response = Invoke-RestMethod -Uri $url -Method Get

    # Obtener la URL de descarga
    $fileUrl = $response.download_url

    # Definir la carpeta de destino
    $localFolder = "Uninstall"

    # Crear la carpeta local "Uninstall" si no existe
    New-Item -Path $localFolder -ItemType Directory -Force > $null

    # Definir la ruta completa donde se guardar� el archivo
    $filePath = Join-Path -Path $localFolder -ChildPath "Get-OfficeVersion.ps1"

    # Descargar el archivo
    Invoke-WebRequest -Uri $fileUrl -OutFile $filePath

    Write-Host "Archivo descargado en $ScriptPath\$filePath"

    # Ejecutar Get-OfficeVersion.ps1
    Write-Host "Ejecutando Get-OfficeVersion.ps1 para obtener las versiones de Office instaladas..."
    Write-Host ""
    . $filePath
    $OfficeVersions = Get-OfficeVersion

    # Validar si se obtuvo informaci�n
    if ($OfficeVersions) {
        Write-Host "Se encontraron las siguientes versiones de Office instaladas:"
        Write-Host "------------------------------------------------------------"

        # Imprimir de manera m�s legible
        foreach ($version in $OfficeVersions) {
            Write-Host "Nombre: $($version.DisplayName)"
            Write-Host "Versi�n: $($version.Version)"
            Write-Host "Ruta de instalaci�n: $($version.InstallPath)"
            Write-Host "Arquitectura: $($version.Bitness)"
            Write-Host "Idioma: $($version.ClientCulture)"
            Write-Host "Click-to-Run: $($version.ClickToRun)"
            Write-Host "Actualizaciones habilitadas: $($version.ClickToRunUpdatesEnabled)"
            Write-Host "------------------------------------------------------------"
        }

        # Preguntar al usuario si desea desinstalar la versi�n encontrada
        $UninstallOffice = Read-Host "�Desea desinstalar todas las versiones de Office encontradas? (S/N)"
        if ($UninstallOffice -eq "S" -or $UninstallOffice -eq "s") {
            # Descargar archivos de desinstalaci�n desde GitHub
            Write-Host "Descargando los archivos de desinstalaci�n desde GitHub..."

            # URL de la API para obtener el contenido de la carpeta
            $url = "https://api.github.com/repos/OfficeDev/Office-IT-Pro-Deployment-Scripts/contents/Office-ProPlus-Deployment/Remove-PreviousOfficeInstalls"

            # Realizar la solicitud a la API
            $response = Invoke-RestMethod -Uri $url -Method Get

            # Verificar si la solicitud fue exitosa
            if ($response) {
                # Cambiar el nombre de la carpeta local a "Uninstall"
                $localFolder = "Uninstall"
                New-Item -Path $localFolder -ItemType Directory -Force > $null

                # Descargar cada archivo en la carpeta
                foreach ($file in $response) {
                    if ($file.type -eq 'file') {  # Solo descargar archivos (no carpetas)
                        $fileName = $file.name

                        # Excluir archivos README o archivos con extensi�n .md
                        if ($fileName -notmatch "README" -and $fileName -notlike "*.md") {
                            $fileUrl = $file.download_url
                            $filePath = Join-Path -Path $localFolder -ChildPath $fileName

                            # Descargar el archivo
                            Invoke-WebRequest -Uri $fileUrl -OutFile $filePath
                            Write-Host "Archivo $fileName descargado en $ScriptPath\$filePath"
                        } else {
                            Write-Host "Archivo ignorado: $fileName"
                        }
                    }
                }
            } else {
                Write-Host "Error al obtener el contenido de la carpeta."
            }

            # Ejecutar Remove-PreviousOfficeInstalls.ps1
            Write-Host "Ejecutando Remove-PreviousOfficeInstalls.ps1 para desinstalar las versiones previas de Office..."
            $RemovePreviousOfficeInstallsScript = Join-Path -Path $localFolder -ChildPath "Remove-PreviousOfficeInstalls.ps1"
            . $RemovePreviousOfficeInstallsScript
            Remove-PreviousOfficeInstalls
            Write-Host "Proceso de desinstalaci�n completado."

            # Preguntar si desea proceder con la instalaci�n de Office
            $ProceedInstall = Read-Host "�Desea proceder con la instalaci�n de Office ahora? (S/N)"
            if ($ProceedInstall -eq "S" -or $ProceedInstall -eq "s") {
                # Ejecutar DeploymentScriptTool para instalar Office
                Write-Host "Ejecutando $DeploymentScriptTool..."
                if ($Command -eq "python") {
                    Start-Process $Command -ArgumentList $ArgumentList
                } else {
                    & $Command
                }
                Write-Host "Instalaci�n de Office completada."
            } else {
                Write-Host "El proceso de instalaci�n ha sido cancelado. No se proceder� con la instalaci�n de Office."
                exit 0  # Finalizar el script
            }

        } else {
            Write-Host "La versi�n de Office no ser� desinstalada."

            # Informar al usuario sobre los problemas posibles
            Write-Host "Advertencia: Tener m�s de una versi�n de Office instalada puede ocasionar problemas."

            # Preguntar si desea continuar con la instalaci�n
            $ContinueInstall = Read-Host "�Desea continuar e instalar una nueva versi�n de Office? (S/N)"
            if ($ContinueInstall -eq "S" -or $ContinueInstall -eq "s") {
                Write-Host "Ejecutando DeploymentScriptTool..."
                if ($Command -eq "python") {
                    Start-Process $Command -ArgumentList $ArgumentList
                } else {
                    & $Command
                }
                Write-Host "Instalaci�n de Office completada."
            } else {
                Write-Host "El proceso ha sido cancelado. No se proceder� con la instalaci�n."
            }
        }

    } else {
        Write-Host "No se encontraron versiones de Office instaladas."
        
        # Preguntar si desea continuar con la instalaci�n
        $ContinueInstall = Read-Host "�Desea continuar e instalar una nueva versi�n de Office? (S/N)"
        if ($ContinueInstall -eq "S" -or $ContinueInstall -eq "s") {
            Write-Host "Ejecutando DeploymentScriptTool para instalar Office..."
            if ($Command -eq "python") {
                Start-Process $Command -ArgumentList $ArgumentList
            } else {
                & $Command
            }
            Write-Host "Instalaci�n de Office completada."
        } else {
            Write-Host "El proceso ha sido cancelado. No se proceder� con la instalaci�n."
        }
    }
} else {
    # No se detectan versiones de Office, proceder con la instalaci�n
    Write-Host "Advertencia: Tener m�s de una versi�n de Office instalada puede ocasionar problemas."
    $ContinueInstall = Read-Host "�Desea continuar e instalar una nueva versi�n de Office? (S/N)"
    if ($ContinueInstall -eq "S" -or $ContinueInstall -eq "s") {
        Write-Host "Ejecutando DeploymentScriptTool..."
        if ($Command -eq "python") {
            Start-Process $Command -ArgumentList $ArgumentList
        } else {
            & $Command
        }
        Write-Host "Instalaci�n de Office completada."
    } else {
        Write-Host "El proceso ha sido cancelado. No se proceder� con la instalaci�n."
    }
}