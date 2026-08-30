import 'package:soutnaqi/features/media/data/video_player_factory_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/media/data/video_player_factory_io.dart'
    if (dart.library.html) 'package:soutnaqi/features/media/data/video_player_factory_web.dart';
import 'package:video_player/video_player.dart';

VideoPlayerController createVideoPlayerController(String uri) =>
    createPlatformVideoPlayerController(uri);
