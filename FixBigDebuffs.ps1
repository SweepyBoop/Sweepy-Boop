$overrideFile = Join-Path -Path $PSScriptRoot -ChildPath "Internal\BigDebuffsOverride.lua"
$addonDir = "D:\World of Warcraft\_retail_\Interface\Addons\BigDebuffs"
$spellFile = Join-Path -Path $addonDir -ChildPath "BigDebuffs_Mainline.lua"
$spellFileCata = Join-Path -Path $addonDir -ChildPath "BigDebuffs_Cata.lua"

$outputFile = Join-Path -Path $PSScriptRoot -ChildPath "Common\CrowdControlAuras.lua"

# Initialize an empty hashtable to store the IDs and comments
$crowdControlTable = @{}

# Read the content of $spellFile
$spellFileContent = Get-Content $spellFile

# Loop through each line in the file content
foreach ($line in $spellFileContent) {
    if ($line -match 'type = CROWD_CONTROL' -or $line -match 'type = ROOT') {
        # Extract the ID and comment from the line
        if ($line -match '\[(\d+)\].*--\s*(.+)$') {
            $id = $matches[1]
            $comment = $matches[2]
            # Add the ID and comment to the hashtable
            $crowdControlTable[$id] = $comment
        }
    }
}

# Prepare the output content
$outputContent = "local _, addon = ...;`n`naddon.CrowdControlAuras = {`n"
foreach ($id in $crowdControlTable.Keys) {
    $outputContent += "    [$id] = true, -- $($crowdControlTable[$id])`n"
}
$outputContent += "};`n"

# Write the output content to $outputFile
$outputContent | Set-Content $outputFile
Write-Host "Crowd control IDs with comments have been written to $outputFile successfully."



$outputFileCata = Join-Path -Path $PSScriptRoot -ChildPath "Common\CrowdControlAuras_Cata.lua"

# Initialize an empty hashtable to store the IDs and comments
$crowdControlTableCata = @{}

# Read the content of $spellFile
$spellFileContentCata = Get-Content $spellFileCata

# Loop through each line in the file content
foreach ($line in $spellFileContentCata) {
    if ($line -match 'type = CROWD_CONTROL' -or $line -match 'type = ROOT') {
        # Extract the ID and comment from the line
        if ($line -match '\[(\d+)\].*--\s*(.+)$') {
            $id = $matches[1]
            $commentCata = $matches[2]
            # Add the ID and comment to the hashtable
            $crowdControlTableCata[$id] = $commentCata
        }
    }
}

# Prepare the output content
$outputContentCata = "local _, addon = ...;`n`naddon.CrowdControlAuras = {`n"
foreach ($id in $crowdControlTableCata.Keys) {
    $outputContentCata += "    [$id] = true, -- $($crowdControlTableCata[$id])`n"
}
$outputContentCata += "};`n"

# Write the output content to $outputFile
$outputContentCata | Set-Content $outputFileCata
Write-Host "Crowd control IDs with comments have been written to $outputFileCata successfully."
