$queryRaw = $args -join ' '
$query = [uri]::EscapeDataString($queryRaw)
start "http://ordbok.uib.no/perl/ordbok.cgi?OPP=$($query)&ant_bokmaal=5&ant_nynorsk=5&nynorsk=+&ordbok=nynorsk"
