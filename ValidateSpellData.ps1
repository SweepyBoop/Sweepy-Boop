# Read all spell IDs from Common\SpellData.lua
$spellFile = Join-Path -Path $PSScriptRoot -ChildPath "Common\SpellData.lua"
# store spell IDs in a hashtable
$spellTable = @{}
# Read the content of $spellFile
$spellFileContent = Get-Content $spellFile
# Loop through each line in the file content
foreach ($line in $spellFileContent) {
    # if line contains "addon.SpellResets", abort the loop
    if ($line -match 'addon.SpellResets') {
        Write-Host "End of spell IDs"
        break
    }

    if ($line -match '\[(\d+)\]') {
        $id = $matches[1]
        # Add the ID to the hashtable
        $spellTable[$id] = $True
    }
}

$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\OmniBar"
# Read all entries from OmniBar_Mainline.lua and store them in a hashtable
$spellFileOmniBar = Join-Path -Path $addonDir -ChildPath "OmniBar_Mainline.lua"
$spellTableOmniBar = @{}
# Read the content of $spellFile
$spellFileContentOmniBar = Get-Content $spellFileOmniBar
# Loop through each line in the file content
foreach ($line in $spellFileContentOmniBar) {
    if ($line -match '\[(\d+)\].*--\s*(.+)$') {
        $id = $matches[1]
        $commentOmniBar = $matches[2]
        # Add the ID and comment to the hashtable
        $spellTableOmniBar[$id] = $commentOmniBar
    }
}

# Find spell IDs in $spellTable that are not in $spellTableOmniBar
$missingSpellIDs = @()
foreach ($id in $spellTable.Keys) {
    if (-not $spellTableOmniBar.ContainsKey($id)) {
        $missingSpellIDs += $id
    }
}

# Print the missing spell IDs
if ($missingSpellIDs.Count -eq 0) {
    Write-Host "All spell IDs from SpellData.lua are present in OmniBar_Mainline.lua."
} else {
    Write-Host "Missing spell IDs from OmniBar_Mainline.lua:"
    foreach ($id in $missingSpellIDs) {
        Write-Host $id
    }
}
