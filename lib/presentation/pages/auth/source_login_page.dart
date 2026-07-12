import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/constants/design_tokens.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/source_auth/source_auth_cubit.dart';
import 'package:nhasixapp/presentation/widgets/animated_dice_widget.dart';

class SourceLoginPage extends StatefulWidget {
  final String sourceId;

  const SourceLoginPage({
    super.key,
    required this.sourceId,
  });

  @override
  State<SourceLoginPage> createState() => _SourceLoginPageState();
}

class _SourceLoginPageState extends State<SourceLoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SourceAuthCubit>()..initialize(widget.sourceId),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: BlocBuilder<SourceAuthCubit, SourceAuthState>(
            builder: (context, state) {
              final l10n = AppLocalizations.of(context)!;
              return Text(
                state.authenticated
                    ? l10n.sourceAuthProfileTitle(widget.sourceId)
                    : l10n.sourceAuthLoginTitle(widget.sourceId),
              );
            },
          ),
        ),
        body: BlocConsumer<SourceAuthCubit, SourceAuthState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(_mapError(l10n, state.errorMessage!))),
                );
            }
          },
          builder: (context, state) {
            final l10n = AppLocalizations.of(context)!;

            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.authenticated) {
              return _buildAuthenticated(context, state, l10n);
            }

            return _buildUnauthenticated(context, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildAuthenticated(
      BuildContext context, SourceAuthState state, AppLocalizations l10n) {
    final initial = (state.accountName ?? 'U').substring(0, 1).toUpperCase();
    final hues = [170, 200, 220];
    final avatarColor = HSLColor.fromAHSL(
      1.0, hues[widget.sourceId.hashCode % hues.length].toDouble(), 0.5, 0.4,
    ).toColor();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        children: [
          // ── Avatar + Name Card ──
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnim.value,
              child: child,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
                gradient: LinearGradient(
                  colors: [
                    avatarColor.withValues(alpha: 0.2),
                    avatarColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: avatarColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: avatarColor,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    state.accountName ?? l10n.sourceAuthUser,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (state.profileEmail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      state.profileEmail!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                  if (state.profileSlug != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.sourceAuthSlug}: ${state.profileSlug}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Connected badge ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.sourceAuthConnectedAccount,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Gimmick: source quote ──
          _buildGimmick(context, l10n),

          const SizedBox(height: 28),

          // ── Logout button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<SourceAuthCubit>().logout();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l10n.sourceAuthLogout),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGimmick(BuildContext context, AppLocalizations l10n) {
    // Choose gimmick by source
    if (widget.sourceId == 'nhentai') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.tertiary, size: 20),
            const SizedBox(height: 10),
            Text(
              'Abandon all hope,\nye who enter here',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Text(
              '汝等こゝに入るもの一切の望みを棄てよ',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 11),
            ),
          ],
        ),
      );
    }

    // Default: animated dice gimmick (matching Crotpedia)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: AnimatedDiceWidget(isSpinning: false),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.sourceAuthConnectedDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticated(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Source icon
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surfaceContainerLow,
                    Theme.of(context).colorScheme.surfaceContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              ),
              child: Icon(
                widget.sourceId == 'nhentai'
                    ? Icons.library_books_rounded
                    : Icons.lock_person,
                size: 40,
                color: widget.sourceId == 'nhentai'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.sourceAuthLoginTitle(widget.sourceId),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.sourceAuthLoginDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: () => _launchWebViewLogin(context),
              icon: const Icon(Icons.login),
              label: Text(l10n.sourceAuthSecureLogin),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WebView Login ──

  Future<void> _launchWebViewLogin(BuildContext context) async {
    final urls = _getLoginUrls(widget.sourceId);
    if (urls == null) return;

    try {
      final result = await KuronNative.instance.showLoginWebView(
        url: urls.url,
        autoCloseOnCookie: urls.autoCloseCookie,
        clearCookies: true,
      );

      if (!context.mounted) return;

      if (result != null && result['success'] == true) {
        final cookies =
            (result['cookies'] as List<dynamic>?)?.cast<String>() ?? [];
        final hasSession =
            cookies.any((c) => c.startsWith('${urls.autoCloseCookie}='));

        if (hasSession) {
          await _saveWebViewSession(cookies, urls.autoCloseCookie);
          if (context.mounted) {
            context.read<SourceAuthCubit>().initialize(widget.sourceId);
          }
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.loginIncomplete)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .loginFailedError(e.toString())),
          ),
        );
      }
    }
  }

  Future<void> _saveWebViewSession(
      List<String> cookies, String? cookieName) async {
    if (cookieName == null) return;
    String? accessToken;
    for (final c in cookies) {
      if (c.startsWith('$cookieName=')) {
        accessToken = c.substring('$cookieName='.length);
        break;
      }
    }
    if (accessToken == null || accessToken.isEmpty) return;

    // Derive session key same as ConfigDrivenApiAuthClient
    final config = getIt<RemoteConfigService>().getRawConfig(widget.sourceId);
    final apiBase = ((config?['api'] as Map?)??{})['apiBase']?.toString() ?? '';
    final endpoints = (config?['auth'] as Map?)??['endpoints'] as Map? ?? {};
    final loginEndpoint = endpoints['login']?.toString() ?? '';
    final keySeed = '$apiBase|$loginEndpoint';
    final sessionKey = 'kuron_special_api_auth_${keySeed.hashCode}';
    const storage = FlutterSecureStorage();
    await storage.write(
      key: sessionKey,
      value: jsonEncode({'accessToken': accessToken}),
    );
  }

  _LoginUrls? _getLoginUrls(String sourceId) {
    final config = getIt<RemoteConfigService>().getRawConfig(sourceId);
    if (config == null) return null;

    final auth = config['auth'] as Map<String, dynamic>?;
    final webview = auth?['webviewLogin'] as Map<String, dynamic>?;
    if (webview == null) return null;

    final url = webview['url']?.toString().trim();
    final cookieName = webview['autoCloseCookie']?.toString().trim();
    if (url == null || url.isEmpty) return null;

    return _LoginUrls(url: url, autoCloseCookie: cookieName);
  }

  String _mapError(AppLocalizations l10n, String raw) {
    final text = raw.toLowerCase();
    if (text.contains('timeout')) return l10n.errorConnectionTimeout;
    if (text.contains('connection')) return l10n.errorNetwork;
    if (text.contains('session expired') ||
        text.contains('unauthorized') ||
        text.contains('401') ||
        text.contains('403')) {
      return l10n.errorServer;
    }
    if (text.contains('500')) return l10n.errorServer;
    return l10n.errorUnknown;
  }
}

class _LoginUrls {
  final String url;
  final String? autoCloseCookie;

  _LoginUrls({
    required this.url,
    this.autoCloseCookie,
  });
}
