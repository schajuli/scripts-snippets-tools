<#
    update-manifest.ps1

    Erstellt ein SHA-256 Manifest (manifest.json) aus allen .jar-Dateien
    im "AKTUELL"-Ordner (nur diese Ebene, KEINE Unterordner) und pusht
    dieses Manifest in ein OEFFENTLICHES GitHub-Repo.

    Dieses Skript und der Token bleiben bewusst LOKAL (nicht am Netzlaufwerk),
    aus Sicherheitsgruenden. Im AKTUELL-Ordner liegt nur eine Verknuepfung
    (.lnk) hierher.
#>

$ErrorActionPreference = "Stop"

# ============================================================
#  KONFIGURATION - hier anpassen
# ============================================================

# Pfad zum AKTUELL-Ordner am Netzlaufwerk
$WatchPath = "X:\ODE-Templates\ODE Solibri\ODE-DEV\ODE-API\AKTUELL"

# Oeffentliches GitHub-Repo, Format: "benutzername/repositoryname"
$PublicRepo = "schajuli/ode-solibri-voight-kampff"

# Dateiname des Manifests im Repo (i.d.R. nicht aendern)
$ManifestRepoPath = "manifest.json"

# ============================================================
#  Ab hier normalerweise nichts mehr anpassen
# ============================================================

# ------------------------------------------------------------
#  WICHTIG - EINMALIGES SETUP (falls Skript auf neuem Rechner
#  oder nach Neuinstallation verwendet wird):
#
#  Der GitHub-Token wird NICHT hier im Skript gespeichert,
#  sondern muss als USER-UMGEBUNGSVARIABLE gesetzt sein.
#  Falls "GITHUB_MANIFEST_TOKEN ist nicht gesetzt" kommt,
#  einmalig in einer PowerShell (nicht in diesem Skript) ausfuehren:
#
#     [System.Environment]::SetEnvironmentVariable("GITHUB_MANIFEST_TOKEN", "ghp_DEIN_TOKEN_HIER", "User")
#
#  Danach Terminal / Explorer einmal neu starten, damit die
#  Variable geladen wird. Test mit:  echo $env:GITHUB_MANIFEST_TOKEN
# ------------------------------------------------------------
$GithubToken = $env:GITHUB_MANIFEST_TOKEN

$ManifestLocalPath = Join-Path $env:TEMP "manifest.json"


function New-Manifest {
    Write-Host "=== Schritt 1: Jars einlesen und hashen ===" -ForegroundColor Cyan
    Write-Host "Quelle: $WatchPath`n"

    if (-not (Test-Path $WatchPath)) {
        throw "Pfad nicht gefunden: $WatchPath  (Netzlaufwerk verbunden? Laufwerksbuchstabe korrekt?)"
    }

    # ------------------------------------------------------------
    #  WICHTIG - Filterung:
    #  - KEIN "-Recurse"  -> Unterordner werden NICHT durchsucht,
    #                        egal was/wie viel darin liegt.
    #  - "-File"          -> nur Dateien, keine Ordner selbst
    #                        (ein Ordner "irgendwas.jar" waere sonst
    #                        theoretisch moeglich, wird so ausgeschlossen)
    #  - "-Filter *.jar"  -> alle anderen Dateitypen (.txt, .zip, .xml, ...)
    #                        auf oberster Ebene werden ignoriert
    #
    #  Ergebnis: Es werden ausschliesslich .jar-Dateien direkt in
    #  $WatchPath beruecksichtigt. Unterordner (egal wie sie heissen
    #  oder was drin liegt) und Nicht-Jar-Dateien auf oberster Ebene
    #  werden komplett ignoriert.
    # ------------------------------------------------------------
    $jars = Get-ChildItem -LiteralPath $WatchPath -Filter *.jar -File

    if ($jars.Count -eq 0) {
        Write-Warning "Keine .jar-Dateien in $WatchPath gefunden. Manifest wird trotzdem (leer) erzeugt."
    }

    $files = foreach ($jar in $jars) {
        $hash = Get-FileHash -LiteralPath $jar.FullName -Algorithm SHA256
        Write-Host ("  {0,-40} {1}" -f $jar.Name, $hash.Hash.ToLower())
        [PSCustomObject]@{
            name   = $jar.Name
            sha256 = $hash.Hash.ToLower()
            size   = $jar.Length
        }
    }

    $manifest = [PSCustomObject]@{
        generated = (Get-Date).ToUniversalTime().ToString("o")
        source    = $WatchPath
        files     = @($files)
    }

    $json = $manifest | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $ManifestLocalPath -Value $json -Encoding UTF8

    Write-Host "`nManifest lokal erzeugt: $ManifestLocalPath" -ForegroundColor Green
}


function Publish-ManifestToGithub {
    Write-Host "`n=== Schritt 2: Manifest auf GitHub pushen ===" -ForegroundColor Cyan

    if ([string]::IsNullOrWhiteSpace($GithubToken)) {
        throw "GITHUB_MANIFEST_TOKEN ist nicht gesetzt. Bitte gemaess Setup-Anleitung als User-Umgebungsvariable anlegen und Terminal neu starten."
    }

    $apiUrl  = "https://api.github.com/repos/$PublicRepo/contents/$ManifestRepoPath"
    $headers = @{
        Authorization = "token $GithubToken"
        Accept        = "application/vnd.github+json"
    }

    # Aktuelle SHA der Datei im Repo ermitteln (fuer Update noetig, sonst 422 Fehler)
    $existingSha = $null
    try {
        $existing = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
        $existingSha = $existing.sha
        Write-Host "Bestehendes Manifest im Repo gefunden, wird aktualisiert."
    } catch {
        Write-Host "Noch kein Manifest im Repo vorhanden, wird neu angelegt."
    }

    $contentBytes  = [System.IO.File]::ReadAllBytes($ManifestLocalPath)
    $contentBase64 = [Convert]::ToBase64String($contentBytes)

    $bodyObj = @{
        message = "Update manifest $(Get-Date -Format o)"
        content = $contentBase64
    }
    if ($existingSha) { $bodyObj.sha = $existingSha }

    $bodyJson = $bodyObj | ConvertTo-Json

    Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $bodyJson | Out-Null

    $rawUrl = "https://raw.githubusercontent.com/$PublicRepo/main/$ManifestRepoPath"
    Write-Host "`nManifest erfolgreich veroeffentlicht." -ForegroundColor Green
    Write-Host "Repo:    https://github.com/$PublicRepo"
    Write-Host "Raw-URL: $rawUrl"
}


# ============================================================
#  Ablauf
# ============================================================
try {
    New-Manifest
    Publish-ManifestToGithub
    Write-Host "`n=== FERTIG ===" -ForegroundColor Green
} catch {
    Write-Host "`n=== FEHLER ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`nBeliebige Taste zum Schliessen..."
[void][System.Console]::ReadKey($true)
