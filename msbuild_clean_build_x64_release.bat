@echo off
setlocal EnableExtensions

REM Usage:
REM   msbuild_clean_build_x64_release.bat [path-to.sln|path-to.vcxproj]
REM   msbuild_clean_build_x64_release.bat
REM     - If no target is provided and CMakeLists.txt exists,
REM       this script configures CMake and builds with MSBuild.

set "TARGET=%~1"
set "SRC_DIR=%CD%"
set "BUILD_DIR=%SRC_DIR%\build\msbuild-x64-release"
set "GENERATOR=Visual Studio 17 2022"

set "MSBUILD=msbuild"
where msbuild >nul 2>nul
if errorlevel 1 (
  set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
  if exist "%VSWHERE%" (
    for /f "usebackq delims=" %%m in (`"%VSWHERE%" -latest -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do (
      set "MSBUILD=%%m"
      goto :MSBUILD_FOUND
    )
  )

  REM Fallback: common Visual Studio install paths
  for %%p in (
    "%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
    "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
    "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe"
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
  ) do (
    if exist %%~p (
      set "MSBUILD=%%~p"
      goto :MSBUILD_FOUND
    )
  )

  echo [WARN] MSBuild auto-detection failed.
  set /p MSBUILD=Enter full path to MSBuild.exe: 
  if "%MSBUILD%"=="" (
    echo [ERROR] MSBuild path is required.
    exit /b 1
  )
  if not exist "%MSBUILD%" (
    echo [ERROR] Invalid path: %MSBUILD%
    exit /b 1
  )
)

where cmake >nul 2>nul
if errorlevel 1 (
  echo [ERROR] CMake is not installed or not in PATH.
  exit /b 1
)

:MSBUILD_FOUND
if "%TARGET%"=="" (
  if exist "%SRC_DIR%\CMakeLists.txt" (
    echo [INFO] CMake project detected. Generating Visual Studio files...
    cmake -S "%SRC_DIR%" -B "%BUILD_DIR%" -G "%GENERATOR%" -A x64
    if errorlevel 1 (
      echo [ERROR] CMake configure failed.
      exit /b 1
    )

    set "TARGET=%BUILD_DIR%\ALL_BUILD.vcxproj"
  ) else (
    for /f "delims=" %%f in ('dir /b /s *.sln 2^>nul') do (
      set "TARGET=%%f"
      goto :TARGET_FOUND
    )
  )
)

:TARGET_FOUND
if "%TARGET%"=="" (
  echo [ERROR] No build target found.
  echo [INFO] Provide a .sln/.vcxproj path or run this in a CMake project folder.
  exit /b 1
)

if not exist "%TARGET%" (
  echo [ERROR] Target not found: %TARGET%
  exit /b 1
)

echo [INFO] Target: %TARGET%
echo [INFO] MSBuild: %MSBUILD%
echo [INFO] Configuration: Release, Platform: x64
echo.

echo [INFO] Cleaning...
"%MSBUILD%" "%TARGET%" /t:Clean /p:Configuration=Release;Platform=x64 /m
if errorlevel 1 (
  echo [ERROR] Clean failed.
  exit /b 1
)

echo.
echo [INFO] Building...
"%MSBUILD%" "%TARGET%" /t:Build /p:Configuration=Release;Platform=x64 /m
if errorlevel 1 (
  echo [ERROR] Build failed.
  exit /b 1
)

echo.
echo [DONE] Clean + Build completed successfully.
exit /b 0
