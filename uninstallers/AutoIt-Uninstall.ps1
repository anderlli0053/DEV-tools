$programname = "AutoIt v*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFilesX86")
$processname = "AutoIt3.exe"
$processname2 = "AutoIt3_x64.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   taskkill /F /IM $processname2 /FI 'status eq running'
   &\"$ProgramFilesPath\\AutoIt3\\uninstall.exe\" /S | Out-Null
}
