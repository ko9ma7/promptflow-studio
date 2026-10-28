@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title PromptFlow - GitHub Update

echo.
echo ====================================================
echo PromptFlow Studio - Safe GitHub Update
echo ====================================================
where git >nul 2>nul || (echo ERROR: Git not installed. & goto fail)
where gh >nul 2>nul || (echo ERROR: GitHub CLI not installed. & goto fail)
gh auth status >nul 2>nul || (echo GitHub login required. & gh auth login & if errorlevel 1 goto fail)
git rev-parse --is-inside-work-tree >nul 2>nul || (echo ERROR: Not inside a Git repository. Run github-bootstrap.cmd first. & goto fail)
set "ORIGIN="
for /f "usebackq delims=" %%R in (`git remote get-url origin 2^>nul`) do set "ORIGIN=%%R"
if not defined ORIGIN (echo ERROR: No origin remote. Run bootstrap first. & goto fail)
echo Remote: !ORIGIN!
set "BRANCH="
for /f "usebackq delims=" %%B in (`git branch --show-current 2^>nul`) do set "BRANCH=%%B"
if /i not "!BRANCH!"=="main" (echo ERROR: Current branch must be main. & goto fail)

git add -A || goto fail
git diff --cached --quiet
if errorlevel 1 (
  set "MSG=chore: update PromptFlow Studio"
  if not "%~1"=="" set "MSG=%~1"
  git commit -m "!MSG!" || goto fail
) else (
  echo No new local changes. Checking remote state.
)
echo Pushing safely (no force)...
git push origin main || (echo ERROR: Push failed. Remote may have new commits. Fetch and resolve manually before retry. & goto fail)
echo.
echo Push accepted. GitHub Actions may still be running.
echo Check: gh run list --limit 5
gh run list --workflow deploy.yml --limit 5
echo.
echo Review the GitHub Actions deployment before considering this update complete.
pause
exit /b 0
:fail
echo.
echo Update failed safely. Review the error above; no force push was used.
pause
exit /b 1
