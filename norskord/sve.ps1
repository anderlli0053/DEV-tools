$queryRaw = $args -join ' '
$query = [uri]::EscapeDataString($queryRaw)
Start-Process "https://svenska.se/tre/?sok=$query"
