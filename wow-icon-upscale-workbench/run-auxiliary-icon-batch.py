import argparse
import hashlib
import json
import shutil
import subprocess
from math import ceil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    name = "arialbd.ttf" if bold else "arial.ttf"
    try:
        return ImageFont.truetype(name, size)
    except OSError:
        return ImageFont.load_default()


def make_pair(
    source: Path,
    output: Path,
    destination: Path,
    label: str,
    processing: str,
) -> None:
    with Image.open(source) as source_image, Image.open(output) as output_image:
        original = source_image.convert("RGBA").resize((256, 256), Image.Resampling.NEAREST)
        generated = output_image.convert("RGBA")
        canvas = Image.new("RGBA", (550, 320), (15, 19, 24, 255))
        canvas.alpha_composite(original, (12, 48))
        canvas.alpha_composite(generated, (282, 48))
        draw = ImageDraw.Draw(canvas)
        draw.text((12, 12), label, fill=(245, 247, 250, 255), font=load_font(19, True))
        draw.text((12, 292), f"Original {source_image.width}x{source_image.height} (nearest)", fill=(174, 184, 196, 255), font=load_font(13))
        output_label = (
            "Native extraction 256x256"
            if processing == "native-extraction"
            else "Digital Art / native 256x256"
        )
        draw.text((282, 292), output_label, fill=(174, 184, 196, 255), font=load_font(13))
        canvas.save(destination, format="PNG")


def main() -> None:
    parser = argparse.ArgumentParser(description="Upscale and compare auxiliary SweepyBoop icons.")
    parser.add_argument("manifest", type=Path)
    parser.add_argument("inputs", type=Path)
    parser.add_argument("scratch", type=Path)
    parser.add_argument("upscaler", type=Path)
    parser.add_argument("models", type=Path)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    assets = manifest["assets"]
    gpu_inputs = args.scratch / "gpu-inputs"
    raw_outputs = args.scratch / "raw-outputs"
    outputs = args.scratch / "outputs"
    comparisons = args.scratch / "comparisons"
    individual = comparisons / "individual"
    for directory in (gpu_inputs, raw_outputs, outputs, individual):
        directory.mkdir(parents=True, exist_ok=True)
        for child in directory.glob("*.png"):
            child.unlink()

    gpu_assets = []
    for asset in assets:
        source = args.inputs / f'{asset["outputName"]}.png'
        with Image.open(source) as image:
            size = image.size
        if size == (256, 256):
            shutil.copy2(source, outputs / source.name)
        else:
            shutil.copy2(source, gpu_inputs / source.name)
            gpu_assets.append(asset)

    if gpu_assets:
        subprocess.run(
            [
                str(args.upscaler),
                "-i", str(gpu_inputs),
                "-o", str(raw_outputs),
                "-m", str(args.models),
                "-n", manifest["model"],
                "-z", "4",
                "-s", "4",
                "-f", "png",
                "-v",
            ],
            check=True,
        )

    report_assets = []
    for asset in assets:
        name = f'{asset["outputName"]}.png'
        source = args.inputs / name
        output = outputs / name
        raw_output = raw_outputs / name
        if raw_output.exists():
            with Image.open(raw_output) as image:
                generated = image.convert("RGBA")
                if generated.size != (manifest["targetSize"], manifest["targetSize"]):
                    generated = generated.resize(
                        (manifest["targetSize"], manifest["targetSize"]),
                        Image.Resampling.LANCZOS,
                    )
                generated.save(output, format="PNG")

        pair = individual / name
        make_pair(
            source,
            output,
            pair,
            asset["label"],
            asset.get("processing", "digital-art-4x"),
        )
        with Image.open(source) as source_image, Image.open(output) as output_image:
            report_assets.append(
                {
                    **asset,
                    "inputSize": list(source_image.size),
                    "inputSha256": sha256(source),
                    "outputSize": list(output_image.size),
                    "outputSha256": sha256(output),
                    "outputPath": str(output),
                }
            )

    sheet_height = 92 + ceil(len(assets) / 2) * 310
    sheet = Image.new("RGBA", (1120, sheet_height), (11, 15, 20, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((20, 16), "SweepyBoop auxiliary icons", fill=(245, 247, 250, 255), font=load_font(24, True))
    draw.text((20, 48), "Original Blizzard source vs approved 256x256 runtime asset", fill=(174, 184, 196, 255), font=load_font(15))
    for index, asset in enumerate(assets):
        pair_path = individual / f'{asset["outputName"]}.png'
        with Image.open(pair_path) as pair:
            x = 10 + (index % 2) * 555
            y = 82 + (index // 2) * 310
            sheet.alpha_composite(pair.convert("RGBA"), (x, y))
    sheet_path = comparisons / "all-auxiliary-icons-index.png"
    sheet.save(sheet_path, format="PNG")

    report = {
        "model": manifest["model"],
        "targetSize": manifest["targetSize"],
        "generatedAssets": len(report_assets),
        "assets": report_assets,
        "comparisonSheet": str(sheet_path),
    }
    report_path = args.scratch / "auxiliary-run-report.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"Generated {len(report_assets)} auxiliary icons and {sheet_path}")


if __name__ == "__main__":
    main()
