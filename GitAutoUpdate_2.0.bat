@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo -------------------------------------
echo Git-Sync-Skript (Clean and Fast)
echo -------------------------------------

:: 1. Verzeichnis prüfen
set "REPO_DIR=%~dp0"
cd /d "%REPO_DIR%"

:: 2. Pull
echo 1. Pulling...
git pull
if %ERRORLEVEL% neq 0 (echo Fehler beim Pull! & pause & exit)

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
git status -s
echo.
set /p "CONFIRM=Änderungen erkannt. Fortfahren? [J/N] (Enter für Ja): "
if /I "%CONFIRM%"=="N" exit

:: 4. Add
git add .

:: 5. Message-Logik (UTF8 ohne BOM-Fragezeichen)
echo.
echo Geben Sie die Nachricht ein (Bestätigen mit Enter - kein Text für Auto-Message):
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