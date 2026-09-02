# SoutNaqi (صوت نقي)

A bilingual (Arabic / English) Flutter app for everyday audio and video work on your phone or desktop — trim clips, convert formats, preview waveforms, split vocals from instrumentals, and keep a local project history.

Processing runs on-device where possible (FFmpeg on Android, iOS, and desktop). **Vocal separation runs fully on the phone** via an ONNX Demucs model — no PC server required by default.

## What it does

| Area | Details |
|------|---------|
| **Workspace** | Pick audio or video, trim on a timeline, play back, export |
| **Audio** | Transcode between common formats (MP3, AAC, WAV, FLAC, OGG, …) |
| **Video** | Extract audio, mute audio, compress |
| **Separation** | Pull out vocals or instrumental stems on-device (after a one-time model download) |
| **Waveform** | Visual preview of the loaded audio |
| **History** | Reopen recent projects stored on the device |
| **Settings** | Light / dark theme, language toggle, on-device model download |

Web builds are supported for browsing the UI, but heavy processing and separation are disabled there — use a mobile or desktop target for real edits.

## Screenshots

_Add screenshots here before publishing._

## Requirements

- Flutter SDK **3.8+** ([install guide](https://docs.flutter.dev/get-started/install))
- A device or emulator (Android, iOS, Windows, macOS, or Linux)
- **FFmpeg** is bundled via `ffmpeg_kit_flutter` on IO targets — no separate install for basic editing
- For **on-device vocal separation**: ~160 MB free storage for the one-time model download (Wi‑Fi recommended)

## Quick start — run the app

```bash
git clone https://github.com/mostafa-hashem/soutnaqi.git
cd soutnaqi
flutter pub get
flutter run
```

No extra config is needed for the default on-device separation path.

### Optional: dart defines

Advanced backends are opt-in via `dart_defines.json` (gitignored). Copy the example if you need them:

```bash
cp dart_defines.example.json dart_defines.json
```

Leave both keys empty for on-device separation only:

```json
{
  "SEPARATION_SERVER_URL": "",
  "REPLICATE_API_TOKEN": ""
}
```

If you use VS Code / Cursor, `.vscode/launch.json` passes `--dart-define-from-file=dart_defines.json` when that file exists.

Run from the terminal:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## Vocal separation — on-device (default)

Separation uses an ONNX export of HT-Demucs FT directly on the phone. After the model is cached, every run is fully offline.

### Before your first separation

1. Open the app on **Android or iOS** (or desktop).
2. Go to **Settings → On-device model**.
3. Tap **Download** and wait for the ~160 MB model to finish.
4. Return to **Workspace**, import media, then use **Vocals only** or **Music only**.

The first separation after each app launch may spend ~30 seconds preparing the AI engine (NNAPI on Android). Keep the app open — a progress overlay shows each stage.

### Optional: local Demucs server on your PC

If you prefer running Demucs on a computer instead, set `SEPARATION_SERVER_URL` in `dart_defines.json`. The app prefers the local server when that key is set.

See [`tools/local_demucs_server/README.md`](tools/local_demucs_server/README.md) for setup.

### Optional: Replicate

Set `REPLICATE_API_TOKEN` in `dart_defines.json` for cloud separation. Local server URL takes priority when both are set.

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
│   ├── workspace/            # main editor (cubit + ui)
│   ├── history/
│   ├── settings/
│   ├── audio_processing/     # FFmpeg audio ops (data layer)
│   ├── video_processing/
│   ├── waveform/
│   ├── separation/           # on-device ONNX + optional server/cloud
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
- `onnxruntime_v2` for on-device Demucs separation
- `just_audio`, `video_player`
- `hugeicons`, Cairo + Inter fonts
- Optional local server: FastAPI + Demucs + uvicorn

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
