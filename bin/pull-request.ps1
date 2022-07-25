#!/usr/bin/env pwsh -c

<#
.DESCRIPTION
    Creates a GitHub pull request for a given branch if it doesn't already exist
    <https://docs.github.com/en/rest/pulls/pulls#create-a-pull-request>
.PARAMETER RepoOwner
    The GitHub repository owner to create the pull request against.
.PARAMETER RepoName
    The GitHub repository name to create the pull request against.
.PARAMETER BaseBranch
    The name of the branch you want the changes pulled into.
    This should be an existing branch on the current repository.
    You cannot submit a pull request to one repository that requests a merge to a base of another repository.
.PARAMETER PROwner
    The owner of the branch we want to create a pull request for.
.PARAMETER PRBranch
    The branch which we want to create a pull request for.
.PARAMETER AuthToken
    A personal access token
.PARAMETER PRTitle
    The title of the new pull request.
.PARAMETER PRBody
    The contents of the pull request.
.EXAMPLE
    > .\bin\pull-request.ps1 "Ryanjiena" "scoop-apps" "master" "Ryanjiena" "JaimeZeng/clash" "my-auth-token" "Amazing new feature" "Please pull these awesome changes in!"
.EXAMPLE
    > .\bin\pull-request.ps1 -PRBranch "pr-branch" -AuthToken "my-auth-token" "Amazing new feature" "Please pull these awesome changes in!"
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [String] $RepoOwner,
    [String] $RepoName,
    [String] $BaseBranch,
    [String] $PROwner,
    [Parameter(Mandatory = $true)]
    [String] $PRBranch,
    [Parameter(Mandatory = $true)]
    [String] $AuthToken,
    [Parameter(Mandatory = $true)]
    [String] $PRTitle,
    [Parameter(Mandatory = $true)]
    [String] $PRBody
)

if (!$RepoOwner) { $RepoOwner = "Ryanjiena" }
if (!$RepoName) { $RepoName = "scoop-apps" }
if (!$BaseBranch) { $BaseBranch = "master" }
if (!$PROwner) { $PROwner = $RepoOwner }

# confirm 'gh' is installed
if (!(scoop which gh)) {
    Write-Host "Please install gh 'scoop install gh'" -ForegroundColor Yellow
    exit 1
}

# # gh login with token
# $AuthToken | gh auth login --with-token


$headers = @{
    Authorization = "bearer $AuthToken"
}

$query = "state=open&head=${PROwner}:${PRBranch}&base=${BaseBranch}"

try {
    $resp = Invoke-RestMethod -Headers $headers "https://api.github.com/repos/$RepoOwner/$RepoName/pulls?$query"
} catch {
    Write-Error "Invoke-RestMethod [https://api.github.com/repos/$RepoOwner/$RepoName/pulls?$query] failed with exception:`n$_"
    exit 1
}
$resp | Write-Verbose

if ($resp.Count -gt 0) {
    Write-Host -f green "Pull request already exists $($resp[0].html_url)"
} else {
    $data = @{
        title                 = $PRTitle
        head                  = "${PROwner}:${PRBranch}"
        base                  = $BaseBranch
        body                  = $PRBody
        maintainer_can_modify = $true
    }

    try {
        $resp = Invoke-RestMethod -Method POST -Headers $headers `
            "https://api.github.com/repos/$RepoOwner/$RepoName/pulls" `
            -Body ($data | ConvertTo-Json)
    } catch {
        Write-Error "Invoke-RestMethod [https://api.github.com/repos/$RepoOwner/$RepoName/pulls] failed with exception:`n$_"
        exit 1
    }

    $resp | Write-Verbose
    Write-Host -f green "Pull request created https://github.com/$RepoOwner/$RepoName/pull/$($resp.number)"
}


# # gh auth logout
# Write-Output "Y" | gh auth logout --hostname github.com
