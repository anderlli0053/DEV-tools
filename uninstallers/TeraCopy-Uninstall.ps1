$programname = "TeraCopy*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFiles")
$processname = "TeraCopy.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   $uninstallpath = Get-ChildItem -Path "$ProgramFilesPath\TeraCopy\" | Where-Object {$_.Name -clike "unins*.exe"} | Write-Output -InputObject {$_.FullName}
   &"$uninstallpath" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART | Out-Null
}
