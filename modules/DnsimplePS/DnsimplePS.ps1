
function BaseUri($Account) {
    "https://api.dnsimple.com/v2/$Account/"
}

function RecordsUri($Account, $Zone) {
    "$(BaseUri $Account)zones/$Zone/records"
}

function RecordUri($Account, $Zone, $id) {
    "$(RecordsUri $Account $Zone)/$Id"
}

function ToClearText([System.Security.SecureString] $Token) {
    (new-object PSCredential 'doesntmatter',$Token).GetNetworkCredential().Password
}

function CreateHeaders($Token) {
    @{'Authorization'="Bearer $(ToClearText $Token)"}
}

<#
.SYNOPSIS Retrieves records for a certain zone

.DESCRIPTION Retrieves records for a certain zone

#> 
function Get-ZoneRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        $Zone,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName=$true)]
        $Account,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName=$true)]
        [System.Security.SecureString]$AccessToken,
        [Parameter(Mandatory=$false,ParameterSetName='ListRecords')]
        [ValidateSet('A','ALIAS','CNAME','MX','SPF','URL','TXT','NS','SRV','NAPTR','PTR','AAAA','SSHFP','HINFO','POOL','CAA')]
        $RecordType,
        [Parameter(Mandatory=$false,ParameterSetName='ListRecords')]
        $Name,
        [Parameter(Mandatory=$false,ParameterSetName='ListRecords')]
        $NameLike,
        [Parameter(Mandatory,ParameterSetName='ListRecords')]
        [switch]$Search,
        [Parameter(Mandatory,ParameterSetName='ById')]
        $Id
        )
    $old__errPref = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'stop'
        if (-not($Search)) {
            Invoke-RestMethod -Method GET -Uri (RecordUri $Account $Zone $Id) -Headers (CreateHeaders $AccessToken) `
                | Select-Object -ExpandProperty data
        } else {
            $Uri = "$(BaseUri $Account)zones/$Zone/records"
            $query = @{}
            if ($RecordType) { $query.Add('type',$RecordType) }
            if ($Name) { $query.Add('name', $Name) }
            if ($NameLike) { $query.Add('name_like', $NameLike) }
            if ($query.Count -gt 0) {
                $qRaw = ($query.Keys | ForEach-Object { "$_=$([Uri]::EscapeDataString($query[$_]))" }) `
                    -join '&'
                $Uri += "?$qRaw"
            }
            Write-Debug "Requesting: GET $Uri"
            Invoke-RestMethod -Method Get -Uri $Uri -Headers (CreateHeaders $AccessToken) -UseBasicParsing `
                | Select-Object -ExpandProperty data
        }
    } finally {
        $ErrorActionPreference = $old__errPref
    }
}

function Add-ZoneRecord {
    param(
        [Parameter(Mandatory,Position=0)]
        $Zone,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName=$true)]
        $Account,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName=$true)]
        [System.Security.SecureString]$AccessToken = $null,
        [Parameter(Mandatory)]
        [ValidateSet('A','ALIAS','CNAME','MX','SPF','URL','TXT','NS','SRV','NAPTR','PTR','AAAA','SSHFP','HINFO','POOL','CAA')]
        $RecordType,
        [Parameter(Mandatory)]
        $Name,
        [Parameter(Mandatory)]
        $Content
        )

    $data = [pscustomobject]@{
        'name' = $Name
        'content' = $Content
        'type' = $RecordType
    } | ConvertTo-Json

    $uri = RecordsUri $Account $Zone
    Write-Debug "Calling Uri $uri with payload $data"

    Invoke-RestMethod -Method POST -Uri $uri -Headers (CreateHeaders $AccessToken) `
        -Body $data -ContentType 'application/json' `
        | Select-Object -ExpandProperty data
}

function Remove-ZoneRecord {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory,Position=0)]
        $Zone,
        [Parameter(Mandatory,Position=1)]
        $Id,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName=$true)]
        $Account,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName=$true)]
        [System.Security.SecureString]$AccessToken
        )

    if ($PsCmdLet.ShouldProcess($Id)) {
        $Uri = RecordUri $Account $Zone $Id
        Write-Debug "Requesting: DELETE $Uri"
        Invoke-WebRequest -Method DELETE -Uri $Uri -Headers (CreateHeaders $AccessToken) `
            | select-object StatusCode,StatusDescription
    }
}

function Get-AccessToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $clientId,
        [Parameter(Mandatory)]
        $clientSecret
        )

    $ie = new-object -ComObject InternetExplorer.application
    $ie.Height = 480
    $ie.Width = 640
    $ie.ToolBar = $false
    $ie.StatusBar = $false
    $ie.TheaterMode = $false
    $ie.AddressBar = $false
    $ie.Silent = $false
    $state = Get-Random
    $ie.Navigate("https://dnsimple.com/oauth/authorize?response_type=code&client_id=$clientId&state=$state&redirect_uri=https://github.com/vidarkongsli/vidars-scoop-bucket")
    $ie.Visible = $true
    while (-not($ie.LocationUrl -match "error=[^&]*|code=[^&]*") -and $ie.Visible -eq $true)
    {
        Start-Sleep -Milliseconds 200
    }
    $query = ($ie.LocationUrl -split '\?')[-1] -split '\&'
    $codeParameter = $query | Where-Object { $_ -match '^code=' }
    $ie.Quit()
    if ($codeParameter) {
        $code = $codeParameter.Replace('code=','')
    } else {
        $error = $query | Where-Object { $_ -match '^error=' }
        $errorDescription = $query | Where-Object { $_ -match '^error_description=' }
        Write-error "No code found. Error: $error, $errorDescription"
    }
    invoke-restmethod -Method POST -Uri 'https://api.dnsimple.com/v2/oauth/access_token' `
        -Body @{
            'grant_type'='authorization_code'
            'client_id'=$clientId
            'client_secret'=$clientSecret
            'code'=$code
            'redirect_uri'='https://github.com/vidarkongsli/vidars-scoop-bucket'
            'state'=$state
        } `
        | Select-Object -ExpandProperty access_token
}

function Encrypt($Token) {
    $t = $Token
    if ($t -isnot [System.Security.SecureString]) {
        Write-debug 'Input is cleartext - creating SecureString'
        $t = ConvertTo-SecureString -AsPlainText $t -Force
    } else {
        Write-debug 'Input is already SecureString'
    }
    ConvertFrom-SecureString $t
}

function Decrypt($TokenEncrypted) {
    ConvertTo-SecureString $TokenEncrypted
}

function Write-AccessToken {
    param(
        [Parameter(Mandatory,Position=0)]
        $AccessToken,
        [Parameter(Mandatory,Position=1)]
        $Account,
        [Parameter(Mandatory=$false)]
        $Path = "$(join-path (split-path $PROFILE) '.dnsimple.tokens')"
        )

    $store = @{}
    if (test-path $Path) {
        Write-debug "Reading access tokens from $Path"
        $store = Import-CliXml -Path $Path
        WRite-debug "$($store.Count) tokens read"
    } else {
        Write-debug "Access tokens store at $Path does not exist"
    }
    $store[$Account] = Encrypt $AccessToken
    Write-debug "Writing access tokens (count: $($store.Count)) to store at $Path"
    Export-CliXml -Path $Path -InputObject $store
}

function Read-AccessToken {
    param(
        [Parameter(Mandatory=$false,Position=0)]
        $Account,
        [Parameter(Mandatory=$false, Position=1)]
        $Path = "$(join-path (split-path $PROFILE) '.dnsimple.tokens')"
        )
    if (-not(test-path $Path)) {
        Write-error "Access token store at $Path not found"
        return
    }
    Write-debug "Reading access tokens from $Path"
    $store = Import-CliXml -Path $Path
    Write-debug "$($store.Count) tokens read"
    if ($Account) {
        new-object PSObject -Property @{Account=$Account;AccessToken = (Decrypt $store[$Account])}
    } else {
        $store.Keys | foreach-object { new-object PSObject -Property @{Account=$_} }
    }
}
