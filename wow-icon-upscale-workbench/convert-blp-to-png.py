import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert a Blizzard BLP icon to lossless PNG.")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(args.input) as image:
        image.load()
        image.save(args.output, format="PNG")


if __name__ == "__main__":
    main()
