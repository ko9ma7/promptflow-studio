@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul 2>&1
cd /d "%~dp0"
set "OWNER=ko9ma7"
set "REPO_NAME=promptflow-studio"
set "DESCRIPTION=Guide AI content creation with real-time prompts, page planning and iterative revisions."
set "TOPICS=prompt-builder,prompt-engineering,github-pages,presentation,workflow"
set "BRANCH=main"
set "REPO=%OWNER%/%REPO_NAME%"
set "REPO_URL=https://github.com/%REPO%.git"
set "PAGE_URL=https://%OWNER%.github.io/%REPO_NAME%/"

echo ====================================================
echo PromptFlow Studio - Safe GitHub Pages Publish
echo Repository: %REPO%  ^|  No force push
 echo ====================================================
echo [CHECK] Checking installed tools...
where git >nul 2>&1 || (echo [ERROR] Git not installed. https://git-scm.com/downloads & goto :fail)
where gh >nul 2>&1 || (echo [ERROR] GitHub CLI not installed. https://cli.github.com/ & goto :fail)
git --version
gh --version | findstr /r "^gh version" 
echo [CHECK] Checking GitHub account login...
gh auth status >nul 2>&1 || (echo [WARN] GitHub CLI login required. & gh auth login)
gh auth status >nul 2>&1 || (echo [ERROR] GitHub login failed. & goto :fail)
git config user.name >nul 2>&1 || (echo [ERROR] Configure Git name: git config --global user.name "Your Name" & goto :fail)
git config user.email >nul 2>&1 || (echo [ERROR] Configure Git email: git config --global user.email "you@example.com" & goto :fail)
if not exist ".git" (
  echo [CHECK] Initializing local repository...
  git init
  if errorlevel 1 goto :fail
  git branch -M main
)
git symbolic-ref HEAD >nul 2>&1 || git branch -M main
for /f %%B in ('git branch --show-current') do set "CURRENT_BRANCH=%%B"
if /I not "!CURRENT_BRANCH!"=="%BRANCH%" (echo [CHECK] Switching to main branch... & git switch main 2>nul || (echo [ERROR] Cannot switch to main. Review your current branch and changes. & goto :fail))
echo [CHECK] Checking remote repository...
gh repo view "%REPO%" >nul 2>&1
if errorlevel 1 (
  echo [CHECK] Creating a NEW repository only if it does not exist...
  gh repo create "%REPO%" --public --description "%DESCRIPTION%" || goto :fail
) else echo [OK] Remote repository already exists. No duplicate.
git remote get-url origin >nul 2>&1
if errorlevel 1 (
  git remote add origin "%REPO_URL%" || goto :fail
) else (
  for /f "delims=" %%R in ('git remote get-url origin') do set "CURRENT_REMOTE=%%R"
  echo [CHECK] Existing origin: !CURRENT_REMOTE!
  echo !CURRENT_REMOTE!|find /I "%OWNER%/%REPO_NAME%" >nul
  if errorlevel 1 (echo [ERROR] Existing origin points to another repository. Review manually. & goto :fail)
)
echo [CHECK] Preparing local files...
git add -A || goto :fail
git diff --cached --quiet >nul 2>&1
if errorlevel 1 (
  git commit -m "feat: improve guided prompt workflow and live preview" || goto :fail
) else echo [OK] No new file changes to commit.
echo [CHECK] Retrieving remote main before pushing...
git ls-remote --exit-code --heads origin "%BRANCH%" >nul 2>&1
if not errorlevel 1 (
  git fetch origin "%BRANCH%" --tags || goto :fail
  git merge-base --is-ancestor origin/%BRANCH% HEAD >nul 2>&1
  if not errorlevel 1 (
    echo [OK] Local history already contains remote main.
  ) else (
    git merge-base --is-ancestor HEAD origin/%BRANCH% >nul 2>&1
    if not errorlevel 1 (
      echo [CHECK] Applying remote fast-forward...
      git merge --ff-only origin/%BRANCH% || goto :fail
    ) else (
      git merge-base HEAD origin/%BRANCH% >nul 2>&1
      if errorlevel 1 (
        echo [WARN] Local and remote repositories started with unrelated histories.
        echo [WARN] Backup current local history before continuing.
        git branch backup-before-first-sync >nul 2>&1
        choice /C YN /M "Merge histories, prefer local versions for conflicting files?"
        if errorlevel 2 goto :fail
        git merge --allow-unrelated-histories -X ours --no-edit origin/%BRANCH%
      ) else (
        echo [CHECK] Both sides have commits. Creating safe merge...
        git merge --no-edit origin/%BRANCH%
      )
      if errorlevel 1 (
        echo [ERROR] Merge conflict. Attempting to return to pre-merge state.
        git merge --abort >nul 2>&1
        goto :fail
      )
    )
  )
) else echo [OK] Remote main not initialized yet.
echo [CHECK] Pushing with NO force...
git push -u origin "%BRANCH%" || goto :fail
echo [CHECK] Setting Repository About...
gh repo edit "%REPO%" --description "%DESCRIPTION%" --homepage "%PAGE_URL%" --add-topic "%TOPICS%"
if errorlevel 1 echo [WARN] About update failed. You can update Description/Homepage/Topics in GitHub manually.
echo [CHECK] Enabling GitHub Pages via GitHub Actions...
gh api "repos/%REPO%/pages" >nul 2>&1
if errorlevel 1 (
  gh api -X POST "repos/%REPO%/pages" -f "build_type=workflow" >nul 2>&1
  if errorlevel 1 echo [WARN] Pages could not be automatically enabled. Open Settings ^> Pages ^> Source: GitHub Actions.
) else (
  gh api -X PUT "repos/%REPO%/pages" -f "build_type=workflow" >nul 2>&1
  if errorlevel 1 echo [WARN] Check Pages publishing source: GitHub Actions.
)
echo [CHECK] Checking GitHub Actions...
gh run list --repo "%REPO%" --workflow deploy.yml --limit 3
if errorlevel 1 echo [WARN] Workflow may take a minute to appear, or Pages permissions may require manual configuration.
for /f %%I in ('gh run list --repo "%REPO%" --workflow deploy.yml --limit 1 --json databaseId --jq ".[0].databaseId" 2^>nul') do set "LATEST_RUN=%%I"
if defined LATEST_RUN (
 echo [CHECK] Watching latest deployment run !LATEST_RUN!...
 gh run watch !LATEST_RUN! --repo "%REPO%" --exit-status
 if errorlevel 1 echo [WARN] Pages deployment not confirmed. Inspect GitHub Actions logs.
) else echo [WARN] No workflow run available yet. Open the Actions tab and confirm deployment.
echo [CHECK] Tagging initial release only when absent...
git rev-parse "v1.0.0" >nul 2>&1
if errorlevel 1 (git tag v1.0.0 & git push origin v1.0.0)
echo [OK] Local upload attempted successfully.
echo Repo: https://github.com/%REPO%
echo Pages: %PAGE_URL%
echo Check Actions and test the deployed site before marking the release complete.
pause
exit /b 0
:fail
echo [ERROR] Setup halted safely. No force push performed.
echo [HELP] Run: git status
 echo [HELP] Run: git fetch origin main
 echo [HELP] For unresolved conflicts, review files or contact a Git administrator.
pause
exit /b 1
