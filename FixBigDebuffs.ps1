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

$outputFile = Join-Path -Path $PSScriptRoot -ChildPath "Common\CrowdControlAuras.lua"

# Initialize an empty hashtable to store the IDs
$crowdControlTable = @{}

# Read the content of $spellFile
$spellFileContent = Get-Content $spellFile

# Loop through each line in the file content
foreach ($line in $spellFileContent) {
    if ($line -match 'type = CROWD_CONTROL') {
        # Extract the ID from the line
        if ($line -match '\[(\d+)\]') {
            $id = $matches[1]
            # Add the ID to the hashtable
            $crowdControlTable[$id] = $true
        }
    }
}

# Prepare the output content
$outputContent = "local _, addon = ...;`naddon.CrowdControl = {`n"
foreach ($id in $crowdControlTable.Keys) {
    $outputContent += "    [$id] = true,`n"
}
$outputContent += "}`n"

# Write the output content to $outputFile
$outputContent | Set-Content $outputFile
Write-Host "Crowd control IDs have been written to $outputFile successfully."
