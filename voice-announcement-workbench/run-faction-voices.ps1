param(
    [switch]$Force,
    [switch]$Remaster,
    [switch]$Redesign,
    [switch]$DesignOnly,
    [switch]$NoOpen,
    [string]$Speaker,
    [string]$Phrase,
    [ValidateSet('auto', 'cuda', 'mps', 'cpu')]
    [string]$Device = 'cuda'
)

$ErrorActionPreference = 'Stop'

$workbench = $PSScriptRoot
$workbenchScratch = Join-Path $workbench 'scratch'
$scratch = Join-Path $workbenchScratch 'faction-voices'
$python = Join-Path $workbenchScratch 'python\Scripts\python.exe'
$generator = Join-Path $workbench 'generate-faction-voices.py'
$validator = Join-Path $workbench 'validate-faction-voices.py'
$manifest = Join-Path $workbench 'faction-voice-manifest.json'
$modelCache = Join-Path $workbenchScratch 'models'
$listeningPage = Join-Path $scratch 'listening\index.html'

foreach ($requiredPath in @($python, $generator, $validator, $manifest)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required workbench file is missing: $requiredPath"
    }
}

& $python $validator --manifest $manifest
if ($LASTEXITCODE -ne 0) {
    throw "Faction voice manifest validation failed with exit code $LASTEXITCODE."
}

$arguments = @(
    $generator,
    '--manifest', $manifest,
    '--scratch', $scratch,
    '--model-cache', $modelCache,
    '--device', $Device
)
if ($Force) { $arguments += '--force' }
if ($Remaster) { $arguments += '--remaster' }
if ($Redesign) { $arguments += '--redesign' }
if ($DesignOnly) { $arguments += '--design-only' }
if ($Speaker) { $arguments += @('--speaker', $Speaker) }
if ($Phrase) { $arguments += @('--phrase', $Phrase) }

$env:PYTORCH_ENABLE_MPS_FALLBACK = '1'
& $python @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Faction voice generation failed with exit code $LASTEXITCODE."
}

if ($DesignOnly) { exit 0 }
if (-not (Test-Path -LiteralPath $listeningPage -PathType Leaf)) {
    throw "Listening page was not generated: $listeningPage"
}

Write-Host "Listening page: $listeningPage"
if (-not $NoOpen) {
    Start-Process -FilePath $listeningPage
}
