import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soutnaqi/core/constants/layout_constants.dart';
import 'package:soutnaqi/core/platform/app_platform.dart';
import 'package:soutnaqi/features/audio_processing/data/audio_processing_platform.dart';
import 'package:soutnaqi/features/export/data/local_export_platform.dart';
import 'package:soutnaqi/features/history/cubit/history_cubit.dart';
import 'package:soutnaqi/features/history/data/project_history_repository.dart';
import 'package:soutnaqi/features/media/data/media_picker_repository.dart';
import 'package:soutnaqi/features/separation/cubit/on_device_model_cubit.dart';
import 'package:soutnaqi/features/separation/data/separation_platform.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/features/shell/cubit/shell_cubit.dart';
import 'package:soutnaqi/features/shell/ui/app_shell.dart';
import 'package:soutnaqi/features/splash/ui/splash_screen.dart';
import 'package:soutnaqi/features/video_processing/data/video_processing_platform.dart';
import 'package:soutnaqi/features/waveform/data/waveform_platform.dart';
import 'package:soutnaqi/features/workspace/cubit/workspace_cubit.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _splashHoldComplete = false;
  late final ProjectHistoryRepository _historyRepository;

  @override
  void initState() {
    super.initState();
    _historyRepository = ProjectHistoryRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AppPlatform.warmUpAfterFirstFrame());
    });
    unawaited(_holdSplash());
  }

  Future<void> _holdSplash() async {
    await Future<void>.delayed(kSplashMinDuration);
    if (!mounted) return;
    setState(() => _splashHoldComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final settingsLoaded = context.select<SettingsCubit, bool>(
      (cubit) => cubit.state.isLoaded,
    );

    if (!settingsLoaded || !_splashHoldComplete) {
      return const SplashScreen();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ShellCubit()),
        BlocProvider(
          create: (_) => HistoryCubit(repository: _historyRepository),
        ),
        BlocProvider(create: (_) => OnDeviceModelCubit()),
        BlocProvider(
          create: (_) => WorkspaceCubit(
            mediaPickerRepository: MediaPickerRepository(),
            audioProcessingService: createAudioProcessingService(),
            videoProcessingService: createVideoProcessingService(),
            waveformService: createWaveformService(),
            projectHistoryRepository: _historyRepository,
            separationService: createSeparationService(),
            localExportService: createLocalExportService(),
          )..initialize(),
        ),
      ],
      child: const AppShell(),
    );
  }
}
