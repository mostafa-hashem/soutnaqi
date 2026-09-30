import 'package:flutter/material.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
  });

  final int itemCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (index) {
        final isSelected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isSelected ? 24 : 8,
          decoration: BoxDecoration(
            color: isSelected
                ? context.accentPrimary
                : context.textMuted.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
