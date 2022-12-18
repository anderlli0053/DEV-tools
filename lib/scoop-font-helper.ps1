function Get-FontInfo([System.IO.FileInfo] $file, $index) {
    $job = Start-Job -ScriptBlock {
        Add-Type -AssemblyName PresentationCore
        $uri = [UriBuilder]::new($using:file.FullName)
        $uri.Fragment = $using:index
        $font = [Windows.Media.GlyphTypeface]::new($uri.Uri)
        return @{
            'FamilyName' = $font.FamilyNames['en-US']
            'FaceName' = $font.FaceNames['en-US']
            'Win32FamilyName' = $font.Win32FamilyNames['en-US']
            'Win32FaceName' = $font.Win32FaceNames['en-US']
        }
    }
    Wait-Job -Job $job | Out-Null
    $ret = Receive-Job $job
    Remove-Job $job
    return $ret
}

function Get-NumberOfFonts([System.IO.FileInfo] $file) {
    try {
        $fr = [System.IO.File]::Open($file.FullName,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite + [System.IO.FileShare]::Delete)
        $br = [System.IO.BinaryReader]::new($fr)
        $br.ReadBytes(4+2+2) | Out-Null
        $b = $br.ReadBytes(4)
        if ([BitConverter]::IsLittleEndian) {
            [Array]::Reverse($b)
        }
        $ret = [BitConverter]::ToUInt32($b, 0)
    } finally {
        if ($br -ne $null) {
            $br.Close()
        }
        if ($fr -ne $null) {
            $fr.Close()
        }
    }
    return $ret
}

function Get-OTFName([System.IO.FileInfo] $file) {
    $fontInfo = Get-FontInfo $file
    return "$($fontInfo.Win32FamilyName) $($fontInfo.Win32FaceName) (OpenType)"
}

function Get-TTFName([System.IO.FileInfo] $file) {
    $fontInfo = Get-FontInfo $file
    return "$($fontInfo.Win32FamilyName) $($fontInfo.Win32FaceName) (TrueType)"
}

function Get-TTCName([System.IO.FileInfo] $file) {
    $numFonts = Get-NumberOfFonts($file)
    $i = 0
    $fontList = @()
    while ($i -lt $numFonts) {
        $fontInfo = Get-FontInfo $file $i
        if ("$($fontInfo.FamilyName) $($fontInfo.FaceName)" -eq $fontInfo.Win32FamilyName) {
            $fontList += $fontInfo.Win32FamilyName
        } else {
            $fontList += "$($fontInfo.Win32FamilyName) $($fontInfo.Win32FaceName)"
        }
        $i++
        if (($fontList -join ' & ').Length -gt 255) {
            break
        }
    }
    $fontName = $fontList -join ' & '
    if ($i -eq $numFonts) {
        $fontName += ' (TrueType)'
    }
    return $fontName
}

function Get-FontName([System.IO.FileInfo] $file) {
    if ($_.Extension -eq '.otf') {
        $fontName = Get-OTFName($file)
    } elseif ($_.Extension -eq '.ttf') {
        $fontName = Get-TTFName($file)
    } elseif ($_.Extension -eq '.ttc') {
        $fontName = Get-TTCName($file)
    }
    return $fontName
}

function Install-Font($dir) {
    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    New-Item $fontsDir -ItemType Directory -ErrorAction SilentlyContinue
    Get-ChildItem $dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontFile = "$fontsDir\$($_.Name)"
        Remove-Item $fontFile -ErrorAction SilentlyContinue
        if (Test-Path $fontFile) {
            error "Couldn't remove '$fontFile'; it may be in use."
            exit 1
        }
        Copy-Item $_.FullName -Destination $fontsDir
    }
    Get-ChildItem $dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontName = Get-FontName($_)
        info "Installing font $($_.Name) -> $fontName"
        $fontFile = "$fontsDir\$($_.Name)"
        New-ItemProperty -Path $regPath -Name $fontName -Value $fontFile -Force | Out-Null
    }
}

function Uninstall-Font($dir) {
    if (!(is_admin)) { warn 'Use sudo' }
    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    Get-ChildItem $dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontName = Get-FontName($_)
        info "Uninstalling font $($_.Name) -> $fontName"
        Remove-ItemProperty -Path $regPath -Name $fontName -ErrorAction SilentlyContinue
    }
    if ((Get-Service 'FontCache').Status -eq 'Running') {
        info 'Stop FontCache service (stop the service manually as needed)'
        if (is_admin) {
            Stop-Service FontCache
        }
        (Get-Service 'FontCache').WaitForStatus('Stopped', [TimeSpan]::New(0, 1, 0, 0))
    }
    Get-ChildItem $dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontFile = "$fontsDir\$($_.Name)"
        Remove-Item $fontFile -ErrorAction SilentlyContinue
        if (Test-Path $fontFile) {
            warn "Couldn't remove '$fontFile'; it may be in use."
        }
    }
}
