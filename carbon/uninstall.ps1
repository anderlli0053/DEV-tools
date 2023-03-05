remove-module carbon -ErrorAction SilentlyContinue
if (-not(test-path $profile)) {
    Exit 0
}

$prof = (get-content $profile) -notmatch 'import-carbon.ps1'
$prof > $profile