<#
.SYNOPSIS
Probes Blizzard's public World of Warcraft APIs for PvP-related character data.

.DESCRIPTION
This script is intentionally external to the addon runtime. WoW addons cannot call
Blizzard's web APIs directly, so this is a development probe for discovering which
fields are available before generating addon snapshot data.

Credentials are passed as parameters. If omitted, the script prompts for them:
  -ClientId
  -ClientSecret

Example:
  pwsh .\Tools\ProbeBlizzardPvP.ps1 -ClientId "..."

You can also pass the secret explicitly, but that can leave it in shell history:
  pwsh .\Tools\ProbeBlizzardPvP.ps1 -ClientId "..." -ClientSecret "..."

Outputs raw JSON responses into .\Tools\BlizzardProbeOutput by default.
#>

[CmdletBinding()]
param(
    [string]$Region = "us",
    [string]$Realm = "tichondrius",
    [string]$Character = "Swëëpybööp",
    [string]$Locale = "en_US",
    [string[]]$ExtraBrackets = @(),
    [string]$OutputDir = (Join-Path $PSScriptRoot "BlizzardProbeOutput"),
    [string]$ClientId,
    [string]$ClientSecret,
    [switch]$IncludeLeaderboards
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-Slug {
    param([Parameter(Mandatory = $true)][string]$Value)
    return $Value.Trim().ToLowerInvariant().Replace(" ", "-")
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

$regionSlug = ConvertTo-Slug $Region
$realmSlug = ConvertTo-Slug $Realm
$characterSlug = ConvertTo-Slug $Character
$apiHost = Get-BlizzardApiHost -Region $regionSlug
$profileNamespace = "profile-$regionSlug"
$dynamicNamespace = "dynamic-$regionSlug"
$staticNamespace = "static-$regionSlug"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Host "Blizzard PvP probe"
Write-Host "  Region:    $regionSlug"
Write-Host "  Realm:     $realmSlug"
Write-Host "  Character: $characterSlug"
Write-Host "  Output:    $OutputDir"

if ([string]::IsNullOrWhiteSpace($ClientId)) {
    $ClientId = Read-Host "Blizzard client id"
}

if ([string]::IsNullOrWhiteSpace($ClientSecret)) {
    $secureClientSecret = Read-Host "Blizzard client secret" -AsSecureString
    $ClientSecret = Read-PlainTextSecret -SecureString $secureClientSecret
}

$token = Get-AccessToken -Region $regionSlug -ClientId $ClientId -ClientSecret $ClientSecret

$encodedCharacter = [Uri]::EscapeDataString($characterSlug)
$characterBase = "$apiHost/profile/wow/character/$realmSlug/$encodedCharacter"

$pvpSummaryResult = Invoke-BlizzardApi `
    -Name "character-pvp-summary" `
    -Uri "$characterBase/pvp-summary?namespace=$profileNamespace&locale=$Locale" `
    -Token $token `
    -OutputDir $OutputDir

$requests = @(
    @{ Name = "character-profile"; Uri = "$characterBase`?namespace=$profileNamespace&locale=$Locale" },
    @{ Name = "character-achievements"; Uri = "$characterBase/achievements?namespace=$profileNamespace&locale=$Locale" },
    @{ Name = "character-achievement-statistics"; Uri = "$characterBase/achievements/statistics?namespace=$profileNamespace&locale=$Locale" },
    @{ Name = "character-statistics"; Uri = "$characterBase/statistics?namespace=$profileNamespace&locale=$Locale" },
    @{ Name = "character-media"; Uri = "$characterBase/character-media?namespace=$profileNamespace&locale=$Locale" },
    @{ Name = "pvp-season-index"; Uri = "$apiHost/data/wow/pvp-season/index?namespace=$dynamicNamespace&locale=$Locale" },
    @{ Name = "pvp-tier-index"; Uri = "$apiHost/data/wow/pvp-tier/index?namespace=$staticNamespace&locale=$Locale" },
    @{ Name = "realm-index"; Uri = "$apiHost/data/wow/realm/index?namespace=$dynamicNamespace&locale=$Locale" }
)

if ($pvpSummaryResult.Status -eq "OK" -and $pvpSummaryResult.Body.brackets) {
    foreach ($bracket in $pvpSummaryResult.Body.brackets) {
        $href = [string]$bracket.href
        $bracketSlug = ($href -replace '^.*/pvp-bracket/', '') -replace '\?.*$', ''
        if (-not [string]::IsNullOrWhiteSpace($bracketSlug)) {
            $requests += @{ Name = "character-pvp-bracket-$bracketSlug"; Uri = "$characterBase/pvp-bracket/$bracketSlug`?namespace=$profileNamespace&locale=$Locale" }
        }
    }
}

foreach ($bracket in $ExtraBrackets) {
    $bracketSlug = ConvertTo-Slug $bracket
    $requests += @{ Name = "character-pvp-bracket-extra-$bracketSlug"; Uri = "$characterBase/pvp-bracket/$bracketSlug`?namespace=$profileNamespace&locale=$Locale" }
}

if ($IncludeLeaderboards) {
    Write-Host "Leaderboards require a season id. The script writes pvp-season-index first; pass a concrete request manually after inspecting it."
}

$results = @($pvpSummaryResult)
$results += foreach ($request in $requests) {
    Invoke-BlizzardApi -Name $request.Name -Uri $request.Uri -Token $token -OutputDir $OutputDir
}

$summaryResults = $results | Select-Object Name, Status, StatusCode, Path
$summaryPath = Join-Path $OutputDir "summary.json"
$summaryResults | ConvertTo-Json -Depth 20 | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "Summary: $summaryPath"

$failed = @($results | Where-Object { $_.Status -ne "OK" })
if ($failed.Count -gt 0) {
    Write-Warning "$($failed.Count) request(s) failed. Inspect the generated JSON files."
}
