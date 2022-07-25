$programname = "Adobe Flash Player 32 PPAPI*"
$msiprogramname = "Adobe Flash Player 32 PPAPI"
if(Get-Package -Provider Programs -IncludeWindowsInstaller -Name "$programname" -ErrorAction SilentlyContinue)
{
   taskkill /F /IM $processname /FI 'status eq running'
   $id = wmic product where """name like '$msiprogramname%'""" get IdentifyingNumber | find /i """-"""
   Start-Process -Wait -WindowStyle Hidden cmd "/c msiexec /x $id /qn /norestart" -Verb RunAs
}
