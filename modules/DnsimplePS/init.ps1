$ModuleName = 'DnsimplePS'
New-ModuleManifest -Path $PSScriptRoot\$ModuleName.psd1 -RootModule $PSScriptRoot\$ModuleName.psm1 `
    -PowerShellVersion 5.0 -Author 'Vidar Kongsli' -FormatsToProcess "$ModuleName.Format.ps1xml"