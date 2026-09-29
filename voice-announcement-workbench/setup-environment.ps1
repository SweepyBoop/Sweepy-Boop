param(
    [switch]$Recreate
)

$ErrorActionPreference = 'Stop'

$workbench = $PSScriptRoot
$scratch = Join-Path $workbench 'scratch'
$pythonDirectory = Join-Path $scratch 'python'
$python = Join-Path $pythonDirectory 'Scripts\python.exe'
$reports = Join-Path $scratch 'reports'
$generator = Join-Path $workbench 'generate-samples.py'
$factionGenerator = Join-Path $workbench 'generate-faction-voices.py'

if ($Recreate -and (Test-Path -LiteralPath $pythonDirectory)) {
    Remove-Item -LiteralPath $pythonDirectory -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $scratch, $reports | Out-Null
$env:PIP_CACHE_DIR = Join-Path $scratch 'pip-cache'

if (-not (Test-Path -LiteralPath $python)) {
    & py -3.10 -m venv $pythonDirectory
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create the Python 3.10 environment at $pythonDirectory."
    }
}

& $python -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to upgrade pip in the isolated environment.'
}

& $python -m pip install --upgrade `
    'torch==2.9.1+cu128' `
    'torchaudio==2.9.1+cu128' `
    --index-url 'https://download.pytorch.org/whl/cu128'
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to install CUDA 12.8 PyTorch packages.'
}

& $python -m pip install --upgrade `
    'qwen-tts==0.1.1' `
    'imageio-ffmpeg==0.6.0' `
    'hf-xet==1.6.0'
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to install Qwen3-TTS and audio tooling.'
}

& $python -m pip freeze | Set-Content -LiteralPath (Join-Path $reports 'pip-freeze.txt') -Encoding utf8

& $python $generator --verify-only
if ($LASTEXITCODE -ne 0) {
    throw 'The isolated voice generation environment failed preset-voice verification.'
}

& $python $factionGenerator --verify-only
if ($LASTEXITCODE -ne 0) {
    throw 'The isolated voice generation environment failed faction-voice verification.'
}

Write-Host "Voice generation environment is ready: $python"
