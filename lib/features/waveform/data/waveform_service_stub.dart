import 'dart:math';

import 'package:soutnaqi/features/media/data/models/media_file.dart';
import 'package:soutnaqi/features/waveform/data/waveform_service.dart';

WaveformService createPlatformWaveformService() => StubWaveformService();

class StubWaveformService implements WaveformService {
  @override
  Future<List<double>> extractPeaks({
    required MediaFile media,
    int barCount = 120,
  }) {
    return Future.value(_generatePlaceholderPeaks(media.name, barCount));
  }

  List<double> _generatePlaceholderPeaks(String seed, int barCount) {
    final random = Random(seed.hashCode);
    return List.generate(
      barCount,
      (index) {
        final wave = sin(index / barCount * pi * 6);
        return (0.2 + (wave.abs() * 0.35) + random.nextDouble() * 0.25)
            .clamp(0.08, 1.0);
      },
    );
  }
}
