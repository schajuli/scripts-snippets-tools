### Anleitung: Zentrales Git-Update-System

Dieses System besteht aus zwei Teilen: Der **Logik** (das Gehirn) und dem **Caller** (der Auslöser in jedem Projekt).

#### 1. Die Logik-Datei (Das Gehirn)

Speichere dein Hauptskript an einem zentralen Ort (z. B. auf einem Netzlaufwerk oder in einem speziellen Tools-Ordner).

* **Dateiname:** `GitAutoUpdate_2.0.bat`
* **Speicherort:** z. B. `C:\Zentral\GitAutoUpdate_2.0.bat`
* **Inhalt:** Das komplette Skript mit der Zeile `set "REPO_DIR=%CD%"`.

#### 2. Die Caller-Datei (Der Auslöser)

In jedem deiner Git-Repositories (deinen Projekten) erstellst du nun eine kleine Datei, die auf das Gehirn verweist.

* **Dateiname:** `CallGitAutoUpdater_X1.bat`
* **Inhalt:**
```batch
@echo off
:: Ruft das zentrale Skript auf und übergibt die Kontrolle
call "C:\Zentral\GitAutoUpdate_2.0.bat"

```


*(Den Pfad musst du natürlich anpassen, je nachdem wo deine `GitAutoUpdate_2.0.bat` liegt).*

---

### So funktioniert der Ablauf im Alltag:

1. Du arbeitest in deinem Projektordner.
2. Wenn du fertig bist, machst du einen Doppelklick auf `CallGitAutoUpdater_X1.bat`.
3. Dieses kleine Skript "holt" sich die Logik aus der zentralen Datei.
4. **Der Clou:** Da das zentrale Skript mit `%CD%` arbeitet, weiß es sofort: *"Ah, ich wurde zwar in C:\Zentral gestartet, aber ich soll im aktuellen Projektordner arbeiten!"*
5. Du gibst deine Nachricht ein, bestätigst mit Enter – fertig.

### Warum das besser ist:

* **Einmal fixen, überall nutzen:** Wenn du merkst, dass du am Ablauf etwas ändern willst (z. B. eine neue Farbe oder ein anderes Zeitformat), änderst du nur die **eine** Datei `GitAutoUpdate_2.0.bat`.
* **Keine Redundanz:** Du hast in deinen Projekten keine riesigen Batch-Dateien mehr liegen, sondern nur noch diesen kleinen Einzeiler.

---

### Ein wichtiger Hinweis für das zentrale Skript:

Achte darauf, dass in deiner `GitAutoUpdate_2.0.bat` am Ende kein `exit` steht, sondern nur `pause` oder gar nichts, damit der Caller das Fenster nicht hart schließt, falls du die Fehlermeldungen noch lesen willst.

Möchtest du, dass ich dir den Pfad in der `CallGitAutoUpdater_X1.bat` so umschreibe, dass er automatisch erkennt, ob er auf einem USB-Stick oder einer anderen Festplatte liegt?