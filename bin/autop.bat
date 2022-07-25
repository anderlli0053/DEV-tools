@echo off
setlocal

for %%i in (%0) do set DIR=%%~dpi..
cd %DIR%
git pull --ff-only origin master
git checkout master
for /f %%i in ('git diff --name-only') do (
    git add %%i
    for /f %%v in ('jq .version %%i') do (
        git commit -m "%%~ni: Update to version %%v"
        git tag "%%~ni-%%v"
    )
)
git push origin master --tags
git checkout -f master
