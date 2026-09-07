@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
mode con: cols=150 lines=9999

echo -------------------------------------
echo Git-Sync-Skript (Clean and Fast)
echo -------------------------------------

:: 1. Verzeichnis des Aufrufs nutzen (WICHTIG WENN SKRIPT VIA PATH AUSGEFÜHRT WIRD!)
set "REPO_DIR=%CD%"
cd /d "%REPO_DIR%"

:: 2. Fetch
echo 1. Fetching latest changes...
echo.
git fetch
if %ERRORLEVEL% neq 0 (echo Fehler beim Fetch! & pause & exit)

:: 3. Prüfen, ob lokaler Branch behind/ ahead ist
for /f %%i in ('git rev-list --count HEAD..origin/main') do set "BEHIND=%%i"
for /f %%i in ('git rev-list --count origin/main..HEAD') do set "AHEAD=%%i"

:: Änderungen anzeigen, falls behind oder ahead
if %BEHIND% NEQ 0 (
    echo Dein lokaler Branch ist hinter 'origin/main' um %BEHIND% Commits!
)
if %AHEAD% NEQ 0 (
    echo Achtung: Dein lokaler Branch ist ahead von 'origin/main' um %AHEAD% Commits!
    echo Du solltest diese Änderungen pushen, bevor du pullst.
)

if %BEHIND% NEQ 0 if %AHEAD% EQU 0 echo.
echo Überblick über die Änderungen:
echo.
git diff --stat origin/main | more
echo.

:: 4. Pull
if %BEHIND% NEQ 0 (
    set /p "CONFIRM_PULL=Fortfahren mit Pull? [J/N] (Enter=Ja): "
    if /I "%CONFIRM_PULL%"=="N" exit
    echo 2. Pulling latest changes...
    git pull
    if %ERRORLEVEL% neq 0 (echo Fehler beim Pull! & pause & exit)
) else (
    echo Kein Pull nötig. Branch auf aktuellem Stand.
)


:: 3. Status Check
git status --porcelain > temp_status.txt
set "HAS_CHANGES="
for /f "delims=" %%i in (temp_status.txt) do set "HAS_CHANGES=1"
del temp_status.txt 2>nul

if not defined HAS_CHANGES (
    echo Keine Änderungen gefunden.
    pause
    exit
)

echo.
git status -s | more
echo.
set /p "CONFIRM=Lokale Änderungen erkannt. Fortfahren mit Commit? [J/N] (Enter für Ja): "
if /I "%CONFIRM%"=="N" exit

:: 4. Add
git add .

:: 5. Message-Logik (UTF8 ohne BOM-Fragezeichen)
echo.
echo Geben Sie die Commit-Message ein (Bestätigen mit Enter - kein Text für d. Auto-Message):
:: Wir nutzen New-Object UTF8Encoding($false) um das BOM-Symbol wegzulassen
powershell -NoProfile -Command "$m = Read-Host; if([string]::IsNullOrWhiteSpace($m)){$m='Auto-commit %date% %time%'}; $utf8NoBom = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllLines('c_msg.tmp', $m, $utf8NoBom)"

:: 6. Vorschau & finale Bestätigung
echo.
echo -------------------------------------
echo VORSCHAU: 
if exist c_msg.tmp (type c_msg.tmp) else (echo FEHLER: Message-Datei nicht gefunden!)
echo -------------------------------------
set /p "FINAL_CHECK=Commit jetzt ausführen? [J/N] (Enter für Ja): "
if /I "%FINAL_CHECK%"=="N" (
    del c_msg.tmp 2>nul
    echo Abgebrochen.
    pause
    exit
)

:: 7. Commit ausführen
echo.
echo Committing...
git commit -F c_msg.tmp
set "COMMIT_EXIT_CODE=%ERRORLEVEL%"

if exist c_msg.tmp del c_msg.tmp 2>nul

if %COMMIT_EXIT_CODE% neq 0 (
    echo Fehler beim Commit!
    pause
    exit
)

:: 8. Push
echo.
echo Pushing...
git push
if %ERRORLEVEL% neq 0 (
    echo Fehler beim Push!
) else (
    echo [OK] Erfolg!
)

pause