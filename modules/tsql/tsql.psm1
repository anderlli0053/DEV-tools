


function New-ConnectionString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $server,
        [Parameter(Mandatory)]
        $database,
        [Parameter(Mandatory=$false)]
        $user='',
        [Parameter(Mandatory=$false)]
        $pwd,
        [Parameter(Mandatory=$false)]
        [int]$port = 1433
    )
    if ([Uri]::CheckHostName($server) -eq 'Dns') {
        $str = "Server=tcp:$($server),$($port);Initial Catalog=$($database);Persist Security Info=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    } else {
        $str = "Server=$Server;Database=$($database)"
    }

    if ($user -and ($user -ne '')) {
        $str = "$str;User ID=$($user);Password=$($pwd);MultipleActiveResultSets=False;"
    } else {
        $str = "$str;Integrated Security=SSPI;"
    }
    $str
}

function New-DbConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        $connectionString,
        [Parameter(Mandatory=$false)]
        [switch]$dontOpenConnection
    )
    $conn = new-object ('System.Data.SqlClient.SqlConnection')
    $conn.ConnectionString = $connectionString
    if (-not($dontOpenConnection)) {
        $conn.Open()
    }
    $conn
}

function Close-DbConnection {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.Data.SqlClient.SqlConnection]$connection
    )
    if ($connection -eq 'Open') {
        $connection.Close()
    }    
}

function Write-SqlNonQuery {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.Data.SqlClient.SqlConnection]$connection,
        [Parameter(Mandatory)]
        $stmt
    )
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.CommandText = $stmt
    $sqlCmd.Connection = $connection
    if ($connection.State -ne 'Open') {
        $connection.Open()
    }
    $sqlCmd.ExecuteNonQuery()
}

function Read-SqlQuery {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.Data.SqlClient.SqlConnection]$connection,
        [Parameter(Mandatory)]
        $query 
    )

    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.CommandText = $query
    $sqlCmd.Connection = $connection
    if ($connection.State -ne 'Open') {
        $connection.Open()
    }
    $data = $sqlCmd.ExecuteReader()
    while ($data.read() -eq $true) {
        $max = $data.FieldCount -1
        $obj = New-Object Object
        For ($i = 0; $i -le $max; $i++) {
            $name = $data.GetName($i)
	        if ($name) {
                $obj | Add-Member Noteproperty $name -value $data.GetValue($i)
	        } else {
                $obj = $data.GetValue($i)
	        }
        }
        $obj
    }
    $data.Close()
}

function Add-sqldb {
    PARAM (
    [Parameter(Mandatory=$true)]
    $dbname,
    [Parameter(Mandatory=$true)]
    [ValidateScript({ -not(test-Path $_)})]
    $dbpath,
    [Parameter(Mandatory=$true)]
    $server
    )

    if (-not(Read-SqlQuery $server "SELECT * from sysdatabases" | Where-Object { $_.name -eq $dbname })) {
        Write-Host "Creating $dbname"
        $createStmt = @"
        CREATE DATABASE
            [$dbname]
        ON PRIMARY (
           NAME=Test_data,
           FILENAME = '$($dbpath).mdf'
        )
        LOG ON (
            NAME=Test_log,
            FILENAME = '$($dbpath).ldf'
        )
"@
        Write-Debug $createStmt
        Write-SqlNonQuery $server $createStmt
    }
}

function Add-sqllogin($server, $login='IIS APPPOOL\DefaultAppPool') {
    if (-not(Read-SqlQuery $server "SELECT * from sys.syslogins where loginname = '$login'")) {
        $createStmt = @"
            CREATE LOGIN [$login] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
"@
        Write-debug $createStmt
        Write-SqlNonQuery $server $createStmt | out-null
    }
}

function Add-sqluser($server, $dbname, $user='IIS APPPOOL\DefaultAppPool') {
    $qry = "SELECT * FROM sys.sysusers"# where name = '$user'"
    $res = Read-SqlQuery $server $qry $dbname
    if (-not($res | where-object { $_.name -eq $user }))
    { 
        $createStmt = @"
            CREATE USER [$user] FOR LOGIN [$user] WITH DEFAULT_SCHEMA=[dbo]
"@
        Write-debug $createStmt
        Write-SqlNonQuery $server $createStmt $dbname | out-null
    }
}

Export-modulemember -function Add-sqluser,Add-sqllogin,Add-sqldb,Read-SqlQuery,Write-SqlNonQuery,New-ConnectionString,New-DbConnection,Close-DbConnection
