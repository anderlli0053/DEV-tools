if(!(test-path $profile)) {
    $profile_dir = split-path $profile
    if(!(test-path $profile_dir)) { mkdir $profile_dir > $null } 
    '' > $profile
}
$text = (gc $profile) -notmatch 'setenvforvs.ps1' 
$new_text = @($text) + "try { & 'setenvforvs.ps1'} catch { }"
$new_text > $profile
Write-host 'Adding Visual Studio environment init to your powershell profile'