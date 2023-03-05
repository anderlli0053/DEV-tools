#Requires -RunAsAdministrator
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

    $kibanaAppFile = "$PSScriptRoot\bin\kibana.bat"

    $logsDirectory = "$PSScriptRoot\logs"
    if (-not(test-path -Path $logsDirectory -PathType Container)) { mkdir $logsDirectory | out-null }
        
    nssm install $serviceName $kibanaAppFile
    Write-host "Setting application directory to $PSScriptRoot"
    nssm set $serviceName AppDirectory "$PSScriptRoot\bin" 2>&1 | out-null
    nssm set $serviceName AppStdout "$logsDirectory\stdout.log" 2>&1 | out-null
    nssm set $serviceName AppStderr "$logsDirectory\stderr.log" 2>&1 | out-null
    Write-host "Created service $serviceName. To start service, type: $(split-path $MyInvocation.MyCommand.Path -Leaf) start"
	Exit 0
}

get-service $serviceName -ErrorAction 'SilentlyContinue' | out-null
if (!$?) {
    Write-Error "Kibana service with name '$serviceName' not found. So quitting."
}

if (@('start','stop') -contains $command) {
    nssm $command $serviceName
    if ($command -eq 'start') {
        Write-host "Started kibana service. Visit UI at http://localhost:5601"
    }
    Exit 0
}

if ($command -eq 'remove') {
    nssm remove $serviceName confirm
    Exit 0
}

# You should not get here!
Write-error "Something when awry. I don't know the command $command"
