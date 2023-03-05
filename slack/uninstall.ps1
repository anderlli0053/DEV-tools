
$exec = "$env:LOCALAPPDATA\slack\update.exe"
if (test-path $exec) {& $exec --uninstall }
