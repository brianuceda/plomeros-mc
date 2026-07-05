# ============================================================
#  Backup automatico del mundo -> commit + push a GitHub
#  - Si el server esta corriendo: save-off + save-all flush por RCON
#    (asi el mundo no se corrompe por copiarlo a medio guardado)
#  - git add -A  ->  commit (solo si hay cambios)  ->  push
#  - Reactiva el guardado con save-on
#
#  Uso manual:   powershell -ExecutionPolicy Bypass -File backup-world.ps1
#  Programado:   ver tarea "PlomerosBackup" en el Programador de tareas
# ============================================================

$ErrorActionPreference = 'Continue'
$repo   = "C:\Users\buceda\Documents\GitHub\plomeros\plomeros-mc"
$mcrcon = "C:\Program Files\mcrcon-0.7.2\mcrcon.exe"
$rconHost = "127.0.0.1"
$rconPort = "25575"
$rconPass = "P6gRwQ77s8yi8KtHfveYzXpKXoEHdXEP"

Set-Location $repo
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[$stamp] Iniciando backup..." -ForegroundColor Cyan

# ¿Esta el server escuchando RCON? (best-effort)
$serverUp = $false
try {
  $t = Test-NetConnection -ComputerName $rconHost -Port $rconPort -WarningAction SilentlyContinue
  $serverUp = $t.TcpTestSucceeded
} catch { $serverUp = $false }

function Rcon($cmd) {
  if ($serverUp -and (Test-Path $mcrcon)) {
    & $mcrcon -H $rconHost -P $rconPort -p $rconPass $cmd 2>$null | Out-Null
  }
}

if ($serverUp) {
  Write-Host "Server ACTIVO -> desactivando guardado y forzando flush..." -ForegroundColor Yellow
  Rcon "save-off"
  Rcon "save-all flush"
  Start-Sleep -Seconds 3
} else {
  Write-Host "Server apagado -> backup directo del mundo en disco." -ForegroundColor DarkGray
}

try {
  git add -A
  $changes = git status --porcelain
  if ([string]::IsNullOrWhiteSpace($changes)) {
    Write-Host "Sin cambios desde el ultimo backup. Nada que subir." -ForegroundColor Green
  } else {
    $n = ($changes -split "`n").Count
    git commit -q -m "backup automatico $stamp ($n archivos)"
    Write-Host "Commit hecho. Empujando a GitHub..." -ForegroundColor Cyan
    git push origin main
    Write-Host "Backup subido correctamente." -ForegroundColor Green
  }
} finally {
  # SIEMPRE reactivar el guardado, pase lo que pase
  if ($serverUp) { Rcon "save-on"; Write-Host "Guardado reactivado (save-on)." -ForegroundColor Yellow }
}
