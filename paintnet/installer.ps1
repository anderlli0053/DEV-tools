$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Start-process -FilePath "$scriptPath\paint.net.4.0.12.install.exe" -ArgumentList "/auto `"TARGETDIR=$scriptPath`" DESKTOPSHORTCUT=0" -Wait
del $scriptPath\paint.net.4.0.12.install.exe