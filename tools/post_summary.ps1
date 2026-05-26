# Postet einen Summary-Embed an den Test-Channel via Webhook.
#
# Aufruf:
#   .\tools\post_summary.ps1 -Title "..." -Lines @("...","...")

param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][AllowEmptyString()][string[]]$Lines,
    [int]$Color = 0xFFC107
)

$ErrorActionPreference = "Stop"

$webhook = "https://discord.com/api/webhooks/1508835274271232051/HVdpzGoMyy7RxQhFy1Z58H4wrDzXTyLRZyDYv_Me51YKJXoBzgL3WA_8Kp4wbnBBoerT"

$body = @{
    username = "Cogwright Auto-Analyse"
    embeds = @(
        @{
            title = $Title
            color = $Color
            description = ($Lines -join "`n")
            timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    )
} | ConvertTo-Json -Depth 5

# Explizit UTF-8 senden (Discord verlangt das, PowerShell-Default ist sonst kaputt)
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
Invoke-WebRequest -Uri $webhook -Method Post -Body $bytes -ContentType "application/json; charset=utf-8" -UseBasicParsing | Out-Null
"Posted: $Title"
