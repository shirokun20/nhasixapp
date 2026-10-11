import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/constants/text_style_const.dart';
import '../../core/di/service_locator.dart';
import '../../core/routing/app_router.dart';
import '../../core/services/streak_widget_sync_service.dart';
import '../../domain/entities/reading_statistics.dart';
import '../cubits/streak/streak_cubit.dart';
import 'kuro_mascot.dart';

// Home-tab streak card. Answers one question — "am I still in a streak?" —
// and offers the single next action: resume what was last read.
//
// Privacy: streak count, the Sn–Mn checklist and the mascot only. No title,
// cover, tag or source name ever reaches this surface.
class StreakCard extends StatefulWidget {
  const StreakCard({super.key, this.cubit, this.onContinueReading});

  // Injected by tests; production resolves it from getIt and owns its life.
  final StreakCubit? cubit;

  // Overridable so the CTA is testable without a GoRouter.
  final Future<void> Function(BuildContext context, String contentId)?
      onContinueReading;

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> with WidgetsBindingObserver {
  static const double _mascotSize = 72;
  static const double _dayDotSize = 28;
  static const double _checkIconSize = 16;
  static const List<String> _dayLabels = [
    'Sn',
    'Sl',
    'Rb',
    'Km',
    'Jm',
    'Sb',
    'Mn',
  ];

  late final StreakCubit _cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final injected = widget.cubit;
    if (injected != null) {
      _cubit = injected;
    } else {
      _cubit = getIt<StreakCubit>()..loadStreak();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // An injected cubit belongs to the caller — closing it here would end its
    // life mid-test.
    if (widget.cubit == null) _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Recomputes streak + mood, so a phone whose date moved while the app
        // was closed shows the right face on return instead of yesterday's.
        _cubit.refresh();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Last chance to push to the launcher widget before the app may die.
        unawaited(_syncWidget());
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _syncWidget() {
    final state = _cubit.state;
    return StreakWidgetSyncService.syncWidget(
      ReadingStatistics.streak(
        readingStreak: state.readingStreak,
        lastReadDate: state.lastReadDate,
        readDays: state.readDays,
        totalContentRead: state.totalContentRead,
      ),
      now: state.referenceDate,
    );
  }

  Future<void> _continueReading(String contentId) async {
    final navigate = widget.onContinueReading ?? _goToReader;
    await navigate(context, contentId);
    if (mounted) await _cubit.refresh();
  }

  static Future<void> _goToReader(BuildContext context, String contentId) =>
      AppRouter.goToReader(context, contentId);

  static String _moodCopy(KuroMood mood) => switch (mood) {
        KuroMood.happy => 'Kuro senang hari ini.',
        KuroMood.reader => 'Kuro tenggelam di bacaan. Lanjut!',
        KuroMood.ghost => 'Kuro menghantui daftar bacaanmu.',
        KuroMood.cry => 'Kuro nangis. Kamu gak buka bacaan.',
        KuroMood.tsundere => 'Kuro cemburu. Sudah lama gak dibaca.',
        KuroMood.frozenCry => 'Kuro membeku kesepian. Yuk lanjut baca!',
        KuroMood.waiting => 'Kuro nunggu kamu buka bacaan.',
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final kuronColors = Theme.of(context).extension<KuronColors>();

    return BlocBuilder<StreakCubit, StreakState>(
      bloc: _cubit,
      builder: (context, state) {
        final checklist = state.weeklyChecklist;
        final canContinue = state.lastContentId?.isNotEmpty ?? false;
        return Container(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            border: Border.all(
              color: kuronColors?.cardBorder ?? colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.readingStreak}',
                          style: TextStyleConst.headingLarge
                              .copyWith(color: colorScheme.primary),
                        ),
                        Text(
                          'Hari Streak',
                          style: TextStyleConst.label
                              .copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: DesignTokens.spaceXs),
                        Text(
                          _moodCopy(state.mood),
                          style: TextStyleConst.bodySmall
                              .copyWith(color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                  KuroMascot(
                    key: ValueKey(state.mood),
                    mood: state.mood,
                    size: _mascotSize,
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              Row(
                children: [
                  for (var i = 0; i < _dayLabels.length; i++)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _dayLabels[i],
                            style: TextStyleConst.label
                                .copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: DesignTokens.spaceXs),
                          _DayDot(read: checklist[i]),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canContinue
                      ? () => _continueReading(state.lastContentId!)
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    'Lanjutkan Baca',
                    style: TextStyleConst.buttonMedium
                        .copyWith(color: colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.read});

  final bool read;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: _StreakCardState._dayDotSize,
      height: _StreakCardState._dayDotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: read ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      ),
      child: read
          ? Icon(
              Icons.check_rounded,
              size: _StreakCardState._checkIconSize,
              color: colorScheme.onPrimary,
            )
          : null,
    );
  }
}
