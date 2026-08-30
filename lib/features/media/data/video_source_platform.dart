import 'package:soutnaqi/features/media/data/video_source_resolver.dart';
import 'package:soutnaqi/features/media/data/video_source_resolver_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/media/data/video_source_resolver_io.dart'
    if (dart.library.html) 'package:soutnaqi/features/media/data/video_source_resolver_web.dart';

VideoSourceResolver createVideoSourceResolver() =>
    createPlatformVideoSourceResolver();
