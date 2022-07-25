$programname = "balenaEtcher*"
$LocalApplicationData = [Environment]::GetFolderPath("LocalApplicationData")
$processname = "balenaEtcher.exe"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   &"$LocalApplicationData\Programs\balena-etcher\Uninstall balenaEtcher.exe" /S
   Start-Sleep -s 10
}
