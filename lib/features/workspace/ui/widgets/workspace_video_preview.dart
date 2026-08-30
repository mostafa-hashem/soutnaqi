import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/media/data/models/media_file.dart';
import 'package:soutnaqi/features/media/data/video_player_platform.dart';
import 'package:soutnaqi/features/media/data/video_source_platform.dart';
import 'package:soutnaqi/features/media/data/video_source_resolver.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

class WorkspaceVideoPreview extends StatefulWidget {
  const WorkspaceVideoPreview({
    super.key,
    required this.settingsCubit,
    required this.media,
    required this.state,
  });

  final SettingsCubit settingsCubit;
  final MediaFile media;
  final WorkspaceState state;

  @override
  State<WorkspaceVideoPreview> createState() => _WorkspaceVideoPreviewState();
}

class _WorkspaceVideoPreviewState extends State<WorkspaceVideoPreview> {
  VideoPlayerController? _controller;
  VideoSourceResolver? _resolver;
  String? _activeUri;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant WorkspaceVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sourceChanged = oldWidget.state.playbackSource !=
            widget.state.playbackSource ||
        oldWidget.state.processedPath != widget.state.processedPath;
    if (sourceChanged) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    _resolver ??= createVideoSourceResolver();
    final useProcessed = widget.state.playbackSource == PlaybackSource.processed &&
        widget.state.hasProcessedOutput;

    final uri = _resolver!.resolve(
      path: widget.media.path,
      bytes: widget.media.bytes,
      mimeType: widget.media.mimeType,
      processedPath: widget.state.processedPath,
      useProcessed: useProcessed,
    );

    if (uri == null) {
      setState(() => _hasError = true);
      return;
    }

    await _controller?.dispose();
    _resolver!.disposeBlob(_activeUri);
    _activeUri = uri;

    final controller = createVideoPlayerController(uri);

    setState(() {
      _controller = controller;
      _hasError = false;
    });

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _resolver?.disposeBlob(_activeUri);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;

    if (_hasError || controller == null || !controller.value.isInitialized) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            l10n.videoPreviewUnavailable,
            textAlign: TextAlign.center,
            style: font14W400(
              settingsCubit: widget.settingsCubit,
              color: context.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VideoPlayer(controller),
          ),
        ),
        const SizedBox(height: 12),
        _VideoControls(
          settingsCubit: widget.settingsCubit,
          controller: controller,
        ),
      ],
    );
  }
}

class _VideoControls extends StatelessWidget {
  const _VideoControls({
    required this.settingsCubit,
    required this.controller,
  });

  final SettingsCubit settingsCubit;
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final position = value.position;
        final duration = value.duration;
        final maxMs = duration.inMilliseconds;
        final progress = maxMs > 0 ? position.inMilliseconds / maxMs : 0.0;

        return Column(
          children: [
            Row(
              children: [
                Material(
                  color: context.accentPrimary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () {
                      if (value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: HugeIcon(
                          icon: value.isPlaying
                              ? HugeIconsStrokeRounded.pause
                              : HugeIconsStrokeRounded.play,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_format(position)} / ${_format(duration)}',
                  style: font12W400(
                    settingsCubit: settingsCubit,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
            Slider(
              value: progress.clamp(0, 1),
              onChanged: maxMs > 0
                  ? (next) => controller.seekTo(
                        Duration(milliseconds: (next * maxMs).round()),
                      )
                  : null,
              activeColor: context.accentPrimary,
              inactiveColor: context.borderSubtle,
            ),
          ],
        );
      },
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
