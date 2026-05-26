# Cogwright — Asset-Import-Pipeline
# Holt PNGs aus dem Downloads-Ordner, mappt Filenames, BG-removed wo nötig, reimport.
#
# Verwendung:
#   PowerShell-Konsole öffnen → ".\Import_Assets_From_Downloads.ps1" im game-Ordner ausführen
#   ODER: PS-Befehl: & 'c:\KI-Projekte\Godot\game\Import_Assets_From_Downloads.ps1'

$ErrorActionPreference = "Stop"

$dl = "$env:USERPROFILE\Downloads"
$game_root = "c:\KI-Projekte\Godot\game"
$game_assets = "$game_root\assets"
$godot_exe = "c:\KI-Projekte\Godot\bin\Godot_v4.6.3-stable_win64_console.exe"

# Mapping: Downloads-Filename → Target im Projekt + ob BG-Removal nötig
$mapping = @{
    # A — Charaktere (Hintergrund Teil des Bildes — KEIN BG-Removal)
    "A1.png" = @{ target = "$game_assets\characters\char_pressure.png"; remove_bg = $false }
    "A2.png" = @{ target = "$game_assets\characters\char_blunt.png"; remove_bg = $false }
    "A3.png" = @{ target = "$game_assets\characters\char_reactive.png"; remove_bg = $false }
    # B — Bosse
    "B1.png" = @{ target = "$game_assets\bosses\boss_uhrwerk_hexe.png"; remove_bg = $false }
    "B2.png" = @{ target = "$game_assets\bosses\boss_funken_tyrann.png"; remove_bg = $false }
    "B3.png" = @{ target = "$game_assets\bosses\boss_stiller_maschinist.png"; remove_bg = $false }
    "B4.png" = @{ target = "$game_assets\bosses\boss_oelbaron_krasnik.png"; remove_bg = $false }
    "B5.png" = @{ target = "$game_assets\bosses\boss_schwarze_lokomotive.png"; remove_bg = $false }
    # C — Items (weißer Hintergrund → BG-Removal)
    "C1.png" = @{ target = "$game_assets\items\alchemist_flask.png"; remove_bg = $true }
    "C2.png" = @{ target = "$game_assets\items\firebomb.png"; remove_bg = $true }
    "C3.png" = @{ target = "$game_assets\items\ice_diffuser.png"; remove_bg = $true }
    "C4.png" = @{ target = "$game_assets\items\steel_aegis.png"; remove_bg = $true }
    "C5.png" = @{ target = "$game_assets\items\phosphor_lobber.png"; remove_bg = $true }
    "C6.png" = @{ target = "$game_assets\items\aegis_pump.png"; remove_bg = $true }
    # D — City-Backgrounds (Bild komplett gefüllt, KEIN BG-Removal)
    "D1.png" = @{ target = "$game_assets\backgrounds\bg_city_far_buildings.png"; remove_bg = $false }
    "D2.png" = @{ target = "$game_assets\backgrounds\bg_city_mid_buildings.png"; remove_bg = $false }
    "D3.png" = @{ target = "$game_assets\backgrounds\bg_city_foreground.png"; remove_bg = $false }
    # E — Map-Knoten-Icons (weißer Hintergrund)
    "E1.png" = @{ target = "$game_assets\ui\map_nodes\map_start.png"; remove_bg = $true }
    "E2.png" = @{ target = "$game_assets\ui\map_nodes\map_combat.png"; remove_bg = $true }
    "E3.png" = @{ target = "$game_assets\ui\map_nodes\map_elite.png"; remove_bg = $true }
    "E4.png" = @{ target = "$game_assets\ui\map_nodes\map_boss.png"; remove_bg = $true }
    "E5.png" = @{ target = "$game_assets\ui\map_nodes\map_shop.png"; remove_bg = $true }
    "E6.png" = @{ target = "$game_assets\ui\map_nodes\map_heal.png"; remove_bg = $true }
    "E7.png" = @{ target = "$game_assets\ui\map_nodes\map_event.png"; remove_bg = $true }
    # F — Tower-Etagen
    "F1.png" = @{ target = "$game_assets\tower\tower_floor_foundation.png"; remove_bg = $true }
    "F2.png" = @{ target = "$game_assets\tower\tower_floor_workshop.png"; remove_bg = $true }
    "F3.png" = @{ target = "$game_assets\tower\tower_floor_top.png"; remove_bg = $true }
    # G — UI-Frames
    "G1.png" = @{ target = "$game_assets\ui\frames\ui_button_default.png"; remove_bg = $true }
    "G2.png" = @{ target = "$game_assets\ui\frames\ui_button_hover.png"; remove_bg = $true }
    "G3.png" = @{ target = "$game_assets\ui\frames\ui_button_pressed.png"; remove_bg = $true }
    "G4.png" = @{ target = "$game_assets\ui\frames\ui_frame_common.png"; remove_bg = $true }
    "G5.png" = @{ target = "$game_assets\ui\frames\ui_frame_uncommon.png"; remove_bg = $true }
    "G6.png" = @{ target = "$game_assets\ui\frames\ui_frame_rare.png"; remove_bg = $true }
    "G7.png" = @{ target = "$game_assets\ui\frames\ui_frame_legendary.png"; remove_bg = $true }
    # H — Partikel (mittel-grauer Hintergrund, additive im Spiel)
    "H1.png" = @{ target = "$game_assets\particles\particle_spark.png"; remove_bg = $false }
    "H2.png" = @{ target = "$game_assets\particles\particle_steam.png"; remove_bg = $false }
    "H3.png" = @{ target = "$game_assets\particles\particle_smoke.png"; remove_bg = $false }
    "H4.png" = @{ target = "$game_assets\particles\particle_oil_drop.png"; remove_bg = $false }
    "H5.png" = @{ target = "$game_assets\particles\particle_splinter.png"; remove_bg = $false }
    # A4 — Pyrotechniker (Neugenerierung im neuen Style)
    "A4.png" = @{ target = "$game_assets\characters\char_fire.png"; remove_bg = $false }
    "A5.png" = @{ target = "$game_assets\characters\char_gunner.png"; remove_bg = $false }
    "A6.png" = @{ target = "$game_assets\characters\char_mastermind.png"; remove_bg = $false }
    # Z — Hero-Backgrounds (volles Bild)
    "Z1.png" = @{ target = "$game_assets\backgrounds\bg_main_menu.png"; remove_bg = $false }
    "Z2.png" = @{ target = "$game_assets\backgrounds\bg_map_parchment.png"; remove_bg = $false }
    "Z3.png" = @{ target = "$game_assets\backgrounds\bg_runstart.png"; remove_bg = $false }
    "Z4.png" = @{ target = "$game_assets\backgrounds\bg_workshop.png"; remove_bg = $false }
    "Z5.png" = @{ target = "$game_assets\backgrounds\bg_stats.png"; remove_bg = $false }
    "Z6.png" = @{ target = "$game_assets\backgrounds\bg_settings.png"; remove_bg = $false }
    "Z7.png" = @{ target = "$game_assets\backgrounds\bg_victory.png"; remove_bg = $false }
    "Z8.png" = @{ target = "$game_assets\backgrounds\bg_defeat.png"; remove_bg = $false }
    "Z9.png" = @{ target = "$game_assets\backgrounds\bg_heal.png"; remove_bg = $false }
    "Z10.png" = @{ target = "$game_assets\backgrounds\bg_tower_builder.png"; remove_bg = $false }
    "Z11.png" = @{ target = "$game_assets\backgrounds\bg_sandbox.png"; remove_bg = $false }
    # C7-C12 — neue Kanonenmeister-Items
    "C7.png" = @{ target = "$game_assets\items\triple_cannon.png"; remove_bg = $true }
    "C8.png" = @{ target = "$game_assets\items\ammo_belt.png"; remove_bg = $true }
    "C9.png" = @{ target = "$game_assets\items\armor_plate.png"; remove_bg = $true }
    "C10.png" = @{ target = "$game_assets\items\grappling_hook.png"; remove_bg = $true }
    "C11.png" = @{ target = "$game_assets\items\stabilizer_brace.png"; remove_bg = $true }
    "C12.png" = @{ target = "$game_assets\items\grenade_launcher.png"; remove_bg = $true }
    # P1-P13 — Perk-Icons (weisser Hintergrund)
    "P1.png" = @{ target = "$game_assets\ui\perks\perk_notvorrat.png"; remove_bg = $true }
    "P2.png" = @{ target = "$game_assets\ui\perks\perk_schnellfeuer.png"; remove_bg = $true }
    "P3.png" = @{ target = "$game_assets\ui\perks\perk_aetherantrieb.png"; remove_bg = $true }
    "P4.png" = @{ target = "$game_assets\ui\perks\perk_druckverwerter.png"; remove_bg = $true }
    "P5.png" = @{ target = "$game_assets\ui\perks\perk_werkbank_mogul.png"; remove_bg = $true }
    "P6.png" = @{ target = "$game_assets\ui\perks\perk_gluecksrad.png"; remove_bg = $true }
    "P7.png" = @{ target = "$game_assets\ui\perks\perk_reaktiv_kette.png"; remove_bg = $true }
    "P8.png" = @{ target = "$game_assets\ui\perks\perk_eisenhaut.png"; remove_bg = $true }
    "P9.png" = @{ target = "$game_assets\ui\perks\perk_marktkenner.png"; remove_bg = $true }
    "P10.png" = @{ target = "$game_assets\ui\perks\perk_pluendererglueck.png"; remove_bg = $true }
    "P11.png" = @{ target = "$game_assets\ui\perks\perk_kritstrom.png"; remove_bg = $true }
    "P12.png" = @{ target = "$game_assets\ui\perks\perk_brand_stapel.png"; remove_bg = $true }
    "P13.png" = @{ target = "$game_assets\ui\perks\perk_zeitloser_mechanismus.png"; remove_bg = $true }
    # U — Werkstatt-Upgrade-Icons (weißer Hintergrund)
    "U1.png" = @{ target = "$game_assets\ui\upgrades\upgrade_gold.png"; remove_bg = $true }
    "U2.png" = @{ target = "$game_assets\ui\upgrades\upgrade_tower.png"; remove_bg = $true }
    "U3.png" = @{ target = "$game_assets\ui\upgrades\upgrade_market.png"; remove_bg = $true }
    "U4.png" = @{ target = "$game_assets\ui\upgrades\upgrade_shop_plus.png"; remove_bg = $true }
    "U5.png" = @{ target = "$game_assets\ui\upgrades\upgrade_heal.png"; remove_bg = $true }
    "U6.png" = @{ target = "$game_assets\ui\upgrades\upgrade_salvage.png"; remove_bg = $true }
    "U7.png" = @{ target = "$game_assets\ui\upgrades\upgrade_skip.png"; remove_bg = $true }
    "U8.png" = @{ target = "$game_assets\ui\upgrades\upgrade_extra_item.png"; remove_bg = $true }
    "U9.png" = @{ target = "$game_assets\ui\upgrades\upgrade_crit.png"; remove_bg = $true }
    "U10.png" = @{ target = "$game_assets\ui\upgrades\upgrade_elite_gold.png"; remove_bg = $true }
    "U11.png" = @{ target = "$game_assets\ui\upgrades\upgrade_luck.png"; remove_bg = $true }
    "U12.png" = @{ target = "$game_assets\ui\upgrades\upgrade_discovery.png"; remove_bg = $true }
    "U13.png" = @{ target = "$game_assets\ui\upgrades\upgrade_shield.png"; remove_bg = $true }
    "U14.png" = @{ target = "$game_assets\ui\upgrades\upgrade_boss_heal.png"; remove_bg = $true }
}

Add-Type -AssemblyName System.Drawing

function Remove-WhiteBackground {
    param([string]$Path, [int]$Threshold = 240)
    $src = New-Object System.Drawing.Bitmap($Path)
    $w = $src.Width; $h = $src.Height
    $dst = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $srcData = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $dstData = $dst.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $bytes = $srcData.Stride * $h
    $buf = New-Object byte[] $bytes
    [System.Runtime.InteropServices.Marshal]::Copy($srcData.Scan0, $buf, 0, $bytes)
    $softMin = $Threshold - 25; $softMax = $Threshold
    for ($i = 0; $i -lt $bytes; $i += 4) {
        $b = $buf[$i]; $g = $buf[$i + 1]; $r = $buf[$i + 2]
        $m = [Math]::Min($r, [Math]::Min($g, $b))
        if ($m -ge $softMax) { $buf[$i + 3] = 0 }
        elseif ($m -ge $softMin) {
            $a = 255 - [int](255.0 * ($m - $softMin) / ($softMax - $softMin))
            $buf[$i + 3] = [byte]$a
        }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $dstData.Scan0, $bytes)
    $src.UnlockBits($srcData); $dst.UnlockBits($dstData); $src.Dispose()
    $dst.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png); $dst.Dispose()
}

# Godot stoppen
Get-Process | Where-Object { $_.ProcessName -like "*Godot*" -or $_.ProcessName -eq "Cogwright" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 600

$moved = 0; $bg_removed = 0
foreach ($key in $mapping.Keys | Sort-Object) {
    $src_file = Join-Path $dl $key
    if (-not (Test-Path $src_file)) { continue }
    $info = $mapping[$key]
    $target_dir = Split-Path $info.target -Parent
    if (-not (Test-Path $target_dir)) { New-Item -ItemType Directory -Force -Path $target_dir | Out-Null }
    Copy-Item $src_file $info.target -Force
    $moved += 1
    Write-Host "  $key -> $($info.target.Replace($game_assets + '\', ''))"
    if ($info.remove_bg) {
        Remove-WhiteBackground -Path $info.target -Threshold 240
        $bg_removed += 1
    }
}
Write-Host ""
Write-Host "Verschoben: $moved, BG-Removed: $bg_removed"

if ($moved -gt 0) {
    Write-Host ""
    Write-Host "Headless-Reimport..."
    & $godot_exe --headless --path $game_root --import --quit 2>&1 | Select-String "DONE|ERROR" | Select-Object -Last 5
}
