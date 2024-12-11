$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\SweepyBoop"
$constantsFile = Join-Path -Path $addonDir -ChildPath "Common\Constants.lua"
"addon.isTestMode = true;" | Out-File -FilePath $constantsFile -Append -Encoding UTF8