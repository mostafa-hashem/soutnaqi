import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';

class WorkspaceWaveform extends StatelessWidget {
  const WorkspaceWaveform({
    super.key,
    required this.state,
    required this.onSeekFraction,
  });

  final WorkspaceState state;
  final ValueChanged<double> onSeekFraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Skeletonizer(
        enabled: state.isWaveformLoading,
        child: CustomPaint(
          painter: _WaveformPainter(
            peaks: state.isWaveformLoading
                ? List<double>.filled(80, 0.4)
                : state.waveformPeaks,
            progress: state.duration.inMilliseconds > 0
                ? state.position.inMilliseconds /
                    state.duration.inMilliseconds
                : 0,
            trimStart: state.duration.inMilliseconds > 0
                ? state.trimStart.inMilliseconds /
                    state.duration.inMilliseconds
                : 0,
            trimEnd: state.duration.inMilliseconds > 0
                ? state.effectiveTrimEnd.inMilliseconds /
                    state.duration.inMilliseconds
                : 1,
            waveColor: context.accentPrimary,
            mutedColor: context.borderSubtle,
            playheadColor: context.accentSecondary,
            trimOverlay: context.accentPrimary.withValues(alpha: 0.12),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final fraction = details.localPosition.dx / box.size.width;
              onSeekFraction(fraction);
            },
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.peaks,
    required this.progress,
    required this.trimStart,
    required this.trimEnd,
    required this.waveColor,
    required this.mutedColor,
    required this.playheadColor,
    required this.trimOverlay,
  });

  final List<double> peaks;
  final double progress;
  final double trimStart;
  final double trimEnd;
  final Color waveColor;
  final Color mutedColor;
  final Color playheadColor;
  final Color trimOverlay;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final barWidth = size.width / peaks.length;
    final centerY = size.height / 2;
    final trimLeft = size.width * trimStart.clamp(0, 1);
    final trimRight = size.width * trimEnd.clamp(0, 1);

    canvas.drawRect(
      Rect.fromLTRB(trimLeft, 0, trimRight, size.height),
      Paint()..color = trimOverlay,
    );

    for (var index = 0; index < peaks.length; index++) {
      final fraction = index / peaks.length;
      final barHeight = peaks[index].clamp(0.08, 1.0) * (size.height * 0.8);
      final x = index * barWidth + barWidth / 2;
      final isPlayed = fraction <= progress;
      final inTrim = fraction >= trimStart && fraction <= trimEnd;

      final paint = Paint()
        ..color = isPlayed
            ? waveColor
            : (inTrim ? waveColor.withValues(alpha: 0.45) : mutedColor)
        ..strokeWidth = barWidth * 0.55
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }

    final playheadX = size.width * progress.clamp(0, 1);
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      Paint()
        ..color = playheadColor
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks ||
        oldDelegate.progress != progress ||
        oldDelegate.trimStart != trimStart ||
        oldDelegate.trimEnd != trimEnd;
  }
}
