param(
    [Parameter(Mandatory=$false)]
    [string]$BucketPath = ".",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxAppsPerRun = 50,
    
    [Parameter(Mandatory=$false)]
    [int]$CheckIntervalHours = 24
)

# Configuration
$TrackerFile = Join-Path $BucketPath ".github/data/app-tracker.json"
$ManifestsPath = Join-Path $BucketPath "bucket"

# Load tracker database
if (Test-Path $TrackerFile) {
    $tracker = Get-Content $TrackerFile | ConvertFrom-Json
} else {
    $tracker = @{}
}

# Get all manifests
$manifests = Get-ChildItem $ManifestsPath -Filter *.json

Write-Host "Found $($manifests.Count) manifests" -ForegroundColor Cyan

# Calculate which apps to check
$appsToCheck = @()
$now = Get-Date

foreach ($manifest in $manifests) {
    $appName = $manifest.BaseName
    
    # Check if app is in tracker
    if ($tracker.$appName) {
        $lastChecked = [datetime]::Parse($tracker.$appName.lastChecked)
        $hoursSinceCheck = ($now - $lastChecked).TotalHours
        
        # Skip if checked recently
        if ($hoursSinceCheck -lt $CheckIntervalHours) {
            continue
        }
        
        # Calculate priority score
        $updateFrequency = $tracker.$appName.updateFrequency
        $daysSinceUpdate = ($now - [datetime]::Parse($tracker.$appName.lastUpdated)).TotalDays
        
        $priorityScore = $daysSinceUpdate * $updateFrequency
        
        $appsToCheck += [PSCustomObject]@{
            Name = $appName
            Path = $manifest.FullName
            Priority = $priorityScore
            LastChecked = $lastChecked
        }
    } else {
        # New app, high priority
        $appsToCheck += [PSCustomObject]@{
            Name = $appName
            Path = $manifest.FullName
            Priority = 100
            LastChecked = $null
        }
    }
}

# Sort by priority (highest first) and take top N
$appsToCheck = $appsToCheck | Sort-Object Priority -Descending | Select-Object -First $MaxAppsPerRun

Write-Host "Checking $($appsToCheck.Count) apps this run:" -ForegroundColor Green
$appsToCheck | ForEach-Object { Write-Host "  - $($_.Name) (priority: $($_.Priority))" }

# Setup Scoop
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
}

# Add local bucket
scoop bucket add local $BucketPath -ErrorAction SilentlyContinue

# Check each app
$updatedApps = @()

foreach ($app in $appsToCheck) {
    Write-Host "`nChecking $($app.Name)..." -ForegroundColor Cyan
    
    try {
        # Run scoop checkver
        $result = scoop checkver $app.Name --force 2>&1
        
        # Check if update is available
        if ($result -match "->") {
            Write-Host "  Update available!" -ForegroundColor Green
            
            # Parse new version
            if ($result -match "(\d+\.\d+\.\d+)") {
                $newVersion = $matches[1]
                
                # Update tracker
                $tracker.$($app.Name) = @{
                    lastChecked = $now.ToString("o")
                    lastUpdated = $now.ToString("o")
                    currentVersion = $newVersion
                    updateFrequency = 1.0  # Will be adjusted over time
                }
                
                $updatedApps += $app.Name
            }
        } else {
            # No update
            $tracker.$($app.Name) = @{
                lastChecked = $now.ToString("o")
                lastUpdated = $tracker.$($app.Name).lastUpdated ?? $now.ToString("o")
                currentVersion = $tracker.$($app.Name).currentVersion ?? "unknown"
                updateFrequency = ($tracker.$($app.Name).updateFrequency ?? 1.0) * 0.95  # Reduce frequency if no updates
            }
        }
    } catch {
        Write-Host "  Error checking $($app.Name): $_" -ForegroundColor Red
    }
}

# Save tracker
$tracker | ConvertTo-Json -Depth 3 | Set-Content $TrackerFile

# Return results
Write-Host "`n=== Run Summary ===" -ForegroundColor Yellow
Write-Host "Checked: $($appsToCheck.Count) apps" -ForegroundColor Cyan
Write-Host "Updated: $($updatedApps.Count) apps" -ForegroundColor Green

if ($updatedApps.Count -gt 0) {
    Write-Host "Updated apps:" -ForegroundColor Green
    $updatedApps | ForEach-Object { Write-Host "  - $_" }
    
    # Signal that updates were made
    exit 100  # Special exit code to indicate updates
} else {
    exit 0
}