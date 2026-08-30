import 'package:soutnaqi/features/video_processing/data/video_processing_service.dart';
import 'package:soutnaqi/features/video_processing/data/video_processing_service_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/video_processing/data/video_processing_service_io.dart';

VideoProcessingService createVideoProcessingService() =>
    createPlatformVideoProcessingService();
