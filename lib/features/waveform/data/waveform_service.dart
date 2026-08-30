import 'package:soutnaqi/features/media/data/models/media_file.dart';

abstract class WaveformService {
  Future<List<double>> extractPeaks({
    required MediaFile media,
    int barCount = 120,
  });
}
