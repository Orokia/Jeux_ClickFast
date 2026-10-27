# Sauvegarde vérifiée de la base PostgreSQL ClickFast.
#   1. Comptage des lignes de chaque table, pg_dump (format custom) dans clickfast-db
#      sur vm-prod, puis nouveau comptage. La production n'est que lue.
#   2. Restauration complète du dump dans un conteneur postgres:17 jetable sur Docker
#      Desktop (jamais sur vm-prod), puis comparaison table par table des comptages.
#   3. Le dump n'est conservé (avec son manifeste et son SHA-256) que si la
#      restauration réussit. Rotation des anciennes sauvegardes ensuite.
#
# Usage :
#   .\backup-clickfast-db.ps1                      # sauvegarde + test de restauration
#   .\backup-clickfast-db.ps1 -Verify <fichier>    # re-teste une sauvegarde existante

param(
    [string]$Verify,
    [int]$RetentionDays = 14,
    [int]$KeepMin = 3
)

$ProjectDir = "C:\Users\COULIB~1\Desktop\Jeux_ClickFast"
$BackupDir = Join-Path $ProjectDir "backups\db"
$VmName = "vm-prod"
$DbContainer = "clickfast-db"
$DbName = "clickfast"
$DbUser = "clickfast"
$RestoreImage = "postgres:17"

$LogDir = Join-Path $env:LOCALAPPDATA "ClickFast"
New-Item -ItemType Directory -Force -Path $LogDir, $BackupDir | Out-Null
$LogFile = Join-Path $LogDir "backup.log"

function Write-Log([string]$Message) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Write-Host $line
    $line | Out-File -FilePath $LogFile -Append -Encoding utf8
}

# Une seule sauvegarde à la fois.
$Mutex = New-Object System.Threading.Mutex($false, "Local\ClickFastDbBackup")
if (-not $Mutex.WaitOne(0)) { Write-Host "Une sauvegarde est déjà en cours."; exit 0 }

$Docker = (Get-Command docker.exe -ErrorAction SilentlyContinue).Source
if (-not $Docker) { $Docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe" }

# Lance docker et lève une erreur si le code de sortie n'est pas 0.
function Invoke-Docker {
    $out = & $Docker @args 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "docker $($args -join ' ') a échoué : $($out -join ' ')" }
    return $out
}

# Nombre exact de lignes de chaque table utilisateur, une ligne "schema.table|n" par table.
$CountQuery = (@'
select format('%I.%I', table_schema, table_name) || '|' ||
       (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name), false, true, '')))[1]::text
from information_schema.tables
where table_schema not in ('pg_catalog', 'information_schema') and table_type = 'BASE TABLE'
order by 1
'@) -replace '\s+', ' '

function ConvertTo-Counts([string[]]$Lines) {
    $counts = [ordered]@{}
    foreach ($l in $Lines) {
        if ($l -match '^(.+)\|(\d+)$') { $counts[$Matches[1]] = [long]$Matches[2] }
    }
    return $counts
}

function Get-ProdCounts {
    ConvertTo-Counts (Invoke-Docker exec $VmName docker exec $DbContainer psql -U $DbUser -d $DbName -X -At -c $CountQuery)
}

# Restaure le dump dans un conteneur jetable et renvoie les comptages obtenus.
function Test-Restore([string]$DumpFile) {
    $name = "clickfast-restore-test-$(Get-Date -Format 'yyyyMMddHHmmss')"
    try {
        Invoke-Docker run -d --rm --name $name -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_DB=$DbName $RestoreImage | Out-Null
        # -h 127.0.0.1 : le serveur temporaire d'initialisation n'écoute que sur le socket Unix.
        $deadline = (Get-Date).AddSeconds(90)
        do {
            Start-Sleep -Seconds 2
            & $Docker exec $name pg_isready -h 127.0.0.1 -U postgres -d $DbName *> $null
        } while ($LASTEXITCODE -ne 0 -and (Get-Date) -lt $deadline)
        if ($LASTEXITCODE -ne 0) { throw "Le conteneur de test $name ne répond pas" }

        Invoke-Docker cp $DumpFile "${name}:/tmp/restore.dump" | Out-Null
        Invoke-Docker exec $name pg_restore -h 127.0.0.1 -U postgres -d $DbName --exit-on-error --no-owner --no-privileges /tmp/restore.dump | Out-Null
        return ConvertTo-Counts (Invoke-Docker exec $name psql -h 127.0.0.1 -U postgres -d $DbName -X -At -c $CountQuery)
    }
    finally {
        & $Docker rm -f $name *> $null
    }
}

# Chaque table de la production doit être restaurée avec un nombre de lignes compris
# entre le comptage d'avant et celui d'après le dump (le jeu peut écrire pendant le dump).
function Compare-Counts($Before, $After, $Restored) {
    $problems = @()
    $tables = @($Before.Keys) + @($After.Keys) | Sort-Object -Unique
    foreach ($t in $tables) {
        if (-not $Restored.Contains($t)) { $problems += "$t absente après restauration"; continue }
        $lo = [Math]::Min([long]$Before[$t], [long]$After[$t])
        $hi = [Math]::Max([long]$Before[$t], [long]$After[$t])
        if ($Restored[$t] -lt $lo -or $Restored[$t] -gt $hi) {
            $problems += "$t : $($Restored[$t]) lignes restaurées, attendu entre $lo et $hi"
        }
    }
    foreach ($t in $Restored.Keys) {
        if ($tables -notcontains $t) { $problems += "$t inattendue après restauration" }
    }
    return $problems
}

function Remove-OldBackups {
    $dumps = Get-ChildItem $BackupDir -Filter "clickfast_*.dump" | Sort-Object LastWriteTime -Descending
    $limit = (Get-Date).AddDays(-$RetentionDays)
    $dumps | Select-Object -Skip $KeepMin | Where-Object { $_.LastWriteTime -lt $limit } | ForEach-Object {
        Write-Log "Rotation : suppression de $($_.Name)"
        Remove-Item -LiteralPath $_.FullName, ($_.FullName -replace '\.dump$', '.json') -ErrorAction SilentlyContinue
    }
}

# --- Re-vérification d'une sauvegarde existante -----------------------------------
if ($Verify) {
    try {
        $dump = (Resolve-Path $Verify).Path
        $manifest = Get-Content ($dump -replace '\.dump$', '.json') -Raw -Encoding utf8 | ConvertFrom-Json
        Write-Log "=== Vérification de $dump"
        $hash = (Get-FileHash $dump -Algorithm SHA256).Hash.ToLower()
        if ($hash -ne $manifest.sha256) { throw "SHA-256 différent du manifeste : fichier altéré" }
        $expected = [ordered]@{}
        $manifest.tables.PSObject.Properties | ForEach-Object { $expected[$_.Name] = [long]$_.Value }
        $restored = Test-Restore $dump
        $problems = Compare-Counts $expected $expected $restored
        if ($problems) { throw ($problems -join " ; ") }
        Write-Log "OK : restauration conforme ($($restored.Count) tables)"
        exit 0
    }
    catch {
        Write-Log "ÉCHEC de la vérification : $($_.Exception.Message)"
        exit 1
    }
}

# --- Sauvegarde ----------------------------------------------------------------------
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$final = Join-Path $BackupDir "clickfast_$stamp.dump"
$partial = "$final.partial"
# /var/tmp et non /tmp : docker cp depuis l'hôte ne voit pas le /tmp de vm-prod.
$remote = "/var/tmp/clickfast_$stamp.dump"

Write-Log "=== Sauvegarde $stamp"
try {
    $before = Get-ProdCounts
    # pg_dump écrit dans un fichier puis docker cp : un pipe PowerShell abîmerait le binaire.
    Invoke-Docker exec $VmName docker exec $DbContainer pg_dump -U $DbUser -d $DbName -Fc -f $remote | Out-Null
    $after = Get-ProdCounts
    Invoke-Docker exec $VmName docker cp "${DbContainer}:$remote" $remote | Out-Null
    Invoke-Docker cp "${VmName}:$remote" $partial | Out-Null

    $size = (Get-Item $partial).Length
    if ($size -eq 0) { throw "Dump vide" }
    Write-Log "Dump récupéré ($size octets), test de restauration"

    $restored = Test-Restore $partial
    $problems = Compare-Counts $before $after $restored
    if ($problems) { throw "Restauration non conforme : $($problems -join ' ; ')" }

    Move-Item $partial $final
    [ordered]@{
        file        = Split-Path $final -Leaf
        created_at  = (Get-Date).ToString("o")
        size_bytes  = $size
        sha256      = (Get-FileHash $final -Algorithm SHA256).Hash.ToLower()
        pg_version  = (Invoke-Docker exec $VmName docker exec $DbContainer pg_dump --version) -join ""
        restore_test = "ok"
        tables      = $restored
    } | ConvertTo-Json | Out-File ($final -replace '\.dump$', '.json') -Encoding utf8

    Write-Log "OK : $(Split-Path $final -Leaf) vérifiée ($(($restored.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '))"
    Remove-OldBackups
    exit 0
}
catch {
    Write-Log "ÉCHEC de la sauvegarde : $($_.Exception.Message)"
    Remove-Item -LiteralPath $partial -ErrorAction SilentlyContinue
    exit 1
}
finally {
    & $Docker exec $VmName docker exec $DbContainer rm -f $remote *> $null
    & $Docker exec $VmName rm -f $remote *> $null
}
