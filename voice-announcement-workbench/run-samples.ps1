param(
    [switch]$Force,
    [switch]$Remaster,
    [switch]$NoOpen,
    [string]$Speaker,
    [string]$Phrase,
    [string]$ManifestPath,
    [string]$ScratchPath,
    [ValidateSet('auto', 'cuda', 'mps', 'cpu')]
    [string]$Device = 'cuda'
)

$ErrorActionPreference = 'Stop'

$workbench = $PSScriptRoot
$workbenchScratch = Join-Path $workbench 'scratch'
$scratch = if ($ScratchPath) {
    [IO.Path]::GetFullPath($ScratchPath)
} else {
    $workbenchScratch
}
$manifest = if ($ManifestPath) {
    [IO.Path]::GetFullPath($ManifestPath)
} else {
    Join-Path $workbench 'sample-manifest.json'
}
$python = Join-Path $workbenchScratch 'python\Scripts\python.exe'
$modelCache = Join-Path $workbenchScratch 'models'
$generator = Join-Path $workbench 'generate-samples.py'
$listeningPage = Join-Path $scratch 'listening\index.html'

foreach ($requiredPath in @($python, $generator, $manifest)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required workbench file is missing: $requiredPath"
    }
}

$arguments = @(
    $generator,
    '--manifest', $manifest,
    '--scratch', $scratch,
    '--model-cache', $modelCache,
    '--device', $Device
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
    $manifestData = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    $report = Get-Content -LiteralPath (Join-Path $scratch 'reports\sample-run.json') -Raw | ConvertFrom-Json
    $expectedCount = @($manifestData.speakers).Count * @($manifestData.phrases).Count
    if (@($report.samples).Count -ne $expectedCount) {
        throw "Expected $expectedCount reported samples, found $(@($report.samples).Count)."
    }
    foreach ($sample in $report.samples) {
        if (-not (Test-Path -LiteralPath $sample.rawWav.path -PathType Leaf) -or
            -not (Test-Path -LiteralPath $sample.ogg.path -PathType Leaf)) {
            throw "A reported audio file is missing for $($sample.outputKey)."
        }
    }
}

Write-Host "Listening page: $listeningPage"
if (-not $NoOpen) {
    Start-Process -FilePath $listeningPage
}
