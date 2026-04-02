import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/source_auth/source_auth_cubit.dart';
import 'package:nhasixapp/presentation/pages/auth/captcha_solver_page.dart';
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

class _SourceLoginPageState extends State<SourceLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _captchaTokenController = TextEditingController();
  bool _wasAuthenticated = false;
  bool _obscurePassword = true;
  bool _isLoginDialogOpen = false;
  bool _isLoginDialogClosing = false;
  String? _lastSnackMessage;
  DateTime? _lastSnackAt;

  bool get _hasCaptchaToken => _captchaTokenController.text.trim().isNotEmpty;

  bool get _canSubmitLogin =>
      _usernameController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _hasCaptchaToken;

  void _onInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
    _captchaTokenController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _captchaTokenController.removeListener(_onInputChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SourceAuthCubit>()..initialize(widget.sourceId),
      child: Scaffold(
        backgroundColor: const Color(0xFF040B18),
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
            if (state.loginFlowActive && !_isLoginDialogOpen) {
              _showLoginProgressDialog(context);
            }

            if (_isLoginDialogOpen &&
                state.loginFlowSuccess &&
                !_isLoginDialogClosing) {
              _isLoginDialogClosing = true;
              Future<void>.delayed(const Duration(milliseconds: 900), () {
                if (!context.mounted) return;
                _closeLoginProgressDialog();
                context.read<SourceAuthCubit>().clearLoginFlowState();
                context.read<SourceAuthCubit>().refreshProfile();
                _isLoginDialogClosing = false;
              });
            }

            if (_isLoginDialogOpen &&
                !state.loginFlowActive &&
                !state.loginFlowSuccess &&
                !_isLoginDialogClosing) {
              _closeLoginProgressDialog();
            }

            if (_wasAuthenticated && !state.authenticated) {
              _usernameController.clear();
              _passwordController.clear();
              _captchaTokenController.clear();
            }

            _wasAuthenticated = state.authenticated;

            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              _showLocalizedErrorSnackBar(context, state.errorMessage!);
            }
          },
          builder: (context, state) {
            final l10n = AppLocalizations.of(context)!;
            if (state.loading && !state.loginFlowActive) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A1428), Color(0xFF0A1F2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.authenticated
                              ? l10n.sourceAuthConnectedAccount
                              : l10n.sourceAuthSecureLogin,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.authenticated
                              ? l10n.sourceAuthConnectedDescription
                              : l10n.sourceAuthLoginDescription,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.authenticated) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFF0C1524),
                        border: Border.all(
                          color:
                              const Color(0xFF7ED4E7).withValues(alpha: 0.35),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 24,
                            spreadRadius: -8,
                            color: Color(0x55000000),
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: Color(0xFF7ED4E7),
                                child: Icon(Icons.person,
                                    color: Color(0xFF0B1725)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (state.accountName ??
                                                  _usernameController.text
                                                      .trim())
                                              .isEmpty
                                          ? l10n.sourceAuthUser
                                          : (state.accountName ??
                                              _usernameController.text.trim()),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    if (state.profileEmail != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        state.profileEmail!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                    ],
                                    if (state.profileSlug != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${l10n.sourceAuthSlug}: ${state.profileSlug}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.white60),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x2212D8A0),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0x5551E2BA),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.verified_user,
                                        color: Color(0xFF7CE3C1),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(l10n.sourceAuthAuthenticated),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              context.read<SourceAuthCubit>().refreshProfile(),
                          icon: const Icon(Icons.sync),
                          label: Text(l10n.sourceAuthRefreshProfile),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.read<SourceAuthCubit>().logout(),
                          icon: const Icon(Icons.logout),
                          label: Text(l10n.sourceAuthLogout),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFF0A1320),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.sourceAuthUsername,
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: const Color(0xFF060F1B),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l10n.sourceAuthPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF060F1B),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _hasCaptchaToken
                                  ? const Color(0xFF113525)
                                  : const Color(0xFF2A1A1A),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _hasCaptchaToken
                                      ? Icons.verified_rounded
                                      : Icons.shield_outlined,
                                  size: 18,
                                  color: _hasCaptchaToken
                                      ? const Color(0xFF86E8B6)
                                      : const Color(0xFFFFB4B4),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _hasCaptchaToken
                                        ? l10n.sourceAuthCaptchaVerified
                                        : l10n.sourceAuthCaptchaRequired,
                                    style: TextStyle(
                                      color: _hasCaptchaToken
                                          ? const Color(0xFFBFF3D9)
                                          : const Color(0xFFFFB4B4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _hasCaptchaToken
                                    ? const Color(0xFF123929)
                                    : const Color(0xFF10263B),
                                foregroundColor: _hasCaptchaToken
                                    ? const Color(0xFF8BE4B8)
                                    : const Color(0xFF8FD9FF),
                              ),
                              onPressed: (state.captchaProvider == null ||
                                      state.captchaSiteKey == null ||
                                      state.captchaSiteKey!.isEmpty)
                                  ? null
                                  : () => _openCaptchaSolver(
                                        context,
                                        provider: state.captchaProvider!,
                                        siteKey: state.captchaSiteKey!,
                                        baseUrl: state.captchaBaseUrl,
                                      ),
                              icon: Icon(
                                _hasCaptchaToken
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.shield_outlined,
                              ),
                              label: Text(
                                _hasCaptchaToken
                                    ? l10n.sourceAuthCaptchaSolved
                                    : l10n.sourceAuthSolveCaptcha,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _canSubmitLogin
                                  ? () => _submitLogin(context)
                                  : null,
                              icon: const Icon(Icons.login),
                              label: Text(l10n.sourceAuthLoginButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showLoginProgressDialog(BuildContext context) async {
    if (_isLoginDialogOpen) return;

    final sourceAuthCubit = context.read<SourceAuthCubit>();
    _isLoginDialogOpen = true;
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: BlocProvider.value(
            value: sourceAuthCubit,
            child: BlocBuilder<SourceAuthCubit, SourceAuthState>(
              builder: (context, state) {
                final isSuccess = state.loginFlowSuccess;
                final progress = state.loginFlowProgress.clamp(0.0, 1.0);
                final rawMessage = state.loginFlowMessage ??
                    (isSuccess
                        ? 'source_auth.flow.login_success'
                        : 'source_auth.flow.preparing_session');
                final message = _localizeFlowMessage(context, rawMessage);
                final currentStep = progress < 0.34
                    ? 0
                    : progress < 0.75
                        ? 1
                        : 2;

                return Dialog(
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  backgroundColor: Colors.transparent,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 340,
                        maxHeight:
                            MediaQuery.of(dialogContext).size.height * 0.52,
                      ),
                      child: Material(
                        color: const Color(0xFF0A1320),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: isSuccess
                                          ? const Color(0xFF153B2C)
                                          : const Color(0xFF0E2237),
                                    ),
                                    child: isSuccess
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF83E8BB),
                                          )
                                        : const Center(
                                            child: AnimatedDiceWidget(
                                              isSpinning: true,
                                              duration:
                                                  Duration(milliseconds: 600),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isSuccess
                                          ? AppLocalizations.of(context)!
                                              .sourceAuthLoginSuccess
                                          : AppLocalizations.of(context)!
                                              .sourceAuthSigningInSecurely,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLoginStep(
                                title: AppLocalizations.of(context)!
                                    .sourceAuthStepValidateRequest,
                                active: currentStep == 0 && !isSuccess,
                                done: currentStep > 0 || isSuccess,
                              ),
                              _buildLoginStep(
                                title: AppLocalizations.of(context)!
                                    .sourceAuthStepSecureAuth,
                                active: currentStep == 1 && !isSuccess,
                                done: currentStep > 1 || isSuccess,
                              ),
                              _buildLoginStep(
                                title: AppLocalizations.of(context)!
                                    .sourceAuthStepFetchProfile,
                                active: currentStep == 2 && !isSuccess,
                                done: isSuccess,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                message,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 9,
                                  value: progress,
                                  backgroundColor: const Color(0x33283D52),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSuccess
                                        ? const Color(0xFF76E4B4)
                                        : const Color(0xFF74D8F2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${(progress * 100).round()}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    _isLoginDialogOpen = false;
  }

  void _closeLoginProgressDialog() {
    if (!_isLoginDialogOpen || !mounted) return;
    Navigator.of(context, rootNavigator: false).pop();
    _isLoginDialogOpen = false;
  }

  Future<void> _submitLogin(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!context.mounted || !_canSubmitLogin) return;

    unawaited(context.read<SourceAuthCubit>().login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          captchaResponse: _captchaTokenController.text.trim(),
        ));
  }

  Widget _buildLoginStep({
    required String title,
    required bool active,
    required bool done,
  }) {
    final icon = done
        ? Icons.check_circle_rounded
        : active
            ? Icons.hourglass_top_rounded
            : Icons.radio_button_unchecked_rounded;
    final color = done
        ? const Color(0xFF76E4B4)
        : active
            ? const Color(0xFF74D8F2)
            : Colors.white38;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: active || done ? Colors.white : Colors.white60,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocalizedErrorSnackBar(BuildContext context, String rawError) {
    final l10n = AppLocalizations.of(context)!;
    final message = _mapErrorMessage(l10n, rawError);

    final now = DateTime.now();
    final duplicate = _lastSnackMessage == message &&
        _lastSnackAt != null &&
        now.difference(_lastSnackAt!).inSeconds < 3;
    if (duplicate) {
      return;
    }

    _lastSnackMessage = message;
    _lastSnackAt = now;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  String _mapErrorMessage(AppLocalizations l10n, String rawError) {
    final text = rawError.toLowerCase();

    if (text.contains('timeout')) {
      return l10n.errorConnectionTimeout;
    }
    if (text.contains('connection reset') ||
        text.contains('socketexception') ||
        text.contains('connection error')) {
      return l10n.errorNetwork;
    }
    if (text.contains('connection refused')) {
      return l10n.errorConnectionRefused;
    }
    if (text.contains('401') ||
        text.contains('403') ||
        text.contains('unauthorized') ||
        text.contains('session expired')) {
      return l10n.errorServer;
    }
    if (text.contains('500') || text.contains('server')) {
      return l10n.errorServer;
    }

    return l10n.errorUnknown;
  }

  String _localizeFlowMessage(BuildContext context, String rawMessage) {
    final l10n = AppLocalizations.of(context)!;
    final message = rawMessage.trim();

    if (message == 'source_auth.flow.preparing_session' ||
        message.toLowerCase() == 'preparing secure session...') {
      return l10n.sourceAuthFlowPreparingSession;
    }
    if (message == 'source_auth.flow.solving_challenge' ||
        message.toLowerCase() == 'solving security challenge...') {
      return l10n.sourceAuthFlowSolvingChallenge;
    }
    if (message == 'source_auth.flow.fetching_profile' ||
        message.toLowerCase() == 'session verified. fetching profile...') {
      return l10n.sourceAuthFlowFetchingProfile;
    }
    if (message == 'source_auth.flow.login_success' ||
        message.toLowerCase() == 'login successful' ||
        message.toLowerCase() == 'login completed successfully') {
      return l10n.sourceAuthFlowLoginSuccess;
    }

    return rawMessage;
  }

  Future<void> _openCaptchaSolver(
    BuildContext context, {
    required String provider,
    required String siteKey,
    String? baseUrl,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CaptchaSolverPage(
          provider: provider,
          siteKey: siteKey,
          baseUrl: baseUrl,
        ),
      ),
    );

    if (!context.mounted || token == null || token.isEmpty) return;

    setState(() {
      _captchaTokenController.text = token;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.sourceAuthCaptchaCaptured),
      ),
    );
  }
}
