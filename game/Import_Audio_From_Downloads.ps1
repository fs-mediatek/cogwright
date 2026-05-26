# Cogwright - Audio-Import-Pipeline
# Holt ElevenLabs-WAVs aus dem Downloads-Ordner, konvertiert zu OGG Vorbis,
# benennt um und reimport in Godot.
#
# Verwendung:
#   & 'c:\KI-Projekte\Godot\game\Import_Audio_From_Downloads.ps1'

$ErrorActionPreference = "Stop"

$dl = "$env:USERPROFILE\Downloads"
$game_root = "c:\KI-Projekte\Godot\game"
$audio_root = "$game_root\assets\audio\ambient"
$oneshots_root = "$audio_root\oneshots"
$archive = "$dl\_imported_audio"
$godot_exe = "c:\KI-Projekte\Godot\bin\Godot_v4.6.3-stable_win64_console.exe"

# ffmpeg-Pfad: erst PATH, dann WinGet-Install
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) {
    $ffmpeg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg*" -Filter "ffmpeg.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $ffmpeg) {
    Write-Error "ffmpeg nicht gefunden. Install: winget install Gyan.FFmpeg"
    return
}

# Mapping: Filename-Glob im Downloads -> Ziel-Path
$mapping = @(
    @{ pattern = "##_A1_*";            target = "$audio_root\ambient_menu.ogg"             },
    @{ pattern = "##_A2_*";            target = "$audio_root\ambient_map.ogg"              },
    @{ pattern = "Steampunk_combat_*"; target = "$audio_root\ambient_battle.ogg"           },
    @{ pattern = "Copy_block_(A3*";    target = "$audio_root\ambient_battle.ogg"           },
    @{ pattern = "##_A4_*";            target = "$audio_root\ambient_heal.ogg"             },
    @{ pattern = "##_A5_*";            target = "$audio_root\ambient_shop.ogg"             },
    @{ pattern = "##_A6_*";            target = "$audio_root\ambient_workshop.ogg"         },
    @{ pattern = "##_A7_*";            target = "$audio_root\ambient_boss_intro.ogg"       },
    @{ pattern = "##_A8_*";            target = "$audio_root\ambient_event.ogg"            },
    @{ pattern = "##_B1_*";            target = "$oneshots_root\sting_run_start.ogg"       },
    @{ pattern = "##_B2_*";            target = "$oneshots_root\sting_victory.ogg"         },
    @{ pattern = "##_B3_*";            target = "$oneshots_root\sting_defeat.ogg"          },
    @{ pattern = "##_B4_*";            target = "$oneshots_root\sting_node_pick.ogg"       },
    @{ pattern = "##_C1_*";            target = "$audio_root\combat_tension_rise.ogg"      },
    @{ pattern = "##_C2_*";            target = "$oneshots_root\combat_impact_var1.ogg"    },
    @{ pattern = "##_C3_*";            target = "$oneshots_root\combat_impact_var2.ogg"    },
    @{ pattern = "##_C4_*";            target = "$oneshots_root\combat_crit_ring.ogg"      }
)

foreach ($dir in @($audio_root, $oneshots_root, $archive)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

$converted = 0
$skipped = 0

foreach ($m in $mapping) {
    $src = Get-ChildItem $dl -Filter $m.pattern -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $src) {
        Write-Host ("  [skip] " + $m.pattern + " (keine Datei in Downloads)") -ForegroundColor DarkGray
        $skipped++
        continue
    }
    $target_name = Split-Path $m.target -Leaf
    Write-Host ("  " + $src.Name + "  ->  " + $target_name) -ForegroundColor Green
    # WAV -> OGG Vorbis (Q5 ~ 160 kbps, gute Qualitaet fuer Ambient)
    & $ffmpeg -y -hide_banner -loglevel error -i $src.FullName -c:a libvorbis -q:a 5 $m.target
    if ($LASTEXITCODE -ne 0) {
        Write-Warning ("ffmpeg-Fehler bei " + $src.Name + " - uebersprungen")
        $skipped++
        continue
    }
    # Original ins Archiv verschieben (idempotent)
    $archive_path = Join-Path $archive $src.Name
    if (Test-Path $archive_path) { Remove-Item $archive_path -Force }
    Move-Item $src.FullName $archive_path
    $converted++
}

Write-Host ""
Write-Host ("Konvertiert: " + $converted + ", Uebersprungen: " + $skipped) -ForegroundColor Cyan
Write-Host ""

Write-Host "Headless-Reimport..." -ForegroundColor Cyan
if (Test-Path $godot_exe) {
    & $godot_exe --headless --path $game_root --import --quit 2>&1 | Select-String -Pattern "DONE|ERROR|FAIL" | Select-Object -Last 12
} else {
    Write-Warning ("Godot-Binary nicht gefunden: " + $godot_exe + " - bitte manuell reimportieren")
}
