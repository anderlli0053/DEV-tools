$programname = "MPC-BE*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFiles")
$processname = "mpc-be64.exe"
$processname2 = "mpc-be86.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   taskkill /F /IM $processname2 /FI 'status eq running'
   if (Test-Path "$ProgramFilesPath\MPC-BE x64\") {$uninstallpath = Get-ChildItem -Path "$ProgramFilesPath\MPC-BE x64\" | Where-Object {$_.Name -clike "unins*.exe"} | Write-Output -InputObject {$_.FullName}}
   if (Test-Path "$ProgramFilesPath\MPC-BE x86\") {$uninstallpath = Get-ChildItem -Path "$ProgramFilesPath\MPC-BE x86\" | Where-Object {$_.Name -clike "unins*.exe"} | Write-Output -InputObject {$_.FullName}}
   &"$uninstallpath" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART | Out-Null
}
