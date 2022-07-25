$programname = "programname*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFiles")
$processname = "processname.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   $uninstallpath = Get-ChildItem -Path "$ProgramFilesPath\ProgramPath\" | Where-Object {$_.Name -clike "unins*.exe"} | Write-Output -InputObject {$_.FullName}
   &"$uninstallpath" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART | Out-Null
}
