<#PSScriptInfo

.Version
    1.0
.Guid
    cb90dc28-8ba0-425f-9176-835540937079
.Author 
    Thomas J. Malkewitz @dotps1
.Tags 
    Guid, Uninstall, Registry
.ProjectUri
    https://github.com/dotps1/PSFunctions
.ReleaseNotes
    Initial Release.

#>

<#

.Synopsis
    Gets the uninstall string for a program.
.Description
    Gets the uninstall string for a program, can be filtered to a key word of the programs display name.
.Inputs
    System.String
.Outputs
    System.Management.Automation.PSCustomObject
.Parameter Name
    System.String
    The DisplayName of the software.
.Parameter Filter
    System.String
    Filter output based on the DisplayName property.
.Parameter ShowNulls
    System.Management.Automation.SwitchParameter
    Returns software products with empty uninstall values.
.Example
    PS C:\> Get-ProgramUninstallString -Name "Google Chrome"
    
    Name          Version       Guid                                   UninstallString
    ----          -------       ----                                   ---------------
    Google Chrome 57.0.2987.110 {4F711ED6-6E14-3607-A3CA-E3282AFE87B6} MsiExec.exe /X{4F711ED6-6E14-3607-A3CA-E3282AFE87B6}
.Example
    PS C:\> Get-ProgramUninstallString -Filter "Google*"

    Name                 Version       Guid                                   UninstallString
    ----                 -------       ----                                   ---------------
    Google Chrome        57.0.2987.110 {4F711ED6-6E14-3607-A3CA-E3282AFE87B6} MsiExec.exe /X{4F711ED6-6E14-3607-A3CA-E3282AFE87B6}
    Google Update Helper 1.3.32.7      {60EC980A-BDA2-4CB6-A427-B07A5498B4CA} MsiExec.exe /I{60EC980A-BDA2-4CB6-A427-B07A5498B4CA}
.Notes
    None.
.Link
    https://dotps1.github.io
.Link
    https://www.powershellgallery.com/packages/Get-ProgramUninstallString
.Link
    https://grposh.github.io

#>


[CmdletBinding(
    DefaultParameterSetName = "ByName"
)]
[OutputType(
    [PSCustomObject]
)]

param (
    [Parameter(
        ParameterSetName = "ByName",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias(
        "DisplayName"
    )]
    [String[]]
    $Name,

    [Parameter(
        ParameterSetName = "ByFilter"
    )]
    [String]
    $Filter = "*",

    [Parameter()]
    [Switch]
    $ShowNulls
)

begin {
    try {
        if (Test-Path -Path "HKLM:\SOFTWARE\WOW6432Node") {
            $programs = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction Stop
        }
        $programs += Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction Stop
        $programs += Get-ItemProperty -Path "Registry::\HKEY_USERS\*\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
    } catch {
        Write-Error $_
        break
    }
}

process {
    if ($PSCmdlet.ParameterSetName -eq "ByName") {
        foreach ($nameValue in $Name) {
            $programs = $programs.Where({ 
                $_.DisplayName -eq $nameValue
            })
        }
    } else {
        $programs = $programs.Where({ 
            $_.DisplayName -like "*$Filter*" 
        })
    }

    if ($null -ne $programs) {
        if (-not ($ShowNulls.IsPresent)) {
            $programs = $programs.Where({
                -not [String]::IsNullOrEmpty(
                    $_.UninstallString
                )
            })
        }

        $output = $programs.ForEach({
            [PSCustomObject]@{
                Name = $_.DisplayName
                Version = $_.DisplayVersion
                Guid = $_.PSChildName
                UninstallString = $_.UninstallString
            }
        })

        Write-Output -InputObject $output
    }
}
