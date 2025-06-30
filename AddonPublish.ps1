$workDir = "$PSScriptRoot"
#$driveLetter = Split-Path -Qualifier $PSScriptRoot
$publishDir = "${workDir}\SweepyBoop"

# Clean up previous
if (Test-Path -Path $publishDir) {
    Remove-Item -Path $publishDir -Recurse -Force
}
Remove-Item "${workDir}\SweepyBoop.zip" -ErrorAction SilentlyContinue

$excludePatterns = @("*.git*", "*Docs*", "*Internal*", "*VSCode*")
$dirsToCopy = Get-ChildItem -Path $workDir -Directory -Exclude $excludePatterns
New-Item -ItemType Directory -Path $publishDir # Get dirsToCopy to avoid including the publishDir (i.e., infinite loop)

$extensions = @("*.lua", "*.toc", "*.xml")
foreach ($ext in $extensions) {
    Copy-Item -Path "$PSScriptRoot\$ext" -Destination $publishDir -Force
}
foreach ($dir in $dirsToCopy) {
    $destPath = Join-Path -Path $publishDir -ChildPath $dir.Name
    Copy-Item -Path $dir.FullName -Destination $destPath -Recurse -Force
}

# Filter out lines containing "Internal" from the .toc file
$inputTocPath = "${publishDir}\SweepyBoop.toc"
$outputTocPath = "${publishDir}\SweepyBoop.toc.new"

Get-Content -Path $inputTocPath | Where-Object {$_ -notmatch 'Internal'} | Set-Content -Path $outputTocPath

Move-Item -Path $outputTocPath -Destination $inputTocPath -Force

# Do the same for the Mists version
$inputTocPathMists = "${publishDir}\SweepyBoop_Mists.toc"
$outputTocPathMists = "${publishDir}\SweepyBoop_Mists.toc.new"

Get-Content -Path $inputTocPathMists | Where-Object {$_ -notmatch 'Internal'} | Set-Content -Path $outputTocPathMists

Move-Item -Path $outputTocPathMists -Destination $inputTocPathMists -Force

# Use right click and compress to zip, instead of PowerShell, seems like the package is randomly breaking for Mac users
#tar -a -cf SweepyBoop.zip $publishDir
#Remove-Item -Path $publishDir -Recurse -Force