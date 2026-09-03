param (
    [switch]$Off
)

function Update-TestMode {
    param (
        [string]$addonDir,
        [switch]$Off
    )

    $constantsFile = Join-Path -Path $addonDir -ChildPath "Common\Constants.lua"

    if (-not (Test-Path $constantsFile)) {
        Write-Error "The file '$constantsFile' does not exist."
        return
    }

    $fileContent = Get-Content -Path $constantsFile -Encoding UTF8

    $newLine = if ($Off) {
        "addon.TEST_MODE = false;"
    } else {
        "addon.TEST_MODE = true;"
    }

    # Replace the line containing "addon.TEST_MODE" or add it if it doesn't exist
    if ($fileContent -match "addon\.TEST_MODE") {
        $fileContent = $fileContent -replace "addon\.TEST_MODE\s*=\s*.*?;", $newLine
    } else {
        $fileContent += $newLine
    }

    # Write back
    $fileContent | Set-Content -Path $constantsFile -Encoding UTF8

    Write-Output "Updated $constantsFile successfully."
}

# --- Usage ---
Import-Module (Join-Path $PSScriptRoot "ScriptHelpers.psm1") -Force
$gameDir = Get-WowInstallPath
if (-not (Test-Path -LiteralPath $gameDir -PathType Container)) {
    throw "World of Warcraft installation was not found: $gameDir. Update $(Join-Path $PSScriptRoot 'WoWInstallPaths.txt') after installing it."
}

$addonDirs = @(
    (Join-Path $gameDir "_retail_\Interface\AddOns\SweepyBoop"),
    (Join-Path $gameDir "_ptr_\Interface\AddOns\SweepyBoop"),
    (Join-Path $gameDir "_classic_\Interface\AddOns\SweepyBoop"),
    (Join-Path $gameDir "_classic_ptr_\Interface\AddOns\SweepyBoop"),
    (Join-Path $gameDir "_anniversary_\Interface\AddOns\SweepyBoop")
)

foreach ($dir in $addonDirs) {
    Update-TestMode -addonDir $dir -Off:$Off
}
