$workDir = $PSScriptRoot
$gameDir = "C:\Program Files (x86)\World of Warcraft"
$extensions = @("*.lua", "*.toc", "*.xml")
$excludePatterns = @("*.git*", "*Docs*")
$excludedDirectoryNames = @("Tools", "wow-icon-upscale-workbench")

function Deploy-Addon {
    param (
        [string]$sourceDir,
        [string]$destDir
    )

    # Remove old directory if exists
    if (Test-Path -Path $destDir) {
        Remove-Item -Path $destDir -Recurse -Force
    }

    # Recreate directory
    New-Item -ItemType Directory -Path $destDir | Out-Null

    # Copy top-level files
    foreach ($ext in $extensions) {
        Copy-Item -Path (Join-Path $sourceDir $ext) -Destination $destDir -Force
    }

    # Copy subdirectories (excluding patterns and development-only directories)
    $dirsToCopy = Get-ChildItem -Path $sourceDir -Directory -Exclude $excludePatterns |
        Where-Object { $_.Name -notin $excludedDirectoryNames }
    foreach ($dir in $dirsToCopy) {
        $destPath = Join-Path -Path $destDir -ChildPath $dir.Name
        Copy-Item -Path $dir.FullName -Destination $destPath -Recurse -Force
    }

    foreach ($excludedDirectoryName in $excludedDirectoryNames) {
        $unexpectedPath = Join-Path -Path $destDir -ChildPath $excludedDirectoryName
        if (Test-Path -LiteralPath $unexpectedPath) {
            throw "Excluded directory was copied into the addon installation: $unexpectedPath"
        }
    }

    # Append internal flag to Constants.lua
    $constantsFile = Join-Path -Path $destDir -ChildPath "Common\Constants.lua"
    "addon.internal = true;" | Out-File -FilePath $constantsFile -Append -Encoding UTF8

    Write-Output "Deployed addon to $destDir"
}

# --- Deployment ---
$addonDir   = Join-Path $gameDir "_retail_\Interface\AddOns\SweepyBoop"
$ptrDir     = Join-Path $gameDir "_ptr_\Interface\AddOns\SweepyBoop"
$classicDir = Join-Path $gameDir "_classic_\Interface\AddOns\SweepyBoop"
$mopDir     = Join-Path $gameDir "_classic_ptr_\Interface\AddOns\SweepyBoop"
$tbcDir     = Join-Path $gameDir "_anniversary_\Interface\AddOns\SweepyBoop"

foreach ($dir in @($addonDir, $ptrDir, $classicDir, $mopDir, $tbcDir)) {
    Deploy-Addon -sourceDir $workDir -destDir $dir
}
