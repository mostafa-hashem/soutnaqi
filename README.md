# SoutNaqi (صوت نقي)

A bilingual (Arabic / English) Flutter app for everyday audio and video work on your phone or desktop — trim clips, convert formats, preview waveforms, split vocals from instrumentals, and keep a local project history.

Processing runs on-device where possible (FFmpeg on Android, iOS, and desktop). Vocal separation can use a **free local Demucs server** on your PC, or optionally Replicate if you already have an API token.

## What it does

| Area | Details |
|------|---------|
| **Workspace** | Pick audio or video, trim on a timeline, play back, export |
| **Audio** | Transcode between common formats (MP3, AAC, WAV, FLAC, OGG, …) |
| **Video** | Extract audio, mute audio, compress |
| **Separation** | Pull out vocals or instrumental stems (needs server config — see below) |
| **Waveform** | Visual preview of the loaded audio |
| **History** | Reopen recent projects stored on the device |
| **Settings** | Light / dark theme, language toggle |

Web builds are supported for browsing the UI, but heavy processing is disabled there — use a mobile or desktop target for real edits.

## Screenshots

_Add screenshots here before publishing._

## Requirements

- Flutter SDK **3.8+** ([install guide](https://docs.flutter.dev/get-started/install))
- A device or emulator (Android, iOS, Windows, macOS, or Linux)
- **FFmpeg** is bundled via `ffmpeg_kit_flutter` on IO targets — no separate install for basic editing
- For **vocal separation**: Python 3.10+ and the local server in `tools/local_demucs_server` (or a Replicate API token)

## Quick start — run the app

```bash
git clone https://github.com/mostafa-hashem/soutnaqi.git
cd soutnaqi
flutter pub get
flutter run
```

### Optional: dart defines

Copy the example config and edit it with your PC's LAN IP when using local separation:

```bash
cp dart_defines.example.json dart_defines.json
```

`dart_defines.json` is gitignored so your IP and tokens stay local.

If you use VS Code / Cursor, the included `.vscode/launch.json` already passes `--dart-define-from-file=dart_defines.json`.

Run from the terminal instead:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## Vocal separation — local Demucs server

Separation does not run inside the Flutter app. You run a small FastAPI wrapper on your computer; the phone sends audio over Wi‑Fi and gets back a WAV stem.

### 1. One-time setup

```powershell
cd tools\local_demucs_server
python -m venv .venv
.\.venv\Scripts\activate        # macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
```

The first `pip install` pulls PyTorch and Demucs weights (~1–2 GB). FFmpeg must be on your `PATH` (`winget install ffmpeg` on Windows works).

### 2. Start the server

```powershell
python server.py
```

Listens on `http://0.0.0.0:8765`. Check it locally: [http://localhost:8765/health](http://localhost:8765/health) should return `{"status":"ok"}`.

### 3. Point the app at your PC

Find your machine's LAN address (`ipconfig` on Windows, `ip addr` on Linux). Phone and PC must be on the **same network**.

In `dart_defines.json`:

```json
{
  "SEPARATION_SERVER_URL": "http://192.168.1.100:8765"
}
```

Allow **port 8765** through the firewall if the phone cannot reach the server. Test from the phone browser: `http://192.168.1.100:8765/health`.

### Alternative: Replicate

Set `REPLICATE_API_TOKEN` in `dart_defines.json` instead. The app prefers the local server when `SEPARATION_SERVER_URL` is set.

More detail: [`tools/local_demucs_server/README.md`](tools/local_demucs_server/README.md)

## Project layout

Feature-first structure under `lib/`. Each feature owns its UI, state, and data; shared pieces live in `core/`.

```
lib/
├── main.dart                 # entry point
├── app.dart                  # MaterialApp, theme, localization
├── core/
│   ├── config/               # compile-time env (dart-define)
│   ├── constants/
│   ├── errors/
│   ├── layout/
│   ├── logging/
│   ├── platform/
│   ├── storage/
│   ├── theme/
│   ├── toast/
│   └── widgets/              # reused across features only
├── features/
│   ├── shell/                # navigation shell (sidebar / bottom nav)
│   ├── splash/
│   ├── workspace/          # main editor (cubit + ui)
│   ├── history/
│   ├── settings/
│   ├── audio_processing/   # FFmpeg audio ops (data layer)
│   ├── video_processing/
│   ├── waveform/
│   ├── separation/           # local server + Replicate clients
│   ├── export/
│   └── media/                # file picking, video player factories
└── l10n/                     # ARB files + generated localizations
```

**Conventions**

- State: `flutter_bloc` cubits with `Equatable` states
- Imports: always `package:soutnaqi/...` (no relative paths between features)
- Platform split: `*_platform.dart` exports IO or stub implementations via conditional imports
- UI strings: `AppLocalizations` from ARB files — no hard-coded user-facing text

Processing services (`audio_processing`, `video_processing`, etc.) are data-only modules injected into `WorkspaceCubit` at bootstrap time.

## Stack

- Flutter / Dart 3.8
- `flutter_bloc` + `equatable`
- `ffmpeg_kit_flutter_new_min` for on-device transcoding
- `just_audio`, `video_player`
- `hugeicons`, Cairo + Inter fonts
- Local server: FastAPI + Demucs + uvicorn

## Localization

Strings live in `lib/l10n/app_en.arb` and `app_ar.arb`. After editing ARBs:

```bash
flutter gen-l10n
```

## Tests

```bash
flutter test
```

## License

_Not specified yet — add a LICENSE file before making the repo public if you want others to reuse the code._

## Author

[mostafa-hashem](https://github.com/mostafa-hashem)
