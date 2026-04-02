part of 'source_auth_cubit.dart';

class SourceAuthState extends BaseCubitState {
  final String sourceId;
  final bool loading;
  final bool authenticated;
  final String? accountName;
  final String? errorMessage;
  final String? captchaProvider;
  final String? captchaSiteKey;
  final String? captchaBaseUrl;
  final String? powChallenge;
  final int? powDifficulty;
  final String? profileEmail;
  final String? profileSlug;
  final bool loginFlowActive;
  final bool loginFlowSuccess;
  final double loginFlowProgress;
  final String? loginFlowMessage;

  const SourceAuthState({
    required this.sourceId,
    required this.loading,
    required this.authenticated,
    this.accountName,
    this.errorMessage,
    this.captchaProvider,
    this.captchaSiteKey,
    this.captchaBaseUrl,
    this.powChallenge,
    this.powDifficulty,
    this.profileEmail,
    this.profileSlug,
    this.loginFlowActive = false,
    this.loginFlowSuccess = false,
    this.loginFlowProgress = 0,
    this.loginFlowMessage,
  });

  const SourceAuthState.initial()
      : sourceId = '',
        loading = false,
        authenticated = false,
        accountName = null,
        errorMessage = null,
        captchaProvider = null,
        captchaSiteKey = null,
        captchaBaseUrl = null,
        powChallenge = null,
        powDifficulty = null,
        profileEmail = null,
        profileSlug = null,
        loginFlowActive = false,
        loginFlowSuccess = false,
        loginFlowProgress = 0,
        loginFlowMessage = null;

  SourceAuthState copyWith({
    String? sourceId,
    bool? loading,
    bool? authenticated,
    String? accountName,
    bool clearAccountName = false,
    String? errorMessage,
    bool clearError = false,
    String? captchaProvider,
    String? captchaSiteKey,
    String? captchaBaseUrl,
    bool clearCaptchaInfo = false,
    String? powChallenge,
    int? powDifficulty,
    bool clearPowInfo = false,
    String? profileEmail,
    bool clearProfileEmail = false,
    String? profileSlug,
    bool clearProfileSlug = false,
    bool? loginFlowActive,
    bool? loginFlowSuccess,
    double? loginFlowProgress,
    String? loginFlowMessage,
    bool clearLoginFlowMessage = false,
  }) {
    return SourceAuthState(
      sourceId: sourceId ?? this.sourceId,
      loading: loading ?? this.loading,
      authenticated: authenticated ?? this.authenticated,
      accountName: clearAccountName ? null : (accountName ?? this.accountName),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      captchaProvider:
          clearCaptchaInfo ? null : (captchaProvider ?? this.captchaProvider),
      captchaSiteKey:
          clearCaptchaInfo ? null : (captchaSiteKey ?? this.captchaSiteKey),
      captchaBaseUrl:
          clearCaptchaInfo ? null : (captchaBaseUrl ?? this.captchaBaseUrl),
      powChallenge: clearPowInfo ? null : (powChallenge ?? this.powChallenge),
      powDifficulty:
          clearPowInfo ? null : (powDifficulty ?? this.powDifficulty),
      profileEmail:
          clearProfileEmail ? null : (profileEmail ?? this.profileEmail),
      profileSlug: clearProfileSlug ? null : (profileSlug ?? this.profileSlug),
      loginFlowActive: loginFlowActive ?? this.loginFlowActive,
      loginFlowSuccess: loginFlowSuccess ?? this.loginFlowSuccess,
      loginFlowProgress: loginFlowProgress ?? this.loginFlowProgress,
      loginFlowMessage: clearLoginFlowMessage
          ? null
          : (loginFlowMessage ?? this.loginFlowMessage),
    );
  }

  @override
  List<Object?> get props => [
        sourceId,
        loading,
        authenticated,
        accountName,
        errorMessage,
        captchaProvider,
        captchaSiteKey,
        captchaBaseUrl,
        powChallenge,
        powDifficulty,
        profileEmail,
        profileSlug,
        loginFlowActive,
        loginFlowSuccess,
        loginFlowProgress,
        loginFlowMessage,
      ];
}
