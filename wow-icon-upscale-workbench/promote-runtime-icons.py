import argparse
import json
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Promote approved class and spec PNGs to WoW-compatible TGA files."
    )
    parser.add_argument("manifest", type=Path)
    parser.add_argument("source", type=Path)
    parser.add_argument("art", type=Path)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    assets = manifest["assets"]
    if len(assets) != 53:
        raise ValueError(f"Expected 53 assets, found {len(assets)}")

    counts = {"class": 0, "spec": 0}
    for asset in assets:
        kind = asset["kind"]
        if kind not in counts:
            raise ValueError(f"Unsupported asset kind: {kind}")

        source = args.source / f'{asset["outputName"]}.png'
        destination_dir = args.art / ("ClassIcons" if kind == "class" else "SpecIcons")
        destination = destination_dir / f'{asset["outputName"]}.tga'
        destination_dir.mkdir(parents=True, exist_ok=True)

        with Image.open(source) as image:
            image.load()
            if image.size != (256, 256):
                raise ValueError(f"Expected 256x256 source, found {image.size}: {source}")

            rgb = image.convert("RGB")
            alpha = Image.new("L", image.size, 255)
            rgba = Image.merge("RGBA", (*rgb.split(), alpha))
            rgba.save(destination, format="TGA", compression=None)

        counts[kind] += 1

    if counts != {"class": 13, "spec": 40}:
        raise ValueError(f"Unexpected asset counts: {counts}")

    print(f"Promoted {counts['class']} class icons and {counts['spec']} spec icons.")


if __name__ == "__main__":
    main()
