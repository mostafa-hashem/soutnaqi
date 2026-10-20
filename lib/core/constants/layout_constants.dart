import 'package:soutnaqi/core/services/app_info_service.dart';

const double kShellSidebarBreakpoint = 800;

/// Extra space at the bottom of scrollable shell content so controls
/// are not flush against the bottom navigation bar.
const double kShellScrollBottomGap = 16;

/// Approximate shell bottom nav content height (excluding system inset).
const double kShellBottomNavBarHeight = 72;

String get kAppVersion => AppInfoService.instance.displayVersion;

const Duration kSplashMinDuration = Duration(milliseconds: 1800);

const String kTelegramCommunityUrl = 'https://t.me/+bhgjHPz-P9Y4MTc0';
