param (
    [switch]$Off
)

$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\SweepyBoop"
$constantsFile = Join-Path -Path $addonDir -ChildPath "Common\Constants.lua"
$addonDirCata = "D:\World of Warcraft\_classic_\Interface\Addons\SweepyBoop"
$constantsFileCata = Join-Path -Path $addonDirCata -ChildPath "Common\Constants.lua"
$addonDirMop = "D:\World of Warcraft\_classic_beta_\Interface\Addons\SweepyBoop"
$constantsFileMop = Join-Path -Path $addonDirMop -ChildPath "Common\Constants.lua"

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

# Repeat the same process for the Mop version
if (Test-Path $constantsFileMop) {
    $fileContentMop = Get-Content -Path $constantsFileMop -Encoding UTF8
} else {
    Write-Error "The file '$constantsFileMop' does not exist."
    exit 1
}

$newLineMop = if ($Off) {
    "addon.TEST_MODE = false;"
} else {
    "addon.TEST_MODE = true;"
}

# Replace the line containing "addon.TEST_MODE" or add it if it doesn't exist
if ($fileContentMop -match "addon\.TEST_MODE") {
    $fileContentMop = $fileContentMop -replace "addon\.TEST_MODE\s*=\s*.*?;", $newLineMop
} else {
    $fileContentMop += $newLineMop
}

# Write the modified content back to the file
$fileContentMop | Set-Content -Path $constantsFileMop -Encoding UTF8

Write-Output "Updated $constantsFileMop successfully."
