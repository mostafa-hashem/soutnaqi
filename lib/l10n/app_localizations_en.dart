// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SoutNaqi';

  @override
  String get appTagline => 'Pure audio & video processing';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get networkError =>
      'Network error. Check your connection and try again.';

  @override
  String get toastLoading => 'Processing…';

  @override
  String get toastSuccess => 'Done successfully.';

  @override
  String get toastFailure => 'Operation failed.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get homeWelcome => 'Welcome to SoutNaqi';

  @override
  String get homeSubtitle => 'Your workspace foundation is ready.';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkspace => 'Workspace';

  @override
  String get navSettings => 'Settings';

  @override
  String get workspaceTitle => 'Workspace';

  @override
  String get workspaceSubtitle => 'Import media and start processing.';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get aboutSection => 'About';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get themeSection => 'Theme';

  @override
  String get languageLabel => 'Language';

  @override
  String get workspaceEmptyTitle => 'Import your media';

  @override
  String get workspaceEmptySubtitle =>
      'Pick an audio or video file to start working in the canvas.';

  @override
  String get pickAudio => 'Pick audio';

  @override
  String get pickVideo => 'Pick video';

  @override
  String get pickAudioLoading => 'Opening audio picker…';

  @override
  String get pickVideoLoading => 'Opening video picker…';

  @override
  String get pickMediaSuccess => 'Media imported successfully.';

  @override
  String get mediaPickFailed => 'Could not import the selected file.';

  @override
  String get mediaTypeAudio => 'Audio';

  @override
  String get mediaTypeVideo => 'Video';

  @override
  String get previewPlayback => 'Preview';

  @override
  String get playbackOriginal => 'Original';

  @override
  String get playbackProcessed => 'Processed';

  @override
  String get processingTools => 'Processing tools';

  @override
  String get processNormalize => 'Normalize';

  @override
  String get processNoiseReduction => 'Noise reduction';

  @override
  String get processNormalizeLoading => 'Normalizing audio…';

  @override
  String get processNormalizeSuccess => 'Audio normalized successfully.';

  @override
  String get processNoiseLoading => 'Reducing noise…';

  @override
  String get processNoiseSuccess => 'Noise reduced successfully.';

  @override
  String get processingCompleteHint =>
      'Processed file is ready. Toggle playback to compare.';

  @override
  String get processingFailed => 'Processing failed. Try another file.';

  @override
  String get processingWebUnsupported =>
      'Processing is available on Android and iOS only.';

  @override
  String get processingAudioOnly =>
      'Processing is available for audio files only.';

  @override
  String get processingVideoOnly =>
      'Processing is available for video files only.';

  @override
  String get videoProcessingSoon =>
      'Video processing will arrive in a later update.';

  @override
  String get clearWorkspaceLoading => 'Clearing workspace…';

  @override
  String get clearWorkspaceSuccess => 'Workspace cleared.';

  @override
  String get trimTitle => 'Trim';

  @override
  String get trimStart => 'Start';

  @override
  String get trimEnd => 'End';

  @override
  String get applyTrim => 'Apply trim';

  @override
  String get trimLoading => 'Trimming audio…';

  @override
  String get trimSuccess => 'Audio trimmed successfully.';

  @override
  String get exportTitle => 'Export';

  @override
  String get saveExport => 'Save to device';

  @override
  String get shareExport => 'Share';

  @override
  String get saveToHistory => 'Save to history';

  @override
  String get saveLoading => 'Saving to device…';

  @override
  String get saveSuccess => 'Saved to your device.';

  @override
  String get saveFailed => 'Could not save the file.';

  @override
  String get shareLoading => 'Preparing share…';

  @override
  String get shareSuccess => 'Share sheet opened.';

  @override
  String get saveToHistoryLoading => 'Saving to history…';

  @override
  String get saveToHistorySuccess => 'Saved to history.';

  @override
  String get saveToHistoryCompleteHint =>
      'Latest export is saved in your project history.';

  @override
  String get saveToHistoryFailed => 'Could not save the file to history.';

  @override
  String get exportFailed => 'Nothing available to export yet.';

  @override
  String get waveformFailed => 'Could not generate waveform.';

  @override
  String get videoProcessingTools => 'Video tools';

  @override
  String get videoProcessingHint => 'Extract audio or compress the video file.';

  @override
  String get extractAudio => 'Extract audio';

  @override
  String get compressVideo => 'Compress video';

  @override
  String get extractAudioLoading => 'Extracting audio…';

  @override
  String get extractAudioSuccess => 'Audio extracted successfully.';

  @override
  String get compressVideoLoading => 'Compressing video…';

  @override
  String get compressVideoSuccess => 'Video compressed successfully.';

  @override
  String get videoCanvasHint =>
      'Video preview canvas — use tools below to process.';

  @override
  String get navHistory => 'History';

  @override
  String get historyEmptyTitle => 'No projects yet';

  @override
  String get historyEmptySubtitle =>
      'Save exports from the workspace to see them here.';

  @override
  String get historyDeleteLoading => 'Deleting project…';

  @override
  String get historyDeleteSuccess => 'Project deleted.';

  @override
  String get historyLoadFailed => 'Could not load project history.';

  @override
  String get historySaveFailed => 'Could not save project to history.';

  @override
  String get historyDeleteFailed => 'Could not delete project.';

  @override
  String get videoPreviewUnavailable =>
      'Video preview is not available for this file.';

  @override
  String get dropHint => 'Drag and drop an audio or video file here';

  @override
  String get dropLoading => 'Importing dropped file…';

  @override
  String get processIsolateVocals => 'Isolate vocals';

  @override
  String get processIsolateMusic => 'Isolate music';

  @override
  String get processIsolateVocalsLoading =>
      'Isolating vocals with AI… this may take a few minutes.';

  @override
  String get processIsolateVocalsSuccess => 'Vocals isolated successfully.';

  @override
  String get processIsolateMusicLoading =>
      'Isolating music with AI… this may take a few minutes.';

  @override
  String get processIsolateMusicSuccess => 'Music isolated successfully.';

  @override
  String get separationAiHint =>
      'AI separation (Demucs) — may take several minutes.';

  @override
  String get separationNotConfigured =>
      'Enable free separation: run tools/local_demucs_server on your PC and set SEPARATION_SERVER_URL in launch.json.';

  @override
  String get separationLocalHint =>
      'Local Demucs (free) — run the server on your PC. May take several minutes.';

  @override
  String get separationCloudHint =>
      'Demucs via Replicate (paid) — may take several minutes.';

  @override
  String get separationServerUnreachable =>
      'Could not reach the local Demucs server. Ensure it is running and the phone is on the same Wi‑Fi.';

  @override
  String get separationFailed => 'AI separation failed. Try another file.';

  @override
  String get separationInsufficientCredit =>
      'Insufficient Replicate credit. Add billing at replicate.com/account/billing, wait a few minutes, then try again.';

  @override
  String get separationTimeout => 'Separation timed out. Try a shorter file.';

  @override
  String get historyShareLoading => 'Preparing share…';

  @override
  String get historyShareSuccess => 'Share sheet opened.';

  @override
  String get homeOpenWorkspace => 'Open workspace';

  @override
  String get homeOpenHistory => 'View history';

  @override
  String get operationNormalize => 'Normalize';

  @override
  String get operationNoiseReduction => 'Noise reduction';

  @override
  String get operationTrim => 'Trim';

  @override
  String get operationExtractAudio => 'Extract audio';

  @override
  String get operationCompressVideo => 'Compress video';

  @override
  String get operationIsolateVocals => 'Isolate vocals';

  @override
  String get operationIsolateMusic => 'Isolate music';
}
