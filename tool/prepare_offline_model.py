"""Stage the pinned model as a Flutter asset for offline release builds."""

import argparse
import hashlib
import shutil
import tempfile
import urllib.request
from pathlib import Path

NAME = "UVR-MDX-NET-Voc_FT.onnx"
SIZE = 66_762_490
SHA256 = "534b2070fcc7df514b13ef660dc8cbb328679c2374d04354a5c42bb14ecce111"
URL = f"https://huggingface.co/Anjok/model-repo/resolve/main/{NAME}"
DESTINATION = Path(__file__).resolve().parents[1] / "assets" / "models" / NAME


def is_verified(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size != SIZE:
        return False
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest() == SHA256


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, help="Use an existing local ONNX file.")
    args = parser.parse_args()
    if is_verified(DESTINATION):
        print(f"Verified {DESTINATION}")
        return

    with tempfile.TemporaryDirectory(dir=DESTINATION.parent) as directory:
        candidate = Path(directory) / NAME
        if args.model is None:
            with urllib.request.urlopen(URL, timeout=120) as source, candidate.open(
                "wb"
            ) as destination:
                shutil.copyfileobj(source, destination, length=1024 * 1024)
        else:
            shutil.copyfile(args.model, candidate)

        if not is_verified(candidate):
            parser.error("Model size or SHA-256 does not match the pinned release.")
        candidate.replace(DESTINATION)
    print(f"Verified and staged {DESTINATION}")


if __name__ == "__main__":
    main()
