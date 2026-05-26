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
$pck_size_mb = 0
if (Test-Path "$build_dir\Cogwright.pck") {
    $pck_size_mb = [math]::Round((Get-Item "$build_dir\Cogwright.pck").Length / 1MB, 1)
}
Write-Host "Export erfolgreich: Cogwright.exe ($size_mb MB)$(if ($pck_size_mb -gt 0) { ' + Cogwright.pck (' + $pck_size_mb + ' MB)' })" -ForegroundColor Green

# --- HDiffPatch-Tooling finden ---
$hdiffz = (Get-Command hdiffz -ErrorAction SilentlyContinue).Source
$hpatchz = (Get-Command hpatchz -ErrorAction SilentlyContinue).Source
if (-not $hdiffz) {
    $hp_dir = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\sisong.HDiffPatch*" -Filter "hdiffz.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hp_dir) {
        $hdiffz = $hp_dir.FullName
        $hpatchz = Join-Path (Split-Path $hdiffz -Parent) "hpatchz.exe"
    }
}

# --- Updater-Files + hpatchz mit ins Build-Verzeichnis kopieren ---
Copy-Item "$project_root\installer\Cogwright-Update.ps1" "$build_dir\Cogwright-Update.ps1" -Force
Copy-Item "$project_root\installer\Cogwright-Update.bat" "$build_dir\Cogwright-Update.bat" -Force
if ($hpatchz -and (Test-Path $hpatchz)) {
    Copy-Item $hpatchz "$build_dir\hpatchz.exe" -Force
    Write-Host "hpatchz.exe mit ins Build kopiert" -ForegroundColor Green
} else {
    Write-Warning "hpatchz.exe nicht gefunden - Updater kann keine Patches anwenden (nur Full-Download)."
}

# --- ZIP-Distribution ---
$zip_path = "$release_dir\Cogwright-$version.zip"
if (Test-Path $zip_path) { Remove-Item $zip_path -Force }
Write-Host "Erstelle ZIP: $zip_path" -ForegroundColor Cyan
Compress-Archive -Path "$build_dir\*" -DestinationPath $zip_path -CompressionLevel Optimal

$zip_size_mb = [math]::Round((Get-Item $zip_path).Length / 1MB, 1)
Write-Host "ZIP erstellt: Cogwright-$version.zip ($zip_size_mb MB)" -ForegroundColor Green

# --- Hashes pro Update-File berechnen ---
$update_files = @("Cogwright.exe", "Cogwright.pck", "Cogwright-Update.ps1", "Cogwright-Update.bat", "hpatchz.exe")
$file_hashes = @{}
$total_files = 0
foreach ($f in $update_files) {
    $p = Join-Path $build_dir $f
    if (Test-Path $p) {
        $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash.ToLower()
        $file_hashes[$f] = $hash
        $total_files++
    }
}
Write-Host "Hashes berechnet fuer $total_files Files" -ForegroundColor Green

# --- Binary-Diff-Patch der PCK gegen die vorherige Version ---
# Vorherige PCK liegt in release/prev/Cogwright.pck (vom letzten Build).
$prev_dir = "$release_dir\prev"
$prev_pck = "$prev_dir\Cogwright.pck"
$prev_ver_file = "$prev_dir\version.txt"
$pck_patch_info = $null
$new_pck = "$build_dir\Cogwright.pck"
if ($hdiffz -and (Test-Path $hdiffz) -and (Test-Path $prev_pck) -and (Test-Path $prev_ver_file) -and (Test-Path $new_pck)) {
    $prev_version = (Get-Content $prev_ver_file -Raw).Trim()
    $prev_pck_hash = (Get-FileHash -Algorithm SHA256 -Path $prev_pck).Hash.ToLower()
    $patch_name = "Cogwright-$prev_version-to-$version.pck.patch"
    $patch_path = "$release_dir\$patch_name"
    Write-Host "Erzeuge Binary-Patch $prev_version -> $version ..." -ForegroundColor Cyan
    & $hdiffz -f $prev_pck $new_pck $patch_path 2>&1 | Out-Null
    if (Test-Path $patch_path) {
        $patch_size = (Get-Item $patch_path).Length
        $patch_mb = [math]::Round($patch_size / 1MB, 2)
        $patch_hash = (Get-FileHash -Algorithm SHA256 -Path $patch_path).Hash.ToLower()
        $pck_patch_info = [ordered]@{
            from_version   = $prev_version
            from_pck_sha256 = $prev_pck_hash
            file           = $patch_name
            sha256         = $patch_hash
            size           = $patch_size
        }
        Write-Host "Patch erstellt: $patch_name ($patch_mb MB statt $pck_size_mb MB voll)" -ForegroundColor Green
    } else {
        Write-Warning "Patch-Erzeugung fehlgeschlagen - Updater nutzt Full-Download."
    }
} else {
    Write-Host "Kein Vorgaenger-PCK fuer Diff vorhanden (erster Build mit Patch-System) - nur Full-Download." -ForegroundColor Yellow
}

# Aktuelle PCK + Version als 'prev' fuer den naechsten Build sichern
if (-not (Test-Path $prev_dir)) { New-Item -ItemType Directory -Path $prev_dir -Force | Out-Null }
Copy-Item $new_pck $prev_pck -Force
$version | Out-File $prev_ver_file -Encoding utf8 -NoNewline

# --- Manifest fuer Update-Check (inkrementeller Updater) ---
$manifest_path = "$release_dir\manifest.json"
$base_url = "https://github.com/fs-mediatek/cogwright/releases/download/v$version/"
$dl_url = if ($DownloadUrl) { $DownloadUrl } else { "$base_url" + "Cogwright-Setup-$version.exe" }
$manifest_obj = [ordered]@{
    version       = $version
    notes         = "Release v$version - siehe Commit-History fuer Details."
    released_at   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    download_url  = $dl_url
    base_url      = $base_url
    files         = $file_hashes
}
if ($pck_patch_info) {
    $manifest_obj["pck_patch"] = $pck_patch_info
}
$manifest = $manifest_obj | ConvertTo-Json -Depth 4
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
