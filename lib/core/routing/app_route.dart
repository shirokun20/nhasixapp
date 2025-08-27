class AppRoute {
  // Core routes
  static const String splash = '/';
  static const String home = '/home';
  static const String search = '/search';
  static const String contentByTag = '/searchByTag';

  // Content routes
  static const String contentDetail = '/content/:id';
  static const String reader = '/reader/:id';

  // User data routes
  static const String favorites = '/favorites';
  static const String downloads = '/downloads';
  static const String history = '/history';
  static const String offline = '/offline';

  // Settings and management
  static const String settings = '/settings';
  static const String tags = '/tags';
  static const String artists = '/artists';
  static const String filterData = '/filter-data';

  // Utility routes
  static const String random = '/random';
  static const String status = '/status';

  // Legacy route for backward compatibility
  static const String main = '/main';
  static const String defaultRoute = splash;

  // Route names for navigation
  static const String splashName = 'splash';
  static const String homeName = 'home';
  static const String searchName = 'search';
  static const String searchNameWithQuery = 'search-query';
  static const String contentByTagName = 'content-by-tag';
  static const String contentDetailName = 'content-detail';
  static const String readerName = 'reader';
  static const String favoritesName = 'favorites';
  static const String downloadsName = 'downloads';
  static const String historyName = 'history';
  static const String offlineName = 'offline';
  static const String settingsName = 'settings';
  static const String tagsName = 'tags';
  static const String artistsName = 'artists';
  static const String filterDataName = 'filter-data';
  static const String randomName = 'random';
  static const String statusName = 'status';
  static const String mainName = 'main';
}
