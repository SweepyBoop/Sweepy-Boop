param (
    [switch]$Off
)

$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\SweepyBoop"
$constantsFile = Join-Path -Path $addonDir -ChildPath "Common\Constants.lua"

if (Test-Path $constantsFile) {
    $fileContent = Get-Content -Path $constantsFile -Encoding UTF8
} else {
    Write-Error "The file '$constantsFile' does not exist."
    exit 1
}

$newLine = if ($Off) {
    "addon.isTestMode = false;"
} else {
    "addon.isTestMode = true;"
}

# Replace the line containing "addon.isTestMode" or add it if it doesn't exist
if ($fileContent -match "addon\.isTestMode") {
    $fileContent = $fileContent -replace "addon\.isTestMode\s*=\s*.*?;", $newLine
} else {
    $fileContent += $newLine
}

# Write the modified content back to the file
$fileContent | Set-Content -Path $constantsFile -Encoding UTF8

Write-Output "Updated $constantsFile successfully."
