$workDir = "$PSScriptRoot"
$publishDir = "${workDir}\SweepyBoop"

# Clean up previous
if (Test-Path -Path $publishDir) {
    Remove-Item -Path $publishDir -Recurse -Force
}
Remove-Item "${workDir}\SweepyBoop.zip" -ErrorAction SilentlyContinue

$excludePatterns = @("*.git*", "*Docs*", "*Internal*")
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

$zipFile = "${workDir}\SweepyBoop.zip"
Compress-Archive -Path $publishDir -DestinationPath $zipFile
Remove-Item -Path $publishDir -Recurse -Force