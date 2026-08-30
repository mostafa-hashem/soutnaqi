import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createPlatformVideoPlayerController(String uri) {
  final parsed = Uri.parse(uri);
  if (parsed.scheme == 'file') {
    return VideoPlayerController.file(File.fromUri(parsed));
  }
  return VideoPlayerController.networkUrl(parsed);
}
