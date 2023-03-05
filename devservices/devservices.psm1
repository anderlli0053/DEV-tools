
function start-devservices {
    sudo { start-service mss* ; start-service w3svc }
}

set-alias -Name devstart -Value start-devservices

function stop-devservices {
    sudo { start-service mss* ; start-service w3svc }
}

set-alias -Name devstop -Value stop-devservices

Export-ModuleMember -Function start-devservices,stop-devservices -Alias devstop,devstart