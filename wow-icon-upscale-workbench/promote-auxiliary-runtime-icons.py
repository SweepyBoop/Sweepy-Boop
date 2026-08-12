import argparse
import json
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Promote approved auxiliary PNGs to WoW-compatible TGA files."
    )
    parser.add_argument("manifest", type=Path)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    assets = manifest["assets"]
    if len(assets) != 6:
        raise ValueError(f"Expected 6 auxiliary assets, found {len(assets)}")

    args.destination.mkdir(parents=True, exist_ok=True)
    expected_names = {f'{asset["outputName"]}.tga' for asset in assets}
    for old_file in args.destination.glob("*.tga"):
        if old_file.name not in expected_names:
            old_file.unlink()

    for asset in assets:
        source = args.source / f'{asset["outputName"]}.png'
        destination = args.destination / f'{asset["outputName"]}.tga'
        with Image.open(source) as image:
            image.load()
            if image.size != (256, 256):
                raise ValueError(f"Expected 256x256 source, found {image.size}: {source}")
            image.convert("RGBA").save(destination, format="TGA", compression=None)

    print(f"Promoted {len(assets)} auxiliary runtime icons to {args.destination}")


if __name__ == "__main__":
    main()
