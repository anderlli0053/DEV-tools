$programname = "Microsoft Teams*"
$UserLocalAppData = [Environment]::GetFolderPath("LocalApplicationData")
$processname = "Update.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &\"$UserLocalAppData\Microsoft\Teams\Update.exe" --uninstall -s | Out-Null
}
