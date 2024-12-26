$workDir = $PSScriptRoot
$overrideFile = Join-Path -Path $PSScriptRoot -ChildPath "Internal\BigDebuffsOverride.lua"
$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\BigDebuffs"
$spellFile = Join-Path -Path $addonDir -ChildPath "BigDebuffs_Mainline.lua"

# Check if $spellFile exists
if (Test-Path $spellFile) {
    # Read the content of both files
    $spellFileContent = Get-Content $spellFile
    $overrideFileFirstLine = (Get-Content $overrideFile -First 1).Trim()
    
    # Check if the first line of $overrideFile is in $spellFile
    if (-not ($spellFileContent -contains $overrideFileFirstLine)) {
        Write-Host "Spell Overrides are missing in $spellFile. Appending content..."
        
        # Append the content of $overrideFile to $spellFile
        Get-Content $overrideFile | Add-Content $spellFile
        
        Write-Host "Content from $overrideFile has been appended successfully."
    } else {
        Write-Host "Spell Overrides already exists in $spellFile. No changes made."
    }
} else {
    Write-Host "Destination file does not exist."
}
