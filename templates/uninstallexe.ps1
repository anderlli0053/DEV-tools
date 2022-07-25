$programname = "programname*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFiles")
$processname = "process.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &"$ProgramFilesPath\program\uninstall.exe" /S | Out-Null
}
