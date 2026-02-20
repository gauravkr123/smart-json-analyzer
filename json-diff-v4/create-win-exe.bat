@echo off
REM ═══════════════════════════════════════════════════════════
REM  Builds a standalone JSON Diff v4 Windows app (.exe)
REM  Run this ON A WINDOWS MACHINE with .NET 8 SDK installed.
REM  Install SDK:  winget install Microsoft.DotNet.SDK.8
REM ═══════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set APP_NAME=JSON Diff v4
set BUILD_DIR=%~dp0build-win
set PROJECT_DIR=%BUILD_DIR%\project

echo Building %APP_NAME% for Windows...

REM Check for dotnet
where dotnet >nul 2>&1
if errorlevel 1 (
    echo ERROR: .NET SDK not found.
    echo Install it with:  winget install Microsoft.DotNet.SDK.8
    echo Or download from:  https://dotnet.microsoft.com/download
    pause
    exit /b 1
)

REM Clean previous build
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%PROJECT_DIR%"

REM Create .csproj
(
echo ^<Project Sdk="Microsoft.NET.Sdk"^>
echo   ^<PropertyGroup^>
echo     ^<OutputType^>WinExe^</OutputType^>
echo     ^<TargetFramework^>net8.0-windows^</TargetFramework^>
echo     ^<UseWPF^>true^</UseWPF^>
echo     ^<AssemblyName^>JSONDeepDiff^</AssemblyName^>
echo     ^<ApplicationIcon^>app.ico^</ApplicationIcon^>
echo     ^<Nullable^>enable^</Nullable^>
echo   ^</PropertyGroup^>
echo   ^<ItemGroup^>
echo     ^<PackageReference Include="Microsoft.Web.WebView2" Version="1.*" /^>
echo   ^</ItemGroup^>
echo ^</Project^>
) > "%PROJECT_DIR%\JSONDeepDiff.csproj"

REM Copy source
copy "%~dp0JSONDeepDiff.cs" "%PROJECT_DIR%\" >nul

REM Copy icon if available
if exist "%~dp0app.ico" copy "%~dp0app.ico" "%PROJECT_DIR%\" >nul

REM Build
echo Restoring packages and compiling...
dotnet publish "%PROJECT_DIR%\JSONDeepDiff.csproj" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o "%BUILD_DIR%\output"

if errorlevel 1 (
    echo.
    echo BUILD FAILED. Check errors above.
    pause
    exit /b 1
)

REM Create app folder
set APP_FOLDER=%BUILD_DIR%\%APP_NAME%
mkdir "%APP_FOLDER%\Resources" 2>nul
copy "%BUILD_DIR%\output\JSONDeepDiff.exe" "%APP_FOLDER%\" >nul
copy "%~dp0index.html" "%APP_FOLDER%\Resources\" >nul

REM Cleanup intermediate
rmdir /s /q "%PROJECT_DIR%" 2>nul
rmdir /s /q "%BUILD_DIR%\output" 2>nul

echo.
echo ══════════════════════════════════════════════════
echo  Created: %APP_FOLDER%
echo  Run JSONDeepDiff.exe — fully self-contained.
echo ══════════════════════════════════════════════════
pause
