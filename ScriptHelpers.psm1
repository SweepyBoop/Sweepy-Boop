$ErrorActionPreference = "Stop"

function Get-WowInstallPath {
    param (
        [ValidateSet("Windows", "Mac")]
        [string]$Platform
    )

    if (-not $Platform) {
        $Platform = if ([System.IO.Path]::DirectorySeparatorChar -eq "\") { "Windows" } else { "Mac" }
    }

    $configPath = Join-Path $PSScriptRoot "WoWInstallPaths.txt"
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Configuration file is missing: $configPath"
    }

    $key = if ($Platform -eq "Windows") { "WINDOWS_WOW_PATH" } else { "MAC_WOW_PATH" }
    $entry = Get-Content -LiteralPath $configPath |
        Where-Object { $_ -match "^\s*$([regex]::Escape($key))\s*=" } |
        Select-Object -First 1

    if (-not $entry) {
        throw "$key is not set in $configPath"
    }

    $value = ($entry -split "=", 2)[1].Trim()
    if (-not $value) {
        throw "$key is empty in $configPath"
    }

    return $value
}
