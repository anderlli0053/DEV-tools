$programname = "qbittorrent*"
$ProgramFilesPath = [Environment]::GetFolderPath("ProgramFiles")
$processname = "qbittorrent.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &\"$ProgramFilesPath\\qBittorrent\\uninst.exe\" /S | Out-Null
}
