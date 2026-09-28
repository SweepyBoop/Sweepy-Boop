param(
    [switch]$Force,
    [switch]$Remaster,
    [switch]$NoOpen,
    [string]$Speaker,
    [string]$Phrase
)

$ErrorActionPreference = 'Stop'

$workbench = $PSScriptRoot
$scratch = Join-Path $workbench 'scratch'
$python = Join-Path $scratch 'python\Scripts\python.exe'
$generator = Join-Path $workbench 'generate-samples.py'
$manifest = Join-Path $workbench 'sample-manifest.json'
$listeningPage = Join-Path $scratch 'listening\index.html'

foreach ($requiredPath in @($python, $generator, $manifest)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required workbench file is missing: $requiredPath"
    }
}

$arguments = @(
    $generator,
    '--manifest', $manifest,
    '--scratch', $scratch
)
if ($Force) {
    $arguments += '--force'
}
if ($Remaster) {
    $arguments += '--remaster'
}
if ($Speaker) {
    $arguments += @('--speaker', $Speaker)
}
if ($Phrase) {
    $arguments += @('--phrase', $Phrase)
}

& $python @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Voice sample generation failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path -LiteralPath $listeningPage -PathType Leaf)) {
    throw "Listening page was not generated: $listeningPage"
}

if (-not $Speaker -and -not $Phrase) {
    $rawCount = @(Get-ChildItem -LiteralPath (Join-Path $scratch 'raw-wav') -Filter '*.wav' -File).Count
    $oggCount = @(Get-ChildItem -LiteralPath (Join-Path $scratch 'ogg') -Filter '*.ogg' -File).Count
    if ($rawCount -ne 10 -or $oggCount -ne 10) {
        throw "Expected 10 WAV and 10 OGG files, found $rawCount WAV and $oggCount OGG."
    }
}

Write-Host "Listening page: $listeningPage"
if (-not $NoOpen) {
    Start-Process -FilePath $listeningPage
}
