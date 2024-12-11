$workDir = $PSScriptRoot
$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\SweepyBoop"

if (Test-Path -Path $addonDir) {
    Remove-Item -Path $addonDir -Recurse -Force
}
New-Item -ItemType Directory -Path $addonDir | Out-Null

Copy-Item -Path "$workDir\*" -Destination $addonDir -Recurse -Force

$constantsFile = Join-Path -Path $addonDir -ChildPath "Common\Constants.lua"
"addon.internal = true;" | Out-File -FilePath $constantsFile -Append -Encoding UTF8
