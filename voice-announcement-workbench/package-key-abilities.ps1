param(
    [string]$ScratchPath,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$workbench = $PSScriptRoot
$scratch = if ($ScratchPath) {
    [IO.Path]::GetFullPath($ScratchPath)
} else {
    Join-Path $workbench 'scratch\key-abilities'
}
$output = if ($OutputPath) {
    [IO.Path]::GetFullPath($OutputPath)
} else {
    Join-Path $scratch 'aiden-sohee-key-abilities-1.0x.zip'
}
$manifestPath = Join-Path $workbench 'key-abilities-manifest.json'
$coveragePath = Join-Path $scratch 'reports\key-abilities-coverage.md'
$runReportPath = Join-Path $scratch 'reports\sample-run.json'

foreach ($requiredPath in @($manifestPath, $coveragePath, $runReportPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required package input is missing: $requiredPath"
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$report = Get-Content -LiteralPath $runReportPath -Raw | ConvertFrom-Json
$expectedCount = @($manifest.speakers).Count * @($manifest.phrases).Count
if (@($report.samples).Count -ne $expectedCount) {
    throw "Expected $expectedCount generated samples, found $(@($report.samples).Count)."
}
if ([double]$manifest.mastering.tempo -ne 1.0) {
    throw "The key-ability package must use natural 1.0x tempo."
}

$staging = Join-Path ([IO.Path]::GetTempPath()) ("sweepyboop-key-abilities-" + [guid]::NewGuid())
try {
    $oggDestination = Join-Path $staging 'ogg'
    $reportsDestination = Join-Path $staging 'reports'
    New-Item -ItemType Directory -Path $oggDestination, $reportsDestination -Force | Out-Null

    foreach ($sample in $report.samples) {
        if (-not (Test-Path -LiteralPath $sample.ogg.path -PathType Leaf)) {
            throw "A mastered OGG is missing for $($sample.outputKey): $($sample.ogg.path)"
        }
        Copy-Item -LiteralPath $sample.ogg.path -Destination $oggDestination
    }
    Copy-Item -LiteralPath $manifestPath -Destination $staging
    Copy-Item -LiteralPath $coveragePath -Destination $reportsDestination
    Copy-Item -LiteralPath $runReportPath -Destination $reportsDestination

    $outputDirectory = Split-Path -Parent $output
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $output -CompressionLevel Optimal -Force
} finally {
    if (Test-Path -LiteralPath $staging -PathType Container) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
}

$archive = Get-Item -LiteralPath $output
$checksum = Get-FileHash -LiteralPath $output -Algorithm SHA256
Write-Host "Archive: $($archive.FullName)"
Write-Host "Bytes: $($archive.Length)"
Write-Host "SHA256: $($checksum.Hash)"
