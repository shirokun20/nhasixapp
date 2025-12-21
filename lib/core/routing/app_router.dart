import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:nhasixapp/presentation/pages/reader/reader_screen.dart';
import 'package:nhasixapp/presentation/pages/settings/settings_screen.dart';
import 'package:nhasixapp/presentation/pages/splash/splash_screen.dart';
import 'package:nhasixapp/presentation/pages/main/main_screen_scrollable.dart';
import 'package:nhasixapp/presentation/pages/search/search_screen.dart';
import 'package:nhasixapp/presentation/pages/content_by_tag/content_by_tag_screen.dart';
import 'package:nhasixapp/presentation/pages/detail/detail_screen.dart';
import 'package:nhasixapp/presentation/pages/filter_data/filter_data_screen.dart';
import 'package:nhasixapp/presentation/pages/favorites/favorites_screen.dart';
import 'package:nhasixapp/presentation/pages/downloads/downloads_screen.dart';
import 'package:nhasixapp/presentation/pages/offline/offline_content_screen.dart';
import 'package:nhasixapp/presentation/pages/history/history_screen.dart';
import 'package:nhasixapp/presentation/pages/random/random_gallery_screen.dart';
import 'package:nhasixapp/presentation/pages/about/about_screen.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/core/models/image_metadata.dart';
import 'package:nhasixapp/core/utils/app_animations.dart';

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
        builder: (context, state) {
          return const MainScreenScrollable(); // Phase 5: Testing scrollable architecture
        },
      ),

      // Search Screen
      GoRoute(
        path: AppRoute.search,
        name: AppRoute.searchName,
        pageBuilder: (context, state) => AppAnimations.animatedPageBuilder(
          context,
          state,
          const SearchScreen(),
          type: RouteTransitionType.slideLeft,
        ),
      ),

      // Filter Data Screen
      GoRoute(
        path: AppRoute.filterData,
        name: AppRoute.filterDataName,
        builder: (context, state) {
          final filterType = state.uri.queryParameters['type'] ?? 'tag';
          final hideOtherTabs =
              state.uri.queryParameters['hideOtherTabs'] == 'true';

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
            hideOtherTabs: hideOtherTabs,
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

      // Content by Tag Screen
      GoRoute(
        path: AppRoute.contentByTag,
        name: AppRoute.contentByTagName,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return ContentByTagScreen(tagQuery: query);
        },
      ),

      // Content Detail Screen
      GoRoute(
        path: AppRoute.contentDetail,
        name: AppRoute.contentDetailName,
        pageBuilder: (context, state) {
          final contentId = state.pathParameters['id']!;
          return AppAnimations.animatedPageBuilder(
            context,
            state,
            DetailScreen(contentId: contentId),
            type: RouteTransitionType.fadeSlide,
          );
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
          final forceStartFromBeginning =
              state.uri.queryParameters['forceStartFromBeginning'] == 'true';

          // Extract content and imageMetadata from extra
          Content? content;
          List<ImageMetadata>? imageMetadata;
          if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            content = extra['content'] as Content?;
            imageMetadata = extra['imageMetadata'] as List<ImageMetadata>?;
          } else {
            // Backward compatibility: if extra is Content directly
            content = state.extra as Content?;
          }

          return ReaderScreen(
            contentId: contentId,
            initialPage: page,
            forceStartFromBeginning: forceStartFromBeginning,
            preloadedContent: content,
            imageMetadata: imageMetadata,
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
        pageBuilder: (context, state) => AppAnimations.animatedPageBuilder(
          context,
          state,
          const HistoryScreen(),
          type: RouteTransitionType.slideUp,
        ),
      ),

      // Settings Screen
      GoRoute(
        path: AppRoute.settings,
        name: AppRoute.settingsName,
        pageBuilder: (context, state) => AppAnimations.animatedPageBuilder(
          context,
          state,
          const SettingsScreen(),
          type: RouteTransitionType.fade,
        ),
      ),

      // Tags Screen
      GoRoute(
        path: AppRoute.tags,
        name: AppRoute.tagsName,
        builder: (context, state) => Scaffold(
          body: Center(
              child: Text(AppLocalizations.of(context)!.tagsScreenPlaceholder)),
        ),
      ),

      // Artists Screen
      GoRoute(
        path: AppRoute.artists,
        name: AppRoute.artistsName,
        builder: (context, state) => Scaffold(
          body: Center(
              child:
                  Text(AppLocalizations.of(context)!.artistsScreenPlaceholder)),
        ),
      ),

      // Random Screen
      GoRoute(
        path: AppRoute.random,
        name: AppRoute.randomName,
        pageBuilder: (context, state) => AppAnimations.animatedPageBuilder(
          context,
          state,
          const RandomGalleryScreen(),
          type: RouteTransitionType.fadeSlide,
        ),
      ),

      // Status Screen
      GoRoute(
        path: AppRoute.status,
        name: AppRoute.statusName,
        builder: (context, state) => Scaffold(
          body: Center(
              child:
                  Text(AppLocalizations.of(context)!.statusScreenPlaceholder)),
        ),
      ),

      // About Screen
      GoRoute(
        path: AppRoute.about,
        name: AppRoute.aboutName,
        pageBuilder: (context, state) => AppAnimations.animatedPageBuilder(
          context,
          state,
          const AboutScreen(),
          type: RouteTransitionType.fadeSlide,
        ),
      ),

      // Legacy Main Screen route for backward compatibility
      GoRoute(
        path: AppRoute.main,
        name: AppRoute.mainName,
        builder: (context, state) => const MainScreenScrollable(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.pageNotFound)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!
                  .pageNotFoundWithUri(state.uri.toString()),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoute.home),
              child: Text(AppLocalizations.of(context)!.goHome),
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

  static void goToContentByTag(BuildContext context, String tagQuery) {
    context.push('${AppRoute.contentByTag}?q=$tagQuery');
  }

  static Future<SearchFilter?> goToContentDetail(
      BuildContext context, String contentId) async {
    return await context.push<SearchFilter>('/content/$contentId');
  }

  static void goToReader(BuildContext context, String contentId,
      {int page = 1,
      bool forceStartFromBeginning = false,
      Content? content,
      List<ImageMetadata>? imageMetadata}) {
    context.push(
        '/reader/$contentId?page=$page&forceStartFromBeginning=$forceStartFromBeginning',
        extra: {'content': content, 'imageMetadata': imageMetadata});
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

  static void goToAbout(BuildContext context) {
    context.go(AppRoute.about);
  }

  static Future<List<FilterItem>?> goToFilterData(
    BuildContext context, {
    required String filterType,
    required List<FilterItem> selectedFilters,
    bool hideOtherTabs = false,
  }) async {
    try {
      final result = await context.push<List<FilterItem>>(
        '${AppRoute.filterData}?type=$filterType&hideOtherTabs=$hideOtherTabs',
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
