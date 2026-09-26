<p align="center">
  <img src="assets/brand/app-icon.png" alt="SoutNaqi Logo" width="120" style="border-radius: 24px;" />
</p>

<h1 align="center">SoutNaqi (صوت نقي)</h1>

<p align="center">
  <strong>An open-source on-device audio & video processor with AI vocal separation for Android.</strong>
  <br />
  <em>Trim, convert formats, extract audio, and separate vocals/music completely offline on your phone.</em>
</p>

<p align="center">
  <a href="https://github.com/mostafa-hashem/soutnaqi/releases/latest">
    <img src="https://img.shields.io/github/v/release/mostafa-hashem/soutnaqi?color=2563EB&label=Download%20APK&logo=android" alt="Download Release" />
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" alt="Android" />
  <img src="https://img.shields.io/badge/AI_Engine-ONNX%20Demucs-FF6F00" alt="ONNX Demucs" />
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License" />
</p>

---

<p align="center">
  <a href="#-download-apk"><b>📥 Download</b></a> •
  <a href="#-key-features"><b>✨ Features</b></a> •
  <a href="#-how-to-use"><b>🚀 How to Use</b></a> •
  <a href="#-screenshots"><b>📸 Screenshots</b></a> •
  <a href="#-developer-guide"><b>💻 Developer Guide</b></a>
</p>

---

## 📥 Download APK

You can download the latest installable Android APK directly from GitHub Releases:

[![Download APK](https://img.shields.io/badge/Download_APK-Direct_Download-2563EB?style=for-the-badge&logo=android&logoColor=white)](https://github.com/mostafa-hashem/soutnaqi/releases/latest)

> 💡 **Quick Note:** After installing and launching the app, head over to **Settings → On-device model** and download the Demucs AI model (~160 MB) once. After this one-time download, vocal separation runs completely offline without any internet connection!

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🎙️ **AI Vocal Separation** | Extract vocals or instrumental stems (Acappella / Karaoke) using Demucs AI running directly on your mobile device. |
| ✂️ **Audio & Video Trimmer** | High-precision timeline trimming with real-time waveform visual scrubbing. |
| 🔄 **Format Conversion** | Rapidly convert audio tracks between popular formats: **MP3, AAC, WAV, FLAC, OGG, M4A**. |
| 🎬 **Video Tools** | One-tap audio extraction from video clips, mute audio, and compress media. |
| 📊 **Interactive Waveform** | Smooth visual audio representation for intuitive seeking and playback. |
| 📁 **Local Project History** | Automatically save and quickly resume your recent edits and projects on-device. |
| 🌐 **Bilingual & Modern UI** | Seamless Arabic & English support with polished Dark and Light themes. |

---

## 🚀 How to Use

1. **Import Media:** Tap the import button to choose any audio or video file from your phone.
2. **Choose Operation:**
   - **Vocal Separation:** Select **Vocals only** or **Music only**.
   - **Trim & Edit:** Adjust the start and end handles on the timeline.
   - **Convert Format:** Choose your desired output format and audio bitrate.
3. **Process & Export:** Preview the processed result instantly and save it to your storage or share it with friends.

---

## 📸 Screenshots

<p align="center">
  <i>Screenshots coming soon</i>
</p>

---

## 💻 Developer Guide

Want to build or contribute to SoutNaqi locally from source?

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.8 or later).
- Android Studio or VS Code with an Android device or emulator.

### Getting Started

```bash
# 1. Clone the repository
git clone https://github.com/mostafa-hashem/soutnaqi.git

# 2. Navigate to the project directory
cd soutnaqi

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run
```

### Build Release APK

To create optimized and lightweight release APKs (reduces size from ~170MB to ~60MB):

```bash
flutter build apk --split-per-abi
```

The output APK for modern devices (64-bit) will be at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~60 MB).

### Optional: Remote Demucs Server
By default, the app runs Demucs on-device using ONNX Runtime. If you prefer running Demucs on an external PC server or via Replicate, configure `dart_defines.json`:

```bash
cp dart_defines.example.json dart_defines.json
```

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart 3)
- **State Management:** `flutter_bloc` (Cubit Pattern)
- **Audio & Video Processing:** `ffmpeg_kit_flutter_new_min`, `just_audio`, `video_player`
- **AI Neural Engine:** `onnxruntime_v2` (HT-Demucs Model)
- **Typography & Icons:** Cairo & Inter Fonts, HugeIcons

---

## 📄 License

This project is open-source and licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

## 👤 Author

Developed with ❤️ by **[Mostafa Hashem](https://github.com/mostafa-hashem)**.
