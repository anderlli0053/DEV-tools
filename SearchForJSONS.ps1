<#
.SYNOPSIS
Searches for JSON files in subdirectories, counts them, and copies them to a separate folder.

.DESCRIPTION
This PowerShell script searches for JSON files in the current directory and its subdirectories. It counts the number of JSON files found and then copies them to a separate folder named "JSONS" located at the same location as the script. If there are any filename conflicts during the copying process, the script renames the conflicting files by appending numbers to the filenames.

.NOTES
- Make sure to place this script in the directory where you want to start the search for JSON files.
- If the "JSONS" folder already exists, the script will copy the JSON files into that folder without overwriting any existing files.

.EXAMPLE
.\json_search.ps1
Runs the script to search for JSON files, count them, and copy them to the "JSONS" folder.

#>

# Define the root directory to search for JSON files
$rootDirectory = Get-Location

# Create the JSONS folder if it doesn't exist
$jsonsFolder = Join-Path -Path $rootDirectory -ChildPath "JSONS"
if (-not (Test-Path -Path $jsonsFolder)) {
    New-Item -ItemType Directory -Path $jsonsFolder | Out-Null
}

# Search for JSON files in subdirectories
$jsonFiles = Get-ChildItem -Path $rootDirectory -Recurse -Filter "*.json"

# Count the number of JSON files found
$jsonCount = $jsonFiles.Count

# Print the count of JSON files found
Write-Host "Number of JSON files found: $jsonCount"

# Copy the JSON files to the JSONS folder
$jsonFiles | ForEach-Object -Begin {
    $progressPreference = 'SilentlyContinue'  # Disable progress stream
    $progress = 0
    $totalProgress = $jsonFiles.Count
    $progressBar = New-Object -TypeName System.Windows.Forms.ProgressBar
    $progressForm = New-Object -TypeName System.Windows.Forms.Form
    $progressLabel = New-Object -TypeName System.Windows.Forms.Label

    $progressLabel.Text = "Copying JSON files..."
    $progressForm.Controls.Add($progressLabel)
    $progressForm.Controls.Add($progressBar)
    $progressForm.Text = "Progress"
    $progressForm.Width = 300
    $progressForm.Height = 100
    $progressForm.StartPosition = 'CenterScreen'
    $progressBar.Width = 280
    $progressBar.Height = 20
    $progressBar.Left = 10
    $progressBar.Top = 30
    $progressBar.Minimum = 0
    $progressBar.Maximum = $totalProgress
    $progressForm.Show()
} -Process {
    $sourcePath = $_.FullName
    $destinationPath = Join-Path -Path $jsonsFolder -ChildPath $_.Name
    
    # Handle filename conflicts
    $counter = 1
    while (Test-Path -Path $destinationPath) {
        $destinationPath = Join-Path -Path $jsonsFolder -ChildPath ("{0}_({1}){2}" -f $_.BaseName, $counter, $_.Extension)
        $counter++
    }
    
    Copy-Item -Path $sourcePath -Destination $destinationPath -Force
    
    # Update progress bar
    $progress++
    $progressBar.Value = $progress
    $progressForm.Refresh()
} -End {
    $progressForm.Close()
}

# Print the path of the JSONS folder
Write-Host "JSON files copied to: $jsonsFolder"
