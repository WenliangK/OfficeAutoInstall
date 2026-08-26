[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Mensaje de advertencia inicial estilo sysadmin
Clear-Host
Write-Host "==================================================================" -ForegroundColor Red
Write-Host "  [!] ADVERTENCIA: No te asustes, esto es parte del proceso..." -ForegroundColor Yellow
Write-Host "  [!] ¡TIENES QUE LEER EL README ANTES DE EJECUTAR ESTO!" -ForegroundColor Red
Write-Host "==================================================================" -ForegroundColor Red
Start-Sleep -Seconds 3

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`nSolicitando permisos de administrador..." -ForegroundColor Yellow
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Write-LoreText {
    param([string]$Text, [int]$Delay = 25, [ConsoleColor]$Color = "Yellow")
    foreach ($char in $Text.ToCharArray()) {
        Write-Host $char -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host ""
}

# ========================================================================
#                    AUTO-CARGADOR DE MÓDULOS (IA Y ARCADE)
# ========================================================================

$JuegosDisponibles = $false

# Prevenir error de ruta vacía si el script se ejecuta desde RAM (vía internet)
$RutaBase = if ([string]::IsNullOrEmpty($PSScriptRoot)) { (Get-Location).Path } else { $PSScriptRoot }

# 1. Cargar la IA Masi
$ModuloIA = Join-Path -Path $RutaBase -ChildPath "MASII\MasiAI.ps1"
if (Test-Path $ModuloIA) { . $ModuloIA }

# 2. Cargar dinámicamente cualquier juego de la subcarpeta ArcadeGames
$CarpetaArcade = Join-Path -Path $RutaBase -ChildPath "ArcadeGames"
if (Test-Path $CarpetaArcade) {
    Get-ChildItem -Path $CarpetaArcade -Filter "*.ps1" | ForEach-Object { . $_.FullName }
    if (Get-Command Show-ArcadeMenu -ErrorAction SilentlyContinue) {
        $JuegosDisponibles = $true
    }
}

# ========================================================================
#                    FLUJO PRINCIPAL DE INSTALACIÓN
# ========================================================================

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Iniciando Instalador de Office" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$tempDir = "C:\TempOfficeInstall"
if (!(Test-Path -Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }

$urlSetup = "https://raw.githubusercontent.com/WenliangK/OfficeAutoInstall/refs/heads/main/WindowsConfig/setup.exe"
$localSetup = "$tempDir\setup.exe"

Write-LoreText "Conectando con los servidores para descargar el motor de instalacion..." 25 "White"
Invoke-WebRequest -Uri $urlSetup -OutFile $localSetup
Write-LoreText "Motor descargado con exito. El corazon de la suite ya esta en casa." 25 "Green"

$installedOffice = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -match "Microsoft Office" -and $_.DisplayName -notmatch "Update" -and $_.DisplayName -notmatch "Click-to-Run" }

if ($installedOffice) {
    Write-Host "`n[!] ATENCION: Se detectaron las siguientes instalaciones previas:" -ForegroundColor Yellow
    $installedOffice | ForEach-Object { Write-Host "  - $($_.DisplayName)" -ForegroundColor Red }
    
    $respuesta = Read-Host "`n¿Deseas desinstalar esto completamente antes de continuar (Tienes que hacerlo para poder continuar)? (S/N)"
    if ($respuesta -match "^[sS]") {
        Write-Host ""
        Write-LoreText "Detectando basura en el sistema... Esto pasa por dejar restos de instalaciones antiguas de Office por todos lados." 30 "Yellow"
        Write-LoreText "La razon por la que construi esto? Fue para automatizar este dolor de cabeza y no tener que perder horas haciendo clic en 'Siguiente' cada vez que formateas una PC." 30 "Cyan"
        Write-LoreText "Iniciando purga profunda del sistema... Tomate un respiro, esto tomara unos minutos." 30 "Yellow"

        $uninstallXml = "$tempDir\uninstall.xml"
        "<Configuration><Display Level=`"None`" AcceptEULA=`"TRUE`" /><Remove All=`"TRUE`" /></Configuration>" | Out-File -FilePath $uninstallXml -Encoding utf8
        Start-Process -FilePath $localSetup -ArgumentList "/configure `"$uninstallXml`"" -Wait -NoNewWindow
        
        Write-Host ""
        Write-LoreText "Purga completada. El sistema esta totalmente despejado." 30 "Green"
    } else { Write-Host "Omitiendo desinstalacion..." -ForegroundColor Cyan }
} else {
    Write-Host ""
    Write-LoreText "Escaneo completado: No hay rastros de versiones anteriores de Office." 30 "Green"
    Write-LoreText "Excelente, hiciste un trabajo impecable manteniendo todo limpio. Zona despejada." 30 "Cyan"
    Write-LoreText "Bueno, aqui vamos con todo. Preparando el arsenal para el despliegue..." 40 "Yellow"
}

$urlConfig = "https://raw.githubusercontent.com/WenliangK/OfficeAutoInstall/refs/heads/main/WindowsConfig/configuration.xml"
$localConfig = "$tempDir\configuration.xml"

Write-LoreText "Descargando configuracion de instalacion..." 25 "White"
Invoke-WebRequest -Uri $urlConfig -OutFile $localConfig

Write-Host @"
  ___  _____ _____ ___ ____ _____ 
 / _ \|  ___|  ___|_ _/ ___| ____|
| | | | |_  | |_   | | |   |  _|  
| |_| |  _| |  _|  | | |___| |___ 
 \___/|_|   |_|   |___\____|_____|
                                 (\_/)
                         .-""-.-.-' a\
                         /  \      _.--'
                        (\  /_---\_\_
                         `'-.
                          ,__)

        MythEnv - Sh1romsi
"@ -ForegroundColor White

Write-Host "Iniciando el proceso pesado. Toma asiento y trae un café...`n" -ForegroundColor Yellow

$proceso = Start-Process -FilePath $localSetup -ArgumentList "/configure `"$localConfig`"" -PassThru -NoNewWindow
$urlApi = "https://cold-rain-150a.wenliangk.workers.dev"

Write-Host "`n[Instalador]: Hola, Soy Masi tu asistente IA e instalador, por el momento solo robare tus credenciales y te instalare un malware... jajaj es broma, solo instalare tu office, como va tu dia?" -ForegroundColor Cyan
Write-Host "*(Elige tu camino: escribe 'masi' para charlar conmigo o 'juegos' para abrir la feria de minijuegos)*" -ForegroundColor DarkGray

while (-not $proceso.HasExited) {
    $mensajeUsuario = Read-Host "`n[Tu]"
    if ($proceso.HasExited) { break }
    
    # Interceptador del menú de juegos
    if ($mensajeUsuario -match "^(juegos|arcade|snake)$") {
        if ($JuegosDisponibles) {
            Show-ArcadeMenu
            Write-Host "`n[Instalador]: ¡De vuelta al chat! (La instalación sigue en segundo plano, pulsa Enter para actualizar estado o sigue hablando)." -ForegroundColor Cyan
        } else {
            Write-Host "`n[Instalador]: Ups, parece que descargaste la versión 'Lite' sin el módulo de juegos. ¡Pero Masi sigue aquí para charlar!" -ForegroundColor Yellow
        }
        continue
    }

    # Interceptador de la IA
    if (Get-Command Invoke-MasiChat -ErrorAction SilentlyContinue) {
        Invoke-MasiChat -Mensaje $mensajeUsuario -UrlApi $urlApi
    } else {
        Write-Host "`n[Instalador (Offline)]: Módulo IA no detectado. Instalando en silencio..." -ForegroundColor DarkGray
    }
    
    Start-Sleep -Seconds 1
}

# ========================================================================
#                    TRANSICIÓN A LA ACTIVACIÓN
# ========================================================================

Clear-Host
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "             ¡INSTALACIÓN DE OFFICE 100% COMPLETADA!              " -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "`n[Instalador]: Disculpa la interrupción, ya se horneó el pan y los archivos están en tu disco." -ForegroundColor Yellow
Write-Host "`nLimpiando archivos temporales de instalación..." -ForegroundColor White
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "   Ejecutando configuracion final..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "`n[!] ATENCION: Instalación completa, continuaré con la activación." -ForegroundColor Yellow
Write-Host "Ejecutando activación Ohook en 3 segundos..." -ForegroundColor Cyan
Start-Sleep -Seconds 1; Write-Host "2..." -ForegroundColor Yellow
Start-Sleep -Seconds 1; Write-Host "1..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

Write-Host "Activando Office de forma silenciosa, por favor espera..." -ForegroundColor Yellow

# --- INICIO DE LA LÓGICA DE ACTIVACIÓN CORREGIDA ---
$urlActivador = "https://raw.githubusercontent.com/WenliangK/OfficeAutoInstall/refs/heads/main/MAS/Ohook_Activation_AIO.cmd"
$rutaTemporal = Join-Path -Path $env:TEMP -ChildPath "Ohook_Activation_AIO.cmd"

try {
    Invoke-RestMethod -Uri $urlActivador -OutFile $rutaTemporal

    if (Test-Path $rutaTemporal) {
        # Llamamos explícitamente a cmd.exe y pasamos las flags /ohook y /u
        # Las comillas dobles anidadas aseguran que Windows lea bien la ruta temporal
        $argumentosCMD = "/c `"`"$rutaTemporal`" /ohook /u`""
        
        Start-Process -FilePath "cmd.exe" -ArgumentList $argumentosCMD -Wait -WindowStyle Hidden
        
        # Limpieza silenciosa
        Remove-Item -Path $rutaTemporal -Force
    } else {
        Write-Host "`n[Error]: No se pudo guardar el archivo temporal de activación." -ForegroundColor Red
    }
} catch {
    Write-Host "`n[Error]: Falló la descarga del activador. Revisa tu conexión o la URL." -ForegroundColor Red
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   ¡Proceso finalizado! Gracias por confiar en nosotros." -ForegroundColor Green
Write-Host "          by MythEnv & https://github.com/WenliangK" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")