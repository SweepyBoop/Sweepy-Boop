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
$gameDir = "C:\Program Files (x86)\World of Warcraft"

$addonDirs = @(
    (Join-Path $gameDir "_retail_\Interface\Addons\SweepyBoop"),
    (Join-Path $gameDir "_classic_\Interface\Addons\SweepyBoop"),
    (Join-Path $gameDir "_classic_ptr_\Interface\Addons\SweepyBoop")
    (Join-Path $gameDir "_anniversary_\Interface\Addons\SweepyBoop"),
)

foreach ($dir in $addonDirs) {
    Update-TestMode -addonDir $dir -Off:$Off
}
