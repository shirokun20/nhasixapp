class ApiPowChallenge {
  final String challenge;
  final int difficulty;

  const ApiPowChallenge({
    required this.challenge,
    required this.difficulty,
  });
}

class ApiCaptchaConfig {
  final String provider;
  final String siteKey;

  const ApiCaptchaConfig({
    required this.provider,
    required this.siteKey,
  });
}

class ApiAuthSession {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String? tokenType;
  final String? username;

  const ApiAuthSession({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.tokenType,
    this.username,
  });
}

class ApiFavoriteStatus {
  final bool favorited;
  final int? numFavorites;

  const ApiFavoriteStatus({
    required this.favorited,
    this.numFavorites,
  });
}

class ApiAuthConfig {
  final String apiBase;
  final String authorizationScheme;
  final String? powAction;
  final String? powEndpoint;
  final String? captchaEndpoint;
  final String loginEndpoint;
  final String? refreshEndpoint;
  final String? logoutEndpoint;
  final String? favoritesEndpoint;
  final String? galleryFavoriteEndpoint;
  final String? blacklistEndpoint;
  final String? blacklistIdsEndpoint;
  final String? userEndpoint;
  final String usernameField;
  final String passwordField;
  final String captchaField;
  final String challengeField;
  final String nonceField;
  final String actionField;
  final String accessTokenField;
  final String refreshTokenField;
  final String expiresInField;
  final String tokenTypeField;

  const ApiAuthConfig({
    required this.apiBase,
    required this.authorizationScheme,
    required this.loginEndpoint,
    required this.usernameField,
    required this.passwordField,
    required this.captchaField,
    required this.challengeField,
    required this.nonceField,
    required this.actionField,
    required this.accessTokenField,
    required this.refreshTokenField,
    required this.expiresInField,
    required this.tokenTypeField,
    this.powAction,
    this.powEndpoint,
    this.captchaEndpoint,
    this.refreshEndpoint,
    this.logoutEndpoint,
    this.favoritesEndpoint,
    this.galleryFavoriteEndpoint,
    this.blacklistEndpoint,
    this.blacklistIdsEndpoint,
    this.userEndpoint,
  });

  factory ApiAuthConfig.fromSourceConfig(Map<String, dynamic> rawConfig) {
    final api = rawConfig['api'] as Map<String, dynamic>? ?? const {};
    final auth = rawConfig['auth'] as Map<String, dynamic>? ?? const {};
    final endpoints = auth['endpoints'] as Map<String, dynamic>? ?? const {};
    final fields = auth['fields'] as Map<String, dynamic>? ?? const {};

    final apiBase = (api['apiBase'] as String?)?.trim() ??
        (rawConfig['baseUrl'] as String?)?.trim() ??
        '';

    if (apiBase.isEmpty) {
      throw ArgumentError('apiBase/baseUrl is required for auth config');
    }

    final loginEndpoint = (endpoints['login'] as String?)?.trim() ?? '';
    if (loginEndpoint.isEmpty) {
      throw ArgumentError('auth.endpoints.login is required');
    }

    return ApiAuthConfig(
      apiBase: apiBase,
      authorizationScheme:
          (auth['authorizationScheme'] as String?)?.trim() ?? 'User',
      powAction: (auth['powAction'] as String?)?.trim(),
      powEndpoint: (endpoints['pow'] as String?)?.trim(),
      captchaEndpoint: (endpoints['captcha'] as String?)?.trim(),
      loginEndpoint: loginEndpoint,
      refreshEndpoint: (endpoints['refresh'] as String?)?.trim(),
      logoutEndpoint: (endpoints['logout'] as String?)?.trim(),
      favoritesEndpoint: (endpoints['favorites'] as String?)?.trim(),
      galleryFavoriteEndpoint:
          (endpoints['galleryFavorite'] as String?)?.trim(),
      blacklistEndpoint: (endpoints['blacklist'] as String?)?.trim(),
      blacklistIdsEndpoint: (endpoints['blacklistIds'] as String?)?.trim(),
      userEndpoint: (endpoints['user'] as String?)?.trim(),
      usernameField: (fields['username'] as String?)?.trim() ?? 'username',
      passwordField: (fields['password'] as String?)?.trim() ?? 'password',
      captchaField:
          (fields['captchaResponse'] as String?)?.trim() ?? 'captcha_response',
      challengeField:
          (fields['powChallenge'] as String?)?.trim() ?? 'pow_challenge',
      nonceField: (fields['powNonce'] as String?)?.trim() ?? 'pow_nonce',
      actionField: (fields['powAction'] as String?)?.trim() ?? 'pow_action',
      accessTokenField:
          (fields['accessToken'] as String?)?.trim() ?? 'access_token',
      refreshTokenField:
          (fields['refreshToken'] as String?)?.trim() ?? 'refresh_token',
      expiresInField: (fields['expiresIn'] as String?)?.trim() ?? 'expires_in',
      tokenTypeField: (fields['tokenType'] as String?)?.trim() ?? 'token_type',
    );
  }
}
