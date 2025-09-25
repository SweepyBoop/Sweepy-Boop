$workDir = $PSScriptRoot
$gameDir    = "C:\Program Files (x86)\World of Warcraft"

$addonDir   = Join-Path $gameDir "_retail_\Interface\Addons\SweepyBoop"
$classicDir = Join-Path $gameDir "_classic_\Interface\Addons\SweepyBoop"
$mopDir     = Join-Path $gameDir "_classic_ptr_\Interface\Addons\SweepyBoop"

if (Test-Path -Path $addonDir) {
    Remove-Item -Path $addonDir -Recurse -Force
}
if (Test-Path -Path $classicDir) {
    Remove-Item -Path $classicDir -Recurse -Force
}
if (Test-Path -Path $mopDir) {
    Remove-Item -Path $mopDir -Recurse -Force
}
New-Item -ItemType Directory -Path $addonDir | Out-Null
New-Item -ItemType Directory -Path $classicDir | Out-Null
New-Item -ItemType Directory -Path $mopDir | Out-Null

$extensions = @("*.lua", "*.toc", "*.xml")
foreach ($ext in $extensions) {
    Copy-Item -Path "$PSScriptRoot\$ext" -Destination $addonDir -Force
}
foreach ($ext in $extensions) {
    Copy-Item -Path "$PSScriptRoot\$ext" -Destination "$classicDir" -Force
}
foreach ($ext in $extensions) {
    Copy-Item -Path "$PSScriptRoot\$ext" -Destination "$mopDir" -Force
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
foreach ($dir in $dirsToCopy) {
    $destPath = Join-Path -Path $mopDir -ChildPath $dir.Name
    Copy-Item -Path $dir.FullName -Destination $destPath -Recurse -Force
}

$constantsFileRetail = Join-Path -Path $addonDir -ChildPath "Common\Constants.lua"
"addon.internal = true;" | Out-File -FilePath $constantsFileRetail -Append -Encoding UTF8

$constantsFileClassic = Join-Path -Path $classicDir -ChildPath "Common\Constants.lua"
"addon.internal = true;" | Out-File -FilePath $constantsFileClassic -Append -Encoding UTF8

$constantsFileMop = Join-Path -Path $mopDir -ChildPath "Common\Constants.lua"
"addon.internal = true;" | Out-File -FilePath $constantsFileMop -Append -Encoding UTF8
