<#
.SYNOPSIS
    Monitors CPU and RAM metrics for a Meraki MX device in real-time with history.
.DESCRIPTION
    Fetches CPU performance score and RAM usage every minute, displays a live dashboard,
    and logs data to CSV for historical tracking.
.EXAMPLE
    .\Monitor-MerakiMXMetrics.ps1 -Serial "Q2YN-W3AD-VSTA" -OrgId "1278208"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Serial,

    [Parameter(Mandatory=$true)]
    [string]$OrgId,

    [int]$HistorySize = 80  # Nombre de mesures à afficher dans l'historique
)

# --- Configuration ---
$apiKeyFile = Join-Path -Path $PSScriptRoot -ChildPath "meraki_api_key.txt"
$apiKey = Get-Content -Path $apiKeyFile -Raw | ForEach-Object { $_.Trim() }
$csvFile = Join-Path -Path $PSScriptRoot -ChildPath "Meraki_Metrics_History.csv"

# Vérification de l'API Key
if (-not $apiKey) {
    Write-Error "API key is empty or not found in 'meraki_api_key.txt'."
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

# Initialisation de l'historique
$cpuHistory = @()
$ramHistory = @()

# Fonction pour générer un historique compact (chiffre des dizaines du %, ou "*" en cas d'échec)
# Le dernier caractère à droite est la mesure la plus récente.
function Show-AsciiChart {
    param (
        [array]$Data,
        [int]$Width = 20,
        [string]$Color = "Yellow"
    )

    # Chiffre des dizaines de chaque valeur (0-9), ou "*" si la mesure a échoué. 100% -> plafonné à 9.
    $digits = $Data | ForEach-Object {
        if ($_ -eq "*") {
            "*"
        } else {
            [math]::Min([math]::Floor($_ / 10), 9)
        }
    }

    $line = ($digits -join "")

    if ($line.Length -lt $Width) {
        $line = ("_" * ($Width - $line.Length)) + $line
    } elseif ($line.Length -gt $Width) {
        $line = $line.Substring($line.Length - $Width)
    }

    Write-Host ("[" + $line + "]") -ForegroundColor $Color
}

# Fonction pour récupérer les métriques
function Get-MerakiMetrics {
    try {
        # CPU Performance
        $perfUrl = "https://api.meraki.com/api/v1/devices/$Serial/appliance/performance"
        $perfResponse = Invoke-RestMethod -Uri $perfUrl -Method Get -Headers $headers -ErrorAction Stop
        $perfScore = $perfResponse.perfScore

        # RAM Usage
        $memoryUrl = "https://api.meraki.com/api/v1/organizations/$OrgId/devices/system/memory/usage/history/byInterval?productTypes[]=appliance" + "&serials[]=$Serial"
        $memoryResponse = Invoke-RestMethod -Uri $memoryUrl -Method Get -Headers $headers -ErrorAction Stop

        # Extract memory data for the specified serial
        $memoryItem = $memoryResponse.items | Where-Object { $_.serial -eq $Serial }
        if (-not $memoryItem) {
            return @{ Failed = $true }
        }

        $latestMemoryInterval = $memoryItem.intervals | Sort-Object -Property startTs -Descending | Select-Object -First 1
        $usedMemoryMb = $latestMemoryInterval.memory.used.median / 1MB
        $freeMemoryMb = $latestMemoryInterval.memory.free.median / 1MB
        $totalMemoryMb = $usedMemoryMb + $freeMemoryMb
        $memoryUsagePercent = $latestMemoryInterval.memory.used.percentages.maximum

        return @{
            Failed = $false
            Timestamp = Get-Date -Format "HH:mm:ss"
            PerfScore = $perfScore
            MemoryUsagePercent = $memoryUsagePercent
            UsedMemoryMb = [math]::Round($usedMemoryMb, 2)
            TotalMemoryMb = [math]::Round($totalMemoryMb, 2)
        }
    } catch {
        # Pas d'affichage d'erreur rouge : on signale simplement l'échec à l'appelant
        return @{ Failed = $true }
    }
}

# Initialisation du CSV
if (-not (Test-Path -Path $csvFile)) {
    "Timestamp,Serial,OrgId,PerfScore,MemoryUsagePercent,UsedMemoryMb,TotalMemoryMb" | Out-File -FilePath $csvFile -Encoding UTF8
}

# Boucle principale
Write-Host "Starting Meraki MX Monitor for $Serial (Ctrl+C to stop)..." -ForegroundColor Cyan
Write-Host "History will show the last $HistorySize measurements." -ForegroundColor DarkGray

try {
    while ($true) {
        Clear-Host
        $metrics = Get-MerakiMetrics

        Write-Host ("=== Live Metrics for {0} ({1}) ===" -f $Serial, (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) -ForegroundColor Green

        if ($metrics -and -not $metrics.Failed) {
            # Ajout à l'historique
            $cpuHistory += $metrics.PerfScore
            $ramHistory += $metrics.MemoryUsagePercent

            # Limiter la taille de l'historique
            if ($cpuHistory.Count -gt $HistorySize) {
                $cpuHistory = $cpuHistory[-$HistorySize..-1]
                $ramHistory = $ramHistory[-$HistorySize..-1]
            }

            # Affichage
            Write-Host ("CPU Performance: {0}%" -f $metrics.PerfScore) -ForegroundColor Yellow
            Show-AsciiChart -Data $cpuHistory -Width $HistorySize -Color Yellow
            Write-Host ("RAM Usage: {0}% ({1} MB / {2} MB)" -f $metrics.MemoryUsagePercent, $metrics.UsedMemoryMb, $metrics.TotalMemoryMb) -ForegroundColor Yellow
            Show-AsciiChart -Data $ramHistory -Width $HistorySize -Color Cyan

            # Export CSV
            $csvLine = "{0},{1},{2},{3},{4},{5},{6}" -f (
                (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
                $Serial,
                $OrgId,
                $metrics.PerfScore,
                $metrics.MemoryUsagePercent,
                $metrics.UsedMemoryMb,
                $metrics.TotalMemoryMb
            )
            Add-Content -Path $csvFile -Value $csvLine -Encoding UTF8
        } else {
            # Echec de l'appel API (probablement perte réseau)
            $cpuHistory += "*"
            $ramHistory += "*"

            if ($cpuHistory.Count -gt $HistorySize) {
                $cpuHistory = $cpuHistory[-$HistorySize..-1]
                $ramHistory = $ramHistory[-$HistorySize..-1]
            }

            Write-Host "CPU Performance: API Call fail, no network" -ForegroundColor Red
            Show-AsciiChart -Data $cpuHistory -Width $HistorySize -Color Yellow
            Write-Host "RAM Usage: API Call fail, no network" -ForegroundColor Red
            Show-AsciiChart -Data $ramHistory -Width $HistorySize -Color Cyan

            # Log l'échec dans le CSV
            $csvLine = "{0},{1},{2},{3},{4},{5},{6}" -f (
                (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
                $Serial,
                $OrgId,
                "FAIL", "FAIL", "FAIL", "FAIL"
            )
            Add-Content -Path $csvFile -Value $csvLine -Encoding UTF8
        }

        # Attendre 1 minute
        Start-Sleep -Seconds 60
    }
}
catch {
    # Gestion de l'interruption utilisateur (Ctrl+C)
    if ($_.Exception.Message -eq "The operation was canceled by the user.") {
        Write-Host "`nMonitoring stopped by user." -ForegroundColor Red
    } else {
        Write-Error "Unexpected error: $_"
    }
}
