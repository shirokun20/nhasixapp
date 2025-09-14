# Scraping Feature Design Document

## Overview
This document outlines the design decisions, user experience, and architectural patterns for the web scraping feature in NhasixApp.

## Design Principles

### Core Principles
1. **User-Centric**: Prioritize user experience with intuitive interfaces
2. **Performance-First**: Optimize for speed and efficiency
3. **Privacy-Aware**: Respect user privacy and content sensitivity
4. **Scalable**: Design for future expansion and maintenance
5. **Accessible**: Ensure usability for all users

### Design Philosophy
- **Minimalist UI**: Clean, uncluttered interface focusing on content
- **Progressive Disclosure**: Show complexity only when needed
- **Consistent Patterns**: Follow Material Design 3 guidelines
- **Responsive Design**: Adapt to different screen sizes and orientations

## User Experience Design

### User Journey Map

#### Primary User Journey: Content Discovery
1. **Entry Point**: User opens app and navigates to scraping section
2. **Search Initiation**: User enters keywords or selects categories
3. **Source Selection**: User chooses which websites to search (optional)
4. **Results Browsing**: User scrolls through thumbnail grid
5. **Content Selection**: User taps on interesting content
6. **Detail Viewing**: User views full content with image gallery
7. **Download Decision**: User initiates download for offline viewing
8. **Download Management**: User monitors progress and manages downloads

#### Secondary Journeys
- **Settings Configuration**: User customizes scraping preferences
- **Offline Browsing**: User accesses previously downloaded content
- **Search History**: User reviews and reuses previous searches

### User Personas

#### Content Explorer
- **Profile**: Casual user browsing for entertainment
- **Needs**: Quick search, easy navigation, offline access
- **Pain Points**: Slow loading, complex interfaces, limited storage

#### Power User
- **Profile**: Advanced user with specific content preferences
- **Needs**: Advanced filters, batch operations, detailed metadata
- **Pain Points**: Lack of customization, limited search options

#### Collector
- **Profile**: User building personal content library
- **Needs**: Bulk downloads, organization, storage management
- **Pain Points**: Download interruptions, storage limits, content organization

## Interface Design

### Color Scheme
```dart
class ScrapingTheme {
  static const Color primary = Color(0xFF6750A4);
  static const Color secondary = Color(0xFF958DA5);
  static const Color tertiary = Color(0xFFB58392);
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF146C2E);
  static const Color warning = Color(0xFF7D5800);

  static const Color surface = Color(0xFFFEF7FF);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color background = Color(0xFFFEF7FF);
}
```

### Typography Scale
- **Display Large**: 57px/64px - Page titles
- **Display Medium**: 45px/52px - Section headers
- **Headline Large**: 32px/40px - Content titles
- **Headline Medium**: 28px/36px - Card titles
- **Title Large**: 22px/28px - Dialog titles
- **Body Large**: 16px/24px - Primary content
- **Body Medium**: 14px/20px - Secondary content
- **Label Large**: 14px/20px - Buttons, input labels

### Component Library

#### Search Input Component
```dart
class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final Function() onClear;
  final bool showSuggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search content...',
            prefixIcon: Icon(Icons.search),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: onClear,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        if (showSuggestions) _buildSuggestions(),
      ],
    );
  }
}
```

#### Content Card Component
```dart
class ContentCard extends StatelessWidget {
  final ScrapedContent content;
  final Function() onTap;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3/4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: content.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => ShimmerPlaceholder(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                  if (isDownloaded)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.download_done,
                        color: ScrapingTheme.success,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    content.source.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ScrapingTheme.secondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: content.tags.take(3).map((tag) =>
                      Chip(
                        label: Text(
                          tag,
                          style: TextStyle(fontSize: 10),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Image Viewer Component
```dart
class ImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final Function(int) onPageChanged;

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${widget.imageUrls.length}'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _downloadCurrentImage,
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareCurrentImage,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          widget.onPageChanged(index);
        },
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrls[index],
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(Icons.error, size: 48),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: _currentIndex > 0
                ? () => _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.imageUrls.length,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _currentIndex < widget.imageUrls.length - 1
                ? () => _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}
```

## Screen Flow Diagrams

### Main Navigation Flow
```
Home Screen
    │
    ├── Settings → Scraping Settings
    │       ├── Source Selection
    │       ├── Rate Limits
    │       └── Storage Settings
    │
    └── Scraping Section
        │
        ├── Search Screen
        │   ├── Input & Filters
        │   ├── Results Grid
        │   └── Content Detail
        │       ├── Image Viewer
        │       └── Download Options
        │
        └── Downloads Screen
            ├── Active Downloads
            ├── Completed Downloads
            └── Download History
```

### Search Flow
```
Search Input
    │
    ├── Keyword Entry
    │   ├── Real-time Suggestions
    │   └── Search History
    │
    ├── Filter Application
    │   ├── Source Selection
    │   ├── Tag Filters
    │   └── Date Range
    │
    └── Results Display
        ├── Loading State
        ├── Results Grid
        │   ├── Pagination
        │   └── Infinite Scroll
        └── Empty State
```

## State Management Design

### Bloc Architecture Pattern
```
UI Layer (Widgets)
    │
    ├── Events (User Actions)
    │   ├── SearchContentEvent
    │   ├── LoadMoreEvent
    │   ├── DownloadContentEvent
    │   └── SettingsUpdateEvent
    │
    Bloc Layer (Business Logic)
    │
    ├── States (UI States)
    │   ├── SearchInitial
    │   ├── SearchLoading
    │   ├── SearchLoaded
    │   ├── SearchError
    │   └── SearchEmpty
    │
    Use Case Layer (Application Logic)
        │
        ├── SearchContentUseCase
        ├── DownloadContentUseCase
        └── GetSettingsUseCase
            │
            Repository Layer (Data Access)
                │
                ├── ScrapingRepository
                │   ├── EHentaiDataSource
                │   ├── HitomiDataSource
                │   └── PixHentaiDataSource
                │
                └── LocalRepository
                    ├── ContentCache
                    ├── DownloadQueue
                    └── SettingsStorage
```

### State Flow Example
```dart
// Search Bloc State Flow
enum SearchStatus {
  initial,
  loading,
  loaded,
  error,
  empty,
}

class SearchState {
  final SearchStatus status;
  final List<ScrapedContent> contents;
  final bool hasMore;
  final String? errorMessage;
  final SearchQuery? lastQuery;

  const SearchState({
    this.status = SearchStatus.initial,
    this.contents = const [],
    this.hasMore = false,
    this.errorMessage,
    this.lastQuery,
  });

  SearchState copyWith({
    SearchStatus? status,
    List<ScrapedContent>? contents,
    bool? hasMore,
    String? errorMessage,
    SearchQuery? lastQuery,
  }) {
    return SearchState(
      status: status ?? this.status,
      contents: contents ?? this.contents,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
      lastQuery: lastQuery ?? this.lastQuery,
    );
  }
}
```

## Data Flow Architecture

### Search Data Flow
```
User Input
    │
    ↓ (SearchEvent)
Bloc (SearchBloc)
    │
    ↓ (SearchContentUseCase)
Repository (ScrapingRepository)
    │
    ├── EHentai Scraper
    │   ├── HTTP Request
    │   ├── HTML Parsing
    │   └── Data Extraction
    │
    ├── Hitomi Scraper
    │   ├── HTTP Request
    │   ├── HTML Parsing
    │   └── Data Extraction
    │
    └── PixHentai Scraper
        ├── HTTP Request
        ├── HTML Parsing
        └── Data Extraction
    │
    ↓ (List<ScrapedContent>)
Bloc (SearchBloc)
    │
    ↓ (SearchLoaded State)
UI (Search Results)
```

### Download Data Flow
```
Download Request
    │
    ↓ (DownloadEvent)
Bloc (DownloadBloc)
    │
    ↓ (DownloadContentUseCase)
Repository (DownloadRepository)
    │
    ├── Queue Management
    │   ├── Task Creation
    │   └── Priority Handling
    │
    ├── File Download
    │   ├── HTTP Requests
    │   ├── Progress Tracking
    │   └── Error Handling
    │
    └── Storage Management
        ├── Cache Directory
        ├── File Organization
        └── Size Limits
    │
    ↓ (DownloadTask Updates)
Bloc (DownloadBloc)
    │
    ↓ (DownloadProgress State)
UI (Progress Indicators)
```

## Error Handling Design

### Error States and Recovery
```dart
class ErrorState {
  final String title;
  final String message;
  final String? actionLabel;
  final Function()? action;
  final IconData icon;

  const ErrorState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.action,
    this.icon = Icons.error,
  });
}

// Predefined error states
class ErrorStates {
  static const networkError = ErrorState(
    title: 'Connection Error',
    message: 'Unable to connect to the server. Please check your internet connection.',
    actionLabel: 'Retry',
    icon: Icons.wifi_off,
  );

  static const parsingError = ErrorState(
    title: 'Content Error',
    message: 'Unable to process the content. The website structure may have changed.',
    actionLabel: 'Report Issue',
    icon: Icons.bug_report,
  );

  static const rateLimitError = ErrorState(
    title: 'Too Many Requests',
    message: 'Please wait a moment before trying again.',
    icon: Icons.timer,
  );
}
```

### Error Boundary Widget
```dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Function(Object error, StackTrace stack)? onError;

  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  ErrorState? _errorState;

  @override
  void initState() {
    super.initState();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
      return Container(); // Return empty container, error handled below
    };
  }

  void _handleError(Object error, StackTrace? stack) {
    setState(() {
      _errorState = _mapErrorToState(error);
    });
    widget.onError?.call(error, stack ?? StackTrace.empty);
  }

  @override
  Widget build(BuildContext context) {
    if (_errorState != null) {
      return ErrorView(errorState: _errorState!);
    }
    return widget.child;
  }
}
```

## Performance Optimization

### Image Loading Strategy
```dart
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width != null ? (width * MediaQuery.of(context).devicePixelRatio).round() : null,
      memCacheHeight: height != null ? (height * MediaQuery.of(context).devicePixelRatio).round() : null,
      placeholder: (context, url) => ShimmerPlaceholder(),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(
          Icons.image_not_supported,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
```

### List Virtualization
```dart
class VirtualizedGrid extends StatelessWidget {
  final List<ScrapedContent> contents;
  final Function(ScrapedContent) onItemTap;

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.builder(
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _calculateCrossAxisCount(context),
      ),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        return ContentCard(
          content: contents[index],
          onTap: () => onItemTap(contents[index]),
        );
      },
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: EdgeInsets.all(16),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }
}
```

## Accessibility Design

### Screen Reader Support
- All interactive elements have proper labels
- Image alt texts for thumbnails
- Progress indicators announce current status
- Error messages are descriptive and actionable

### Keyboard Navigation
- Tab order follows logical content flow
- Enter/Space activates buttons
- Arrow keys navigate image galleries
- Escape closes modals and dialogs

### High Contrast Support
- All text meets WCAG AA contrast ratios
- Icons have sufficient contrast
- Error states use high-contrast colors
- Focus indicators are clearly visible

## Responsive Design

### Breakpoint System
```dart
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}
```

### Adaptive Layouts
```dart
class AdaptiveSearchLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
        actions: ResponsiveBreakpoints.isDesktop(context)
            ? _buildDesktopActions()
            : null,
      ),
      body: Row(
        children: [
          if (ResponsiveBreakpoints.isDesktop(context))
            _buildDesktopSidebar(),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
      drawer: ResponsiveBreakpoints.isMobile(context)
          ? _buildMobileDrawer()
          : null,
    );
  }
}
```

## Animation and Transitions

### Page Transitions
```dart
class ScrapingPageRoute extends MaterialPageRoute {
  ScrapingPageRoute({required WidgetBuilder builder})
      : super(builder: builder);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}
```

### Loading Animations
```dart
class ShimmerPlaceholder extends StatefulWidget {
  @override
  _ShimmerPlaceholderState createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ).createShader(rect);
          },
          child: Container(
            color: Colors.grey[300],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Theme and Branding

### Light Theme
```dart
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ScrapingTheme.primary,
    brightness: Brightness.light,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: ScrapingTheme.primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    filled: true,
    fillColor: ScrapingTheme.surfaceVariant,
  ),
);
```

### Dark Theme
```dart
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ScrapingTheme.primary,
    brightness: Brightness.dark,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: ScrapingTheme.surface,
    foregroundColor: ScrapingTheme.onSurface,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: ScrapingTheme.surface,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    filled: true,
    fillColor: ScrapingTheme.surfaceVariant,
  ),
);
```

## Source-Specific Design Considerations

### e-hentai.org Advanced Features
- **Filter Integration**: Reuse existing `FilterDataScreen` component with full tabbed interface
- **Complex Filtering**: Support for include/exclude logic, multiple filter types
- **Tag Namespaces**: Visual distinction for different tag types (f:, m:, character:, etc.)
- **Filter State Management**: Persistent filter states with validation

### Other Sources Simplified Design
- **hitomi.la**: Simple tag selection from dropdown or chips
- **pixhentai.com**: Category-based filtering with basic tag support
- **Unified Simple UI**: Use consistent simple filter interface across non-e-hentai sources

### Adaptive UI Components
```dart
class AdaptiveFilterWidget extends StatelessWidget {
  final String selectedSource;

  @override
  Widget build(BuildContext context) {
    if (selectedSource == 'ehentai') {
      return ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/filter-data'),
        child: Text('Advanced Filters'),
      );
    } else {
      return SimpleFilterChips(
        availableTags: getAvailableTagsForSource(selectedSource),
        onTagSelected: (tag) => applySimpleFilter(tag),
      );
    }
  }
}
```

### Scalability
- Component library expansion
- Design system documentation
- Automated testing for UI consistency

### Extensibility
- Plugin architecture for new scrapers
- Theme customization options
- Third-party integration points

### Maintenance
- Design debt tracking
- User feedback integration
- A/B testing framework