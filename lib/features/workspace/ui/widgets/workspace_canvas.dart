import 'package:flutter/material.dart';

import 'package:soutnaqi/core/theme/magliss_context_colors.dart';

class WorkspaceCanvas extends StatelessWidget {
  const WorkspaceCanvas({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.webBackground,
        border: Border.all(color: context.borderSubtle),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}
