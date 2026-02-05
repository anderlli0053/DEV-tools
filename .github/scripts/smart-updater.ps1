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
    $trackerContent = Get-Content $TrackerFile -Raw
    if ($trackerContent.Trim() -ne "") {
        $tracker = $trackerContent | ConvertFrom-Json -AsHashtable
    } else {
        $tracker = @{}
    }
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
    if ($tracker.ContainsKey($appName)) {
        $lastChecked = [datetime]::Parse($tracker[$appName].lastChecked)
        $hoursSinceCheck = ($now - $lastChecked).TotalHours
        
        # Skip if checked recently
        if ($hoursSinceCheck -lt $CheckIntervalHours) {
            continue
        }
        
        # Calculate priority score
        $updateFrequency = $tracker[$appName].updateFrequency
        $daysSinceUpdate = if ($tracker[$appName].lastUpdated) {
            ($now - [datetime]::Parse($tracker[$appName].lastUpdated)).TotalDays
        } else {
            365  # Never updated, high priority
        }
        
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
            Priority = 1000  # Very high priority for new apps
            LastChecked = $null
        }
    }
}

# Sort by priority (highest first) and take top N
$appsToCheck = $appsToCheck | Sort-Object Priority -Descending | Select-Object -First $MaxAppsPerRun

Write-Host "`nChecking $($appsToCheck.Count) apps this run:" -ForegroundColor Green
$appsToCheck | ForEach-Object { Write-Host "  - $($_.Name) (priority: $($_.Priority))" }

# Setup Scoop
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..." -ForegroundColor Yellow
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
}

# Add local bucket (using absolute path)
$bucketFullPath = Resolve-Path $BucketPath
Write-Host "Adding bucket from: $bucketFullPath" -ForegroundColor Yellow
scoop.cmd bucket add local "$bucketFullPath" 2>&1 | Out-Null

# Check each app
$updatedApps = @()
$checkedThisRun = @{}

foreach ($app in $appsToCheck) {
    if ($checkedThisRun.ContainsKey($app.Name)) {
        Write-Host "  Skipping $($app.Name) - already checked this run" -ForegroundColor Gray
        continue
    }
    
    Write-Host "`nChecking $($app.Name)..." -ForegroundColor Cyan
    
    try {
        # Run scoop checkver - need to use scoop.cmd on Windows
        $result = scoop.cmd checkver $app.Name --force 2>&1 | Out-String
        
        # Check if update is available
        if ($result -match "->") {
            Write-Host "  Update available!" -ForegroundColor Green
            
            # Parse new version
            if ($result -match "(\S+)\s+->\s+(\S+)") {
                $newVersion = $matches[2]
                Write-Host "  $($matches[1]) -> $newVersion" -ForegroundColor Green
                
                # Update tracker
                $tracker[$app.Name] = @{
                    lastChecked = $now.ToString("o")
                    lastUpdated = $now.ToString("o")
                    currentVersion = $newVersion
                    updateFrequency = 1.0
                }
                
                $updatedApps += $app.Name
            }
        } else {
            # No update found
            Write-Host "  No update available" -ForegroundColor Gray
            
            # Get current version from manifest
            $manifestContent = Get-Content $app.Path -Raw | ConvertFrom-Json
            $currentVersion = $manifestContent.version
            
            # Update tracker with last checked time
            if (-not $tracker.ContainsKey($app.Name)) {
                $tracker[$app.Name] = @{}
            }
            
            $tracker[$app.Name].lastChecked = $now.ToString("o")
            $tracker[$app.Name].currentVersion = $currentVersion
            
            # Adjust update frequency (reduce if no update)
            if ($tracker[$app.Name].updateFrequency) {
                $tracker[$app.Name].updateFrequency = [math]::Max(0.1, $tracker[$app.Name].updateFrequency * 0.95)
            } else {
                $tracker[$app.Name].updateFrequency = 0.5
            }
        }
    } catch {
        Write-Host "  Error checking $($app.Name): $_" -ForegroundColor Red
        
        # Still update tracker with error time
        if (-not $tracker.ContainsKey($app.Name)) {
            $tracker[$app.Name] = @{}
        }
        $tracker[$app.Name].lastChecked = $now.ToString("o")
        $tracker[$app.Name].updateFrequency = 0.1  # Low frequency for problematic apps
    }
    
    $checkedThisRun[$app.Name] = $true
    
    # Small delay to avoid rate limits
    Start-Sleep -Milliseconds 500
}

# Save tracker
$trackerJson = $tracker | ConvertTo-Json -Depth 3
Set-Content -Path $TrackerFile -Value $trackerJson

# Return results
Write-Host "`n=== Run Summary ===" -ForegroundColor Yellow
Write-Host "Checked: $($appsToCheck.Count) apps" -ForegroundColor Cyan
Write-Host "Updated: $($updatedApps.Count) apps" -ForegroundColor Green

if ($updatedApps.Count -gt 0) {
    Write-Host "Updated apps:" -ForegroundColor Green
    $updatedApps | ForEach-Object { Write-Host "  - $_" }
    
    # Signal that updates were made
    Write-Host "`nExit code: 100 (updates found)" -ForegroundColor Green
    exit 100
} else {
    Write-Host "`nExit code: 0 (no updates)" -ForegroundColor Gray
    exit 0
}
