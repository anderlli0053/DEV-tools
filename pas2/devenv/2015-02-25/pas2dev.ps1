#requires -v 3
param($cmd)
$ErrorPreference = 'stop'
if (!($cmd)) {
    Write-host "usage: pas2dev <command> [<args>]"
    Write-host ""
    Write-host "Hint: use command 'list' to list available commands"
    Write-error "Specify command"
}
$scoop_home = $env:SCOOP, (join-path $env:localappdata scoop) | select -first 1

$pas2bucket = join-path $scoop_home 'buckets\pas2'
if(!(test-path $pas2bucket)) {
    Write-error "PAS2 bucket not found ($pas2bucket)"
}
$pas2appsDirectory = join-path $pas2bucket devenv
$pas2apps = get-childitem -Path $pas2appsDirectory -Filter *.ps1 | %{ 
    new-object -TypeName PSObject -Property `
        (@{
            'Name'=$_.Name.Replace($_.Extension,'');
            'cmd'=$_.FullName
            })
}
$pas2AppsDic = @{}
foreach ($app in $pas2Apps) {
    $pas2AppsDic.Add($app.Name,$app.cmd)
}

if ($cmd -eq 'list') {
    "Available commands:"
    ""
    $pas2apps | % { "  " + $_.Name }
} else {
    if ($pas2AppsDic.Contains($cmd)) {
        & ($pas2AppsDic[$cmd]) @args
    } else {
        Write-error "Command: '$cmd' not found"
    }
}
