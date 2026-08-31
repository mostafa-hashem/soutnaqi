/// Pinned specification for the on-device separation model: HT-Demucs FT
/// (vocals specialist, fp16 weights), exported to ONNX.
///
/// Source: https://huggingface.co/StemSplitio/htdemucs-ft-vocals-onnx
/// [expectedSizeBytes] and [expectedSha256] were verified against the
/// actual downloaded file, and the chunking constants were verified against
/// the model's own reference `infer.py` — do not change without
/// re-verifying against the model card.
class OnDeviceModelSpec {
  OnDeviceModelSpec._();

  static const modelFileName = 'htdemucs_ft_vocals_fp16weights.onnx';
  static const downloadUrl =
      'https://huggingface.co/StemSplitio/htdemucs-ft-vocals-onnx/resolve/main/$modelFileName';
  static const expectedSizeBytes = 165612636;
  static const expectedSha256 =
      '0cbe651f535415c9d26a7bb614f7d322dd5a080fa0298f2e50f478030a994dce';

  static const sampleRate = 44100;
  static const channels = 2;

  /// 7.8s segments, matching the model's fixed input length.
  static const chunkSamples = 343980;

  /// 25% overlap between consecutive chunks, linear-fade blended.
  static const overlapSamples = chunkSamples ~/ 4;
  static const strideSamples = chunkSamples - overlapSamples;

  static const sources = ['drums', 'bass', 'other', 'vocals'];
  static const vocalsStemIndex = 3;

  static const inputNodeName = 'mix';
  static const outputNodeName = 'stems';
}
