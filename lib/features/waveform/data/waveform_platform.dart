import 'package:soutnaqi/features/waveform/data/waveform_service.dart';
import 'package:soutnaqi/features/waveform/data/waveform_service_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/waveform/data/waveform_service_io.dart';

WaveformService createWaveformService() => createPlatformWaveformService();
