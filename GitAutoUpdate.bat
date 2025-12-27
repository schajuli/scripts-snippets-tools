@echo off
chcp 65001 >nul
echo -------------------------------------
echo Git-Sync-Skript mit Sichtbarkeit, Bestätigung und Umlauten
echo -------------------------------------

REM 1. Arbeitsverzeichnis
set "REPO_DIR=%~dp0"
echo 1. Working in repository: %REPO_DIR%
cd /d "%REPO_DIR%"

REM 2. Pull ausführen
echo.
echo 2. Pulling latest changes...
git pull
IF %ERRORLEVEL% NEQ 0 (
    echo Fehler beim Pull! Prüfe die Meldungen oben.
    pause    
    goto :eof
)

echo.

REM 3. Status anzeigen
echo 3. Zeigt Status
git status
echo.

REM 4. Prüfen, ob Änderungen existieren (inkl. neue Dateien)
git status --porcelain > temp_changes.txt
for /f %%i in ('type temp_changes.txt') do set CHANGES=1
del temp_changes.txt

IF NOT DEFINED CHANGES (
    echo 4. Keine Änderungen zum Commit.
    pause
    goto :eof
) ELSE (
    echo 4. Änderungen wurden erkannt!
    choice /M "Fortfahren mit Commit/Push?" 
    IF ERRORLEVEL 2 (
        echo Commit/Push abgebrochen.
        pause
        goto :eof
    )

    REM 5. Alle Änderungen hinzufügen
    echo 5. Git add .
    git add .

    REM 6. Commit mit Datum/Zeit
    set "DATE=%date%_%time%"
    echo 6. Git commit -m "Auto-commit %DATE%"
    git commit -m "Auto-commit %DATE%"

    REM 7. Push zum Remote
    echo 7. Git push
    git push
    IF %ERRORLEVEL% NEQ 0 (
        echo Fehler beim Push! Prüfe die Meldungen oben.
    ) ELSE (
        echo.
        echo -------------------------------------
        echo Commit und Push erfolgreich!
        echo -------------------------------------
    )
    pause
)

echo Fertig!

