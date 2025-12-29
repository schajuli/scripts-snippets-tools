@echo off
setlocal

REM Beschreibung des Skripts
echo Dieses Skript hilft dabei, Unterschiede zwischen zwei Verzeichnissen darzustellen.
echo Es kopiert nichts, sondern listet nur auf, was in dem jeweils anderen Verzeichnis fehlt.
echo Die Ergebnisse werden in einer Log-Datei gespeichert, die im selben Verzeichnis wie das Skript erstellt wird.
echo.


REM Frage nach dem Quellverzeichnis
set /p sourceDir=Bitte geben Sie das Quellverzeichnis ein:

REM Frage nach dem Zielverzeichnis
set /p targetDir=Bitte geben Sie das Zielverzeichnis ein:

REM Ermittle den Pfad des Verzeichnisses, in dem sich die Batch-Datei befindet
set batchDir=%~dp0

REM Ermittle das aktuelle Datum und die Uhrzeit
for /f "delims=" %%i in ('powershell -Command "Get-Date -format yyyyMMdd_HHmmss"') do set datetime=%%i

REM Setze den Pfad für die Log-Datei im Verzeichnis der Batch-Datei mit Datum und Uhrzeit
set logFile=%batchDir%unterschiede_%datetime%.txt

REM Führe Robocopy mit den angegebenen Optionen aus
robocopy "%sourceDir%" "%targetDir%" /L /X /NP /FP /NS /NC /NDL /LOG:"%logFile%"

echo Die Unterschiede wurden in %logFile% gespeichert.

endlocal
pause

