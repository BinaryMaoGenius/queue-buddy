$ErrorActionPreference = "Stop"
$SdkDir = "C:\Users\USER\AppData\Local\Android\Sdk"
$CmdLineToolsDir = "$SdkDir\cmdline-tools"
$ZipPath = "$SdkDir\cmdlinetools.zip"
$Url = "https://dl.google.com/android/repository/commandlinetools-win-11479570_latest.zip"

Write-Host "Création du dossier..."
if (-not (Test-Path -Path $CmdLineToolsDir)) {
    New-Item -Path $CmdLineToolsDir -ItemType Directory -Force | Out-Null
}

Write-Host "Téléchargement des outils..."
Invoke-WebRequest -Uri $Url -OutFile $ZipPath

Write-Host "Extraction..."
Expand-Archive -Path $ZipPath -DestinationPath $CmdLineToolsDir -Force

Write-Host "Renommage du dossier..."
$ExtractedFolder = "$CmdLineToolsDir\cmdline-tools"
$LatestFolder = "$CmdLineToolsDir\latest"
if (Test-Path -Path $LatestFolder) {
    Remove-Item -Path $LatestFolder -Recurse -Force
}
if (Test-Path -Path $ExtractedFolder) {
    Rename-Item -Path $ExtractedFolder -NewName "latest"
}

Write-Host "Nettoyage..."
Remove-Item -Path $ZipPath -Force

Write-Host "Terminé !"
