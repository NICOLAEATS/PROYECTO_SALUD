# Proyecto Salud - Tunnel Cloudflare (PowerShell)
# Da acceso publico a tu sistema desde cualquier lugar

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Resolve-Path "$ScriptDir\.."
$LogFile = "$ProjectDir\tunnel\tunnel.log"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Proyecto Salud - Tunnel Publico" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# PASO 1: Verificar/Iniciar Flask
Write-Host "[1/3] Verificando servidor Flask..." -ForegroundColor Yellow
try {
    $req = Invoke-WebRequest -Uri "http://127.0.0.1:5000/api/db/detect" -Method POST -TimeoutSec 3 -ErrorAction Stop
    $data = $req.Content | ConvertFrom-Json
    Write-Host "  [OK] Flask corriendo - $($data.mensaje)" -ForegroundColor Green
} catch {
    Write-Host "  Iniciando servidor Flask..." -ForegroundColor Yellow
    $venvPython = "$ProjectDir\venv\Scripts\python.exe"
    if (-not (Test-Path $venvPython)) {
        Write-Host "  [ERROR] No se encuentra $venvPython" -ForegroundColor Red
        Write-Host "  Ejecuta primero install-local.sh o config.psi" -ForegroundColor Red
        pause
        exit 1
    }
    Start-Process -FilePath $venvPython -ArgumentList "app.py" -WorkingDirectory $ProjectDir -WindowStyle Hidden
    Start-Sleep -Seconds 5
    Write-Host "  [OK] Flask iniciado" -ForegroundColor Green
}

# PASO 2: Descargar cloudflared
Write-Host "[2/3] Verificando cloudflared..." -ForegroundColor Yellow
$cloudflared = "$ProjectDir\tunnel\cloudflared.exe"
if (-not (Test-Path $cloudflared)) {
    Write-Host "  Descargando cloudflared..." -ForegroundColor Yellow
    try {
        $url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
        Invoke-WebRequest -Uri $url -OutFile $cloudflared -UseBasicParsing
        Write-Host "  [OK] cloudflared descargado" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] No se pudo descargar cloudflared: $_" -ForegroundColor Red
        Write-Host "  Descargalo manual de: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/" -ForegroundColor Yellow
        pause
        exit 1
    }
} else {
    Write-Host "  [OK] cloudflared ya existe" -ForegroundColor Green
}

# PASO 3: Iniciar tunnel
Write-Host "[3/3] Iniciando tunnel Cloudflare..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Generando URL publica..." -ForegroundColor Cyan
Write-Host "  (Esto puede tomar hasta 30 segundos)" -ForegroundColor Gray
Write-Host ""

# Ejecutar cloudflared y capturar la URL
$logFile = "$ProjectDir\tunnel\tunnel.log"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $cloudflared
$psi.Arguments = "tunnel --url http://127.0.0.1:5000 --logfile `"$logFile`""
$psi.WorkingDirectory = "$ProjectDir\tunnel"
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true

$proc = [System.Diagnostics.Process]::Start($psi)

# Esperar a que aparezca la URL en el log
$timeout = 30
$elapsed = 0
$tunnelUrl = $null

while ($elapsed -lt $timeout -and -not $proc.HasExited) {
    Start-Sleep -Seconds 1
    $elapsed++
    if (Test-Path $logFile) {
        $log = Get-Content $logFile -Tail 10 -ErrorAction SilentlyContinue
        $match = [regex]::Match($log, 'https://[a-z0-9.-]+\.trycloudflare\.com')
        if ($match.Success) {
            $tunnelUrl = $match.Value
            break
        }
    }
    Write-Host "  ." -NoNewline -ForegroundColor Gray
}

Write-Host ""
Write-Host ""

if ($tunnelUrl) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  ✅ SISTEMA PUBLICADO!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  URL: $tunnelUrl" -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host ""
    Write-Host "  Accede desde CUALQUIER PC o celular" -ForegroundColor Cyan
    Write-Host "  Solo necesitan un navegador" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [CTRL+C] para cerrar el tunnel" -ForegroundColor Yellow
    Write-Host ""

    # Copiar URL al portapapeles
    try {
        [System.Windows.Forms.Clipboard]::SetText($tunnelUrl)
        Write-Host "  (URL copiada al portapapeles)" -ForegroundColor Gray
    } catch {}

    # Mostrar notificacion Windows
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$cloudflared")
        $notify.BalloonTipTitle = "Proyecto Salud - Publicado"
        $notify.BalloonTipText = $tunnelUrl
        $notify.Visible = $true
        $notify.ShowBalloonTip(10000)
    } catch {}

    $proc.WaitForExit()
} else {
    Write-Host "  [ERROR] No se genero URL en $timeout segundos" -ForegroundColor Red
    Write-Host "  Revisa: $logFile" -ForegroundColor Yellow
    pause
}
