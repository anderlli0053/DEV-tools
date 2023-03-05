param(
	[array]$bin,
	[array]$url,
	[Parameter(Mandatory=$true)]
	$version,
	[array]$shortcuts,
	$env_add_path,
	[array]$env_set,
	$extract_dir,
	$homepage,
	$license,
	[array]$bit32,
	[array]$bit64
)
$ErrorActionPreference = 'stop'
if (-not($url) -and -not($bit32 -and $bit64))
{
	Write-Error "Either specify an -url or -bit32/-bit64 parameters. I must have program code!"
}

$json = @{
	'version'=$version
}

if ($url) {
	$hashes = @()
	$url | % {
		$tempFile = [System.IO.Path]::GetTempFileName()
		iwr $_ -Outfile $tempFile
		$hashes += get-filehash $tempFile | select -expandproperty hash
	}
	$json['url'] = $url
	$json['hash'] = $hashes
}

function add($var, $name)
{
	if ($var) { $json[$name] = $var }
}

add $bin  'bin'
add $shortcuts 'shortcuts'
add $env_add_path 'env_add_path'
add $env_set 'env_set'
add $extract_dir 'extract_dir'
add $homepage 'homepage'
add $license 'license'

$json | Convertto-Json
