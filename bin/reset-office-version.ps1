$dir = "$psscriptroot\..\bucket"

$office = "$dir\office-365-apps-np.json"
(Get-Content "$office").Replace(': "office"', ': "0"') | Set-Content -Path "$office"

$office = "$dir\office-365-apps-minimal-np.json"
(Get-Content "$office").Replace(': "office"', ': "0"') | Set-Content -Path "$office"
