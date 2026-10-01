import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/errors/app_exception.dart';
import 'package:soutnaqi/core/errors/app_exception_l10n.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/core/toast/app_toast.dart';
import 'package:soutnaqi/features/history/cubit/history_cubit.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/video_processing/data/video_to_audio_options.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_cubit.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_state.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class _VideoToAudioRequest {
  const _VideoToAudioRequest({
    required this.options,
    required this.destination,
  });

  final VideoToAudioOptions options;
  final VideoToAudioDestination destination;
}

Future<void> showVideoToAudioSheet(
  BuildContext context, {
  VoidCallback? onCompleted,
}) async {
  final settingsCubit = context.read<SettingsCubit>();
  final workspaceCubit = context.read<WorkspaceCubit>();
  final historyCubit = context.read<HistoryCubit>();

  final request = await showModalBottomSheet<_VideoToAudioRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surfacePrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settingsCubit),
          BlocProvider.value(value: workspaceCubit),
          BlocProvider.value(value: historyCubit),
        ],
        child: const VideoToAudioSheet(),
      );
    },
  );

  if (request == null || !context.mounted) return;

  final l10n = AppLocalizations.of(context);

  AppToast.showLoading(
    context,
    settingsCubit: settingsCubit,
    message: l10n.extractAudioLoading,
  );

  try {
    await workspaceCubit.convertVideoToAudio(
      request.options,
      destination: request.destination,
    );

    if (!context.mounted) {
      AppToast.dismiss();
      return;
    }

    final successMsg = request.destination == VideoToAudioDestination.saveToDevice
        ? l10n.saveSuccess
        : request.destination == VideoToAudioDestination.share
            ? l10n.shareSuccess
            : l10n.extractAudioSuccess;

    AppToast.showSuccess(
      context,
      settingsCubit: settingsCubit,
      message: successMsg,
    );

    onCompleted?.call();
  } on AppException catch (error) {
    if (!context.mounted) {
      AppToast.dismiss();
      return;
    }
    AppToast.showFailure(
      context,
      settingsCubit: settingsCubit,
      message: appExceptionMessage(error, l10n),
    );
  } catch (_) {
    if (!context.mounted) {
      AppToast.dismiss();
      return;
    }
    AppToast.showFailure(
      context,
      settingsCubit: settingsCubit,
      message: l10n.processingFailed,
    );
  }
}

class VideoToAudioSheet extends StatefulWidget {
  const VideoToAudioSheet({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  State<VideoToAudioSheet> createState() => _VideoToAudioSheetState();
}

class _VideoToAudioSheetState extends State<VideoToAudioSheet> {
  AudioOutputFormat _selectedFormat = AudioOutputFormat.m4a;
  AudioOutputBitrate _selectedBitrate = AudioOutputBitrate.b192;
  AudioChannels _selectedChannels = AudioChannels.stereo;
  bool _normalizeVolume = false;
  bool _reduceNoise = false;
  bool _trimOnly = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<WorkspaceCubit>().state;
    _trimOnly = (state.trimStart > Duration.zero) ||
        (state.trimEnd > Duration.zero && state.trimEnd < state.duration);
  }

  void _submit(VideoToAudioDestination destination) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final workspaceState = context.read<WorkspaceCubit>().state;
    final options = VideoToAudioOptions(
      format: _selectedFormat,
      bitrate: _selectedBitrate,
      channels: _selectedChannels,
      normalizeVolume: _normalizeVolume,
      reduceNoise: _reduceNoise,
      trimStart: _trimOnly ? workspaceState.trimStart : null,
      trimEnd: _trimOnly ? workspaceState.trimEnd : null,
    );

    Navigator.of(context).pop(
      _VideoToAudioRequest(
        options: options,
        destination: destination,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);
    final media = context.select<WorkspaceCubit, WorkspaceState>(
      (c) => c.state,
    ).media;
    final state = context.select<WorkspaceCubit, WorkspaceState>(
      (c) => c.state,
    );
    final hasTrim = (state.trimStart > Duration.zero) ||
        (state.trimEnd > Duration.zero && state.trimEnd < state.duration);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIconsStrokeRounded.musicNote02,
                      color: context.accentPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.convertVideoToAudio,
                          style: font18W600(
                            settingsCubit: settingsCubit,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.convertVideoToAudioHint,
                          style: font12W400(
                            settingsCubit: settingsCubit,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (media != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIconsStrokeRounded.computerVideo,
                        color: context.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          media.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: font14W500(
                            settingsCubit: settingsCubit,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        media.formattedSize,
                        style: font12W400(
                          settingsCubit: settingsCubit,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.audioFormat,
                        style: font14W600(
                          settingsCubit: settingsCubit,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AudioOutputFormat.values.map((format) {
                          final isSelected = _selectedFormat == format;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedFormat = format);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.accentPrimary.withValues(alpha: 0.12)
                                    : context.inputFill,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? context.accentPrimary
                                      : context.borderSubtle,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    format.label(l10n),
                                    style: font14W600(
                                      settingsCubit: settingsCubit,
                                      color: isSelected
                                          ? context.accentPrimary
                                          : context.textPrimary,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    HugeIcon(
                                      icon: HugeIconsStrokeRounded.tick02,
                                      color: context.accentPrimary,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedFormat.description(l10n),
                        style: font12W400(
                          settingsCubit: settingsCubit,
                          color: context.textSecondary,
                        ),
                      ),
                      if (_selectedFormat.supportsBitrate) ...[
                        const SizedBox(height: 18),
                        Text(
                          l10n.audioBitrate,
                          style: font14W600(
                            settingsCubit: settingsCubit,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AudioOutputBitrate.values.map((bitrate) {
                            final isSelected = _selectedBitrate == bitrate;
                            return ChoiceChip(
                              label: Text(
                                bitrate.label(l10n),
                                style: font12W500(
                                  settingsCubit: settingsCubit,
                                  color: isSelected
                                      ? context.accentPrimary
                                      : context.textPrimary,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor:
                                  context.accentPrimary.withValues(alpha: 0.14),
                              backgroundColor: context.inputFill,
                              side: BorderSide(
                                color: isSelected
                                    ? context.accentPrimary
                                    : context.borderSubtle,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _selectedBitrate = bitrate);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        l10n.audioChannels,
                        style: font14W600(
                          settingsCubit: settingsCubit,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: AudioChannels.values.map((ch) {
                          final isSelected = _selectedChannels == ch;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selectedChannels = ch);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? context.accentPrimary
                                            .withValues(alpha: 0.12)
                                        : context.inputFill,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? context.accentPrimary
                                          : context.borderSubtle,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    ch.label(l10n),
                                    style: font14W500(
                                      settingsCubit: settingsCubit,
                                      color: isSelected
                                          ? context.accentPrimary
                                          : context.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.soundEnhancements,
                        style: font14W600(
                          settingsCubit: settingsCubit,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _EnhancementSwitchTile(
                        settingsCubit: settingsCubit,
                        title: l10n.normalizeVolume,
                        subtitle: l10n.normalizeVolumeDesc,
                        icon: HugeIconsStrokeRounded.volumeHigh,
                        value: _normalizeVolume,
                        onChanged: (val) => setState(() => _normalizeVolume = val),
                      ),
                      const SizedBox(height: 8),
                      _EnhancementSwitchTile(
                        settingsCubit: settingsCubit,
                        title: l10n.reduceNoise,
                        subtitle: l10n.reduceNoiseDesc,
                        icon: HugeIconsStrokeRounded.audioWave01,
                        value: _reduceNoise,
                        onChanged: (val) => setState(() => _reduceNoise = val),
                      ),
                      if (hasTrim) ...[
                        const SizedBox(height: 8),
                        _EnhancementSwitchTile(
                          settingsCubit: settingsCubit,
                          title: l10n.convertTrimOnly,
                          subtitle: l10n.convertVideoToAudioHint,
                          icon: HugeIconsStrokeRounded.scissor,
                          value: _trimOnly,
                          onChanged: (val) => setState(() => _trimOnly = val),
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.accentPrimary,
                        foregroundColor: context.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: HugeIcon(
                        icon: HugeIconsStrokeRounded.musicNote02,
                        color: context.onAccent,
                        size: 20,
                      ),
                      label: Text(
                        l10n.convertAndOpen,
                        style: font14W600(
                          settingsCubit: settingsCubit,
                          color: context.onAccent,
                        ),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _submit(VideoToAudioDestination.workspace),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: context.borderSubtle),
                      ),
                      icon: HugeIcon(
                        icon: HugeIconsStrokeRounded.download04,
                        color: context.textPrimary,
                        size: 18,
                      ),
                      label: Text(
                        l10n.convertAndSave,
                        style: font14W500(
                          settingsCubit: settingsCubit,
                          color: context.textPrimary,
                        ),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _submit(VideoToAudioDestination.saveToDevice),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: context.borderSubtle),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _submit(VideoToAudioDestination.share),
                    child: HugeIcon(
                      icon: HugeIconsStrokeRounded.share01,
                      color: context.textPrimary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancementSwitchTile extends StatelessWidget {
  const _EnhancementSwitchTile({
    required this.settingsCubit,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final SettingsCubit settingsCubit;
  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.inputFill,
      borderRadius: BorderRadius.circular(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: value ? context.accentPrimary : context.borderSubtle,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        activeThumbColor: context.accentPrimary,
        secondary: HugeIcon(
          icon: icon,
          color: value ? context.accentPrimary : context.textSecondary,
          size: 20,
        ),
        title: Text(
          title,
          style: font14W500(
            settingsCubit: settingsCubit,
            color: context.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: font12W400(
            settingsCubit: settingsCubit,
            color: context.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
