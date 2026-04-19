@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Usage:
REM   git_commit_push.bat "commit message"
REM   git_commit_push.bat "commit message" branch-name

where git >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Git is not installed or not in PATH.
  exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
  echo [ERROR] This folder is not a Git repository.
  exit /b 1
)

set "COMMIT_MSG=%~1"
if "%COMMIT_MSG%"=="" (
  set /p COMMIT_MSG=Commit message: 
)

if "%COMMIT_MSG%"=="" (
  echo [ERROR] Commit message is required.
  exit /b 1
)

set "BRANCH=%~2"
if "%BRANCH%"=="" (
  for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%b"
)

if "%BRANCH%"=="" (
  echo [ERROR] Could not detect branch name.
  exit /b 1
)

echo [INFO] Staging all changes...
git add -A
if errorlevel 1 (
  echo [ERROR] git add failed.
  exit /b 1
)

git diff --cached --quiet
if not errorlevel 1 (
  echo [INFO] No staged changes to commit.
  exit /b 0
)

echo [INFO] Committing with message: "%COMMIT_MSG%"
git commit -m "%COMMIT_MSG%"
if errorlevel 1 (
  echo [ERROR] git commit failed.
  exit /b 1
)

echo [INFO] Pushing to origin/%BRANCH%...
git push origin "%BRANCH%"
if errorlevel 1 (
  echo [ERROR] git push failed.
  exit /b 1
)

echo [DONE] Commit and push completed successfully.
exit /b 0
