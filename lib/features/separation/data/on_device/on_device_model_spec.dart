/// Pinned specification for the on-device separation model: UVR-MDX-NET Voc FT.
///
/// A vocals-specialist MDX-Net (Conv-TDF), much smaller than HTDemucs, so it
/// can run on a phone CPU without freezing the device. Parameters match the
/// UVR model JSON for hash `77d07b2667ddf05b9e3175941b4454a0`:
/// compensate 1.021, dim_f 3072, dim_t 2^8, n_fft 7680, primary stem Vocals.
/// Hop is UVR's fixed 1024. Overlap 0.25 is the UVR default window blend.
///
/// Source file:
/// https://github.com/TRvlvr/model_repo/releases/download/all_public_uvr_models/UVR-MDX-NET-Voc_FT.onnx
class OnDeviceModelSpec {
  OnDeviceModelSpec._();

  static const modelFileName = 'UVR-MDX-NET-Voc_FT.onnx';
  static const legacyModelFileName = 'htdemucs_ft_vocals_fp16weights.onnx';
  static const downloadUrl =
      'https://github.com/TRvlvr/model_repo/releases/download/all_public_uvr_models/$modelFileName';
  static const expectedSizeBytes = 66762490;
  static const expectedSha256 =
      '534b2070fcc7df514b13ef660dc8cbb328679c2374d04354a5c42bb14ecce111';

  static const sampleRate = 44100;
  static const channels = 2;

  static const nFft = 7680;
  static const hopLength = 1024;
  static const dimF = 3072;
  static const dimT = 256;
  static const compensate = 1.021;

  /// Half the FFT. UVR center-pads the mix by this much before chunking.
  static const trimSamples = nFft ~/ 2;

  /// One model window: hop * (dim_t - 1). STFT of this length yields [dimT] frames.
  static const chunkSamples = hopLength * (dimT - 1);

  /// Distance between overlap-add windows at 25% overlap.
  static const strideSamples = chunkSamples * 3 ~/ 4;

  /// UVR's non-checkpoint chunk advance before the overlap step is applied.
  static const genSize = chunkSamples - 2 * trimSamples;

  static const frequencyBins = nFft ~/ 2 + 1;

  static const inputNodeName = 'input';
  static const outputNodeName = 'output';

  /// `[batch, real/imag left+right, freq, time]`.
  static const spectrumElementCount = 4 * dimF * dimT;
}
