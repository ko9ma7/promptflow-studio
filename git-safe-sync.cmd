@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Safe shared Git sync for the first publish and later updates.
rem Never forces a push, resets a branch, or erases remote history.

where git >nul 2>nul || (echo ERROR: Git is not installed. & exit /b 1)
git rev-parse --is-inside-work-tree >nul 2>nul || (echo ERROR: This is not a Git repository. & exit /b 1)
for /f "delims=" %%B in ('git branch --show-current 2^>nul') do set "SYNC_BRANCH=%%B"
if /i not "!SYNC_BRANCH!"=="main" (echo ERROR: Expected local main branch, found !SYNC_BRANCH!. & exit /b 1)
git remote get-url origin >nul 2>nul || (echo ERROR: origin remote is missing. & exit /b 1)

rem GitHub may have an existing repository but no main branch yet.
git ls-remote --exit-code origin refs/heads/main >nul 2>nul
if errorlevel 1 (
  echo No remote main was found. Attempting first push without force...
  git push -u origin main
  exit /b !errorlevel!
)

echo Fetching existing remote main...
git fetch --no-tags origin main
if errorlevel 1 (echo ERROR: Cannot fetch origin/main. Check network and authentication. & exit /b 1)
git show-ref --verify --quiet refs/remotes/origin/main
if errorlevel 1 (echo ERROR: origin/main is not available after fetch. & exit /b 1)

rem Already includes the remote state.
git merge-base --is-ancestor origin/main HEAD >nul 2>nul
if not errorlevel 1 (
  echo Local history already includes remote main.
  goto push
)

rem Local branch is strictly behind the remote state.
git merge-base --is-ancestor HEAD origin/main >nul 2>nul
if not errorlevel 1 (
  echo Local branch is behind remote main. Fast-forwarding safely...
  git merge --ff-only origin/main
  if errorlevel 1 (echo ERROR: Fast-forward merge failed. & exit /b 1)
  goto push
)

rem Otherwise the branches diverged. Different roots are common when the
rem GitHub repository and an extracted ZIP were initialized independently.
git merge-base HEAD origin/main >nul 2>nul
if errorlevel 1 goto unrelated

echo Local and remote have diverged. Merging both histories...
git merge --no-edit origin/main
if errorlevel 1 goto merge_failed
goto push

:unrelated
set "REMOTE_COUNT="
for /f "delims=" %%C in ('git rev-list --count origin/main 2^>nul') do set "REMOTE_COUNT=%%C"
if not "!REMOTE_COUNT!"=="1" (
  echo ERROR: Local and remote histories are unrelated, and remote has more than one commit.
  echo Automatic merge is intentionally disabled to protect existing work.
  echo See README.md under Git sync recovery.
  exit /b 1
)
echo.
echo IMPORTANT: Local and remote repositories began with separate initial commits.
echo The existing remote has just one commit.
echo The following action will create a merge commit preserving BOTH histories.
echo For files changed in BOTH initial commits, YOUR LOCAL FILE is preferred.
echo Remote versions remain retrievable from Git history; nothing is force-pushed.
echo.
choice /c YN /n /m "Merge separate first commits and keep local versions for overlaps? [Y/N]: "
if errorlevel 2 (echo Cancelled without changing history. & exit /b 2)
git branch backup/remote-main-before-first-sync origin/main >nul 2>nul
if errorlevel 1 echo NOTE: A backup branch may already exist. Remote history is still retained.
git merge --allow-unrelated-histories -X ours --no-edit origin/main
if errorlevel 1 goto merge_failed
goto push

:merge_failed
echo.
echo ERROR: Merge has unresolved conflicts. Listing affected files:
git status --short
rem Abort only the merge created by this helper. Prior local commits remain.
git merge --abort >nul 2>nul
if errorlevel 1 (
 echo WARNING: Automatic merge abort failed. Resolve Git state manually before retrying.
) else (
 echo Merge cancelled. Existing local files and committed history were preserved.
)
exit /b 1

:push
echo Uploading main safely. --force is NEVER used.
git push -u origin main
if errorlevel 1 (
  echo ERROR: Push rejected. New changes may have arrived during the operation.
  echo Rerun this script to fetch and integrate the newest remote state.
  exit /b 1
)
echo Git upload completed successfully.
exit /b 0
