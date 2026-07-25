<#
.SYNOPSIS
Compares PvP title achievement timestamps across WoW characters.

.DESCRIPTION
Queries Blizzard's public character achievements endpoint for one or more
characters, filters Gladiator/Elite/Legend-style PvP achievements, and writes a
compact comparison JSON. This is useful for validating public-data alt linking via
shared account-wide achievement timestamps.

Credentials are passed as parameters. If omitted, the script prompts for them:
  -ClientId
  -ClientSecret

Example:
  pwsh .\Tools\CompareBlizzardPvPAchievements.ps1 -ClientId "..."
#>

[CmdletBinding()]
param(
    [string]$Region = "us",
    [string]$Realm = "tichondrius",
    [string[]]$Characters = @("Swëëpyßööp", "Swëëpybööp"),
    [string]$Locale = "en_US",
    [string]$OutputDir = (Join-Path $PSScriptRoot "BlizzardAchievementCompareOutput"),
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

function Get-PvPTitleAchievements {
    param(
        [Parameter(Mandatory = $true)]$AchievementPayload,
        [Parameter(Mandatory = $true)][string]$CharacterName,
        [Parameter(Mandatory = $true)][string]$RealmSlug
    )

    $titlePattern = '(?i)(^gladiator$|^gladiator:|^elite:|^legend:|\bgladiator\b|\belite\b|\blegend\b)'

    foreach ($entry in @($AchievementPayload.achievements)) {
        $achievement = $entry.achievement
        if (-not $achievement -or [string]::IsNullOrWhiteSpace($achievement.name)) {
            continue
        }

        if ($achievement.name -notmatch $titlePattern) {
            continue
        }

        $completedUtc = $null
        if ($entry.completed_timestamp) {
            $completedUtc = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$entry.completed_timestamp).UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss")
        }

        [pscustomobject]@{
            character = "$CharacterName-$RealmSlug"
            achievementId = $achievement.id
            achievementName = $achievement.name
            completedTimestamp = $entry.completed_timestamp
            completedUtc = $completedUtc
        }
    }
}

$regionSlug = ConvertTo-Slug $Region
$realmSlug = ConvertTo-Slug $Realm
$apiHost = Get-BlizzardApiHost -Region $regionSlug
$profileNamespace = "profile-$regionSlug"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Host "Blizzard PvP achievement comparison"
Write-Host "  Region:     $regionSlug"
Write-Host "  Realm:      $realmSlug"
Write-Host "  Characters: $($Characters -join ', ')"
Write-Host "  Output:     $OutputDir"

if ([string]::IsNullOrWhiteSpace($ClientId)) {
    $ClientId = Read-Host "Blizzard client id"
}

if ([string]::IsNullOrWhiteSpace($ClientSecret)) {
    $secureClientSecret = Read-Host "Blizzard client secret" -AsSecureString
    $ClientSecret = Read-PlainTextSecret -SecureString $secureClientSecret
}

$token = Get-AccessToken -Region $regionSlug -ClientId $ClientId -ClientSecret $ClientSecret
$results = @()
$comparison = @()

foreach ($character in $Characters) {
    $characterSlug = ConvertTo-Slug $character
    $encodedCharacter = [Uri]::EscapeDataString($characterSlug)
    $uri = "$apiHost/profile/wow/character/$realmSlug/$encodedCharacter/achievements?namespace=$profileNamespace&locale=$Locale"
    $result = Invoke-BlizzardApi -Name "character-achievements-$characterSlug" -Uri $uri -Token $token -OutputDir $OutputDir
    $results += $result

    if ($result.Status -eq "OK") {
        $comparison += @(Get-PvPTitleAchievements -AchievementPayload $result.Body -CharacterName $character -RealmSlug $realmSlug)
    }
}

$summaryPath = Join-Path $OutputDir "summary.json"
$results | Select-Object Name, Status, StatusCode, Path | ConvertTo-Json -Depth 20 | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "Summary: $summaryPath"

$comparisonPath = Join-Path $OutputDir "pvp-title-achievement-comparison.json"
$comparison | Sort-Object achievementName, completedTimestamp, character | ConvertTo-Json -Depth 20 | Set-Content -Path $comparisonPath -Encoding UTF8
Write-Host "Comparison: $comparisonPath"

$groupPath = Join-Path $OutputDir "pvp-title-achievement-groups.json"
$comparison |
    Group-Object -Property @{ Expression = { "$($_.achievementId):$($_.completedTimestamp)" } } |
    ForEach-Object {
        $items = @($_.Group)
        $characters = @($items | ForEach-Object { $_.character } | Sort-Object -Unique)
        [pscustomobject]@{
            achievementId = $items[0].achievementId
            achievementName = $items[0].achievementName
            completedTimestamp = $items[0].completedTimestamp
            completedUtc = $items[0].completedUtc
            characters = $characters
            characterCount = $characters.Count
        }
    } |
    Sort-Object achievementName, completedTimestamp |
    ConvertTo-Json -Depth 20 |
    Set-Content -Path $groupPath -Encoding UTF8
Write-Host "Groups: $groupPath"

$failed = @($results | Where-Object { $_.Status -ne "OK" })
if ($failed.Count -gt 0) {
    Write-Warning "$($failed.Count) request(s) failed. Inspect the generated JSON files."
}
