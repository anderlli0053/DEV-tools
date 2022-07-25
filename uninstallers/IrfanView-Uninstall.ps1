$programname = "IrfanView*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFiles")
$processname = "i_view64.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &"$ProgramFilesPath\IrfanView\iv_uninstall.exe" /silent
}
