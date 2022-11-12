param(
    [Parameter(Mandatory = $true)][string]$appName
)
python3 $PSScriptRoot\scoop_search.py $appName
