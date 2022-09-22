"pushd $dir; .\freemindw.bat; popd" | Out-File "$dir\freemind.ps1" -Encoding UTF8
"pushd $dir && .\freemindw.bat" | Out-File "$dir\shortcut.bat" -Encoding ASCII
