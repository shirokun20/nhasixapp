import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:nhasixapp/presentation/pages/reader/reader_screen.dart';
import 'package:nhasixapp/presentation/pages/settings/settings_screen.dart';
import 'package:nhasixapp/presentation/pages/splash/splash_screen.dart';
import 'package:nhasixapp/presentation/pages/main/main_screen.dart';
import 'package:nhasixapp/presentation/pages/search/search_screen.dart';
import 'package:nhasixapp/presentation/pages/detail/detail_screen.dart';
import 'package:nhasixapp/presentation/pages/filter_data/filter_data_screen.dart';
import 'package:nhasixapp/presentation/pages/favorites/favorites_screen.dart';
import 'package:nhasixapp/presentation/pages/downloads/downloads_screen.dart';
import 'package:nhasixapp/presentation/pages/offline/offline_content_screen.dart';
import 'package:nhasixapp/domain/entities/entities.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoute.defaultRoute,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoute.splash,
        name: AppRoute.splashName,
        builder: (context, state) => const SplashScreen(),
      ),

      // Home Screen
      GoRoute(
        path: AppRoute.home,
        name: AppRoute.homeName,
        builder: (context, state) =>
            const MainScreen(), // Using MainScreen as home for now
      ),

      // Search Screen
      GoRoute(
        path: AppRoute.search,
        name: AppRoute.searchName,
        builder: (context, state) => const SearchScreen(),
      ),

      // Filter Data Screen
      GoRoute(
        path: AppRoute.filterData,
        name: AppRoute.filterDataName,
        builder: (context, state) {
          final filterType = state.uri.queryParameters['type'] ?? 'tag';

          // Safe type casting for List<FilterItem>
          List<FilterItem> selectedFilters = [];
          if (state.extra != null) {
            try {
              if (state.extra is List<FilterItem>) {
                selectedFilters = state.extra as List<FilterItem>;
              } else if (state.extra is List<dynamic>) {
                // Convert List<dynamic> to List<FilterItem>
                final dynamicList = state.extra as List<dynamic>?;
                selectedFilters = (dynamicList ?? <dynamic>[])
                    .whereType<FilterItem>()
                    .toList();
              }
            } catch (e) {
              // If casting fails, use empty list
              selectedFilters = [];
            }
          }

          return FilterDataScreen(
            filterType: filterType,
            selectedFilters: selectedFilters,
          );
        },
      ),

      GoRoute(
        path: '${AppRoute.search}/:query',
        name: AppRoute.searchNameWithQuery,
        builder: (context, state) {
          final query = state.pathParameters['query']!;
          return SearchScreen(query: query);
        },
      ),

      // Content Detail Screen
      GoRoute(
        path: AppRoute.contentDetail,
        name: AppRoute.contentDetailName,
        builder: (context, state) {
          final contentId = state.pathParameters['id']!;
          return DetailScreen(contentId: contentId);
        },
      ),

      // Reader Screen
      GoRoute(
        path: AppRoute.reader,
        name: AppRoute.readerName,
        builder: (context, state) {
          final contentId = state.pathParameters['id']!;
          final page =
              int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1;
          return ReaderScreen(
            contentId: contentId,
            initialPage: page,
          );
        },
      ),

      // Favorites Screen
      GoRoute(
        path: AppRoute.favorites,
        name: AppRoute.favoritesName,
        builder: (context, state) => const FavoritesScreen(),
      ),

      // Downloads Screen
      GoRoute(
        path: AppRoute.downloads,
        name: AppRoute.downloadsName,
        builder: (context, state) => const DownloadsScreen(),
      ),

      // Offline Content Screen
      GoRoute(
        path: AppRoute.offline,
        name: AppRoute.offlineName,
        builder: (context, state) => const OfflineContentScreen(),
      ),

      // History Screen
      GoRoute(
        path: AppRoute.history,
        name: AppRoute.historyName,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('History Screen - To be implemented')),
        ),
      ),

      // Settings Screen
      GoRoute(
        path: AppRoute.settings,
        name: AppRoute.settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Tags Screen
      GoRoute(
        path: AppRoute.tags,
        name: AppRoute.tagsName,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Tags Screen - To be implemented')),
        ),
      ),

      // Artists Screen
      GoRoute(
        path: AppRoute.artists,
        name: AppRoute.artistsName,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Artists Screen - To be implemented')),
        ),
      ),

      // Random Screen
      GoRoute(
        path: AppRoute.random,
        name: AppRoute.randomName,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Random Screen - To be implemented')),
        ),
      ),

      // Status Screen
      GoRoute(
        path: AppRoute.status,
        name: AppRoute.statusName,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Status Screen - To be implemented')),
        ),
      ),

      // Legacy Main Screen route for backward compatibility
      GoRoute(
        path: AppRoute.main,
        name: AppRoute.mainName,
        builder: (context, state) => const MainScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoute.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  // Navigation helper methods
  static void goToHome(BuildContext context) {
    context.go(AppRoute.home);
  }

  static void goToSearch(BuildContext context) {
    context.push(AppRoute.search);
  }

  static Future<SearchFilter?> goToContentDetail(
      BuildContext context, String contentId) async {
    return await context.push<SearchFilter>('/content/$contentId');
  }

  static void goToReader(BuildContext context, String contentId,
      {int page = 1}) {
    context.push('/reader/$contentId?page=$page');
  }

  static void goToFavorites(BuildContext context) {
    context.go(AppRoute.favorites);
  }

  static void goToDownloads(BuildContext context) {
    context.go(AppRoute.downloads);
  }

  static void goToOffline(BuildContext context) {
    context.go(AppRoute.offline);
  }

  static void goToHistory(BuildContext context) {
    context.go(AppRoute.history);
  }

  static void goToSettings(BuildContext context) {
    context.go(AppRoute.settings);
  }

  static void goToTags(BuildContext context) {
    context.go(AppRoute.tags);
  }

  static void goToArtists(BuildContext context) {
    context.go(AppRoute.artists);
  }

  static void goToRandom(BuildContext context) {
    context.go(AppRoute.random);
  }

  static void goToStatus(BuildContext context) {
    context.go(AppRoute.status);
  }

  static Future<List<FilterItem>?> goToFilterData(
    BuildContext context, {
    required String filterType,
    required List<FilterItem> selectedFilters,
  }) async {
    try {
      final result = await context.push<List<FilterItem>>(
        '${AppRoute.filterData}?type=$filterType',
        extra: selectedFilters,
      );

      // Ensure result is properly typed
      if (result is List<FilterItem>) {
        return result;
      } else if (result is List<dynamic>) {
        // Convert List<dynamic> to List<FilterItem> if needed
        return result ?? [];
      }

      return result;
    } catch (e) {
      // Log error and return null
      debugPrint('AppRouter.goToFilterData error: $e');
      return null;
    }
  }

  // Additional navigation helper methods for better navigation flow
  static void goBackWithResult<T>(BuildContext context, T result) {
    context.pop(result);
  }

  static void goBack(BuildContext context) {
    context.pop();
  }

  static bool canPop(BuildContext context) {
    return context.canPop();
  }

  // Navigation method specifically for returning from FilterDataScreen
  static void returnFromFilterData(
      BuildContext context, List<FilterItem> selectedFilters) {
    try {
      // Ensure we're passing the correct type
      final typedFilters = List<FilterItem>.from(selectedFilters);
      context.pop(typedFilters);
    } catch (e) {
      debugPrint('AppRouter.returnFromFilterData error: $e');
      context.pop(<FilterItem>[]);
    }
  }

  // Navigation method for canceling FilterDataScreen
  static void cancelFilterData(BuildContext context) {
    context.pop();
  }
}
