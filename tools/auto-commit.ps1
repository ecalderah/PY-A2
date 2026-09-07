<#
.SYNOPSIS
    Respaldo automatico en Git: vigila la carpeta del proyecto y hace commit + push
    cuando detecta cambios guardados.

.DESCRIPTION
    Se lanza solo al abrir la carpeta en VS Code (ver .vscode/tasks.json).
    Cada IntervaloSegundos revisa 'git status --porcelain'. Solo hace commit cuando
    el estado se repite identico dos ciclos seguidos, para no commitear a medias
    mientras el editor todavia esta escribiendo el archivo.

.PARAMETER IntervaloSegundos
    Segundos entre revisiones. Por defecto 15.

.PARAMETER SinPush
    Si se indica, solo hace commit local y nunca contacta a GitHub.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\auto-commit.ps1
    powershell -ExecutionPolicy Bypass -File tools\auto-commit.ps1 -IntervaloSegundos 30 -SinPush
#>
[CmdletBinding()]
param(
    [int]$IntervaloSegundos = 15,
    [switch]$SinPush
)

$ErrorActionPreference = 'Continue'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $raiz

# Toda la salida va tambien a .git/auto-commit.log, para poder diagnosticar el
# vigilante cuando lo lanza VS Code y su terminal no esta a la vista.
$bitacora = Join-Path $raiz '.gituto-commit.log'
function Escribir($mensaje, $color = 'Gray') {
    $linea = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $mensaje
    Write-Host $linea -ForegroundColor $color
    try { Add-Content -LiteralPath $bitacora -Value $linea -Encoding utf8 } catch { }
}

if (-not (Test-Path (Join-Path $raiz '.git'))) {
    Escribir "No hay repositorio git en $raiz. Ejecuta 'git init' primero." 'Red'
    exit 1
}

# Candado: evita que dos ventanas de VS Code corran el vigilante a la vez.
# Un candado huerfano (proceso muerto sin limpiar) no debe bloquear el arranque, y
# tampoco basta con que el PID exista: Windows los recicla, asi que se comprueba
# que ese proceso sea de verdad otro auto-commit.
$candado = Join-Path $raiz '.git\auto-commit.lock'
if (Test-Path $candado) {
    $pidPrevio = (Get-Content -LiteralPath $candado -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($pidPrevio -match '^\d+$') {
        $otro = Get-CimInstance Win32_Process -Filter "ProcessId=$pidPrevio" -ErrorAction SilentlyContinue
        if ($otro -and $otro.CommandLine -like '*auto-commit*') {
            Escribir "Ya hay un auto-commit corriendo (PID $pidPrevio). Salgo." 'Yellow'
            exit 0
        }
    }
    Escribir "Candado huerfano encontrado; lo descarto." 'DarkGray'
    Remove-Item -LiteralPath $candado -Force -ErrorAction SilentlyContinue
}
Set-Content -LiteralPath $candado -Value $PID -Encoding ascii

$tienePush = -not $SinPush -and [bool](git remote 2>$null)
if (-not $tienePush) { Escribir "Modo solo-local: no se hara push." 'Yellow' }

Escribir "Arranca vigilante. PID $PID, git en '$((Get-Command git -ErrorAction SilentlyContinue).Source)'." 'DarkGray'
Escribir "Vigilando $raiz cada $IntervaloSegundos s. Cierra esta terminal para detener." 'Cyan'

$estadoPrevio = $null
try {
    while ($true) {
        Start-Sleep -Seconds $IntervaloSegundos

        $estado = (git status --porcelain 2>$null) -join "`n"

        if ([string]::IsNullOrWhiteSpace($estado)) {
            $estadoPrevio = $null
            continue
        }

        # Espera a que el arbol se estabilice antes de commitear.
        if ($estado -ne $estadoPrevio) {
            $estadoPrevio = $estado
            continue
        }

        $archivos = ($estado -split "`n").Count
        $marca = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

        git add -A 2>&1 | Out-Null
        $salida = git commit -m "auto: respaldo $marca" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Escribir "Commit sin efecto: $($salida -join ' ')" 'DarkGray'
            $estadoPrevio = $null
            continue
        }
        Escribir "Commit hecho ($archivos archivo(s))." 'Green'
        $estadoPrevio = $null

        if (-not $tienePush) { continue }

        git push 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Escribir "Push fallo; intento rebase sobre el remoto." 'Yellow'
            git pull --rebase --autostash 2>&1 | Out-Null
            git push 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Escribir "Push sigue fallando (sin red o conflicto). Reintento en el proximo ciclo." 'Red'
                continue
            }
        }
        Escribir "Push a GitHub listo." 'Green'
    }
}
finally {
    Remove-Item -LiteralPath $candado -Force -ErrorAction SilentlyContinue
    Escribir "Auto-commit detenido." 'Cyan'
}
