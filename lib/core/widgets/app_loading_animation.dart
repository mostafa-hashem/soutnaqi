import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:soutnaqi/core/theme/magliss_context_colors.dart';

class AppLoadingAnimation extends StatelessWidget {
  const AppLoadingAnimation({
    super.key,
    this.size = 40,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.staggeredDotsWave(
      color: color ?? context.accentPrimary,
      size: size,
    );
  }
}
