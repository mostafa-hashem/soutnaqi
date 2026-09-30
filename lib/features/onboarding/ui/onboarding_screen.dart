import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:soutnaqi/core/theme/app_radii.dart';
import 'package:soutnaqi/core/theme/magliss_context_colors.dart';
import 'package:soutnaqi/core/theme/magliss_typography.dart';
import 'package:soutnaqi/features/onboarding/ui/widgets/onboarding_feature_slide.dart';
import 'package:soutnaqi/features/onboarding/ui/widgets/onboarding_page_indicator.dart';
import 'package:soutnaqi/features/onboarding/ui/widgets/onboarding_welcome_slide.dart';
import 'package:soutnaqi/features/settings/cubit/settings_cubit.dart';
import 'package:soutnaqi/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalSlides = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _totalSlides - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _complete() {
    context.read<SettingsCubit>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.watch<SettingsCubit>();
    final l10n = AppLocalizations.of(context);
    final isLastPage = _currentPage == _totalSlides - 1;

    return Scaffold(
      backgroundColor: context.webBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top action bar (Skip button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLastPage)
                    TextButton(
                      onPressed: _complete,
                      child: Text(
                        l10n.onboardingSkip,
                        style: font14W600(
                          settingsCubit: settingsCubit,
                          color: context.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),

            // PageView with Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Slide 0: Welcome + Language + Theme Selection
                  OnboardingWelcomeSlide(settingsCubit: settingsCubit),

                  // Slide 1: Separation Features
                  OnboardingFeatureSlide(
                    settingsCubit: settingsCubit,
                    icon: HugeIconsStrokeRounded.audioWave01,
                    badgeText: l10n.onboardingFeature1Subtitle,
                    title: l10n.onboardingFeature1Title,
                    description: l10n.onboardingFeature1Desc,
                    highlights: [
                      OnboardingFeatureItem(
                        icon: HugeIconsStrokeRounded.aiVoice,
                        title: l10n.operationIsolateVocals,
                        description: l10n.aboutFeatureDedicatedDesc,
                      ),
                      OnboardingFeatureItem(
                        icon: HugeIconsStrokeRounded.musicNote02,
                        title: l10n.operationIsolateMusic,
                        description: l10n.aboutFeatureDedicatedTitle,
                      ),
                    ],
                  ),

                  // Slide 2: On-Device AI Engine & Privacy
                  OnboardingFeatureSlide(
                    settingsCubit: settingsCubit,
                    icon: HugeIconsStrokeRounded.cpu,
                    badgeText: l10n.onboardingFeature2Subtitle,
                    title: l10n.onboardingFeature2Title,
                    description: l10n.onboardingFeature2Desc,
                    highlights: [
                      OnboardingFeatureItem(
                        icon: HugeIconsStrokeRounded.securityCheck,
                        title: l10n.aboutFeaturePrivacyTitle,
                        description: l10n.aboutFeaturePrivacyDesc,
                      ),
                      OnboardingFeatureItem(
                        icon: HugeIconsStrokeRounded.computerVideo,
                        title: l10n.aboutFeatureMediaTitle,
                        description: l10n.aboutFeatureMediaDesc,
                      ),
                    ],
                  ),

                  // Slide 3: Model Setup Overview
                  OnboardingFeatureSlide(
                    settingsCubit: settingsCubit,
                    icon: HugeIconsStrokeRounded.cloudDownload,
                    badgeText: l10n.onboardingFeature3Subtitle,
                    title: l10n.onboardingFeature3Title,
                    description: l10n.onboardingFeature3Desc,
                    highlights: [
                      OnboardingFeatureItem(
                        icon: HugeIconsStrokeRounded.settings01,
                        title: l10n.navSettings,
                        description: l10n.guideSettingsStepDesc,
                      ),
                      OnboardingFeatureItem(
                        icon: HugeIconsStrokeRounded.checkmarkCircle02,
                        title: l10n.separationSection,
                        description: l10n.guideModelStepDesc,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Navigation Strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OnboardingPageIndicator(
                    itemCount: _totalSlides,
                    currentIndex: _currentPage,
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: context.accentPrimary,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: InkWell(
                      onTap: _onNext,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastPage
                                  ? l10n.onboardingGetStarted
                                  : (_currentPage == 0
                                      ? l10n.onboardingContinue
                                      : l10n.onboardingNext),
                              style: font16W600(
                                settingsCubit: settingsCubit,
                                color: context.onAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            HugeIcon(
                              icon: isLastPage
                                  ? HugeIconsStrokeRounded.checkmarkSquare02
                                  : (Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? HugeIconsStrokeRounded.arrowLeft01
                                      : HugeIconsStrokeRounded.arrowRight01),
                              color: context.onAccent,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
