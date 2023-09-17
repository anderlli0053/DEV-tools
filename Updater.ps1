$rootDirectory = "C:\Users\ander\Desktop\buckets"

# Function to traverse directories recursively
function TraverseDirectories($path) {
    $directories = Get-ChildItem -Path $path -Directory

    foreach ($directory in $directories) {
        $githubDirectory = Join-Path -Path $directory.FullName -ChildPath ".git"
        if (Test-Path -Path $githubDirectory) {
            Write-Host "Updating repository in $($directory.FullName)"
            Set-Location -Path $directory.FullName
            git pull
            Write-Host
        }

        TraverseDirectories -path $directory.FullName
    }
}

# Start traversing
TraverseDirectories -path $rootDirectory
Pause