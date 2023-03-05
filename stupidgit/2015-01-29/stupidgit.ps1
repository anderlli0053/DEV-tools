# -requires 3.0
param (
    [Parameter(Mandatory)]
    [ValidateSet('browse')]
    $cmd
    )

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
    start $url
} else {
    Write-error "Could not interpet remote.origin.url $remoteOriginUrl"
}