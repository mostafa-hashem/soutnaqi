import 'package:flutter/material.dart';

import 'package:soutnaqi/core/constants/layout_constants.dart';

/// Safe-area helpers for edge-to-edge Android (API 35+) and gesture navigation.
extension MaglissSafeInsets on BuildContext {
  double get maglissSystemBottom => MediaQuery.viewPaddingOf(this).bottom;

  double get maglissSystemTop => MediaQuery.viewPaddingOf(this).top;

  /// Bottom nav bar inner padding (system gesture inset + breathing room).
  EdgeInsets maglissBottomNavPadding({
    double horizontal = 8,
    double vertical = 8,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      vertical,
      horizontal,
      vertical + maglissSystemBottom,
    );
  }

  /// Scroll/list padding inside shell tabs (above bottom navigation).
  EdgeInsets maglissShellScrollPadding({
    double horizontal = 24,
    double top = 24,
    double bottom = 24,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      bottom + kShellScrollBottomGap,
    );
  }

  /// Toast overlay offset — above bottom nav on phone, above system inset on tablet.
  double maglissToastBottomOffset() {
    final showsBottomNav =
        MediaQuery.sizeOf(this).width < kShellSidebarBreakpoint;
    if (!showsBottomNav) {
      return maglissSystemBottom + 24;
    }
    return maglissSystemBottom + kShellBottomNavBarHeight + 16;
  }
}
