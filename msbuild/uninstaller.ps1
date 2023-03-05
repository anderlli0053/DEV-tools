if (-not(test-path $profile)) {
    Exit 0
}

$prof = (get-content $profile) -notmatch 'setenvforvs.ps1'
$prof > $profile