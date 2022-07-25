Add-Type -AssemblyName System.IO.Compression

. "$PSScriptRoot\..\lib\json.ps1"

$BucketDir = "$PSScriptRoot\..\bucket"
if (!(Test-Path -Path $BucketDir)) {
    New-Item -Path $BucketDir -ItemType Directory
}
$TempFile = New-TemporaryFile

$PadURIs = [System.Collections.ArrayList]((Invoke-WebRequest "https://www.nirsoft.net/pad/pad-links.txt" -UseBasicParsing).Content -split "\n")
$PadURIs.Remove("")
# The following are bundles, not individual tools.
$PadURIs.Remove("http://www.nirsoft.net/pad/browsertools.xml")
$PadURIs.Remove("http://www.nirsoft.net/pad/domainlookuptools.xml")
$PadURIs.Remove("http://www.nirsoft.net/pad/networktools.xml")
$PadURIs.Remove("http://www.nirsoft.net/pad/outlooktools.xml")
$PadURIs.Remove("http://www.nirsoft.net/pad/progtools.xml")
$PadURIs.Remove("http://www.nirsoft.net/pad/regtools.xml")
$PadURIs.Remove("http://www.nirsoft.net/pad/systools.xml")
$PadURIs.Remove("http://www.nirsoft.net/pad/videoaudiotools.xml")
# The following are obsolete.
$PadURIs.Remove("http://www.nirsoft.net/pad/astlog.xml")
# The following have passwords and need to be updated manually.
$PadURIs.Remove("http://www.nirsoft.net/pad/chromepass.xml")
$PadURIs.Remove("http://www.nirsoft.net/pad/wirelesskeyview.xml")

foreach ($PadURI in $PadURIs) {
    Write-Output "Parsing $PadURI..."
    [xml]$Pad = (Invoke-WebRequest -Uri $PadURI -UseBasicParsing).Content

    $ProgramName = $Pad.XML_DIZ_INFO.Program_Info.Program_Name.Trim()
    $ShortDescription = (($Pad.XML_DIZ_INFO.Program_Descriptions.English.Char_Desc_45 -replace "[\n\r ]+", " ") -replace '["\*/:<>\?\\\|]+', "_").Trim().TrimEnd(".")
    if ($ShortDescription -eq "") {
        $LinkName = "NirSoft\$ProgramName"
    } else {
        $LinkName = "NirSoft\$ProgramName - $ShortDescription"
    }

    $JSON = [ordered]@{}
    $JSON.Add("homepage", ($Pad.XML_DIZ_INFO.Web_Info.Application_URLs.Application_Info_URL -replace "^http://", "https://"))
    $JSON.Add("checkver", "$ProgramName v(\d+\.\d\d)")
    $JSON.Add("version", $Pad.XML_DIZ_INFO.Program_Info.Program_Version)
    $JSON.Add("license", $Pad.XML_DIZ_INFO.Program_Info.Program_Type.ToLower())
    $JSON.Add("description", ($Pad.XML_DIZ_INFO.Program_Descriptions.English.Char_Desc_2000 -replace "[\n\r ]+", " ").Trim())

    $32URI = $Pad.XML_DIZ_INFO.Web_Info.Download_URLs.Primary_Download_URL -replace "^http://", "https://"
    $64URI = $32URI -replace "\.zip$", "-x64.zip"

    $Has64 = $False
    try {
        $Request = [System.Net.WebRequest]::Create($64URI)
        $Request.Referer = $JSON.homepage
        $Response = $Request.GetResponse()
        if ($Response.StatusCode -eq "OK") {
            $Has64 = $True
            $64Hash = (Get-FileHash -InputStream ($Response.GetResponseStream())).Hash.ToLower()
        }
    } catch {}

    $Has32 = $False
    try {
        $Request = [System.Net.WebRequest]::Create($32URI)
        $Request.Referer = $JSON.homepage
        $Response = $Request.GetResponse()
        if ($Response.StatusCode -eq "OK") {
            $Has32 = $True
            $32Hash = (Get-FileHash -InputStream ($Response.GetResponseStream())).Hash.ToLower()
        }
    } catch {}

    if ($Has32 -and $Has64) {
        $JSON.Add("architecture", [ordered]@{
            "64bit" = [ordered]@{
                "url" = $64URI
                "hash" = $64Hash
            }
            "32bit" = [ordered]@{
                "url" = $32URI
                "hash" = $32Hash
            }
        })
        $JSON.Add("autoupdate", [ordered]@{
            "architecture"=[ordered]@{
                "64bit" = [ordered]@{
                    "url" = $64URI
                }
                "32bit" = [ordered]@{
                    "url" = $32URI
                }
            }
        })
    } elseif ($Has64) {
        $JSON.Add("url", $64URI)
        $JSON.Add("hash", $64Hash)
        $JSON.Add("autoupdate", [ordered]@{
            "url" = $64URI
        })
    } elseif ($Has32) {
        $JSON.Add("url", $32URI)
        $JSON.Add("hash", $32Hash)
        $JSON.Add("autoupdate", [ordered]@{
            "url" = $32URI
        })
    } else {
        Write-Output "Something went seriously wrong. Skipping."
        continue
    }

    $Executable = "$ProgramName.exe"
    try {
        # Yes, I'm downloading the file a second time, but PowerShell doesn't
        # seem to provide any way to duplicate a stream, and downloading to
        # a file can trigger Windows antivirus detection.
        $Request = [System.Net.WebRequest]::Create($32URI)
        $Request.Referer = $JSON.homepage
        $Response = $Request.GetResponse()
        if ($Response.StatusCode -eq "OK") {
            $ZipFile = New-Object IO.Compression.ZipArchive($Response.GetResponseStream())
            $Executable = $ZipFile.Entries.Where({$_.Name -match "\.exe$"})[0].Name
        }
    } catch {}

    $JSON.Add("bin", $Executable)
    $JSON.Add("shortcuts", @(,
        @(
            $Executable,
            $LinkName
        )
    ))

    # Special case.
    if ($PadURI -eq "http://www.nirsoft.net/pad/usbdeview.xml") {
        $IDURI = "http://www.linux-usb.org/usb.ids"
        try {
            Invoke-WebRequest $IDURI -Headers @{"Referer" = $JSON.homepage} -OutFile $TempFile -UserAgent "Mozilla/5.0"
            $IDHash = (Get-FileHash -LiteralPath $TempFile).Hash.ToLower()
            if ($Has32 -and $Has64) {
                $JSON.architecture."64bit".url = @($64URI, $IDURI)
                $JSON.architecture."64bit".hash = @($64Hash, $IDHash)
                $JSON.architecture."32bit".url = @($32URI, $IDURI)
                $JSON.architecture."32bit".hash = @($32Hash, $IDHash)
            } elseif ($Has64) {
                $JSON.url = @($64URI, $IDURI)
                $JSON.hash = @($64Hash, $IDHash)
            } elseif ($Has32) {
                $JSON.url = @($32URI, $IDURI)
                $JSON.hash = @($32Hash, $IDHash)
            }
        } catch {}
    }

    $JSON | ConvertToPrettyJson | Out-File ("$BucketDir\" + ($ProgramName.ToLower() -replace " ", "") + ".json") -Encoding ascii
}

Remove-Item $TempFile.FullName -Force
