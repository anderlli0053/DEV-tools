$programname = "Zoom*"
$AppData = [Environment]::GetFolderPath("ApplicationData")
$processname = "Zoom.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &"$AppData\Zoom\uninstall\installer.exe" /uninstall /S | Out-Null
}
