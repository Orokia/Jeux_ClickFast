# Démarre la chaîne ClickFast (Docker Desktop -> vm-prod -> Docker interne -> conteneurs)
# puis maintient le tunnel SSH localhost:8080 -> vm-prod:8080. Aucune suppression de
# conteneur, d'image ou de volume : uniquement des "start".

$ProjectDir = "C:\Users\COULIB~1\Desktop\Jeux_ClickFast"
$Key = "$ProjectDir\deploy_key"
$KnownHosts = "$ProjectDir\known_hosts.test"
$VmName = "vm-prod"
$InnerContainers = @("clickfast-db", "clickfast-api", "clickfast-stats-api", "clickfast", "clickfast-adminer")
$DockerDesktopExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

$LogDir = Join-Path $env:LOCALAPPDATA "ClickFast"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogFile = Join-Path $LogDir "tunnel.log"

function Write-Log([string]$Message) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

# Une seule instance à la fois (la tâche peut se déclencher plusieurs fois).
$Mutex = New-Object System.Threading.Mutex($false, "Local\ClickFastSshTunnel")
if (-not $Mutex.WaitOne(0)) { exit 0 }

# Limite le journal à ~1 Mo.
if ((Test-Path $LogFile) -and (Get-Item $LogFile).Length -gt 1MB) {
    Move-Item -Force $LogFile "$LogFile.old"
}

$Ssh = (Get-Command ssh.exe -ErrorAction Stop).Source
$Docker = (Get-Command docker.exe -ErrorAction SilentlyContinue).Source
if (-not $Docker) { $Docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe" }

function Test-Docker { & $Docker info *> $null; return ($LASTEXITCODE -eq 0) }
function Test-InnerDocker { & $Docker exec $VmName docker info *> $null; return ($LASTEXITCODE -eq 0) }

function Wait-Until([scriptblock]$Condition, [int]$TimeoutSec) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (& $Condition) { return $true }
        Start-Sleep -Seconds 3
    }
    return $false
}

function Ensure-Stack {
    # 1. Docker Desktop
    if (-not (Test-Docker)) {
        Write-Log "Docker indisponible, démarrage de Docker Desktop"
        if (-not (Get-Process "Docker Desktop" -ErrorAction SilentlyContinue)) {
            Start-Process -FilePath $DockerDesktopExe
        }
        if (-not (Wait-Until { Test-Docker } 300)) { Write-Log "Docker Desktop ne répond pas"; return $false }
    }

    # 2. vm-prod
    $state = & $Docker inspect -f "{{.State.Running}}" $VmName 2>$null
    if ($state -ne "true") {
        Write-Log "$VmName arrêté, démarrage"
        & $Docker start $VmName *> $null
        if ($LASTEXITCODE -ne 0) { Write-Log "Échec du démarrage de $VmName"; return $false }
    }

    # 3. Docker interne : dockerd peut refuser de démarrer à cause d'un containerd.pid
    #    laissé par un arrêt brutal. On ne le supprime que si aucun démon ne tourne.
    if (-not (Wait-Until { Test-InnerDocker } 30)) {
        Write-Log "Docker interne arrêté, relance de dockerd"
        & $Docker exec $VmName sh -c 'pgrep -x dockerd >/dev/null || pgrep -x containerd >/dev/null || rm -f /var/run/docker/containerd/containerd.pid /var/run/docker.pid' *> $null
        & $Docker exec -d $VmName sh -c 'pgrep -x dockerd >/dev/null || exec dockerd-entrypoint.sh >> /proc/1/fd/1 2>&1' *> $null
        if (-not (Wait-Until { Test-InnerDocker } 120)) { Write-Log "Docker interne ne répond pas"; return $false }
    }

    # 4. Conteneurs internes ("start" est sans effet s'ils tournent déjà)
    & $Docker exec $VmName docker start @InnerContainers *> $null
    return $true
}

Write-Log "=== Démarrage du superviseur ClickFast"
while ($true) {
    if (Ensure-Stack) {
        Write-Log "Ouverture du tunnel SSH localhost:8080"
        & $Ssh `
            -i $Key `
            -p 2222 `
            -o IdentitiesOnly=yes `
            -o StrictHostKeyChecking=yes `
            -o "UserKnownHostsFile=$KnownHosts" `
            -o BatchMode=yes `
            -o ConnectTimeout=15 `
            -o ServerAliveInterval=15 `
            -o ServerAliveCountMax=3 `
            -o ExitOnForwardFailure=yes `
            -E "$LogDir\ssh.log" `
            -N `
            -L 8080:localhost:8080 `
            root@localhost
        Write-Log "Tunnel SSH terminé (code $LASTEXITCODE), nouvelle tentative"
    }
    Start-Sleep -Seconds 10
}
