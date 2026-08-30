import 'package:video_player/video_player.dart';

VideoPlayerController createPlatformVideoPlayerController(String uri) {
  return VideoPlayerController.networkUrl(Uri.parse(uri));
}
