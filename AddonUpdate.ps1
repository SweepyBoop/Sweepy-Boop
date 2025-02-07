$workDir = $PSScriptRoot
$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\SweepyBoop"
$classicDir = "D:\World of Warcraft\_classic_\Interface\Addons\SweepyBoop"

if (Test-Path -Path $addonDir) {
    Remove-Item -Path $addonDir -Recurse -Force
}
if (Test-Path -Path $classicDir) {
    Remove-Item -Path $classicDir -Recurse -Force
}
New-Item -ItemType Directory -Path $addonDir | Out-Null
New-Item -ItemType Directory -Path $classicDir | Out-Null

$extensions = @("*.lua", "*.toc", "*.xml")
foreach ($ext in $extensions) {
    Copy-Item -Path "$PSScriptRoot\$ext" -Destination $addonDir -Force
}
foreach ($ext in $extensions) {
    Copy-Item -Path "$PSScriptRoot\$ext" -Destination "$classicDir" -Force
}

$excludePatterns = @("*.git*", "*Docs*")
$dirsToCopy = Get-ChildItem -Path $workDir -Directory -Exclude $excludePatterns
foreach ($dir in $dirsToCopy) {
    $destPath = Join-Path -Path $addonDir -ChildPath $dir.Name
    Copy-Item -Path $dir.FullName -Destination $destPath -Recurse -Force
}
foreach ($dir in $dirsToCopy) {
    $destPath = Join-Path -Path $classicDir -ChildPath $dir.Name
    Copy-Item -Path $dir.FullName -Destination $destPath -Recurse -Force
}

$constantsFile = Join-Path -Path $addonDir -ChildPath "Common\Constants.lua"
"addon.internal = true;" | Out-File -FilePath $constantsFile -Append -Encoding UTF8
