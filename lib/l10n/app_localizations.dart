import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'SoutNaqi'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Pure audio & video processing'**
  String get appTagline;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @toastLoading.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get toastLoading;

  /// No description provided for @toastSuccess.
  ///
  /// In en, this message translates to:
  /// **'Done successfully.'**
  String get toastSuccess;

  /// No description provided for @toastFailure.
  ///
  /// In en, this message translates to:
  /// **'Operation failed.'**
  String get toastFailure;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SoutNaqi'**
  String get homeWelcome;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your workspace foundation is ready.'**
  String get homeSubtitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get navWorkspace;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @workspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspaceTitle;

  /// No description provided for @workspaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import media and start processing.'**
  String get workspaceSubtitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @separationSection.
  ///
  /// In en, this message translates to:
  /// **'Separation'**
  String get separationSection;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @themeSection.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSection;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @workspaceEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Import your media'**
  String get workspaceEmptyTitle;

  /// No description provided for @workspaceEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick an audio or video file to start working in the canvas.'**
  String get workspaceEmptySubtitle;

  /// No description provided for @pickAudio.
  ///
  /// In en, this message translates to:
  /// **'Pick audio'**
  String get pickAudio;

  /// No description provided for @pickVideo.
  ///
  /// In en, this message translates to:
  /// **'Pick video'**
  String get pickVideo;

  /// No description provided for @pickAudioLoading.
  ///
  /// In en, this message translates to:
  /// **'Opening audio picker…'**
  String get pickAudioLoading;

  /// No description provided for @pickVideoLoading.
  ///
  /// In en, this message translates to:
  /// **'Opening video picker…'**
  String get pickVideoLoading;

  /// No description provided for @pickMediaSuccess.
  ///
  /// In en, this message translates to:
  /// **'Media imported successfully.'**
  String get pickMediaSuccess;

  /// No description provided for @mediaPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import the selected file.'**
  String get mediaPickFailed;

  /// No description provided for @mediaTypeAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get mediaTypeAudio;

  /// No description provided for @mediaTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get mediaTypeVideo;

  /// No description provided for @previewPlayback.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewPlayback;

  /// No description provided for @playbackOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get playbackOriginal;

  /// No description provided for @playbackProcessed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get playbackProcessed;

  /// No description provided for @processingTools.
  ///
  /// In en, this message translates to:
  /// **'Processing tools'**
  String get processingTools;

  /// No description provided for @processNormalize.
  ///
  /// In en, this message translates to:
  /// **'Normalize'**
  String get processNormalize;

  /// No description provided for @processNoiseReduction.
  ///
  /// In en, this message translates to:
  /// **'Noise reduction'**
  String get processNoiseReduction;

  /// No description provided for @processNormalizeLoading.
  ///
  /// In en, this message translates to:
  /// **'Normalizing audio…'**
  String get processNormalizeLoading;

  /// No description provided for @processNormalizeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Audio normalized successfully.'**
  String get processNormalizeSuccess;

  /// No description provided for @processNoiseLoading.
  ///
  /// In en, this message translates to:
  /// **'Reducing noise…'**
  String get processNoiseLoading;

  /// No description provided for @processNoiseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Noise reduced successfully.'**
  String get processNoiseSuccess;

  /// No description provided for @processingCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Processed file is ready. Toggle playback to compare.'**
  String get processingCompleteHint;

  /// No description provided for @processingFailed.
  ///
  /// In en, this message translates to:
  /// **'Processing failed. Try another file.'**
  String get processingFailed;

  /// No description provided for @processingWebUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Processing is available on Android and iOS only.'**
  String get processingWebUnsupported;

  /// No description provided for @processingAudioOnly.
  ///
  /// In en, this message translates to:
  /// **'Processing is available for audio files only.'**
  String get processingAudioOnly;

  /// No description provided for @processingVideoOnly.
  ///
  /// In en, this message translates to:
  /// **'Processing is available for video files only.'**
  String get processingVideoOnly;

  /// No description provided for @videoProcessingSoon.
  ///
  /// In en, this message translates to:
  /// **'Video processing will arrive in a later update.'**
  String get videoProcessingSoon;

  /// No description provided for @clearWorkspaceLoading.
  ///
  /// In en, this message translates to:
  /// **'Clearing workspace…'**
  String get clearWorkspaceLoading;

  /// No description provided for @clearWorkspaceSuccess.
  ///
  /// In en, this message translates to:
  /// **'Workspace cleared.'**
  String get clearWorkspaceSuccess;

  /// No description provided for @trimTitle.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get trimTitle;

  /// No description provided for @trimStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get trimStart;

  /// No description provided for @trimEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get trimEnd;

  /// No description provided for @applyTrim.
  ///
  /// In en, this message translates to:
  /// **'Apply trim'**
  String get applyTrim;

  /// No description provided for @trimLoading.
  ///
  /// In en, this message translates to:
  /// **'Trimming audio…'**
  String get trimLoading;

  /// No description provided for @trimSuccess.
  ///
  /// In en, this message translates to:
  /// **'Audio trimmed successfully.'**
  String get trimSuccess;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// No description provided for @saveExport.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get saveExport;

  /// No description provided for @shareExport.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareExport;

  /// No description provided for @saveToHistory.
  ///
  /// In en, this message translates to:
  /// **'Save to history'**
  String get saveToHistory;

  /// No description provided for @saveLoading.
  ///
  /// In en, this message translates to:
  /// **'Saving to device…'**
  String get saveLoading;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved to your device.'**
  String get saveSuccess;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the file.'**
  String get saveFailed;

  /// No description provided for @shareLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing share…'**
  String get shareLoading;

  /// No description provided for @shareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Share sheet opened.'**
  String get shareSuccess;

  /// No description provided for @saveToHistoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Saving to history…'**
  String get saveToHistoryLoading;

  /// No description provided for @saveToHistorySuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved to history.'**
  String get saveToHistorySuccess;

  /// No description provided for @saveToHistoryCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Latest export is saved in your project history.'**
  String get saveToHistoryCompleteHint;

  /// No description provided for @saveToHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the file to history.'**
  String get saveToHistoryFailed;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Nothing available to export yet.'**
  String get exportFailed;

  /// No description provided for @waveformFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate waveform.'**
  String get waveformFailed;

  /// No description provided for @videoProcessingTools.
  ///
  /// In en, this message translates to:
  /// **'Video tools'**
  String get videoProcessingTools;

  /// No description provided for @videoProcessingHint.
  ///
  /// In en, this message translates to:
  /// **'Extract audio or compress the video file.'**
  String get videoProcessingHint;

  /// No description provided for @extractAudio.
  ///
  /// In en, this message translates to:
  /// **'Extract audio'**
  String get extractAudio;

  /// No description provided for @compressVideo.
  ///
  /// In en, this message translates to:
  /// **'Compress video'**
  String get compressVideo;

  /// No description provided for @extractAudioLoading.
  ///
  /// In en, this message translates to:
  /// **'Extracting audio…'**
  String get extractAudioLoading;

  /// No description provided for @extractAudioSuccess.
  ///
  /// In en, this message translates to:
  /// **'Audio extracted successfully.'**
  String get extractAudioSuccess;

  /// No description provided for @compressVideoLoading.
  ///
  /// In en, this message translates to:
  /// **'Compressing video…'**
  String get compressVideoLoading;

  /// No description provided for @compressVideoSuccess.
  ///
  /// In en, this message translates to:
  /// **'Video compressed successfully.'**
  String get compressVideoSuccess;

  /// No description provided for @videoCanvasHint.
  ///
  /// In en, this message translates to:
  /// **'Video preview canvas — use tools below to process.'**
  String get videoCanvasHint;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save exports from the workspace to see them here.'**
  String get historyEmptySubtitle;

  /// No description provided for @historyDeleteLoading.
  ///
  /// In en, this message translates to:
  /// **'Deleting project…'**
  String get historyDeleteLoading;

  /// No description provided for @historyDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Project deleted.'**
  String get historyDeleteSuccess;

  /// No description provided for @historyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load project history.'**
  String get historyLoadFailed;

  /// No description provided for @historySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save project to history.'**
  String get historySaveFailed;

  /// No description provided for @historyDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete project.'**
  String get historyDeleteFailed;

  /// No description provided for @videoPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video preview is not available for this file.'**
  String get videoPreviewUnavailable;

  /// No description provided for @dropHint.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop an audio or video file here'**
  String get dropHint;

  /// No description provided for @dropLoading.
  ///
  /// In en, this message translates to:
  /// **'Importing dropped file…'**
  String get dropLoading;

  /// No description provided for @processIsolateVocals.
  ///
  /// In en, this message translates to:
  /// **'Vocals only'**
  String get processIsolateVocals;

  /// No description provided for @processIsolateMusic.
  ///
  /// In en, this message translates to:
  /// **'Music only'**
  String get processIsolateMusic;

  /// No description provided for @processIsolateVocalsLoading.
  ///
  /// In en, this message translates to:
  /// **'Extracting vocals with AI… this may take a few minutes.'**
  String get processIsolateVocalsLoading;

  /// No description provided for @processIsolateVocalsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vocals extracted successfully.'**
  String get processIsolateVocalsSuccess;

  /// No description provided for @processIsolateMusicLoading.
  ///
  /// In en, this message translates to:
  /// **'Extracting music with AI… this may take a few minutes.'**
  String get processIsolateMusicLoading;

  /// No description provided for @processIsolateMusicSuccess.
  ///
  /// In en, this message translates to:
  /// **'Music extracted successfully.'**
  String get processIsolateMusicSuccess;

  /// No description provided for @separationAiHint.
  ///
  /// In en, this message translates to:
  /// **'AI separation (Demucs) — may take several minutes.'**
  String get separationAiHint;

  /// No description provided for @separationNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Enable free separation: run tools/local_demucs_server on your PC and set SEPARATION_SERVER_URL in launch.json.'**
  String get separationNotConfigured;

  /// No description provided for @separationLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Local Demucs (free) — run the server on your PC. May take several minutes.'**
  String get separationLocalHint;

  /// No description provided for @separationCloudHint.
  ///
  /// In en, this message translates to:
  /// **'Demucs via Replicate (paid) — may take several minutes.'**
  String get separationCloudHint;

  /// No description provided for @separationServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the local Demucs server. Ensure it is running and the phone is on the same Wi‑Fi.'**
  String get separationServerUnreachable;

  /// No description provided for @separationFailed.
  ///
  /// In en, this message translates to:
  /// **'AI separation failed. Try another file.'**
  String get separationFailed;

  /// No description provided for @separationInsufficientCredit.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Replicate credit. Add billing at replicate.com/account/billing, wait a few minutes, then try again.'**
  String get separationInsufficientCredit;

  /// No description provided for @separationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Separation timed out. Try a shorter file.'**
  String get separationTimeout;

  /// No description provided for @separationOnDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'On-device separation (free, fully offline) — first use downloads a one-time model. May take several minutes.'**
  String get separationOnDeviceHint;

  /// No description provided for @separationModelSection.
  ///
  /// In en, this message translates to:
  /// **'On-device model'**
  String get separationModelSection;

  /// No description provided for @onDeviceModelDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the on-device separation model. Check your connection and try again.'**
  String get onDeviceModelDownloadFailed;

  /// No description provided for @onDeviceModelCorrupted.
  ///
  /// In en, this message translates to:
  /// **'The downloaded separation model appears corrupted. Try again.'**
  String get onDeviceModelCorrupted;

  /// No description provided for @onDeviceInsufficientStorage.
  ///
  /// In en, this message translates to:
  /// **'Not enough free storage to download the separation model.'**
  String get onDeviceInsufficientStorage;

  /// No description provided for @separationModelNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded — needed the first time you separate vocals.'**
  String get separationModelNotDownloaded;

  /// No description provided for @separationModelDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String separationModelDownloading(int percent);

  /// No description provided for @separationModelReady.
  ///
  /// In en, this message translates to:
  /// **'Ready — {size} on device'**
  String separationModelReady(String size);

  /// No description provided for @separationModelDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get separationModelDownloadAction;

  /// No description provided for @separationModelDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get separationModelDeleteAction;

  /// No description provided for @separationProgressPreparingAudio.
  ///
  /// In en, this message translates to:
  /// **'Preparing audio…'**
  String get separationProgressPreparingAudio;

  /// No description provided for @separationProgressExtractingAudio.
  ///
  /// In en, this message translates to:
  /// **'Extracting audio from video…'**
  String get separationProgressExtractingAudio;

  /// No description provided for @separationProgressLoadingModel.
  ///
  /// In en, this message translates to:
  /// **'Loading separation model…'**
  String get separationProgressLoadingModel;

  /// No description provided for @separationProgressWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Preparing AI engine (first time only)…'**
  String get separationProgressWarmingUp;

  /// No description provided for @separationProgressSeparating.
  ///
  /// In en, this message translates to:
  /// **'Separating audio… {current}/{total}'**
  String separationProgressSeparating(int current, int total);

  /// No description provided for @separationProgressSeparatingIndeterminate.
  ///
  /// In en, this message translates to:
  /// **'Separating audio with AI…'**
  String get separationProgressSeparatingIndeterminate;

  /// No description provided for @separationProgressEncoding.
  ///
  /// In en, this message translates to:
  /// **'Saving result…'**
  String get separationProgressEncoding;

  /// No description provided for @separationProgressFinalizingVideo.
  ///
  /// In en, this message translates to:
  /// **'Merging separated audio into video…'**
  String get separationProgressFinalizingVideo;

  /// No description provided for @separationProgressKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open — this may take a few minutes.'**
  String get separationProgressKeepOpen;

  /// No description provided for @historyShareLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing share…'**
  String get historyShareLoading;

  /// No description provided for @historyShareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Share sheet opened.'**
  String get historyShareSuccess;

  /// No description provided for @homeOpenWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open workspace'**
  String get homeOpenWorkspace;

  /// No description provided for @homeOpenHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get homeOpenHistory;

  /// No description provided for @operationNormalize.
  ///
  /// In en, this message translates to:
  /// **'Normalize'**
  String get operationNormalize;

  /// No description provided for @operationNoiseReduction.
  ///
  /// In en, this message translates to:
  /// **'Noise reduction'**
  String get operationNoiseReduction;

  /// No description provided for @operationTrim.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get operationTrim;

  /// No description provided for @operationExtractAudio.
  ///
  /// In en, this message translates to:
  /// **'Extract audio'**
  String get operationExtractAudio;

  /// No description provided for @operationCompressVideo.
  ///
  /// In en, this message translates to:
  /// **'Compress video'**
  String get operationCompressVideo;

  /// No description provided for @operationIsolateVocals.
  ///
  /// In en, this message translates to:
  /// **'Vocals only'**
  String get operationIsolateVocals;

  /// No description provided for @operationIsolateMusic.
  ///
  /// In en, this message translates to:
  /// **'Music only'**
  String get operationIsolateMusic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
