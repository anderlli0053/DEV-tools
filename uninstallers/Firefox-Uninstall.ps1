$programname = "Mozilla Firefox*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFiles")
$processname = "firefox.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &"$ProgramFilesPath\Mozilla Firefox\uninstall\helper.exe" -ms | Out-Null
}
