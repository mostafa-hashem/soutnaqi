import 'package:soutnaqi/l10n/app_localizations.dart';

enum AudioOutputFormat {
  m4a,
  mp3,
  wav,
  flac;

  String get extension => switch (this) {
        AudioOutputFormat.m4a => 'm4a',
        AudioOutputFormat.mp3 => 'mp3',
        AudioOutputFormat.wav => 'wav',
        AudioOutputFormat.flac => 'flac',
      };

  String get mimeType => switch (this) {
        AudioOutputFormat.m4a => 'audio/mp4',
        AudioOutputFormat.mp3 => 'audio/mpeg',
        AudioOutputFormat.wav => 'audio/wav',
        AudioOutputFormat.flac => 'audio/flac',
      };

  String label(AppLocalizations l10n) => switch (this) {
        AudioOutputFormat.m4a => 'M4A (AAC)',
        AudioOutputFormat.mp3 => 'MP3',
        AudioOutputFormat.wav => 'WAV (Lossless)',
        AudioOutputFormat.flac => 'FLAC',
      };

  String description(AppLocalizations l10n) => switch (this) {
        AudioOutputFormat.m4a => l10n.formatM4aDesc,
        AudioOutputFormat.mp3 => l10n.formatMp3Desc,
        AudioOutputFormat.wav => l10n.formatWavDesc,
        AudioOutputFormat.flac => l10n.formatFlacDesc,
      };

  bool get supportsBitrate => this == AudioOutputFormat.m4a || this == AudioOutputFormat.mp3;
}

enum AudioOutputBitrate {
  b128(128),
  b192(192),
  b256(256),
  b320(320);

  const AudioOutputBitrate(this.kbps);
  final int kbps;

  String label(AppLocalizations l10n) => switch (this) {
        AudioOutputBitrate.b128 => '128 kbps (${l10n.bitrateEco})',
        AudioOutputBitrate.b192 => '192 kbps (${l10n.bitrateStandard})',
        AudioOutputBitrate.b256 => '256 kbps (${l10n.bitrateHigh})',
        AudioOutputBitrate.b320 => '320 kbps (${l10n.bitrateUltra})',
      };
}

enum AudioChannels {
  stereo(2),
  mono(1);

  const AudioChannels(this.channels);
  final int channels;

  String label(AppLocalizations l10n) => switch (this) {
        AudioChannels.stereo => l10n.channelStereo,
        AudioChannels.mono => l10n.channelMono,
      };
}

enum VideoToAudioDestination {
  workspace,
  saveToDevice,
  share,
}

class VideoToAudioOptions {
  const VideoToAudioOptions({
    this.format = AudioOutputFormat.m4a,
    this.bitrate = AudioOutputBitrate.b192,
    this.channels = AudioChannels.stereo,
    this.normalizeVolume = false,
    this.reduceNoise = false,
    this.trimStart,
    this.trimEnd,
  });

  final AudioOutputFormat format;
  final AudioOutputBitrate bitrate;
  final AudioChannels channels;
  final bool normalizeVolume;
  final bool reduceNoise;
  final Duration? trimStart;
  final Duration? trimEnd;

  VideoToAudioOptions copyWith({
    AudioOutputFormat? format,
    AudioOutputBitrate? bitrate,
    AudioChannels? channels,
    bool? normalizeVolume,
    bool? reduceNoise,
    Duration? trimStart,
    Duration? trimEnd,
    bool clearTrim = false,
  }) {
    return VideoToAudioOptions(
      format: format ?? this.format,
      bitrate: bitrate ?? this.bitrate,
      channels: channels ?? this.channels,
      normalizeVolume: normalizeVolume ?? this.normalizeVolume,
      reduceNoise: reduceNoise ?? this.reduceNoise,
      trimStart: clearTrim ? null : (trimStart ?? this.trimStart),
      trimEnd: clearTrim ? null : (trimEnd ?? this.trimEnd),
    );
  }
}
