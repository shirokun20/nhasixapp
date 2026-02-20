import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/presentation/widgets/adguard_warning_dialog.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SplashBloc>(),
      child: const SplashMainWidget(),
    );
  }
}

class SplashMainWidget extends StatefulWidget {
  const SplashMainWidget({super.key});

  @override
  State<SplashMainWidget> createState() => _SplashMainWidgetState();
}

class _SplashMainWidgetState extends State<SplashMainWidget>
    with TickerProviderStateMixin {
  late AnimationController _dotsAnimationController;
  late List<Animation<double>> _dotAnimations;
  late AnimationController _successAnimationController;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize dots animation controller
    _dotsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create staggered animations for each dot
    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotsAnimationController,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    // Start dots animation
    _dotsAnimationController.repeat(reverse: true);

    // Initialize success animation controller
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Optimized from 800ms
      vsync: this,
    );

    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _successOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Start the splash process after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashBloc>().add(SplashStartedEvent());
    });
  }

  @override
  void dispose() {
    _dotsAnimationController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocConsumer<SplashBloc, SplashState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (!context.mounted) return;

          if (state is SplashSuccess) {
            // Stop dots animation and start success animation
            _dotsAnimationController.stop();
            _successAnimationController.forward().then((_) async {
              if (!context.mounted) return;

              await AdGuardWarningDialog.showNonBypassable(context);

              if (mounted) {
                // Navigate after success animation completes
                Timer(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    context.go(AppRoute.main);
                  }
                });
              }
            });
          } else if (state is SplashError) {
            // Stop dots animation on error
            _dotsAnimationController.stop();
          }
        },
        builder: (context, state) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo with enhanced styling
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                        .withValues(alpha: 0.3),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Image(
                    height: 200,
                    width: 200,
                    image: AssetImage('assets/icons/komiktap.png'),
                  ),
                ),

                const SizedBox(height: 40),

                // App title
                Text(
                  AppLocalizations.of(context)?.appTitle ?? 'KomikTap',
                  style: TextStyleConst.headingLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)?.appSubtitle ??
                      'Enhanced Reading Experience',
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 40),

                // Loading States with enhanced progress indicators
                if (state is SplashInitializing ||
                    state is SplashBypassInProgress)
                  Column(
                    children: [
                      // Enhanced loading indicator with progress
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: state is SplashInitializing
                                  ? 0.3
                                  : 0.7, // Show progress
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              strokeWidth: 4,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              state is SplashInitializing
                                  ? Icons.settings
                                  : Icons.security,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Loading status text with better styling
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          state is SplashInitializing
                              ? AppLocalizations.of(context)?.initializingApp ??
                                  'Initializing Application...'
                              : (state as SplashBypassInProgress).message,
                          style: TextStyleConst.headingSmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Detailed progress text
                      Text(
                        state is SplashInitializing
                            ? AppLocalizations.of(context)
                                    ?.settingUpComponents ??
                                'Setting up components and checking connection...'
                            : AppLocalizations.of(context)
                                    ?.bypassingProtection ??
                                'Bypassing protection and establishing connection...',
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (state is SplashInitializing) ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: state.progress,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  color: Theme.of(context).colorScheme.primary,
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(state.progress * 100).toInt()}%',
                                style: TextStyleConst.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Enhanced progress dots animation
                      const SizedBox(height: 20),
                      _buildProgressDots(),
                    ],
                  ),

                // Success State
                if (state is SplashSuccess) _buildSuccessState(state),

                // Error State with Retry Button
                if (state is SplashError && state.canRetry)
                  Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          AppLocalizations.of(context)?.connectionFailed ??
                              'Connection Failed',
                          style: TextStyleConst.statusError.copyWith(
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context
                            .read<SplashBloc>()
                            .add(SplashRetryBypassEvent()),
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: TextStyleConst.buttonMedium,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessState(SplashSuccess state) {
    return AnimatedBuilder(
      animation: _successAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _successOpacityAnimation.value,
          child: Transform.scale(
            scale: _successScaleAnimation.value,
            child: Column(
              children: [
                // Success icon with animated background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 24),

                // Success title
                Text(
                  AppLocalizations.of(context)?.readyToGo ?? 'Ready to Go!',
                  style: TextStyleConst.headingMedium.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Success message
                Text(
                  state.message,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Additional success info
                Text(
                  AppLocalizations.of(context)?.launchingApp ??
                      'Launching main application...',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Success indicator dots
                _buildSuccessDots(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildProgressDots() {
    return AnimatedBuilder(
      animation: _dotsAnimationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: _dotAnimations[index].value,
                    ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
