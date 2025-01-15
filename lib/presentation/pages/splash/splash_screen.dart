import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/presentation/widgets/webview_bs_widget.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashMainWidget();
  }
}

class SplashMainWidget extends StatefulWidget {
  const SplashMainWidget({super.key});

  @override
  State<SplashMainWidget> createState() => _SplashMainWidgetState();
}

class _SplashMainWidgetState extends State<SplashMainWidget> {
  void _showWebViewBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: context.read<SplashBloc>(),
        child: const WebviewBsWidget(),
      ),
    );
  }

  @override
  void initState() {
    getIt<SplashBloc>().add(SplashStartedEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsConst.primaryColor,
      body: BlocListener<SplashBloc, SplashState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (state is SplashSuccess) {
            _snacBarCustom(
              message: 'Success Bypass Cloudflare',
              onFinish: _navigateToMainScreen,
            );
          } else if (state is SplashError) {
            _snacBarCustom(
              message: state.message,
              onFinish: () {
                // _showWebViewBottomSheet(context);
              },
            );
          } else if (state is SplashCloudflareInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showWebViewBottomSheet(context);
            });
          }
        },
        child: const Center(
          child: Image(
            height: 250,
            width: 250,
            image: AssetImage('assets/icons/ic_launcher-web.png'),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToMainScreen() async {
    context.go(AppRoute.main);
  }

  void _snacBarCustom({
    String message = '',
    VoidCallback? onFinish,
  }) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();
    scaffold
        .showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: ColorsConst.primaryTextColor,
            content: Text(
              message,
              style: TextStyleConst.styleRegular(
                size: 16,
                textColor: ColorsConst.primaryColor,
              ),
            ),
          ),
        )
        .closed
        .then(
      (reason) {
        onFinish?.call();
      },
    );
  }
}
