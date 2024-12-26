$workDir = $PSScriptRoot
$overrideFile = Join-Path -Path $PSScriptRoot -ChildPath "Internal\BigDebuffsOverride.lua"
$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\BigDebuffs"
$spellFile = Join-Path -Path $addonDir -ChildPath "BigDebuffs_Mainline.lua"

# Check if $spellFile exists
if (Test-Path $spellFile) {
    # Read the content of $spellFile
    $spellFileContent = Get-Content $spellFile
    
    # Check if the line "-- Spell type overrides" is present
    if (-not ($spellFileContent -contains "-- Spell type overrides")) {
        Write-Host "'-- Spell type overrides' is missing in $spellFile. Appending content from $overrideFile..."
        
        # Append content of $overrideFile to $spellFile
        Get-Content $overrideFile | Add-Content $spellFile
        
        Write-Host "Content appended successfully."
    } else {
        Write-Host "'-- Spell type overrides' already exists in $spellFile. No changes made."
    }
} else {
    Write-Host "File $spellFile does not exist. Please ensure the path is correct."
}
