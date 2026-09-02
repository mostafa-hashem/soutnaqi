// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'صوت نقي';

  @override
  String get appTagline => 'معالجة صوت وفيديو بجودة عالية';

  @override
  String get genericError => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get networkError => 'خطأ في الشبكة. تحقق من اتصالك وحاول مجدداً.';

  @override
  String get toastLoading => 'جاري المعالجة…';

  @override
  String get toastSuccess => 'تم بنجاح.';

  @override
  String get toastFailure => 'فشلت العملية.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'النظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get homeWelcome => 'مرحباً بك في صوت نقي';

  @override
  String get homeSubtitle => 'الأساس جاهز لبدء العمل.';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navWorkspace => 'مساحة العمل';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get workspaceTitle => 'مساحة العمل';

  @override
  String get workspaceSubtitle => 'استورد الوسائط وابدأ المعالجة.';

  @override
  String get appearanceSection => 'المظهر';

  @override
  String get separationSection => 'فصل الصوت';

  @override
  String get aboutSection => 'حول التطبيق';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get themeSection => 'السمة';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get workspaceEmptyTitle => 'استورد وسائطك';

  @override
  String get workspaceEmptySubtitle =>
      'اختر ملف صوت أو فيديو للبدء في مساحة العمل.';

  @override
  String get pickAudio => 'اختيار صوت';

  @override
  String get pickVideo => 'اختيار فيديو';

  @override
  String get pickAudioLoading => 'جاري فتح محدد الصوت…';

  @override
  String get pickVideoLoading => 'جاري فتح محدد الفيديو…';

  @override
  String get pickMediaSuccess => 'تم استيراد الوسائط بنجاح.';

  @override
  String get mediaPickFailed => 'تعذر استيراد الملف المحدد.';

  @override
  String get mediaTypeAudio => 'صوت';

  @override
  String get mediaTypeVideo => 'فيديو';

  @override
  String get previewPlayback => 'معاينة';

  @override
  String get playbackOriginal => 'الأصلي';

  @override
  String get playbackProcessed => 'بعد المعالجة';

  @override
  String get processingTools => 'أدوات المعالجة';

  @override
  String get processNormalize => 'توحيد الصوت';

  @override
  String get processNoiseReduction => 'تقليل الضوضاء';

  @override
  String get processNormalizeLoading => 'جاري توحيد الصوت…';

  @override
  String get processNormalizeSuccess => 'تم توحيد الصوت بنجاح.';

  @override
  String get processNoiseLoading => 'جاري تقليل الضوضاء…';

  @override
  String get processNoiseSuccess => 'تم تقليل الضوضاء بنجاح.';

  @override
  String get processingCompleteHint =>
      'الملف المعالج جاهز. بدّل المعاينة للمقارنة.';

  @override
  String get processingFailed => 'فشلت المعالجة. جرّب ملفاً آخر.';

  @override
  String get processingWebUnsupported =>
      'المعالجة متاحة على Android و iOS فقط.';

  @override
  String get processingAudioOnly => 'المعالجة متاحة لملفات الصوت فقط.';

  @override
  String get processingVideoOnly => 'المعالجة متاحة لملفات الفيدio فقط.';

  @override
  String get videoProcessingSoon => 'معالجة الفيدio قادمة في تحديث لاحق.';

  @override
  String get clearWorkspaceLoading => 'جاري مسح مساحة العمل…';

  @override
  String get clearWorkspaceSuccess => 'تم مسح مساحة العمل.';

  @override
  String get trimTitle => 'قص';

  @override
  String get trimStart => 'البداية';

  @override
  String get trimEnd => 'النهاية';

  @override
  String get applyTrim => 'تطبيق القص';

  @override
  String get trimLoading => 'جاري قص الصوت…';

  @override
  String get trimSuccess => 'تم قص الصوت بنجاح.';

  @override
  String get exportTitle => 'تصدير';

  @override
  String get saveExport => 'حفظ على الجهاز';

  @override
  String get shareExport => 'مشاركة';

  @override
  String get saveToHistory => 'حفظ في السجل';

  @override
  String get saveLoading => 'جاري الحفظ على الجهاز…';

  @override
  String get saveSuccess => 'تم الحفظ على جهازك.';

  @override
  String get saveFailed => 'تعذّر حفظ الملف.';

  @override
  String get shareLoading => 'جاري تجهيز المشاركة…';

  @override
  String get shareSuccess => 'تم فتح نافذة المشاركة.';

  @override
  String get saveToHistoryLoading => 'جاري الحفظ في السجل…';

  @override
  String get saveToHistorySuccess => 'تم الحفظ في السجل.';

  @override
  String get saveToHistoryCompleteHint => 'آخر تصدير محفوظ في سجل المشاريع.';

  @override
  String get saveToHistoryFailed => 'تعذّر حفظ الملف في السجل.';

  @override
  String get exportFailed => 'لا يوجد ملف للتصدير بعد.';

  @override
  String get waveformFailed => 'تعذر إنشاء الموجة الصوتية.';

  @override
  String get videoProcessingTools => 'أدوات الفيدio';

  @override
  String get videoProcessingHint => 'استخرج الصوت أو اضغط ملف الفيدio.';

  @override
  String get extractAudio => 'استخراج الصوت';

  @override
  String get compressVideo => 'ضغط الفيدio';

  @override
  String get extractAudioLoading => 'جاري استخراج الصوت…';

  @override
  String get extractAudioSuccess => 'تم استخراج الصوت بنجاح.';

  @override
  String get compressVideoLoading => 'جاري ضغط الفيدio…';

  @override
  String get compressVideoSuccess => 'تم ضغط الفيدio بنجاح.';

  @override
  String get videoCanvasHint =>
      'لوحة معاينة الفيدio — استخدم الأدوات بالأسفل للمعالجة.';

  @override
  String get navHistory => 'السجل';

  @override
  String get historyEmptyTitle => 'لا توجد مشاريع بعد';

  @override
  String get historyEmptySubtitle => 'احفظ التصدير من مساحة العمل ليظهر هنا.';

  @override
  String get historyDeleteLoading => 'جاري حذف المشروع…';

  @override
  String get historyDeleteSuccess => 'تم حذف المشروع.';

  @override
  String get historyLoadFailed => 'تعذّر تحميل سجل المشاريع.';

  @override
  String get historySaveFailed => 'تعذّر حفظ المشروع في السجل.';

  @override
  String get historyDeleteFailed => 'تعذّر حذف المشروع.';

  @override
  String get videoPreviewUnavailable => 'معاينة الفيدio غير متاحة لهذا الملف.';

  @override
  String get dropHint => 'اسحب ملف صوت أو فيدio وأفلته هنا';

  @override
  String get dropLoading => 'جاري استيراد الملف…';

  @override
  String get processIsolateVocals => 'صوت فقط';

  @override
  String get processIsolateMusic => 'موسيقى فقط';

  @override
  String get processIsolateVocalsLoading =>
      'جاري استخراج الصوت بالذكاء الاصطناعي… قد يستغرق دقائق.';

  @override
  String get processIsolateVocalsSuccess => 'تم استخراج الصوت بنجاح.';

  @override
  String get processIsolateMusicLoading =>
      'جاري استخراج الموسيقى بالذكاء الاصطناعي… قد يستغرق دقائق.';

  @override
  String get processIsolateMusicSuccess => 'تم استخراج الموسيقى بنجاح.';

  @override
  String get separationAiHint =>
      'الفصل بالذكاء الاصطناعي (Demucs) — قد يستغرق عدة دقائق.';

  @override
  String get separationNotConfigured =>
      'فعّل الفصل المجاني: شغّل tools/local_demucs_server على جهازك وأضف SEPARATION_SERVER_URL في launch.json.';

  @override
  String get separationLocalHint =>
      'Demucs محلي (مجاني) — شغّل السيرفر على جهازك. قد يستغرق عدة دقائق.';

  @override
  String get separationCloudHint =>
      'Demucs عبر Replicate (مدفوع) — قد يستغرق عدة دقائق.';

  @override
  String get separationServerUnreachable =>
      'تعذّر الاتصال بسيرفر Demucs المحلي. تأكد أنه يعمل وأن الهاتف على نفس شبكة Wi‑Fi.';

  @override
  String get separationFailed => 'فشل الفصل بالذكاء الاصطناعي. جرّب ملفاً آخر.';

  @override
  String get separationInsufficientCredit =>
      'رصيد Replicate غير كافٍ. أضف رصيداً من replicate.com/account/billing ثم حاول مجدداً.';

  @override
  String get separationTimeout => 'انتهت مهلة الفصل. جرّب ملفاً أقصر.';

  @override
  String get separationOnDeviceHint =>
      'الفصل على الجهاز (مجاني، بدون إنترنت بالكامل) — يتم تنزيل نموذج مرة واحدة عند أول استخدام. قد يستغرق عدة دقائق.';

  @override
  String get separationModelSection => 'نموذج الفصل على الجهاز';

  @override
  String get onDeviceModelDownloadFailed =>
      'تعذّر تنزيل نموذج الفصل على الجهاز. تحقق من اتصالك وحاول مجدداً.';

  @override
  String get onDeviceModelCorrupted =>
      'يبدو أن النموذج الذي تم تنزيله تالف. حاول مجدداً.';

  @override
  String get onDeviceInsufficientStorage =>
      'لا توجد مساحة تخزين كافية لتنزيل نموذج الفصل.';

  @override
  String get separationModelNotDownloaded =>
      'غير مُنزَّل — سيُطلب عند أول استخدام لفصل الصوت.';

  @override
  String separationModelDownloading(int percent) {
    return 'جاري التنزيل… $percent%';
  }

  @override
  String separationModelReady(String size) {
    return 'جاهز — $size على الجهاز';
  }

  @override
  String get separationModelDownloadAction => 'تنزيل';

  @override
  String get separationModelDeleteAction => 'حذف';

  @override
  String get separationProgressPreparingAudio => 'جاري تجهيز الصوت…';

  @override
  String get separationProgressExtractingAudio =>
      'جاري استخراج الصوت من الفيدio…';

  @override
  String get separationProgressLoadingModel => 'جاري تحميل نموذج الفصل…';

  @override
  String get separationProgressWarmingUp =>
      'جاري تجهيز محرك الذكاء الاصطناعي (مرة واحدة فقط)…';

  @override
  String separationProgressSeparating(int current, int total) {
    return 'جاري فصل الصوت… $current/$total';
  }

  @override
  String get separationProgressSeparatingIndeterminate =>
      'جاري فصل الصوت بالذكاء الاصطناعي…';

  @override
  String get separationProgressEncoding => 'جاري حفظ النتيجة…';

  @override
  String get separationProgressFinalizingVideo =>
      'جاري دمج الصوت المفصول في الفيدio…';

  @override
  String get separationProgressKeepOpen =>
      'اترك التطبيق مفتوحاً — قد يستغرق الأمر عدة دقائق.';

  @override
  String get historyShareLoading => 'جاري تجهيز المشاركة…';

  @override
  String get historyShareSuccess => 'تم فتح نافذة المشاركة.';

  @override
  String get homeOpenWorkspace => 'فتح مساحة العمل';

  @override
  String get homeOpenHistory => 'عرض السجل';

  @override
  String get operationNormalize => 'توحيد الصوت';

  @override
  String get operationNoiseReduction => 'تقليل الضوضاء';

  @override
  String get operationTrim => 'قص';

  @override
  String get operationExtractAudio => 'استخراج الصوت';

  @override
  String get operationCompressVideo => 'ضغط الفيدio';

  @override
  String get operationIsolateVocals => 'صوت فقط';

  @override
  String get operationIsolateMusic => 'موسيقى فقط';
}
