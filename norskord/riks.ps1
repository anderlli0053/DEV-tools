$queryRaw = $args -join ' '
$query = [uri]::EscapeDataString($queryRaw)
Start-Process "https://www.naob.no/s%C3%B8k/$query"
