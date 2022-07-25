#!/usr/bin/env pwsh -c

if (!(scoop which gh)) {
    Write-Host "Please install hub 'scoop install gh'" -ForegroundColor Yellow
    exit 1
}

function parse_repo($RepoName) {

    $Parts = $RepoName.Split("/")
    $Result = @{}

    switch ($Parts.Length) {
        2 {
            $Result.Server = "github.com"
            $Result.Owner = $parts[0]
            $Result.Repo = $parts[1]
        }

        3 {
            $Result.Server = $parts[0]
            $Result.Owner = $parts[1]
            $Result.Repo = $parts[2]
        }

        default {
            throw "Invalid RepoName: $RepoName"
        }
    }

    return $Result
}

function login_with_token() {
    <#
    .DESCRIPTION
        Authenticate with a GitHub host.

    .PARAMETER GitProtocol
        The protocol to use for git operations.
        * https
        * ssh

    .PARAMETER AuthToken
        The GitHub auth token in the format of 'gho_xxxxxx'.
        The minimum required scopes for the token are: "repo", "read:org".

    .PARAMETER HostName
        The GitHub server to authenticate with.

    .LINK
        https://cli.github.com/manual/gh_auth_login

    .EXAMPLE
        login_with_token -GitProtocol "ssh" -AuthToken "gho_xxxxxx" -HostName "github.com"
    #>

    [ValidateSet("https", "ssh")]
    [String] $GitProtocol = "ssh",
    [Parameter(Mandatory = $true)]
    [ValidateScript( {
            if (!($_.StartsWith('gho_'))) {
                throw 'AuthToken must be start with: gho_'
            }
            $true
        })]
    [String] $AuthToken
    [Parameter(Mandatory = $true)]
    [String] $HostName = "github.com"

    $AuthToken | gh auth login --git-protocol $GitProtocol --hostname $HostName --with-token
}

function logout() {
    <#
    .DESCRIPTION
        Logout from a GitHub host.

    .PARAMETER HostName
        The GitHub server to authenticate with.

    .LINK
        https://cli.github.com/manual/gh_auth_logout

    .EXAMPLE
        > logout HostName "github.com"
    #>

    [String] $HostName

    Write-Output "Y" | gh auth logout --hostname $HostName
}

function list_pull_request() {
    <#
    .DESCRIPTION
        List Pull Request.

    .PARAMETER RepoName
        The name of the repository.(e.g. "Ryanjiena/Meta" or "github.com/Ryanjiena/Meta")

    .PARAMETER State
        To filter by state.(Default: 'open')
        * open
        * closed
        * all

    .PARAMETER Head
        Filter pulls by head user or head organization and branch name in the format of 'user:ref-name' or 'organization:ref-name'.
        e.g. 'github:new-script-format' or 'octocat:test-branch'.

    .PARAMETER Base
        Filter pulls by base branch name. e.g. 'master'.

    .PARAMETER Sort
        What to sort results by. (Default: 'created')
        * created
        * updated
        * popularity (comment count)
        * long-running (age, filtering by pulls updated in the last month)

    .PARAMETER Direction
        The direction of the sort. (Default: 'desc' when sort is 'created' or sort is not specified, otherwise 'asc'.)
        * asc
        * desc

    .PARAMETER PerPage
        Results per page (max 100) (Default: '30')

    .PARAMETER Page
        Page number of the results to fetch. (Default: '1')

    .LINK
        https://docs.github.com/en/rest/pulls/pulls#list-pull-requests

    .EXAMPLE
        > list_pull_request -RepoName "github.com/Ryanjiena/Meta" -State "open" -Head "JaimeZeng:clash" -Base "master" -Sort "created" -Direction "asc" -PerPage 10 -Page 1

    #>

    param(
        [Parameter(Mandatory = $true)]
        [String] $RepoName,
        [ValidateSet('open', 'closed', 'all')]
        [String] $State,
        [Parameter(Mandatory = $true)]
        [ValidateScript( {
                if (!($_ -match '^(.*):(.*)$')) {
                    throw 'Head must be in this format: <user>:<branch>'
                }
                $true
            })]
        [String] $Head,
        [Parameter(Mandatory = $true)]
        [String] $Base,
        [ValidateSet('created', 'updated', 'popularity', 'long-running')]
        [String] $Sort,
        [ValidateSet('asc', 'desc')]
        [String] $Direction,
        [Parameter(Mandatory = $true)]
        [Int64] $PerPage,
        [Parameter(Mandatory = $true)]
        [Int64] $Page
    )

    $Result = parse_repo $RepoName

    $Owner = $Result.Owner
    $Repo = $Result.Repo

    $Response = (gh api -X GET repos/$Owner/$Repo/pulls -f head="$Head" -f state="$State" -f base="$Base" -f sort="$Sort" -f direction="$Direction" -f per_page=$PerPage -f page=$Page | ConvertFrom-Json )

    if ($Response.html_url.length -ne 0) {
        Write-Host "Pull Request : '$Response.html_url'" -ForegroundColor Green
    }
}

function create_pull_request() {
    <#
    .DESCRIPTION
        Create Pull Request.

    .PARAMETER RepoName
        The name of the repository.(e.g. "Ryanjiena/Meta" or "github.com/Ryanjiena/Meta")

    .PARAMETER Title
        The title of the new pull request.

    .PARAMETER Head
        The name of the branch where your changes are implemented. For cross-repository pull requests in the same network, namespace head with a user like this: `username:branch`.

    .PARAMETER Base
        The name of the branch you want the changes pulled into. This should be an existing branch on the current repository. You cannot submit a pull request to one repository that requests a merge to a base of another repository.

    .PARAMETER Body
        The contents of the pull request.

    .PARAMETER Modify
        Indicates whether maintainers can modify the pull request.

    .PARAMETER Draft
        Indicates whether the pull request is a draft.

    .PARAMETER Issue
        The issue number of the existing issue on which to create the pull request.

    .LINK
        https://docs.github.com/en/rest/pulls/pulls#create-a-pull-request

    .EXAMPLE
        > create_pull_request -RepoName "github.com/Ryanjiena/Meta" -Title "New Script Format" -Head "JaimeZeng:clash" -Base "master" -Body "This is a new script format." -Modify $true -Draft $false -Issue 9
    #>

    [Parameter(Mandatory = $true)]
    [String] $RepoName,
    [Parameter(Mandatory = $true)]
    [String] $Title,
    [Parameter(Mandatory = $true)]
    [String] $Head,
    [Parameter(Mandatory = $true)]
    [String] $Base,
    [Parameter(Mandatory = $true)]
    [String] $Body,
    [Parameter(Mandatory = $true)]
    [Switch] $Modify,
    [Parameter(Mandatory = $true)]
    [Switch] $Draft

    $Result = parse_repo $RepoName
    $Server = $Result.Server
    $Owner = $Result.Owner
    $Repo = $Result.Repo

    # return (gh api --method POST repos/$Owner/$Repo/pulls -f title="$Title" -f head="$Head" -f base="$Base" -f body="$Body" -f maintainer_can_modify="$Modify" -f draft="$Draft" | ConvertFrom-Json )

    $getParams = @(
        "--repo $Server/$Owner/$Repo",
        "--title '$Title'",
        "--head $Head",
        "--base $Base",
        "--body '$Body'"
    )
    if (!$Modify) { $Params += "--no-maintainer-edit" }
    if ($Draft) { $Params += "--draft" }

    $Params = ($getParams -join ' ')
    gh pr create $Params

}
