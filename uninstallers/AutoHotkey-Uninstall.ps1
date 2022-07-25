$programname = "AutoHotkey*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFiles")
$processname = "AutoHotkey.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &\"$ProgramFilesPath\\AutoHotkey\\AutoHotkey.exe\" \"$ProgramFilesPath\\AutoHotkey\\Installer.ahk\" /Uninstall | Out-Null
}
