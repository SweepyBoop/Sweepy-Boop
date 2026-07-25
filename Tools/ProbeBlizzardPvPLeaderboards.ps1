<#
.SYNOPSIS
Probes Blizzard's public World of Warcraft PvP leaderboard APIs.

.DESCRIPTION
This script discovers PvP seasons and leaderboard brackets, fetches leaderboard
payloads, and writes raw JSON plus a compact summary. It is intended to evaluate
whether PvP leaderboards are a practical seed source for generating addon snapshot
data.

Credentials are passed as parameters. If omitted, the script prompts for them:
  -ClientId
  -ClientSecret

Example:
  pwsh .\Tools\ProbeBlizzardPvPLeaderboards.ps1 -ClientId "..."

Outputs raw JSON responses into .\Tools\BlizzardLeaderboardProbeOutput by default.
#>

[CmdletBinding()]
param(
    [string]$Region = "us",
    [string]$Locale = "en_US",
    [string]$SeasonId,
    [string[]]$Brackets = @(),
    [string]$OutputDir = (Join-Path $PSScriptRoot "BlizzardLeaderboardProbeOutput"),
    [string]$ClientId,
    [string]$ClientSecret
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-Slug {
    param([Parameter(Mandatory = $true)][string]$Value)
    return $Value.Trim().ToLowerInvariant().Replace(" ", "-")
}

function Read-PlainTextSecret {
    param([Parameter(Mandatory = $true)][Security.SecureString]$SecureString)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Get-BlizzardOAuthHost {
    param([Parameter(Mandatory = $true)][string]$Region)

    if ($Region.ToLowerInvariant() -eq "cn") {
        return "https://www.battlenet.com.cn"
    }

    return "https://oauth.battle.net"
}

function Get-BlizzardApiHost {
    param([Parameter(Mandatory = $true)][string]$Region)
    return "https://$($Region.ToLowerInvariant()).api.blizzard.com"
}

function Get-AccessToken {
    param(
        [Parameter(Mandatory = $true)][string]$Region,
        [Parameter(Mandatory = $true)][string]$ClientId,
        [Parameter(Mandatory = $true)][string]$ClientSecret
    )

    if ([string]::IsNullOrWhiteSpace($ClientId) -or [string]::IsNullOrWhiteSpace($ClientSecret)) {
        throw "ClientId and ClientSecret are required. Pass -ClientId and -ClientSecret, or omit either value to be prompted."
    }

    $pair = "${ClientId}:${ClientSecret}"
    $basicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
    $oauthHost = Get-BlizzardOAuthHost -Region $Region

    $response = Invoke-RestMethod `
        -Method Post `
        -Uri "$oauthHost/token" `
        -Headers @{ Authorization = "Basic $basicAuth" } `
        -ContentType "application/x-www-form-urlencoded" `
        -Body "grant_type=client_credentials"

    return $response.access_token
}

function Invoke-BlizzardApi {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$OutputDir
    )

    $safeName = $Name -replace "[^A-Za-z0-9_.-]", "_"
    $outputPath = Join-Path $OutputDir "$safeName.json"

    Write-Host "GET $Name"
    Write-Host "  $Uri"

    try {
        $response = Invoke-RestMethod `
            -Method Get `
            -Uri $Uri `
            -Headers @{ Authorization = "Bearer $Token"; Accept = "application/json" }

        $response | ConvertTo-Json -Depth 100 | Set-Content -Path $outputPath -Encoding UTF8
        Write-Host "  -> wrote $outputPath"
        return @{ Name = $Name; Status = "OK"; Path = $outputPath; Body = $response }
    }
    catch {
        $statusCode = $null
        $errorBody = $null

        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = [IO.StreamReader]::new($stream)
                    $errorBody = $reader.ReadToEnd()
                }
            }
            catch {
                $errorBody = $null
            }
        }

        $errorRecord = [ordered]@{
            name = $Name
            uri = $Uri
            statusCode = $statusCode
            error = $_.Exception.Message
            body = $errorBody
        }

        $errorRecord | ConvertTo-Json -Depth 20 | Set-Content -Path $outputPath -Encoding UTF8
        Write-Warning "  -> failed; wrote $outputPath"
        return @{ Name = $Name; Status = "FAILED"; Path = $outputPath; StatusCode = $statusCode }
    }
}

function Get-IdFromHref {
    param([Parameter(Mandatory = $true)][string]$Href)

    $match = [regex]::Match($Href, '/pvp-season/(\d+)')
    if ($match.Success) {
        return [int]$match.Groups[1].Value
    }

    return $null
}

function Get-BracketSlugFromHref {
    param([Parameter(Mandatory = $true)][string]$Href)

    $match = [regex]::Match($Href, '/pvp-leaderboard/([^?]+)')
    if ($match.Success) {
        return [Uri]::UnescapeDataString($match.Groups[1].Value)
    }

    return $null
}

$regionSlug = ConvertTo-Slug $Region
$apiHost = Get-BlizzardApiHost -Region $regionSlug
$dynamicNamespace = "dynamic-$regionSlug"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Host "Blizzard PvP leaderboard probe"
Write-Host "  Region: $regionSlug"
Write-Host "  Output: $OutputDir"

if ([string]::IsNullOrWhiteSpace($ClientId)) {
    $ClientId = Read-Host "Blizzard client id"
}

if ([string]::IsNullOrWhiteSpace($ClientSecret)) {
    $secureClientSecret = Read-Host "Blizzard client secret" -AsSecureString
    $ClientSecret = Read-PlainTextSecret -SecureString $secureClientSecret
}

$token = Get-AccessToken -Region $regionSlug -ClientId $ClientId -ClientSecret $ClientSecret
$results = @()

$seasonIndexResult = Invoke-BlizzardApi `
    -Name "pvp-season-index" `
    -Uri "$apiHost/data/wow/pvp-season/index?namespace=$dynamicNamespace&locale=$Locale" `
    -Token $token `
    -OutputDir $OutputDir
$results += $seasonIndexResult

if ([string]::IsNullOrWhiteSpace($SeasonId)) {
    if ($seasonIndexResult.Status -ne "OK" -or -not $seasonIndexResult.Body.seasons) {
        throw "Cannot discover latest season because pvp-season-index failed or returned no seasons."
    }

    $SeasonId = [string]@($seasonIndexResult.Body.seasons | ForEach-Object { Get-IdFromHref -Href $_.key.href } | Where-Object { $_ -ne $null } | Sort-Object -Descending | Select-Object -First 1)[0]
}

Write-Host "  Season: $SeasonId"

$seasonResult = Invoke-BlizzardApi `
    -Name "pvp-season-$SeasonId" `
    -Uri "$apiHost/data/wow/pvp-season/$SeasonId`?namespace=$dynamicNamespace&locale=$Locale" `
    -Token $token `
    -OutputDir $OutputDir
$results += $seasonResult

$leaderboardIndexResult = Invoke-BlizzardApi `
    -Name "pvp-season-$SeasonId-leaderboard-index" `
    -Uri "$apiHost/data/wow/pvp-season/$SeasonId/pvp-leaderboard/index?namespace=$dynamicNamespace&locale=$Locale" `
    -Token $token `
    -OutputDir $OutputDir
$results += $leaderboardIndexResult

$bracketSlugs = @()
if ($Brackets.Count -gt 0) {
    $bracketSlugs = @($Brackets | ForEach-Object { ConvertTo-Slug $_ })
}
elseif ($leaderboardIndexResult.Status -eq "OK" -and $leaderboardIndexResult.Body.leaderboards) {
    $bracketSlugs = @(
        $leaderboardIndexResult.Body.leaderboards |
            ForEach-Object { Get-BracketSlugFromHref -Href $_.key.href } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Sort-Object -Unique
    )
}
else {
    throw "Cannot discover leaderboard brackets because leaderboard index failed or returned no leaderboards."
}

Write-Host "  Brackets: $($bracketSlugs -join ', ')"

$leaderboardSummaries = @()
foreach ($bracketSlug in $bracketSlugs) {
    $leaderboardResult = Invoke-BlizzardApi `
        -Name "pvp-season-$SeasonId-leaderboard-$bracketSlug" `
        -Uri "$apiHost/data/wow/pvp-season/$SeasonId/pvp-leaderboard/$bracketSlug`?namespace=$dynamicNamespace&locale=$Locale" `
        -Token $token `
        -OutputDir $OutputDir
    $results += $leaderboardResult

    if ($leaderboardResult.Status -eq "OK") {
        $entries = @($leaderboardResult.Body.entries)
        $topEntry = $entries | Sort-Object rank | Select-Object -First 1
        $leaderboardSummaries += [ordered]@{
            bracket = $bracketSlug
            entries = $entries.Count
            topRank = if ($topEntry) { $topEntry.rank } else { $null }
            topRating = if ($topEntry) { $topEntry.rating } else { $null }
            topCharacter = if ($topEntry) { "$($topEntry.character.name)-$($topEntry.character.realm.slug)" } else { $null }
        }
    }
}

$summaryResults = $results | Select-Object Name, Status, StatusCode, Path
$summaryPath = Join-Path $OutputDir "summary.json"
$summaryResults | ConvertTo-Json -Depth 20 | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "Summary: $summaryPath"

$leaderboardSummaryPath = Join-Path $OutputDir "leaderboard-summary.json"
$leaderboardSummaries | ConvertTo-Json -Depth 20 | Set-Content -Path $leaderboardSummaryPath -Encoding UTF8
Write-Host "Leaderboard summary: $leaderboardSummaryPath"

$failed = @($results | Where-Object { $_.Status -ne "OK" })
if ($failed.Count -gt 0) {
    Write-Warning "$($failed.Count) request(s) failed. Inspect the generated JSON files."
}
