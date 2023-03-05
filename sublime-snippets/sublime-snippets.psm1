

function _locateSublime {
    if(-not(get-command scoop -ErrorAction 'silentlycontinue')) {
        Write-Error "Scoop not found." 
    }
    $sublimeLocation = scoop which subl
    if ($sublimeLocation -match 'not found') {
        $sublimeLocation = get-command subl -ErrorAction 'silentlycontinue'
        if (-not($sublimeLocation)) {
            Write-Error "Sublime not found"
        }
    }
    $sublimeLocation = resolve-path $sublimeLocation | select -ExpandProperty Path
    Write-debug "Located Sublime at $sublimeLocation"
    split-path $sublimeLocation 
}

$_snippetsFile = 'sublime-snippets.knownSnippets'

function Import-Snippets {
    $ErrorActionPreference = 'stop'
    $userPath = resolve-path (join-path (_locateSublime) '\Data\Packages\User') | select -ExpandProperty Path
    Write-Debug "Sublime user directory found at $userPath"

    $inventory = join-path $userPath $_snippetsFile
    if (-not(test-path $inventory)) {
        '' | out-file -FilePath $inventory
    }
    $inventory = resolve-path $inventory
    Write-Debug "Inventory file is $inventory"
    $snippets = dir -Path $psscriptroot -Filter *.sublime-snippet -Recurse | select -ExpandProperty Name
    $existingSnippets = if (test-path $inventory) {
        get-content $inventory        
    } else {
        @()
    }
    $existingSnippets | % {
        Write-Debug "Checking if $_ exists"
        if (test-path (join-path $userPath $_)) {
            del (join-path $userPath $_)
            Write-host "Deleted $_"
        }
    }
    $snippets | %{
        Copy (join-path $psscriptroot $_) (join-path $userPath $_)
        Write-host "Copied $_ to $userPath"
    }
    $snippets | out-file -filepath $inventory
    Write-host "Wrote inventory to $inventory"
}

Export-ModuleMember -Function Import-snippets
