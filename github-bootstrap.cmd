@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title PromptFlow - First GitHub Setup
set "REPO_NAME=promptflow-studio"
set "ABOUT_DESC=Create HTML report and PPT AI prompts with 3-step guidance, page planning, and iterative review."
set "ABOUT_TOPICS=prompt-engineering,github-pages,presentation,reporting,workflow"

echo.
echo ====================================================
echo PromptFlow Studio - First GitHub Pages Publish
echo ====================================================
echo.
echo Repo name: %REPO_NAME%
echo Edit REPO_NAME above if you need another repository name.
echo.
where git >nul 2>nul || (echo ERROR: Install Git from https://git-scm.com/downloads & goto fail)
where gh >nul 2>nul || (echo ERROR: Install GitHub CLI from https://cli.github.com/ & goto fail)
gh auth status >nul 2>nul || (echo GitHub authentication is required. & gh auth login & if errorlevel 1 goto fail)
git config user.name >nul 2>nul || (echo ERROR: Run git config --global user.name "Your Name" & goto fail)
git config user.email >nul 2>nul || (echo ERROR: Run git config --global user.email "you@example.com" & goto fail)
if not exist "index.html" (echo ERROR: index.html is missing. & goto fail)
if not exist ".github\workflows\deploy.yml" (echo ERROR: deployment workflow is missing. & goto fail)
for /f "usebackq delims=" %%O in (`gh api user --jq .login 2^>nul`) do set "OWNER=%%O"
if not defined OWNER (echo ERROR: Could not read GitHub username. & goto fail)
set "FULL_REPO=!OWNER!/%REPO_NAME%"
set "PAGE_URL=https://!OWNER!.github.io/%REPO_NAME%/"
echo GitHub repository: !FULL_REPO!
echo.
if not exist ".git" (
  git init -b main || goto fail
)
for /f "usebackq delims=" %%B in (`git branch --show-current 2^>nul`) do set "BRANCH=%%B"
if defined BRANCH if /i not "!BRANCH!"=="main" (echo ERROR: Current branch is !BRANCH!, not main. & goto fail)

gh repo view "!FULL_REPO!" >nul 2>nul
if errorlevel 1 (
  echo Creating remote repository !FULL_REPO! ...
  gh repo create "!FULL_REPO!" --public --description "%ABOUT_DESC%" || goto fail
) else (
  echo Remote repository already exists. No duplicate will be created.
)
set "ORIGIN="
for /f "usebackq delims=" %%R in (`git remote get-url origin 2^>nul`) do set "ORIGIN=%%R"
if not defined ORIGIN (
  git remote add origin "https://github.com/!FULL_REPO!.git" || goto fail
) else (
  echo Existing origin: !ORIGIN!
  echo !ORIGIN! | findstr /i /c:"!FULL_REPO!" >nul
  if errorlevel 1 (
    echo ERROR: origin does not match !FULL_REPO!. Resolve manually to prevent pushing elsewhere.
    goto fail
  )
)

echo Preparing changes...
git add -A || goto fail
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "chore: publish PromptFlow Studio" || goto fail
) else (
  git rev-parse --verify HEAD >nul 2>nul
  if errorlevel 1 (echo ERROR: No commit exists. Check Git identity. & goto fail)
  echo No new file changes to commit.
)
echo Synchronizing with GitHub main before upload...
if not exist "git-safe-sync.cmd" (echo ERROR: git-safe-sync.cmd is missing. Extract the FULL updated ZIP. & goto fail)
call "%~dp0git-safe-sync.cmd" || (echo ERROR: Safe Git sync failed. See recovery instructions in README.md. & goto fail)

echo Updating Repository About...
gh repo edit "!FULL_REPO!" --description "%ABOUT_DESC%" --homepage "!PAGE_URL!" --add-topic "%ABOUT_TOPICS%" || echo WARNING: About update failed. Check repository permissions.

echo Configuring GitHub Pages for Actions...
gh api "repos/!FULL_REPO!/pages" >nul 2>nul
if errorlevel 1 (
  gh api --method POST "repos/!FULL_REPO!/pages" -f build_type=workflow >nul 2>nul || echo WARNING: Pages API setup failed. Check Settings - Pages - Source: GitHub Actions.
) else (
  gh api --method PUT "repos/!FULL_REPO!/pages" -f build_type=workflow >nul 2>nul || echo WARNING: Could not switch Pages source. Check Settings - Pages.
)
echo.
echo ----------------------------------------------------
echo Files pushed to: https://github.com/!FULL_REPO!
echo Expected site URL: !PAGE_URL!
echo Check GitHub Actions status before treating the site as published.
echo Recent workflow runs:
gh run list --repo "!FULL_REPO!" --workflow deploy.yml --limit 4
if errorlevel 1 echo Workflow run might not yet be available. See the Actions tab.
echo.
echo If Pages is disabled, open GitHub repository - Settings - Pages - Source = GitHub Actions.
echo GitHub Repository Social Preview image can be set in Settings - General - Social preview.
echo To make later updates, run github-update.cmd.
echo ----------------------------------------------------
pause
exit /b 0
:fail
echo.
echo Setup stopped. No force push was performed.
echo See README.md for recovery and manual configuration.
pause
exit /b 1
