$programname = "Teamviewer*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFilesX86")
$processname = "teamviewer.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &"$ProgramFilesPath\TeamViewer\uninstall.exe" /S | Out-Null
}
