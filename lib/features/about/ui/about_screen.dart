import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/about/ui/widgets/about_disclaimer_card.dart';
import 'package:soutnaqi/features/about/ui/widgets/about_features_card.dart';
import 'package:soutnaqi/features/about/ui/widgets/about_footer.dart';
import 'package:soutnaqi/features/about/ui/widgets/about_header.dart';
import 'package:soutnaqi/features/about/ui/widgets/about_tips_card.dart';
import 'package:soutnaqi/features/about/ui/widgets/about_vision_card.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: context.webBackground,
      appBar: AppBar(
        backgroundColor: context.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: isRtl
                ? HugeIconsStrokeRounded.arrowRight01
                : HugeIconsStrokeRounded.arrowLeft01,
            color: context.textPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.aboutSoutNaqiTitle,
          style: font18W600(
            settingsCubit: settingsCubit,
            color: context.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                AboutHeader(settingsCubit: settingsCubit),
                const SizedBox(height: 24),
                AboutVisionCard(settingsCubit: settingsCubit),
                const SizedBox(height: 16),
                AboutDisclaimerCard(settingsCubit: settingsCubit),
                const SizedBox(height: 16),
                AboutFeaturesCard(settingsCubit: settingsCubit),
                const SizedBox(height: 16),
                AboutTipsCard(settingsCubit: settingsCubit),
                const SizedBox(height: 20),
                AboutFooter(settingsCubit: settingsCubit),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
