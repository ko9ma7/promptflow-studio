@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title PromptFlow - Recover rejected GitHub push
echo.
echo ====================================================
echo PromptFlow Studio - Recover Rejected GitHub Push
echo ====================================================
echo.
if not exist "git-safe-sync.cmd" (echo ERROR: git-safe-sync.cmd is missing. & goto fail)
where git >nul 2>nul || (echo ERROR: Git is missing. & goto fail)
git rev-parse --verify HEAD >nul 2>nul || (echo ERROR: No local commit exists yet. Use github-bootstrap.cmd first. & goto fail)
git config user.name >nul 2>nul || (echo ERROR: Git user.name is missing. & goto fail)
git config user.email >nul 2>nul || (echo ERROR: Git user.email is missing. & goto fail)
echo Saving updated helper scripts and any local changes to a new commit...
git add -A || goto fail
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "fix: repair safe GitHub publish" || goto fail
) else (
  echo No local file changes to commit.
)
call "%~dp0git-safe-sync.cmd" || goto fail
echo.
echo SUCCESS: Git push completed.
echo To refresh GitHub About and Pages settings, run github-bootstrap.cmd once.
pause
exit /b 0
:fail
echo.
echo Recovery stopped safely. No forced push or history deletion occurred.
echo Consult README.md for conflict recovery.
pause
exit /b 1
