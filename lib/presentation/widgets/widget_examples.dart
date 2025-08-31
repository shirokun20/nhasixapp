import 'package:flutter/material.dart';

import '../../core/constants/text_style_const.dart';
import '../../domain/entities/content.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/entities/tag.dart';
import 'widgets.dart';

/// Example usage of the reusable widgets
class WidgetExamplesScreen extends StatefulWidget {
  const WidgetExamplesScreen({super.key});

  @override
  State<WidgetExamplesScreen> createState() => _WidgetExamplesScreenState();
}

class _WidgetExamplesScreenState extends State<WidgetExamplesScreen> {
  SearchFilter _currentFilter = const SearchFilter();
  bool _isLoading = false;

  // Sample content for demonstration
  final Content _sampleContent = Content(
    id: '123456',
    title: 'Sample Manga Title',
    englishTitle: 'Sample English Title',
    japaneseTitle: 'サンプル日本語タイトル',
    coverUrl: 'https://example.com/cover.jpg',
    tags: [
      const Tag(id: 1, name: 'romance', type: 'tag', count: 1000, url: ''),
      const Tag(id: 2, name: 'comedy', type: 'tag', count: 500, url: ''),
      const Tag(id: 3, name: 'school', type: 'tag', count: 300, url: ''),
    ],
    artists: ['Artist Name'],
    characters: ['Character 1', 'Character 2'],
    parodies: ['Original Work'],
    groups: ['Group Name'],
    language: 'english',
    pageCount: 24,
    imageUrls: [],
    uploadDate: DateTime.now().subtract(const Duration(days: 7)),
    favorites: 1500,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Widget Examples',
          style: TextStyleConst.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ContentCard Examples
            _buildSection(
              'Content Cards',
              Column(
                children: [
                  // Standard content card (main screen style - no upload date)
                  SizedBox(
                    width: 200,
                    child: ContentCard(
                      content: _sampleContent,
                      onTap: () => _showSnackBar('Content tapped'),
                      showFavoriteButton: true,
                      isFavorite: false,
                      onFavoriteToggle: () => _showSnackBar('Favorite toggled'),
                      showPageCount: true,
                      showLanguageFlag: true,
                      showUploadDate: false, // Main screen style
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Content card with upload date (search/browse style)
                  SizedBox(
                    width: 200,
                    child: ContentCard(
                      content: _sampleContent,
                      onTap: () => _showSnackBar('Content with date tapped'),
                      showFavoriteButton: true,
                      isFavorite: true,
                      onFavoriteToggle: () => _showSnackBar('Favorite toggled'),
                      showPageCount: true,
                      showLanguageFlag: true,
                      showUploadDate: true, // Search/browse style
                      showTags: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Compact content card
                  CompactContentCard(
                    content: _sampleContent,
                    onTap: () => _showSnackBar('Compact card tapped'),
                    showFavoriteButton: true,
                    isFavorite: true,
                    onFavoriteToggle: () =>
                        _showSnackBar('Compact favorite toggled'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Search Filter Example
            _buildSection(
              'Search Filter',
              SearchFilterWidget(
                filter: _currentFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _currentFilter = filter;
                  });
                  _showSnackBar(
                      'Filter updated: ${filter.activeFilterCount} active');
                },
                popularTags: const [
                  'romance',
                  'comedy',
                  'school',
                  'fantasy',
                  'action',
                ],
                recentSearches: const [
                  'romance manga',
                  'school comedy',
                  'fantasy adventure',
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Progress Indicators
            _buildSection(
              'Progress Indicators',
              Column(
                children: [
                  // Circular progress
                  const AppProgressIndicator(
                    message: 'Loading content...',
                    size: 32,
                  ),

                  const SizedBox(height: 16),

                  // Linear progress
                  const AppLinearProgressIndicator(
                    value: 0.65,
                    message: 'Download progress',
                    showPercentage: true,
                  ),

                  const SizedBox(height: 16),

                  // Pulsing dots
                  const PulsingDotIndicator(
                    dotCount: 3,
                  ),

                  const SizedBox(height: 16),

                  // Shimmer loading
                  SizedBox(
                    width: 200,
                    height: 100,
                    child: ContentCardShimmer(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Error Widgets
            _buildSection(
              'Error Widgets',
              Column(
                children: [
                  // Network error
                  SizedBox(
                    height: 300,
                    child: NetworkErrorWidget(
                      onRetry: () => _showSnackBar('Retry network'),
                      onGoOffline: () => _showSnackBar('Go offline'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Empty state
                  SizedBox(
                    height: 250,
                    child: NoSearchResultsWidget(
                      query: 'sample query',
                      onClearFilters: () => _showSnackBar('Clear filters'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Pagination Widget
            _buildSection(
              'Pagination',
              PaginationWidget(
                currentPage: 5,
                totalPages: 100,
                hasNext: true,
                hasPrevious: true,
                onNextPage: () => _showSnackBar('Next page'),
                onPreviousPage: () => _showSnackBar('Previous page'),
                onGoToPage: (page) => _showSnackBar('Go to page $page'),
                showProgressBar: true,
                showPercentage: true,
                showPageInput: true,
              ),
            ),

            const SizedBox(height: 32),

            // Loading Overlay Example
            _buildSection(
              'Loading Overlay',
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _toggleLoading,
                    child: Text(_isLoading ? 'Hide Loading' : 'Show Loading'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LoadingOverlay(
                      isLoading: _isLoading,
                      message: 'Processing request...',
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Content behind overlay',
                            style: TextStyleConst.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyleConst.headingMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleLoading() {
    setState(() {
      _isLoading = !_isLoading;
    });
  }
}
