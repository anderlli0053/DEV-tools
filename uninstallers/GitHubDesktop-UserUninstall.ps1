$programname = "GitHub Desktop*"
$LocalApplicationData = [Environment]::GetFolderPath("LocalApplicationData")
$processname = "GitHubDesktop.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &"$LocalApplicationData\GitHubDesktop\Update.exe" --uninstall -s | Out-Null
}
