import 'package:flutter/material.dart';

import 'package:soutnaqi/core/theme/soutnaqi_brand.dart';

class SoutNaqiLogo extends StatelessWidget {
  const SoutNaqiLogo({
    super.key,
    this.size = 48,
    this.wordmark,
    this.subtitle,
    this.wordmarkStyle,
    this.subtitleStyle,
    this.spacing = 12,
  });

  final double size;
  final String? wordmark;
  final String? subtitle;
  final TextStyle? wordmarkStyle;
  final TextStyle? subtitleStyle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          SoutNaqiBrand.markAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );

    if (wordmark == null && subtitle == null) {
      return mark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: spacing),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wordmark != null)
                Text(
                  wordmark!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: wordmarkStyle,
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
