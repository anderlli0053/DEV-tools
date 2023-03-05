param(
    $version = '3.2.5'
    )
$args = "/x `"$PSScriptRoot\Setup NcFTP $version.msi`" /qn"
Start-process -FilePath 'msiexec' -ArgumentList $args -Wait