import argparse
import hashlib
import json
import struct
from pathlib import Path

from PIL import Image


BLP2_HEADER_SIZE = 1172


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def open_blp(path: Path) -> Image.Image:
    with path.open("rb") as stream:
        header = stream.read(BLP2_HEADER_SIZE)
        if header[:4] != b"BLP2":
            raise ValueError(f"Expected BLP2 source: {path}")

        encoding, alpha_depth = header[8], header[9]
        width, height = struct.unpack_from("<II", header, 12)
        mip_offset = struct.unpack_from("<I", header, 20)[0]
        mip_size = struct.unpack_from("<I", header, 84)[0]

        if encoding == 3:
            expected_size = width * height * 4
            if alpha_depth != 8 or mip_size != expected_size:
                raise ValueError(f"Unexpected raw BGRA layout: {path}")
            stream.seek(mip_offset)
            raw = stream.read(mip_size)
            return Image.frombytes("RGBA", (width, height), raw, "raw", "BGRA")

    with Image.open(path) as image:
        image.load()
        return image.convert("RGBA")


def crop_from_coords(image: Image.Image, coords: list[float]) -> tuple[Image.Image, list[int]]:
    left, right, top, bottom = coords
    box = [
        round(left * image.width),
        round(top * image.height),
        round(right * image.width),
        round(bottom * image.height),
    ]
    return image.crop(box), box


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract auxiliary WoW icons from Retail BLP files.")
    parser.add_argument("manifest", type=Path)
    parser.add_argument("retail_art", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    assets = manifest["assets"]
    if len(assets) != 7:
        raise ValueError(f"Expected 7 auxiliary assets, found {len(assets)}")

    args.output.mkdir(parents=True, exist_ok=True)
    report_assets = []
    for asset in assets:
        source_path = args.retail_art / Path(asset["retailPath"])
        source_image = open_blp(source_path)
        crop_box = None
        if asset["kind"] == "atlas":
            output_image, crop_box = crop_from_coords(source_image, asset["texCoords"])
        else:
            output_image = source_image

        output_path = args.output / f'{asset["outputName"]}.png'
        output_image.save(output_path, format="PNG")
        report_assets.append(
            {
                **asset,
                "sourcePath": str(source_path),
                "sourceSha256": sha256(source_path),
                "sourceSize": list(source_image.size),
                "cropBox": crop_box,
                "inputSize": list(output_image.size),
                "inputPath": str(output_path),
                "inputSha256": sha256(output_path),
            }
        )

    report = {
        "sourcePolicy": manifest["sourcePolicy"],
        "targetSize": manifest["targetSize"],
        "assets": report_assets,
    }
    report_path = args.output.parent / "auxiliary-extraction-report.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"Extracted {len(report_assets)} auxiliary icons to {args.output}")


if __name__ == "__main__":
    main()
