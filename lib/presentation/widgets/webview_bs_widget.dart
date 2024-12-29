import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/web.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewBsWidget extends StatefulWidget {
  const WebviewBsWidget({super.key});

  @override
  State<WebviewBsWidget> createState() => _WebviewBsWidgetState();
}

class _WebviewBsWidgetState extends State<WebviewBsWidget> {
  late WebViewController _controller;
  Logger log = Logger();
  @override
  void initState() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            bool isSucces = false;
            if (url.contains('nhentai.net') &&
                await isCloudflareBypassed() &&
                mounted) {
              isSucces = true;
            }
            Future.delayed(const Duration(seconds: 1), () {
              getIt<SplashBloc>().add(
                  SplashCFBypassEvent(status: isSucces ? "sukses" : "gagal"));
            });
            context.pop();
          },
          onHttpError: (HttpResponseError error) {
            log.e(error.response);
            Future.delayed(const Duration(seconds: 1), () {
              getIt<SplashBloc>().add(SplashCFBypassEvent(status: "gagal"));
            });
            context.pop();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://nhentai.net'));
    super.initState();
  }

  @override
  void dispose() {
    _WebviewBsWidgetState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Please wait while we bypass Cloudflare...',
              style: TextStyleConst.styleRegular(
                size: 16,
                textColor: ColorsConst.primaryColor,
              ),
            ),
          ),
          Expanded(
            child: WebViewWidget(
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> isCloudflareBypassed() async {
    final cookies =
        await _controller.runJavaScriptReturningResult('document.cookie;');
    if (cookies.toString().contains('cf_clearance')) {
      return true;
    } else if (cookies.toString().contains("csrftoken")) {
      return true;
    } else {
      return false;
    }
  }
}