param (
	[Parameter(Mandatory)]
	[ValidateSet('init')]
	$cmd
)
$ErrorActionPreference = 'stop'

ssh -T git@github.com | out-null
if ($lastexitcode -eq 255) {
	Write-error "Could not log in to GitHub. Get your act together an install SSH keys"
}

if ($cmd -eq 'init') {
	
	if (test-path .\.git) {
		Write-error "Current directory is already a git repo."
	}
	git clone git@github.com:Utdanningsdirektoratet/PAS2-hoved.git
}
