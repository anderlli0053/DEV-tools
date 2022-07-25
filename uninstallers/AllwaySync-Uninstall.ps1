$programname = "Allway Sync version*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFiles")
$processname = "syncappw.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   $uninstallpath = Get-ChildItem -Path "$ProgramFilesPath\Allway Sync\" | Where-Object {$_.Name -clike "unins*.exe"} | Write-Output -InputObject {$_.FullName}
   &"$uninstallpath" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART | Out-Null
}
