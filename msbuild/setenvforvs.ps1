function _xpd($s) {$ExecutionContext.InvokeCommand.ExpandString($s)}

get-command msbuild -ErrorAction SilentlyContinue 2>&1 | out-null
if (-not($?)) {

  $Command = '"C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"', `
           '"C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat"', `
           '"C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat"' `
           | ?{ test-path (_xpd($_).Replace('"','')) -PathType Leaf } `
           | select -First 1
  if ($Command) {
    Write-Verbose "Expanded Visual Studio environment from $Command"
    cmd /c "$Command > nul 2>&1 && set" | .{process{
        if ($_ -match '^([^=]+)=(.*)') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }}
  } else {
    Write-Error "Could not find Visual Studio"
  }
} else {
  Write-Verbose "Msbuild already on path. So quitting."
}
