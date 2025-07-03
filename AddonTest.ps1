param (
    [switch]$Off
)

$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\SweepyBoop"
$constantsFile = Join-Path -Path $addonDir -ChildPath "Common\Constants.lua"
$addonDirCata = "D:\World of Warcraft\_classic_\Interface\Addons\SweepyBoop"
$constantsFileCata = Join-Path -Path $addonDirCata -ChildPath "Common\Constants.lua"
$addonDirMists = "D:\World of Warcraft\_classic_beta_\Interface\Addons\SweepyBoop"
$constantsFileMists = Join-Path -Path $addonDirMists -ChildPath

if (Test-Path $constantsFile) {
    $fileContent = Get-Content -Path $constantsFile -Encoding UTF8
} else {
    Write-Error "The file '$constantsFile' does not exist."
    exit 1
}

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

# Write the modified content back to the file
$fileContent | Set-Content -Path $constantsFile -Encoding UTF8

Write-Output "Updated $constantsFile successfully."

# Repeat the same process for the Cata version
if (Test-Path $constantsFileCata) {
    $fileContentCata = Get-Content -Path $constantsFileCata -Encoding UTF8
} else {
    Write-Error "The file '$constantsFileCata' does not exist."
    exit 1
}

$newLineCata = if ($Off) {
    "addon.TEST_MODE = false;"
} else {
    "addon.TEST_MODE = true;"
}

# Replace the line containing "addon.TEST_MODE" or add it if it doesn't exist
if ($fileContentCata -match "addon\.TEST_MODE") {
    $fileContentCata = $fileContentCata -replace "addon\.TEST_MODE\s*=\s*.*?;", $newLineCata
} else {
    $fileContentCata += $newLineCata
}

# Write the modified content back to the file
$fileContentCata | Set-Content -Path $constantsFileCata -Encoding UTF8

Write-Output "Updated $constantsFileCata successfully."

# Repeat the same process for the Mists version
if (Test-Path $constantsFileMists) {
    $fileContentMists = Get-Content -Path $constantsFileMists -Encoding UTF8
} else {
    Write-Error "The file '$constantsFileMists' does not exist."
    exit 1
}
$newLineMists = if ($Off) {
    "addon.TEST_MODE = false;"
} else {
    "addon.TEST_MODE = true;"
}

# Replace the line containing "addon.TEST_MODE" or add it if it doesn't exist
if ($fileContentMists -match "addon\.TEST_MODE") {
    $fileContentMists = $fileContentMists -replace "addon\.TEST_MODE\s*=\s*.*?;", $newLineMists
} else {
    $fileContentMists += $newLineMists
}

# Write the modified content back to the file
$fileContentMists | Set-Content -Path $constantsFileMists -Encoding UTF8

Write-Output "Updated $constantsFileMists successfully."
