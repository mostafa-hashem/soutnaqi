import 'package:soutnaqi/features/audio_processing/data/audio_processing_service.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_processing_service_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/audio_processing/data/audio_processing_service_io.dart';

AudioProcessingService createAudioProcessingService() =>
    createPlatformAudioProcessingService();
