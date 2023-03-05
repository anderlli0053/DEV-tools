# -requires 3.0
param (
    [Parameter(Mandatory)]
    [ValidateSet('browse','clip')]
    $cmd
    )

function run ($url) {
    if ($cmd -eq 'browse' ){
        Write-host "Loading $url in browser"
        start $url
    } else {
        Write-host "Copy $url to clipboard"
        $url | clip
    }
}
$ErrorActionPreference = 'stop'
$remoteOriginUrl = git config --get remote.origin.url
if (-not($remoteOriginUrl)) {
    Write-error "Not in a git repo. You stupid git"
}
$match =  $remoteOriginUrl | select-string -Pattern "^git@(?<host>[^\:]+)\:(?<user>[^\/]+)\/(?<repo>.+?)\.git$" | select -Expand Matches | select -first 1
if (-not($match)) {
    $match = $remoteOriginUrl | select-string -Pattern "^https://(?<host>[^\/]+)\/(?<user>[^\/]+)\/(?<repo>.+?)\.git$" | select -Expand Matches | select -first 1
}

if ($match) {
    $repo = $match.Groups['repo']
    $user = $match.Groups['user']
    $ihost = $match.Groups['host']
    $url = "https://$ihost/$user/$repo"
    run $url
} else {
    # Try VSTS
    # ssh://felleskjopet@vs-ssh.visualstudio.com:22/DefaultCollection/felleskjopet.no/_ssh/identity
    
    $match =  $remoteOriginUrl | select-string -Pattern "^ssh://(?<host>[^@]+)@[^/]+/DefaultCollection/(?<project>[^/]+)/_ssh/(?<repo>.+)" | select -Expand Matches | select -first 1
    if ($match) {
        $repo = $match.Groups['repo']
        $project = $match.Groups['project']
        $ihost = $match.Groups['host']
        # https://felleskjopet.visualstudio.com/felleskjopet.no/_git/identity
        $url = "https://$($ihost).visualstudio.com/$project/_git/$repo"
        run $url
    } else {
        Write-error "Could not interpet remote.origin.url $remoteOriginUrl"
    }
}