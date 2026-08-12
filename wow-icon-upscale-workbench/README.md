# WoW Icon Upscaling Workbench

This directory documents the reproducible workflow for experimenting with AI-upscaled World of Warcraft UI art. It is written as a handoff for future contributors and coding agents such as GPT and Claude.

## Repository contract

- Keep durable instructions and small automation files in this directory.
- Put downloaded applications, model weights, copied inputs, generated outputs, and comparison images under `scratch/`.
- `scratch/` is intentionally ignored by Git because the downloaded tools and model files exceed GitHub's file-size limits.
- Do not place workbench files in the addon package. `AddonUpdate.ps1` and `AddonPublish.ps1` exclude the top-level `wow-icon-upscale-workbench` directory.
- Do not overwrite addon art during exploration. Copy an approved final asset into `../Art/` only after a human reviews it.

## Current local layout

```text
wow-icon-upscale-workbench/
|-- README.md
`-- scratch/                         # ignored local artifacts
    |-- inputs/class-icons/          # copied 64x64 source PNGs
    |-- outputs/
    |   |-- digital-art-4x/          # recommended model output
    |   |-- remacri-4x/
    |   `-- ultrasharp-4x/
    |-- comparisons/original-vs-digital-art-4x/
    |-- make-comparisons.ps1
    |-- upscayl-2.15.0/
    |-- upscayl-2.15.0-win.zip
    |-- realesrgan/                   # incomplete upstream portable package
    `-- realesrgan-ncnn-vulkan-v0.2.0-windows.zip
```

All paths below are relative to this workbench unless stated otherwise.

## Environment used

The initial experiment ran successfully on Windows with:

- NVIDIA GeForce RTX 5080, 16 GB VRAM
- NVIDIA driver 610.88
- Vulkan 1.4
- PowerShell 7
- Upscayl 2.15.0 portable Windows distribution

The NCNN/Vulkan command-line runner does not require Python, PyTorch, or CUDA packages. A Vulkan-capable GPU and current graphics driver are required.

## Source textures

The source repository used for the experiment was the sibling checkout:

```text
../wow-ui-textures/Icons/ClassIcon_*.PNG
```

In the original local layout, `wow-ui-textures` was a sibling of the `Sweepy-Boop` repository, so its absolute relationship from this workbench is:

```text
../../wow-ui-textures/Icons/ClassIcon_*.PNG
```

That repository contains PNG conversions of Blizzard BLP textures, not TGA originals. Twelve 64x64 class icons were found. There was no Evoker icon in that set.

Copy the inputs into scratch:

```powershell
$Workbench = $PSScriptRoot
$Scratch = Join-Path $Workbench 'scratch'
$SourceIcons = Join-Path $Workbench '..\..\wow-ui-textures\Icons'
$InputDirectory = Join-Path $Scratch 'inputs\class-icons'

New-Item -ItemType Directory -Force -Path $InputDirectory | Out-Null
Get-ChildItem $SourceIcons -Filter 'ClassIcon_*.PNG' |
    Copy-Item -Destination $InputDirectory -Force
```

When using a different source, keep lossless PNG or TGA originals. Do not upscale an image that has already been resized or JPEG-compressed.

## Tool setup

The working runtime is the official portable Upscayl 2.15.0 Windows ZIP:

```text
https://github.com/upscayl/upscayl/releases/download/v2.15.0/upscayl-2.15.0-win.zip
```

The ZIP used in the initial experiment had this SHA-256:

```text
6AA2F137CE45BAC3877C5634BB0829F398ED757CBF4A72CCDEF12B7473407823
```

Download and extract it into scratch:

```powershell
$Scratch = Join-Path $PSScriptRoot 'scratch'
$Archive = Join-Path $Scratch 'upscayl-2.15.0-win.zip'
$Runtime = Join-Path $Scratch 'upscayl-2.15.0'
$Url = 'https://github.com/upscayl/upscayl/releases/download/v2.15.0/upscayl-2.15.0-win.zip'

New-Item -ItemType Directory -Force -Path $Scratch | Out-Null
Invoke-WebRequest -Headers @{ 'User-Agent' = 'SweepyBoop-Art-Workbench' } -Uri $Url -OutFile $Archive
(Get-FileHash -Algorithm SHA256 $Archive).Hash
Expand-Archive -LiteralPath $Archive -DestinationPath $Runtime
```

Important: the official Real-ESRGAN NCNN Vulkan 0.2.0 Windows release was also tested, but its published ZIP omitted the required `models` directory. Its executable detected the GPU correctly but could not run inference. Prefer the Upscayl package, which bundles compatible models and the same style of NCNN/Vulkan CLI.

## Upscaling

The relevant executable and model directory are:

```powershell
$Scratch = Join-Path $PSScriptRoot 'scratch'
$Upscaler = Join-Path $Scratch 'upscayl-2.15.0\resources\bin\upscayl-bin.exe'
$Models = Join-Path $Scratch 'upscayl-2.15.0\resources\models'
$Inputs = Join-Path $Scratch 'inputs\class-icons'
```

Run the three useful comparison models at 4x:

```powershell
foreach ($Model in @('digital-art-4x', 'remacri-4x', 'ultrasharp-4x')) {
    $Output = Join-Path $Scratch "outputs\$Model"
    New-Item -ItemType Directory -Force -Path $Output | Out-Null

    & $Upscaler `
        -i $Inputs `
        -o $Output `
        -m $Models `
        -n $Model `
        -z 4 `
        -s 4 `
        -f png `
        -v

    if ($LASTEXITCODE -ne 0) {
        throw "$Model failed with exit code $LASTEXITCODE"
    }
}
```

For 64x64 inputs, expected outputs are 256x256 lossless PNGs.

## Current findings

The initial review ranked the models as follows:

1. `digital-art-4x`: best overall result for these small painted UI icons; clean shapes and coherent edges.
2. `ultrasharp-4x`: retains more texture, but adds grain and harsh edges.
3. `remacri-4x`: introduces blocky reconstruction artifacts on several 64x64 icons.

`digital-art-4x` is the current default, not a permanent decision. Recompare models when the source art style changes.

AI upscaling reconstructs details rather than recovering ground truth. Inspect thin silhouettes, borders, glow effects, text-like markings, and alpha edges at both native and enlarged display sizes before promoting an asset.

## Side-by-side comparisons

The existing comparison generator is local scratch tooling:

```powershell
& (Join-Path $PSScriptRoot 'scratch\make-comparisons.ps1')
```

It reads:

```text
scratch/inputs/class-icons/ClassIcon_*.PNG
scratch/outputs/digital-art-4x/ClassIcon_*.png
```

It writes twelve labeled pairs and one overview sheet to:

```text
scratch/comparisons/original-vs-digital-art-4x/
```

The left side enlarges each 64x64 source to 256x256 with nearest-neighbor sampling so the original pixels remain visible. The right side shows the 256x256 AI output.

If the comparison script is regenerated, make its root resolve to its own directory because the current script lives inside scratch:

```powershell
$root = $PSScriptRoot
```

## Verification checklist

Before presenting or promoting results:

1. Confirm every expected input has an output.
2. Confirm each 4x output is exactly four times the input width and height.
3. Open representative icons with metal edges, soft glow, organic texture, and transparency.
4. Generate the overview comparison sheet.
5. Confirm `git status` does not list anything under `scratch/`.
6. Confirm `AddonPublish.ps1` stages neither `Tools` nor `wow-icon-upscale-workbench`.
7. Copy only human-approved final assets into the addon's tracked art directories.

Useful checks:

```powershell
$Scratch = Join-Path $PSScriptRoot 'scratch'
Get-ChildItem (Join-Path $Scratch 'outputs\digital-art-4x') -Filter '*.png'
git -C (Join-Path $PSScriptRoot '..') status --short
```

## Complete class and specialization batch

The tracked manifest and runner are:

```text
icon-manifest.json
run-icon-batch.ps1
```

The manifest follows SweepyBoop's class/spec override identifiers: 13 classes and 40 specializations. All 53 inputs come from the current installed Retail interface-art extraction under:

```text
C:\Program Files (x86)\World of Warcraft\_retail_\BlizzardInterfaceArt\Interface\Icons
```

The runner resolves each stable icon basename to its Retail `.blp` file. It converts the 64x64 BLP2 files to lossless PNG with `convert-blp-to-png.py` and Pillow 12.3.0 in the ignored `scratch/python` environment, runs `digital-art-4x`, verifies all 256x256 outputs, and records source and generated SHA-256 hashes.

Prepare the local converter once:

```powershell
py -3.10 -m venv .\scratch\python
.\scratch\python\Scripts\python.exe -m pip install Pillow==12.3.0
```

Run the batch from this directory:

```powershell
.\run-icon-batch.ps1
```

Current source coverage is complete: 53 of 53 icons. The generated review is under:

```text
scratch/comparisons/retail-class-spec-digital-art-4x/
|-- all-class-spec-icons-index.png
|-- by-class/
`-- individual/
```

The provenance report is:

```text
scratch/retail-class-spec-run-report.json
```

The Git-visible backup of the latest Retail run is:

```text
../Docs/IconUpscaleBackup-Retail/
|-- digital-art-4x/
|-- comparisons/
|   |-- all-class-spec-icons-index.png
|   `-- by-class/
|-- icon-manifest.json
`-- retail-class-spec-run-report.json
```

## Continuing the work

A future agent should begin by reading this file, checking whether `scratch/` already contains a runtime and outputs, and asking which source art and target in-game dimensions should be evaluated. Reuse existing downloads when their hashes and versions match. Keep experimental binaries, models, copied source textures, generated images, logs, and temporary scripts under `scratch/`.
