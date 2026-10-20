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
import 'package:soutnaqi/features/workspace/ui/widgets/speed_picker_sheet.dart';
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
  int _playerGeneration = 0;

  bool get _isProcessing =>
      widget.state.status == WorkspaceStatus.processing;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant WorkspaceVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasProcessing =
        oldWidget.state.status == WorkspaceStatus.processing;
    final sourceChanged = oldWidget.state.playbackSource !=
            widget.state.playbackSource ||
        oldWidget.state.processedPath != widget.state.processedPath;

    if (_isProcessing && !wasProcessing) {
      _releaseDecoder();
      return;
    }
    if (wasProcessing && !_isProcessing) {
      _initializePlayer();
      return;
    }
    if (sourceChanged && !_isProcessing) {
      final savedPos = _controller?.value.position;
      final wasPlaying = _controller?.value.isPlaying ?? false;
      _initializePlayer(seekToPosition: savedPos, autoPlay: wasPlaying);
    }
  }

  /// Hardware decode (MediaTek AVC + audio) stays alive while the preview
  /// plays and fights ONNX for CPU and buffers until the process is killed.
  Future<void> _releaseDecoder() async {
    final generation = ++_playerGeneration;
    final controller = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await controller?.pause();
    if (generation != _playerGeneration) return;
    await controller?.dispose();
  }

  Future<void> _initializePlayer({
    Duration? seekToPosition,
    bool autoPlay = false,
  }) async {
    if (_isProcessing) return;

    final generation = ++_playerGeneration;
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

    if (!mounted || generation != _playerGeneration) return;

    if (uri == null) {
      setState(() => _hasError = true);
      return;
    }

    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    if (!mounted || generation != _playerGeneration) return;

    _resolver!.disposeBlob(_activeUri);
    _activeUri = uri;

    final controller = createVideoPlayerController(uri);

    setState(() {
      _controller = controller;
      _hasError = false;
    });

    try {
      await controller.initialize();
      if (!mounted || generation != _playerGeneration) {
        await controller.dispose();
        return;
      }
      if (seekToPosition != null && seekToPosition > Duration.zero) {
        await controller.seekTo(seekToPosition);
      }
      if (autoPlay) {
        await controller.play();
      }
      setState(() {});
    } catch (_) {
      if (!mounted || generation != _playerGeneration) return;
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

class _VideoControls extends StatefulWidget {
  const _VideoControls({
    required this.settingsCubit,
    required this.controller,
  });

  final SettingsCubit settingsCubit;
  final VideoPlayerController controller;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  double? _dragFraction;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final position = value.position;
        final duration = value.duration;
        final maxMs = duration.inMilliseconds;
        final progress = maxMs > 0 ? position.inMilliseconds / maxMs : 0.0;
        final isCompleted = maxMs > 0 && position >= duration;
        final sliderValue = (_dragFraction ?? progress).clamp(0.0, 1.0);

        final currentDuration = _dragFraction != null
            ? Duration(milliseconds: (_dragFraction! * maxMs).round())
            : position;

        return Column(
          children: [
            Row(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () {
                            final target = position - const Duration(seconds: 10);
                            widget.controller.seekTo(
                              target < Duration.zero ? Duration.zero : target,
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIconsStrokeRounded.backward01,
                                color: context.textPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: context.accentPrimary,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          onTap: () async {
                            if (value.isPlaying) {
                              await widget.controller.pause();
                            } else {
                              if (isCompleted || position >= duration) {
                                await widget.controller.seekTo(Duration.zero);
                              }
                              await widget.controller.play();
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
                                    : (isCompleted
                                        ? HugeIconsStrokeRounded.replay
                                        : HugeIconsStrokeRounded.play),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () {
                            final target = position + const Duration(seconds: 10);
                            widget.controller.seekTo(
                              duration > Duration.zero && target > duration
                                  ? duration
                                  : target,
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIconsStrokeRounded.forward01,
                                color: context.textPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${_format(currentDuration)} / ${_format(duration)}',
                      overflow: TextOverflow.ellipsis,
                      style: font12W400(
                        settingsCubit: widget.settingsCubit,
                        color: context.textMuted,
                      ),
                    ),
                  ),
                ),
                Material(
                  color: context.inputFill,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () async {
                      final selected = await showSpeedPickerSheet(
                        context,
                        settingsCubit: widget.settingsCubit,
                        currentSpeed: value.playbackSpeed,
                      );
                      if (selected != null) {
                        await widget.controller.setPlaybackSpeed(selected);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIconsStrokeRounded.dashboardSquare01,
                            color: context.accentPrimary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${value.playbackSpeed}x',
                            style: font12W600(
                              settingsCubit: widget.settingsCubit,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Slider(
                value: sliderValue,
                onChangeStart: maxMs > 0
                    ? (next) => setState(() => _dragFraction = next)
                    : null,
                onChanged: maxMs > 0
                    ? (next) => setState(() => _dragFraction = next)
                    : null,
                onChangeEnd: maxMs > 0
                    ? (next) async {
                        final target =
                            Duration(milliseconds: (next * maxMs).round());
                        await widget.controller.seekTo(target);
                        setState(() => _dragFraction = null);
                      }
                    : null,
                activeColor: context.accentPrimary,
                inactiveColor: context.borderSubtle,
              ),
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
