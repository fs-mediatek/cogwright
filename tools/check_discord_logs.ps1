# Discord-Log-Reader: holt neue Battle-Telemetry-Embeds aus dem Test-Channel
# und schreibt sie als JSON-Liste auf stdout. Inkrementell via .discord_last_seen_id.
#
# Verwendung:
#   .\tools\check_discord_logs.ps1            # nur neue seit letztem Aufruf
#   .\tools\check_discord_logs.ps1 -All       # alle (bis 100), ignoriert last_seen
#   .\tools\check_discord_logs.ps1 -Limit 25  # max N Messages

param(
    [switch]$All,
    [int]$Limit = 50
)

$ErrorActionPreference = "Stop"

$root = "c:\KI-Projekte\Godot"
$token_file = "$root\.discord_bot_token"
$channel_file = "$root\.discord_channel_id"
$last_seen_file = "$root\.discord_last_seen_id"

if (-not (Test-Path $token_file) -or -not (Test-Path $channel_file)) {
    Write-Error "Bot-Token oder Channel-ID fehlen ($token_file / $channel_file)"
    exit 1
}

$token = (Get-Content $token_file -Raw).Trim()
$channel = (Get-Content $channel_file -Raw).Trim()
$last_seen = if ((-not $All) -and (Test-Path $last_seen_file)) { (Get-Content $last_seen_file -Raw).Trim() } else { "" }

$headers = @{
    "Authorization" = "Bot $token"
    "User-Agent" = "CogwrightLogReader (v0.2.1)"
}

$url = "https://discord.com/api/v10/channels/$channel/messages?limit=$Limit"
if ($last_seen -ne "") { $url += "&after=$last_seen" }

$msgs = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop

if ($msgs.Count -eq 0) {
    Write-Output "{`"count`": 0, `"messages`": []}"
    exit 0
}

# Neuestes Message-ID merken (Discord liefert neuestes zuerst)
$newest_id = $msgs[0].id
$newest_id | Out-File $last_seen_file -Encoding utf8 -NoNewline

# Drei Message-Typen:
#  - "telemetry"  = Embed mit Charakter-Field (Battle-Log vom Spiel)
#  - "feedback"   = Plain-Text von einem echten Tester (kein Bot, kein Webhook)
#  - "system"     = sonstige (eigene Summary-Posts, Bot-Echo) — werden geskippt
$results = @()
foreach ($m in $msgs) {
    $is_bot = [bool]$m.author.bot
    $has_embed = ($m.embeds -and $m.embeds.Count -gt 0)
    $content = if ($m.content) { $m.content } else { "" }
    $author_name = $m.author.username
    $author_id = $m.author.id

    if ($has_embed -and $is_bot) {
        # Telemetry-Embed (Webhook vom Spiel)
        $e = $m.embeds[0]
        # Skip: unser eigenes Auto-Analyse-Embed (vom Reader-Bot oder Auto-Analyse-Webhook)
        $is_self = ($e.title -match "Auto-Analyse|Telemetry-Setup-Test")
        if ($is_self) { continue }
        $entry = @{
            id = $m.id
            timestamp = $m.timestamp
            type = "telemetry"
            title = $e.title
        }
        foreach ($f in $e.fields) {
            $key = ($f.name -replace "[^a-zA-Z]", "_").ToLower()
            $entry[$key] = $f.value
        }
        $results += $entry
    } elseif ((-not $is_bot) -and ($content.Trim() -ne "")) {
        # Echte Tester-Nachricht (Feedback)
        $results += @{
            id = $m.id
            timestamp = $m.timestamp
            type = "feedback"
            author = $author_name
            author_id = $author_id
            content = $content
        }
    }
}

$payload = @{
    count = $results.Count
    newest_id = $newest_id
    messages = $results
}
$payload | ConvertTo-Json -Depth 6 -Compress
