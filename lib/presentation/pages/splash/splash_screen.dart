import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';

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
      duration: const Duration(milliseconds: 800),
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
      backgroundColor: ColorsConst.darkBackground,
      body: BlocConsumer<SplashBloc, SplashState>(
        listenWhen: (previous, current) => previous != current,
        listener: (_, state) {
          if (!mounted) return;

          if (state is SplashSuccess) {
            // Stop dots animation and start success animation
            _dotsAnimationController.stop();
            _successAnimationController.forward().then((_) async {
              // Navigate after success animation completes
              await Future.delayed(const Duration(milliseconds: 1200));
              if (mounted) {
                context.go(AppRoute.main);
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
                // App Logo
                const Image(
                  height: 250,
                  width: 250,
                  image: AssetImage('assets/icons/ic_launcher-web.png'),
                ),

                const SizedBox(height: 40),

                // Loading States
                if (state is SplashInitializing ||
                    state is SplashBypassInProgress)
                  Column(
                    children: [
                      // Animated loading indicator
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            ColorsConst.accentBlue,
                          ),
                          strokeWidth: 3,
                          backgroundColor: ColorsConst.darkCard,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Loading status text
                      Text(
                        state is SplashInitializing
                            ? 'Initializing Application...'
                            : (state as SplashBypassInProgress).message,
                        style: TextStyleConst.headingSmall.copyWith(
                          color: ColorsConst.darkTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Detailed progress text
                      Text(
                        state is SplashInitializing
                            ? 'Setting up components and checking connection...'
                            : 'Bypassing protection and establishing connection...',
                        style: TextStyleConst.bodySmall.copyWith(
                          color: ColorsConst.darkTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Progress dots animation
                      const SizedBox(height: 16),
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
                        color: ColorsConst.accentRed,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Connection Failed',
                          style: TextStyleConst.statusError.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsConst.accentBlue,
                          foregroundColor: ColorsConst.darkBackground,
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
                    color: ColorsConst.accentGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorsConst.accentGreen.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: ColorsConst.accentGreen,
                  ),
                ),
                const SizedBox(height: 24),

                // Success title
                Text(
                  'Ready to Go!',
                  style: TextStyleConst.headingMedium.copyWith(
                    color: ColorsConst.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Success message
                Text(
                  state.message,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: ColorsConst.darkTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Additional success info
                Text(
                  'Launching main application...',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.darkTextSecondary,
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
          decoration: const BoxDecoration(
            color: ColorsConst.accentGreen,
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
                color: ColorsConst.accentBlue.withValues(
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
