function IfNotInstalled($cmd, $block) {
	gcm $cmd -ErrorAction continue 2>&1 | out-null
	if (!$?) { & $block } else { Write-host "$cmd already available" }
}

IfNotInstalled 'scoop' { iex (new-object net.WebClient).DownloadString('https://get.scoop.sh') }
IfNotInstalled 'ssh' { scoop install openssh }
IfNotInstalled 'git' { scoop install git }