param(
    [string]$TextureRepository = 'C:\Users\kunhouseliu\Documents\GitHub\wow-ui-textures',
    [string]$RetailInterface = 'C:\Program Files (x86)\World of Warcraft\_retail_\BlizzardInterfaceArt\Interface',
    [switch]$SkipUpscale
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$workbench = $PSScriptRoot
$scratch = Join-Path $workbench 'scratch'
$manifestPath = Join-Path $workbench 'icon-manifest.json'
$inputDirectory = Join-Path $scratch 'inputs\class-spec-icons'
$outputDirectory = Join-Path $scratch 'outputs\digital-art-4x-class-spec-icons'
$comparisonDirectory = Join-Path $scratch 'comparisons\class-spec-digital-art-4x'
$pairDirectory = Join-Path $comparisonDirectory 'individual'
$classSheetDirectory = Join-Path $comparisonDirectory 'by-class'
$reportPath = Join-Path $scratch 'class-spec-run-report.json'
$upscaler = Join-Path $scratch 'upscayl-2.15.0\resources\bin\upscayl-bin.exe'
$modelDirectory = Join-Path $scratch 'upscayl-2.15.0\resources\models'
$python = Join-Path $scratch 'python\Scripts\python.exe'
$blpConverter = Join-Path $workbench 'convert-blp-to-png.py'

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$assets = @($manifest.assets)

if ($assets.Count -ne 53) {
    throw "Expected 53 manifest entries, found $($assets.Count)."
}
if (@($assets | Where-Object kind -eq 'class').Count -ne 13) {
    throw 'The manifest must contain exactly 13 class icons.'
}
if (@($assets | Where-Object kind -eq 'spec').Count -ne 40) {
    throw 'The manifest must contain exactly 40 specialization icons.'
}
if (-not (Test-Path -LiteralPath (Join-Path $TextureRepository '.git'))) {
    throw "Texture repository is not a Git checkout: $TextureRepository"
}
if (-not (Test-Path -LiteralPath $RetailInterface)) {
    throw "Extracted Retail interface art is missing: $RetailInterface"
}
if (-not (Test-Path -LiteralPath $python)) {
    throw "Scratch Python environment is missing: $python"
}
if (-not (Test-Path -LiteralPath $blpConverter)) {
    throw "BLP converter script is missing: $blpConverter"
}
if (-not $SkipUpscale -and -not (Test-Path -LiteralPath $upscaler)) {
    throw "Upscayl CLI is missing: $upscaler"
}
if (-not $SkipUpscale -and -not (Test-Path -LiteralPath (Join-Path $modelDirectory 'digital-art-4x.bin'))) {
    throw "Digital Art model is missing from: $modelDirectory"
}

foreach ($directory in @($inputDirectory, $outputDirectory, $pairDirectory, $classSheetDirectory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
}
Get-ChildItem -LiteralPath $inputDirectory -File -ErrorAction SilentlyContinue | Remove-Item -Force
if (-not $SkipUpscale) {
    Get-ChildItem -LiteralPath $outputDirectory -File -ErrorAction SilentlyContinue | Remove-Item -Force
}
Get-ChildItem -LiteralPath $pairDirectory -File -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath $classSheetDirectory -File -ErrorAction SilentlyContinue | Remove-Item -Force

function Export-GitBlob {
    param(
        [string]$Repository,
        [string]$Revision,
        [string]$Path,
        [string]$Destination
    )

    $objectName = & git -C $Repository rev-parse "$Revision`:$Path" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $objectName) {
        throw "Source does not exist at ${Revision}:$Path"
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git.exe'
    $startInfo.ArgumentList.Add('-C')
    $startInfo.ArgumentList.Add($Repository)
    $startInfo.ArgumentList.Add('cat-file')
    $startInfo.ArgumentList.Add('blob')
    $startInfo.ArgumentList.Add($objectName.Trim())
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [Diagnostics.Process]::Start($startInfo)
    $file = [IO.File]::Create($Destination)
    try {
        $process.StandardOutput.BaseStream.CopyTo($file)
    }
    finally {
        $file.Dispose()
    }
    $errorText = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        throw "Could not export ${Revision}:$Path. $errorText"
    }

    return $objectName.Trim()
}

$staged = @()
$missing = @()
foreach ($asset in $assets) {
    $inputPath = Join-Path $inputDirectory ($asset.outputName + '.png')
    $sourceType = $null
    $sourcePath = $null
    $sourceBlob = $null
    $sourceSha256 = $null

    if ($asset.sourcePath) {
        $sourceType = 'wow-ui-textures'
        $sourcePath = $asset.sourcePath
        $sourceBlob = Export-GitBlob -Repository $TextureRepository -Revision $manifest.sourceRef -Path $asset.sourcePath -Destination $inputPath
        $sourceSha256 = (Get-FileHash -LiteralPath $inputPath -Algorithm SHA256).Hash
    }
    elseif ($asset.retailPath) {
        $sourceType = 'retail-interface-blp'
        $sourcePath = Join-Path $RetailInterface ($asset.retailPath -replace '/', '\')
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            $missing += [PSCustomObject]@{
                kind = $asset.kind
                class = $asset.class
                specId = $asset.specId
                label = $asset.label
                outputName = $asset.outputName
                reason = "Retail BLP source is missing: $sourcePath"
            }
            continue
        }
        $sourceSha256 = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
        & $python $blpConverter $sourcePath $inputPath
        if ($LASTEXITCODE -ne 0) {
            throw "BLP conversion failed for $sourcePath with exit code $LASTEXITCODE."
        }
    }
    else {
        $missing += [PSCustomObject]@{
            kind = $asset.kind
            class = $asset.class
            specId = $asset.specId
            label = $asset.label
            outputName = $asset.outputName
            reason = 'No source is configured.'
        }
        continue
    }

    $image = [Drawing.Image]::FromFile($inputPath)
    try {
        if ($image.Width -ne 64 -or $image.Height -ne 64) {
            throw "Expected a 64x64 source for $($asset.outputName), found $($image.Width)x$($image.Height)."
        }
    }
    finally {
        $image.Dispose()
    }

    $staged += [PSCustomObject]@{
        kind = $asset.kind
        classId = $asset.classId
        class = $asset.class
        specId = $asset.specId
        label = $asset.label
        outputName = $asset.outputName
        sourceType = $sourceType
        sourceRef = if ($sourceType -eq 'wow-ui-textures') { $manifest.sourceRef } else { $null }
        sourcePath = $sourcePath
        sourceBlob = $sourceBlob
        sourceSha256 = $sourceSha256
        inputPath = $inputPath
        inputSha256 = (Get-FileHash -LiteralPath $inputPath -Algorithm SHA256).Hash
    }
}

if ($staged.Count -ne 53) {
    throw "Expected to stage all 53 class and spec assets, staged $($staged.Count)."
}
if ($missing.Count -ne 0) {
    throw "Expected no unavailable assets, found $($missing.Count): $($missing.outputName -join ', ')"
}

if (-not $SkipUpscale) {
    & $upscaler `
        -i $inputDirectory `
        -o $outputDirectory `
        -m $modelDirectory `
        -n $manifest.model `
        -z $manifest.scale `
        -s $manifest.scale `
        -f png `
        -v
    if ($LASTEXITCODE -ne 0) {
        throw "Upscayl failed with exit code $LASTEXITCODE."
    }
}

foreach ($asset in $staged) {
    $outputPath = Join-Path $outputDirectory ($asset.outputName + '.png')
    if (-not (Test-Path -LiteralPath $outputPath)) {
        throw "Missing output: $outputPath"
    }
    $image = [Drawing.Image]::FromFile($outputPath)
    try {
        if ($image.Width -ne 256 -or $image.Height -ne 256) {
            throw "Expected a 256x256 output for $($asset.outputName), found $($image.Width)x$($image.Height)."
        }
    }
    finally {
        $image.Dispose()
    }
    Add-Member -InputObject $asset -NotePropertyName outputPath -NotePropertyValue $outputPath
    Add-Member -InputObject $asset -NotePropertyName outputSha256 -NotePropertyValue (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
}

$fontFamily = [Drawing.FontFamily]::GenericSansSerif
$titleFont = [Drawing.Font]::new($fontFamily, 16, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
$labelFont = [Drawing.Font]::new($fontFamily, 12, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
$smallFont = [Drawing.Font]::new($fontFamily, 10, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
$textBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(238, 242, 248))
$mutedBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(170, 181, 196))
$missingBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 190, 90))
$backgroundBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(17, 20, 25))
$panelBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(28, 33, 40))
$borderPen = [Drawing.Pen]::new([Drawing.Color]::FromArgb(67, 77, 91), 1)

function Draw-AssetPair {
    param(
        [Drawing.Graphics]$Graphics,
        [object]$Asset,
        [int]$X,
        [int]$Y,
        [int]$ImageSize = 256
    )

    $panelWidth = ($ImageSize * 2) + 42
    $panelHeight = $ImageSize + 68
    $Graphics.FillRectangle($panelBrush, $X, $Y, $panelWidth, $panelHeight)
    $Graphics.DrawRectangle($borderPen, $X, $Y, $panelWidth - 1, $panelHeight - 1)
    $kindLabel = if ($Asset.kind -eq 'class') { 'Class' } else { "Spec $($Asset.specId)" }
    $Graphics.DrawString("$($Asset.label)  |  $kindLabel", $titleFont, $textBrush, $X + 12, $Y + 9)

    if (-not $Asset.sourcePath) {
        $Graphics.DrawString('Missing from wow-ui-textures', $labelFont, $missingBrush, $X + 12, $Y + 38)
        $Graphics.DrawString($Asset.outputName, $smallFont, $mutedBrush, $X + 12, $Y + 58)
        return
    }

    $Graphics.DrawString('Original 64x64 (nearest)', $smallFont, $mutedBrush, $X + 12, $Y + 38)
    $Graphics.DrawString('Digital Art 4x', $smallFont, $mutedBrush, $X + 30 + $ImageSize, $Y + 38)
    $original = [Drawing.Image]::FromFile($Asset.inputPath)
    $upscaled = [Drawing.Image]::FromFile($Asset.outputPath)
    try {
        $oldInterpolation = $Graphics.InterpolationMode
        $oldPixelOffset = $Graphics.PixelOffsetMode
        $Graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $Graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
        $Graphics.DrawImage($original, [Drawing.Rectangle]::new($X + 12, $Y + 58, $ImageSize, $ImageSize), 0, 0, 64, 64, [Drawing.GraphicsUnit]::Pixel)
        $Graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $Graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $Graphics.DrawImage($upscaled, [Drawing.Rectangle]::new($X + 30 + $ImageSize, $Y + 58, $ImageSize, $ImageSize), 0, 0, 256, 256, [Drawing.GraphicsUnit]::Pixel)
        $Graphics.InterpolationMode = $oldInterpolation
        $Graphics.PixelOffsetMode = $oldPixelOffset
    }
    finally {
        $original.Dispose()
        $upscaled.Dispose()
    }
}

try {
    $renderAssets = foreach ($asset in $assets) {
        $available = $staged | Where-Object outputName -eq $asset.outputName | Select-Object -First 1
        if ($available) { $available } else { $asset }
    }

    foreach ($asset in $staged) {
        $bitmap = [Drawing.Bitmap]::new(554, 324, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::ClearTypeGridFit
            Draw-AssetPair -Graphics $graphics -Asset $asset -X 0 -Y 0
            $bitmap.Save((Join-Path $pairDirectory ($asset.outputName + '_comparison.png')), [Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }

    $classNames = $assets | Sort-Object classId | Select-Object -ExpandProperty class -Unique
    foreach ($className in $classNames) {
        $classAssets = @($renderAssets | Where-Object class -eq $className | Sort-Object @{ Expression = { if ($_.kind -eq 'class') { 0 } else { 1 } } }, specId)
        $width = 590
        $height = 58 + ($classAssets.Count * 338)
        $bitmap = [Drawing.Bitmap]::new($width, $height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.FillRectangle($backgroundBrush, 0, 0, $width, $height)
            $graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::ClearTypeGridFit
            $classLabel = ($classAssets | Where-Object kind -eq 'class' | Select-Object -First 1).label
            $graphics.DrawString("${classLabel}: original vs Digital Art 4x", $titleFont, $textBrush, 18, 17)
            for ($index = 0; $index -lt $classAssets.Count; $index++) {
                Draw-AssetPair -Graphics $graphics -Asset $classAssets[$index] -X 18 -Y (54 + ($index * 338))
            }
            $bitmap.Save((Join-Path $classSheetDirectory ($className + '.png')), [Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }

    $thumbSize = 96
    $cardWidth = 230
    $cardHeight = 154
    $columns = 4
    $rows = [Math]::Ceiling($renderAssets.Count / $columns)
    $masterWidth = 30 + ($columns * $cardWidth) + (($columns - 1) * 12)
    $masterHeight = 80 + ($rows * $cardHeight) + (($rows - 1) * 12)
    $master = [Drawing.Bitmap]::new($masterWidth, $masterHeight, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($master)
    try {
        $graphics.FillRectangle($backgroundBrush, 0, 0, $masterWidth, $masterHeight)
        $graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::ClearTypeGridFit
        $graphics.DrawString('SweepyBoop class + spec icons', $titleFont, $textBrush, 18, 15)
        $graphics.DrawString('53 generated from original Blizzard sources', $labelFont, $mutedBrush, 18, 42)
        for ($index = 0; $index -lt $renderAssets.Count; $index++) {
            $asset = $renderAssets[$index]
            $column = $index % $columns
            $row = [Math]::Floor($index / $columns)
            $x = 18 + ($column * ($cardWidth + 12))
            $y = 72 + ($row * ($cardHeight + 12))
            $graphics.FillRectangle($panelBrush, $x, $y, $cardWidth, $cardHeight)
            $graphics.DrawRectangle($borderPen, $x, $y, $cardWidth - 1, $cardHeight - 1)
            $graphics.DrawString("$($asset.class): $($asset.label)", $smallFont, $textBrush, $x + 8, $y + 7)
            if (-not $asset.sourcePath) {
                $graphics.DrawString('MISSING SOURCE', $labelFont, $missingBrush, $x + 48, $y + 70)
                continue
            }
            $original = [Drawing.Image]::FromFile($asset.inputPath)
            $upscaled = [Drawing.Image]::FromFile($asset.outputPath)
            try {
                $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
                $graphics.DrawImage($original, [Drawing.Rectangle]::new($x + 8, $y + 34, $thumbSize, $thumbSize), 0, 0, 64, 64, [Drawing.GraphicsUnit]::Pixel)
                $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.DrawImage($upscaled, [Drawing.Rectangle]::new($x + 126, $y + 34, $thumbSize, $thumbSize), 0, 0, 256, 256, [Drawing.GraphicsUnit]::Pixel)
                $graphics.DrawString('Original', $smallFont, $mutedBrush, $x + 30, $y + 133)
                $graphics.DrawString('4x AI', $smallFont, $mutedBrush, $x + 157, $y + 133)
            }
            finally {
                $original.Dispose()
                $upscaled.Dispose()
            }
        }
        $master.Save((Join-Path $comparisonDirectory 'all-class-spec-icons-index.png'), [Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $master.Dispose()
    }
}
finally {
    foreach ($resource in @($titleFont, $labelFont, $smallFont, $textBrush, $mutedBrush, $missingBrush, $backgroundBrush, $panelBrush, $borderPen)) {
        $resource.Dispose()
    }
}

$report = [ordered]@{
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    textureRepository = (Resolve-Path -LiteralPath $TextureRepository).Path
    retailInterface = (Resolve-Path -LiteralPath $RetailInterface).Path
    sourceRepository = $manifest.sourceRepository
    sourceRef = $manifest.sourceRef
    sourceCommit = (& git -C $TextureRepository rev-parse $manifest.sourceRef).Trim()
    model = $manifest.model
    scale = $manifest.scale
    expectedAssets = $assets.Count
    generatedAssets = $staged.Count
    missingAssets = $missing
    generated = $staged
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8

Write-Output "Generated $($staged.Count) of $($assets.Count) manifest icons."
Write-Output 'Missing source assets: none'
Write-Output "Master comparison: $(Join-Path $comparisonDirectory 'all-class-spec-icons-index.png')"
Write-Output "Per-class comparisons: $classSheetDirectory"
Write-Output "Provenance report: $reportPath"
