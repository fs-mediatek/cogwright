# Cogwright - Build-Skript fuer Release-Distribution
#
# Verwendung:
#   .\build_release.ps1                  # Normaler Release-Build
#   .\build_release.ps1 -DownloadTemplates # Holt Godot Export-Templates falls fehlend
#   .\build_release.ps1 -BumpPatch        # Erhoeht VERSION um Patch + Build
#
# Output:
#   build/Cogwright.exe + Cogwright.pck  (eingebaut wenn embed_pck=true)
#   release/Cogwright-<version>.zip
#   release/manifest.json   (fuer Update-Check)

param(
    [switch]$DownloadTemplates,
    [switch]$BumpPatch,
    [string]$DownloadUrl = ""    # optional: URL die in manifest.json eingetragen wird
)

$ErrorActionPreference = "Stop"

$project_root  = "c:\KI-Projekte\Godot"
$game_dir      = "$project_root\game"
$build_dir     = "$game_dir\build"
$release_dir   = "$project_root\release"
$godot_exe     = "$project_root\bin\Godot_v4.6.3-stable_win64_console.exe"
$godot_ver     = "4.6.3-stable"   # fuer Download-URL (mit Bindestrich)
$tpl_ver       = "4.6.3.stable"   # fuer Templates-Ordnername (Godot nutzt Punkt!)
$tpl_dir       = "$env:APPDATA\Godot\export_templates\$tpl_ver"

# --- Version aus AppVersion.gd lesen ---
$version_file = "$game_dir\scripts\core\AppVersion.gd"
$version_match = (Get-Content $version_file | Select-String -Pattern 'const VERSION: String = "([^"]+)"').Matches
if ($version_match.Count -eq 0) {
    Write-Error "VERSION nicht gefunden in $version_file"
    exit 1
}
$version = $version_match[0].Groups[1].Value
Write-Host "Aktuelle Version: $version" -ForegroundColor Cyan

if ($BumpPatch) {
    $parts = $version.Split(".")
    $parts[2] = [int]$parts[2] + 1
    $newversion = ($parts -join ".")
    (Get-Content $version_file) -replace 'const VERSION: String = "[^"]+"', "const VERSION: String = `"$newversion`"" | Set-Content $version_file -Encoding UTF8
    $version = $newversion
    Write-Host "Version gebumpt auf: $version" -ForegroundColor Yellow
}

# --- Templates pruefen ---
if (-not (Test-Path $tpl_dir) -or (Get-ChildItem $tpl_dir -ErrorAction SilentlyContinue).Count -eq 0) {
    Write-Warning "Godot Export-Templates fehlen unter: $tpl_dir"
    if ($DownloadTemplates) {
        $tpz_url = "https://github.com/godotengine/godot/releases/download/$godot_ver/Godot_v$($godot_ver)_export_templates.tpz"
        $tpz_path = "$env:TEMP\godot_templates_$godot_ver.tpz"
        Write-Host "Lade Export-Templates (~700 MB) von:`n  $tpz_url" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $tpz_url -OutFile $tpz_path -UseBasicParsing
        Write-Host "Entpacke nach: $tpl_dir" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $tpl_dir -Force | Out-Null
        # tpz ist eine ZIP-Datei
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($tpz_path)
        foreach ($entry in $zip.Entries) {
            # Stripped: entry.FullName beginnt mit "templates/<file>"
            $name = $entry.Name
            if ($name -eq "") { continue }
            $dest = Join-Path $tpl_dir $name
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dest, $true)
        }
        $zip.Dispose()
        Remove-Item $tpz_path -Force
        Write-Host "Templates installiert." -ForegroundColor Green
    } else {
        Write-Host @"
Bitte Templates installieren:
  1. Godot starten: $godot_exe
  2. Editor > Editor > Manage Export Templates > Download and Install
  ODER: dieses Skript erneut starten mit -DownloadTemplates
"@ -ForegroundColor Yellow
        exit 1
    }
}

# --- Build-Ordner vorbereiten ---
if (Test-Path $build_dir) { Remove-Item $build_dir -Recurse -Force }
New-Item -ItemType Directory -Path $build_dir -Force | Out-Null
if (-not (Test-Path $release_dir)) { New-Item -ItemType Directory -Path $release_dir -Force | Out-Null }

# --- Export ---
Write-Host "Starte Headless-Export..." -ForegroundColor Cyan
$exp_out = & $godot_exe --headless --path $game_dir --export-release "Windows Desktop" "$build_dir\Cogwright.exe" 2>&1
$err_lines = $exp_out | Select-String -Pattern "ERROR" | Where-Object { $_ -notmatch "resources still in use|NativeCommandError" }
if ($err_lines) {
    $err_lines | Select-Object -First 5 | ForEach-Object { Write-Host $_ -ForegroundColor Red }
}

if (-not (Test-Path "$build_dir\Cogwright.exe")) {
    Write-Error "Export fehlgeschlagen - Cogwright.exe nicht erstellt."
    exit 1
}

$size_mb = [math]::Round((Get-Item "$build_dir\Cogwright.exe").Length / 1MB, 1)
Write-Host "Export erfolgreich: Cogwright.exe ($size_mb MB)" -ForegroundColor Green

# --- ZIP-Distribution ---
$zip_path = "$release_dir\Cogwright-$version.zip"
if (Test-Path $zip_path) { Remove-Item $zip_path -Force }
Write-Host "Erstelle ZIP: $zip_path" -ForegroundColor Cyan
Compress-Archive -Path "$build_dir\*" -DestinationPath $zip_path -CompressionLevel Optimal

$zip_size_mb = [math]::Round((Get-Item $zip_path).Length / 1MB, 1)
Write-Host "ZIP erstellt: Cogwright-$version.zip ($zip_size_mb MB)" -ForegroundColor Green

# --- Manifest fuer Update-Check ---
$manifest_path = "$release_dir\manifest.json"
$dl_url = if ($DownloadUrl) { $DownloadUrl } else { "https://github.com/fs-mediatek/cogwright/releases/download/v$version/Cogwright-$version.zip" }
$manifest = @{
    version      = $version
    download_url = $dl_url
    notes        = "Release v$version - siehe Commit-History fuer Details."
    released_at  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 3
$manifest | Out-File -FilePath $manifest_path -Encoding UTF8
Write-Host "Manifest geschrieben: $manifest_path" -ForegroundColor Green

# --- Installer-Build (Inno Setup) ---
$iscc = $null
$pf_x86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
$pf     = [Environment]::GetEnvironmentVariable("ProgramFiles")
$lad    = [Environment]::GetEnvironmentVariable("LOCALAPPDATA")
$iscc_candidates = @(
    "$lad\Programs\Inno Setup 6\ISCC.exe",
    "$pf_x86\Inno Setup 6\ISCC.exe",
    "$pf\Inno Setup 6\ISCC.exe"
)
foreach ($p in $iscc_candidates) {
    if (Test-Path $p) { $iscc = $p; break }
}

$installer_path = ""
if ($iscc) {
    Write-Host "Baue Installer (Inno Setup)..." -ForegroundColor Cyan
    $iss = "$project_root\installer\cogwright_setup.iss"
    & $iscc /Q "/DAppVersion=$version" $iss 2>&1 |
        Where-Object { $_ -match "Error|fatal|Compiled" } | Select-Object -First 5
    $installer_path = "$release_dir\Cogwright-Setup-$version.exe"
    if (Test-Path $installer_path) {
        $installer_mb = [math]::Round((Get-Item $installer_path).Length / 1MB, 1)
        Write-Host "Installer erstellt: Cogwright-Setup-$version.exe ($installer_mb MB)" -ForegroundColor Green
    } else {
        Write-Warning "Installer-Build fehlgeschlagen - ZIP ist trotzdem da."
        $installer_path = ""
    }
} else {
    Write-Warning "Inno Setup nicht gefunden - Installer wird nicht gebaut. Install: winget install JRSoftware.InnoSetup"
}

Write-Host ""
Write-Host "FERTIG. Output:" -ForegroundColor Cyan
Write-Host "  $build_dir\Cogwright.exe"
Write-Host "  $zip_path"
Write-Host "  $manifest_path"
if ($installer_path) { Write-Host "  $installer_path" }
Write-Host ""
Write-Host "Next steps: ZIP + Installer + manifest.json hochladen (GitHub Releases)."
