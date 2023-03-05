
$ErrorActionPreference ='stop'
get-command python -ErrorAction SilentlyContinue 2>&1 |out-null
if (!$?) {
    Write-error "Python not found. Installation problem..."
}

python (resolve-path (join-path $psscriptroot 'rabbitmqadmin')) @args