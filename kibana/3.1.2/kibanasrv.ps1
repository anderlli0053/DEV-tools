<#
    Install, starts, stops, and removes Windows Service for Kibana. 
#>
param(
	[Parameter(Mandatory=$true,Position=1)]
	[ValidateSet('install','start','stop','remove')]
	$command,
	[Parameter(Mandatory=$false,Position=2)]
	$serviceName = 'kibana'
)
$ErrorActionPreference = 'Stop'

# Ensure backwards compatability
$PSScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { split-path $MyInvocation.MyCommand.Path }

if ($command -eq 'install') {
	get-service $serviceName -ErrorAction 'SilentlyContinue' | out-null
    if ($?) {
        Write-Error 'Kibana service already exists. So quitting.'
    }

    $nginxInstallDir = split-path (scoop which nginx)
    if (-not(test-path -Path $nginxInstallDir -PathType Container)) {
        Write-Error "Nginx installation not found. Please install with 'sudo scoop install nginx --global'"
    }

    if (-not(test-path -Path "$PSScriptRoot\mime.types" -PathType Leaf)) {
        copy-item "$nginxInstallDir\conf\mime.types" $PSScriptRoot | out-null
    }

    $logsDirectory = "$PSScriptRoot\logs"
    if (-not(test-path -Path $logsDirectory -PathType Container)) { mkdir $logsDirectory | out-null }
    $tempDirectory = "$PSScriptRoot\temp"
    if (-not(test-path -Path $tempDirectory -PathType Container)) { mkdir $tempDirectory | out-null }
        
    sudo nssm install $serviceName nginx -c nginx.conf
    Write-host "Setting application directory to $PSScriptRoot"
    sudo nssm set $serviceName AppDirectory $PSScriptRoot 2>&1 | out-null
    sudo nssm set $serviceName AppStdout "$logsDirectory\stdout.log" 2>&1 | out-null
    sudo nssm set $serviceName AppStderr "$logsDirectory\stderr.log" 2>&1 | out-null
    Write-host "Created service $serviceName. To start service, type: $(split-path $MyInvocation.MyCommand.Path -Leaf) start"
	Exit 0
}

get-service $serviceName -ErrorAction 'SilentlyContinue' | out-null
if (!$?) {
    Write-Error "Kibana service with name '$serviceName' not found. So quitting."
}

if (@('start','stop') -contains $command) {
    sudo nssm $command $serviceName
    if ($command -eq 'start') {
        Write-host "Started kibana service. Visit UI at http://localhost:8080"
    }
    Exit 0
}

if ($command -eq 'remove') {
    sudo nssm remove $serviceName confirm
    Exit 0
}

# You should not get here!
Write-error "Something when awry. I don't know the command $command"
