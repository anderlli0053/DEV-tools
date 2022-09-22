#include unzip.ps1

$target = "$dir\jdk-8u65-windows-x64.exe"
unzip $target $dir

@('Tools.zip', 'installerexe') | % { unzip "$dir\$_" $dir }

while (1) {
    try {
		Write-Host "Listing *.pack files"
        [array] $files = dir -Recurse "$dir\*.pack" | Select -Expand FullName
		if ($files.Length -gt 0) {
			$files | % {
				$fp = $_
				$o = [IO.Path]::ChangeExtension($fp, 'jar')
				Write-Host "Unpacking $fp"
				& "$dir\bin\unpack200.exe" $fp $o
				Remove-Item $fp
			}
		}
        break
    } catch {
		# It seems listing the *.pack files will get `Access denied` error initially, but will succeed after a while
		$interval = 5
        Write-Warning "$($_.Exception.Message), retrying in $interval seconds"
        Start-Sleep -seconds $interval
    }
}
