"""Free local Demucs server for SoutNaqi (personal use).

Setup:
  cd tools/local_demucs_server
  python -m venv .venv
  .venv\\Scripts\\activate   # Windows
  pip install -r requirements.txt
  python server.py

Then in .vscode/launch.json set:
  --dart-define=SEPARATION_SERVER_URL=http://YOUR_PC_LAN_IP:8765

Phone and PC must be on the same Wi-Fi. Allow port 8765 in Windows Firewall.
FFmpeg must be on PATH (install from https://ffmpeg.org or via winget install ffmpeg).
"""

from __future__ import annotations

import logging
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import uvicorn
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import Response

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("soutnaqi_demucs")

app = FastAPI(title="SoutNaqi Local Demucs")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/separate")
async def separate(
    audio: UploadFile = File(...),
    target: str = Form("vocals"),
) -> Response:
    if target not in {"vocals", "instrumental"}:
        raise HTTPException(status_code=400, detail="target must be vocals or instrumental")

    work_dir = Path(tempfile.mkdtemp(prefix="soutnaqi_demucs_"))
    try:
        input_path = work_dir / "input.wav"
        input_path.write_bytes(await audio.read())

        output_root = work_dir / "separated"
        command = [
            sys.executable,
            "-m",
            "demucs",
            "--two-stems",
            "vocals",
            "-o",
            str(output_root),
            str(input_path),
        ]
        logger.info("Running Demucs for target=%s", target)
        completed = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
        )
        if completed.returncode != 0:
            detail = (completed.stderr or completed.stdout or "demucs failed").strip()
            logger.error("Demucs failed: %s", detail)
            raise HTTPException(status_code=500, detail=detail[:500])

        if not output_root.exists():
            raise HTTPException(status_code=500, detail="demucs produced no output directory")

        stem_name = "vocals.wav" if target == "vocals" else "no_vocals.wav"
        matches = list(output_root.rglob(stem_name))
        if not matches:
            available = ", ".join(
                path.name for path in output_root.rglob("*.wav")
            )
            logger.error("Stem not found: %s (available: %s)", stem_name, available)
            raise HTTPException(
                status_code=500,
                detail=f"stem not found: {stem_name} (available: {available})",
            )

        stem_path = matches[0]
        stem_bytes = stem_path.read_bytes()
        logger.info("Separation complete: %s (%s bytes)", stem_name, len(stem_bytes))
        return Response(content=stem_bytes, media_type="audio/wav")
    finally:
        shutil.rmtree(work_dir, ignore_errors=True)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8765)
