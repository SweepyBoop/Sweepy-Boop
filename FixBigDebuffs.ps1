$overrideFile = Join-Path -Path $PSScriptRoot -ChildPath "Internal\BigDebuffsOverride.lua"
$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\BigDebuffs"
$spellFile = Join-Path -Path $addonDir -ChildPath "BigDebuffs_Mainline.lua"

# Check if $spellFile exists
if (Test-Path $spellFile) {
    # Read the content of both files
    $spellFileContent = Get-Content $spellFile
    $overrideFileFirstLine = Get-Content $overrideFile -First 1
    
    # Check if the first line of $overrideFile exists in $spellFile
    $lineIndex = $spellFileContent.IndexOf($overrideFileFirstLine)
    if ($lineIndex -ge 0) {
        Write-Host "The first line of $overrideFile exists in $spellFile. Removing it and all subsequent lines..."
        
        # Remove all lines from the first occurrence of the line onwards
        $updatedContent = $spellFileContent[0..($lineIndex - 1)]
        
        # Overwrite the $spellFile with the updated content
        $updatedContent | Set-Content $spellFile
        Write-Host "Lines removed successfully."
    }
    
    # Append the content of $overrideFile to $spellFile
    Write-Host "Appending content from $overrideFile to $spellFile..."
    Get-Content $overrideFile | Add-Content $spellFile
    Write-Host "Content from $overrideFile has been appended successfully."
} else {
    Write-Host "Destination file does not exist."
}
