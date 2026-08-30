/// AAC output compatible with ffmpeg-kit-flutter **min** (no libmp3lame).
class FfmpegAudioCodec {
  const FfmpegAudioCodec._();

  static const outputExtension = 'm4a';
  static const mimeType = 'audio/mp4';
  static const _bitrate = '192k';

  static String encodeTo(String outputPath) {
    return '-c:a aac -b:a $_bitrate "$outputPath"';
  }
}
