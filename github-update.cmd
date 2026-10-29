@echo off
setlocal
cd /d "%~dp0"
echo ====================================================
echo PromptFlow Studio - Safe Update
 echo ====================================================
echo This script uses the same safe remote-history checks as bootstrap.
call "%~dp0github-bootstrap.cmd"
exit /b %errorlevel%
