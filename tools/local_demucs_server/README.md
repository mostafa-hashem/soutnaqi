# Local Demucs server

Small FastAPI wrapper so SoutNaqi can separate vocals and instrumentals using [Demucs](https://github.com/facebookresearch/demucs) on your own machine — no cloud billing.

The Flutter app POSTs audio to `/separate` and receives a WAV stem back.

## Setup (once)

```powershell
cd tools\local_demucs_server
python -m venv .venv
.\.venv\Scripts\activate          # macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
```

First install downloads PyTorch and model weights (~1–2 GB). FFmpeg must be on `PATH`.

## Run

```powershell
python server.py
```

Server binds to `http://0.0.0.0:8765`.

Health check: `GET /health` → `{"status":"ok"}`

## Configure SoutNaqi

1. Find your PC LAN IP (`ipconfig` / `ip addr`).
2. Copy `dart_defines.example.json` to `dart_defines.json` at the repo root.
3. Set:

```json
{
  "SEPARATION_SERVER_URL": "http://192.168.1.100:8765"
}
```

4. Phone and PC on the same Wi‑Fi. Open port **8765** in the firewall if needed.
5. From the phone browser, hit `http://192.168.1.100:8765/health` to confirm connectivity.

Local server takes priority over `REPLICATE_API_TOKEN` when the URL is set.

## API

| Method | Path | Body | Response |
|--------|------|------|----------|
| `GET` | `/health` | — | `{"status":"ok"}` |
| `POST` | `/separate` | `multipart`: `audio` file + `target` (`vocals` or `instrumental`) | `audio/wav` bytes |
