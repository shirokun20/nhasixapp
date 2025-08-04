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

class _SplashMainWidgetState extends State<SplashMainWidget> {
  @override
  void initState() {
    super.initState();
    // Start the splash process after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashBloc>().add(SplashStartedEvent());
    });
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
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSnackBar(
                scaffoldMessenger: scaffoldMessenger,
                message: state.message,
                isError: false,
                onFinish: _navigateToMainScreen,
              );
            });
          } else if (state is SplashError) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final splashBloc = context.read<SplashBloc>();
            final localMessage = state.message;
            final canRetry = state.canRetry;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 100)).then((_) {
                if (!mounted) return;

                _showSnackBar(
                  scaffoldMessenger: scaffoldMessenger,
                  message: localMessage,
                  isError: true,
                  showRetry: canRetry,
                  onRetry: () => splashBloc.add(SplashRetryBypassEvent()),
                );
              });
            });
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

                // Status Text and Loading Indicator
                if (state is SplashInitializing ||
                    state is SplashBypassInProgress)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorsConst.accentBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state is SplashInitializing
                            ? 'Initializing...'
                            : (state as SplashBypassInProgress).message,
                        style: TextStyleConst.loadingText.copyWith(
                          fontSize: 16,
                          color: ColorsConst.darkTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

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

  Future<void> _navigateToMainScreen() async {
    // Add a small delay to show success message
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      context.go(AppRoute.main);
    }
  }

  void _showSnackBar({
    required ScaffoldMessengerState scaffoldMessenger,
    required String message,
    bool isError = false,
    bool showRetry = false,
    VoidCallback? onFinish,
    VoidCallback? onRetry,
  }) {
    final scaffold = scaffoldMessenger;
    scaffold.hideCurrentSnackBar();
    scaffold
        .showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                isError ? ColorsConst.accentRed : ColorsConst.accentGreen,
            content: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showRetry && onRetry != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      scaffold.hideCurrentSnackBar();
                      onRetry();
                    },
                    child: Text(
                      'RETRY',
                      style: TextStyleConst.buttonSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            duration: Duration(seconds: isError ? 5 : 2),
            action: !showRetry && isError
                ? SnackBarAction(
                    label: 'DISMISS',
                    textColor: Colors.white,
                    onPressed: () => scaffold.hideCurrentSnackBar(),
                  )
                : null,
          ),
        )
        .closed
        .then((reason) {
      onFinish?.call();
    });
  }
}
