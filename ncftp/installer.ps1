param(
    $version = '3.2.5'
    )
$args = "/i `"$PSScriptRoot\Setup NcFTP $version.msi`" TARGETDIR=`"$PSScriptRoot`" /qn"
Start-process -FilePath 'msiexec' -ArgumentList $args -Wait
