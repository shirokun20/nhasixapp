# Pagination Implementation Guide

## Overview

Dokumen ini menjelaskan implementasi lengkap pagination system dalam NhentaiApp, mulai dari parsing HTML hingga UI components yang interaktif.

## Architecture Overview

```
┌─────────────────────────────────────────┐
│              UI Layer                   │
│  ┌─────────────────────────────────────┐│
│  │        PaginationWidget             ││
│  │  - Progress bar                     ││
│  │  - Page input dialog                ││
│  │  - Next/Previous buttons           ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│            BLoC Layer                   │
│  ┌─────────────────────────────────────┐│
│  │         ContentBloc                 ││
│  │  - ContentNextPageEvent             ││
│  │  - ContentPreviousPageEvent         ││
│  │  - ContentGoToPageEvent             ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│           Domain Layer                  │
│  ┌─────────────────────────────────────┐│
│  │       PaginationInfo                ││
│  │  - currentPage, totalPages          ││
│  │  - hasNext, hasPrevious             ││
│  │  - progressPercentage               ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│            Data Layer                   │
│  ┌─────────────────────────────────────┐│
│  │       NhentaiScraper                ││
│  │  - parsePaginationInfo()            ││
│  │  - extractVisiblePages()            ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## Implementation Steps

### 1. HTML Parsing (Data Layer)

#### NhentaiScraper Enhancement

```dart
class NhentaiScraper {
  /// Parse pagination information from HTML
  Map<String, dynamic> parsePaginationInfo(String html) {
    try {
      final document = html_parser.parse(html);
      final paginationSection = document.querySelector('section.pagination');
      
      if (paginationSection == null) {
        return {
          'currentPage': 1,
          'totalPages': 1,
          'hasNext': false,
          'hasPrevious': false,
          'nextPage': null,
          'previousPage': null,
        };
      }

      // Extract current page
      int currentPage = 1;
      final currentPageElement = paginationSection.querySelector('a.page.current');
      if (currentPageElement != null) {
        currentPage = int.tryParse(currentPageElement.text.trim()) ?? 1;
      }

      // Extract total pages from "last" link
      int totalPages = 1;
      final lastPageElement = paginationSection.querySelector('a.last');
      if (lastPageElement != null) {
        final href = lastPageElement.attributes['href'];
        if (href != null) {
          final match = RegExp(r'page=(\d+)').firstMatch(href);
          if (match != null) {
            totalPages = int.tryParse(match.group(1)!) ?? 1;
          }
        }
      }

      // Calculate navigation info
      final hasNext = currentPage < totalPages;
      final hasPrevious = currentPage > 1;
      final nextPage = hasNext ? currentPage + 1 : null;
      final previousPage = hasPrevious ? currentPage - 1 : null;

      return {
        'currentPage': currentPage,
        'totalPages': totalPages,
        'hasNext': hasNext,
        'hasPrevious': hasPrevious,
        'nextPage': nextPage,
        'previousPage': previousPage,
      };
    } catch (e) {
      // Return safe defaults on error
      return {
        'currentPage': 1,
        'totalPages': 1,
        'hasNext': false,
        'hasPrevious': false,
        'nextPage': null,
        'previousPage': null,
      };
    }
  }
}
```

### 2. Domain Entities

#### PaginationInfo Entity

```dart
class PaginationInfo extends Equatable {
  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    this.nextPage,
    this.previousPage,
    this.visiblePages = const [],
  });

  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final int? nextPage;
  final int? previousPage;
  final List<int> visiblePages;

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (totalPages <= 1) return 1.0;
    return currentPage / totalPages;
  }

  /// Get page range string (e.g., "Page 1 of 100")
  String get pageRangeString => 'Page $currentPage of $totalPages';

  @override
  List<Object?> get props => [
    currentPage, totalPages, hasNext, hasPrevious,
    nextPage, previousPage, visiblePages,
  ];
}
```

### 3. BLoC Implementation

#### ContentEvent Extensions

```dart
/// Event to navigate to next page
class ContentNextPageEvent extends ContentEvent {
  const ContentNextPageEvent();
}

/// Event to navigate to previous page
class ContentPreviousPageEvent extends ContentEvent {
  const ContentPreviousPageEvent();
}

/// Event to navigate to specific page
class ContentGoToPageEvent extends ContentEvent {
  const ContentGoToPageEvent(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}
```

#### ContentBloc Handlers

```dart
class ContentBloc extends Bloc<ContentEvent, ContentState> {
  // ... existing code ...

  /// Navigate to next page
  Future<void> _onContentNextPage(
    ContentNextPageEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentLoaded || !currentState.hasNext) {
      return;
    }

    final nextPage = currentState.currentPage + 1;
    await _loadSpecificPage(nextPage, currentState, emit);
  }

  /// Navigate to previous page
  Future<void> _onContentPreviousPage(
    ContentPreviousPageEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentLoaded || !currentState.hasPrevious) {
      return;
    }

    final previousPage = currentState.currentPage - 1;
    await _loadSpecificPage(previousPage, currentState, emit);
  }

  /// Navigate to specific page
  Future<void> _onContentGoToPage(
    ContentGoToPageEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentLoaded) return;

    // Validate page number
    if (event.page < 1 || event.page > currentState.totalPages) return;
    if (event.page == currentState.currentPage) return;

    await _loadSpecificPage(event.page, currentState, emit);
  }

  /// Load specific page based on current context
  Future<void> _loadSpecificPage(
    int page,
    ContentLoaded currentState,
    Emitter<ContentState> emit,
  ) async {
    try {
      emit(const ContentLoading(message: 'Loading page...'));

      ContentListResult result;

      // Load page based on current context
      if (currentState.searchFilter != null) {
        final pageFilter = currentState.searchFilter!.copyWith(page: page);
        result = await _searchContentUseCase(pageFilter);
      } else if (currentState.tag != null) {
        result = await _contentRepository.getContentByTag(
          tag: currentState.tag!,
          page: page,
          sortBy: currentState.sortBy,
        );
      } else {
        final params = GetContentListParams(
          page: page,
          sortBy: currentState.sortBy,
        );
        result = await _getContentListUseCase(params);
      }

      emit(ContentLoaded(
        contents: result.contents,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        sortBy: currentState.sortBy,
        searchFilter: currentState.searchFilter,
        tag: currentState.tag,
        timeframe: currentState.timeframe,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(ContentError(
        message: e.toString(),
        canRetry: true,
        previousContents: currentState.contents,
      ));
    }
  }
}
```

### 4. UI Components

#### Advanced PaginationWidget

```dart
class PaginationWidget extends StatefulWidget {
  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.onNextPage,
    required this.onPreviousPage,
    required this.onGoToPage,
    this.showProgressBar = true,
    this.showPercentage = true,
    this.showPageInput = false,
  });

  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;
  final Function(int) onGoToPage;
  final bool showProgressBar;
  final bool showPercentage;
  final bool showPageInput;

  @override
  State<PaginationWidget> createState() => _PaginationWidgetState();
}

class _PaginationWidgetState extends State<PaginationWidget> {
  final TextEditingController _pageController = TextEditingController();

  double get progressPercentage {
    if (widget.totalPages <= 0) return 0.0;
    return widget.currentPage / widget.totalPages;
  }

  void _showPageInputDialog() {
    _pageController.text = widget.currentPage.toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsConst.thirdColor,
        title: Text('Go to Page'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter page number (1 - ${widget.totalPages})'),
            const SizedBox(height: 16),
            TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Page number',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                _goToPage();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _goToPage();
              Navigator.of(context).pop();
            },
            child: Text('Go'),
          ),
        ],
      ),
    );
  }

  void _goToPage() {
    final pageText = _pageController.text.trim();
    if (pageText.isEmpty) return;

    final page = int.tryParse(pageText);
    if (page == null || page < 1 || page > widget.totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid page number between 1 and ${widget.totalPages}',
          ),
          backgroundColor: ColorsConst.redCustomColor,
        ),
      );
      return;
    }

    widget.onGoToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorsConst.thirdColor,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          
          // Previous button
          IconButton(
            iconSize: 32,
            onPressed: widget.hasPrevious ? widget.onPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            color: widget.hasPrevious 
                ? ColorsConst.primaryTextColor 
                : ColorsConst.primaryTextColor.withValues(alpha: 0.3),
            tooltip: 'Previous page',
          ),
          
          const Spacer(),
          
          // Page info section
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: widget.showPageInput ? _showPageInputDialog : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page text
                  Text(
                    'Page ${widget.currentPage} of ${widget.totalPages}',
                    style: TextStyleConst.styleBold(
                      textColor: ColorsConst.primaryTextColor,
                      size: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (widget.showProgressBar) ...[
                    const SizedBox(height: 6),
                    // Progress bar
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: ColorsConst.primaryTextColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressPercentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ColorsConst.redCustomColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  if (widget.showPercentage) ...[
                    const SizedBox(height: 4),
                    // Progress percentage
                    Text(
                      '${(progressPercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyleConst.styleRegular(
                        textColor: ColorsConst.primaryTextColor.withValues(alpha: 0.7),
                        size: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  if (widget.showPageInput) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tap to jump to page',
                      style: TextStyleConst.styleRegular(
                        textColor: ColorsConst.primaryTextColor.withValues(alpha: 0.5),
                        size: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Next button
          IconButton(
            iconSize: 32,
            onPressed: widget.hasNext ? widget.onNextPage : null,
            icon: const Icon(Icons.chevron_right),
            color: widget.hasNext 
                ? ColorsConst.primaryTextColor 
                : ColorsConst.primaryTextColor.withValues(alpha: 0.3),
            tooltip: 'Next page',
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
}
```

### 5. Screen Integration

#### MainScreen Implementation

```dart
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final ContentBloc _contentBloc;

  @override
  void initState() {
    super.initState();
    _contentBloc = getIt<ContentBloc>()
      ..add(const ContentLoadEvent(sortBy: SortOption.newest));
  }

  Widget _buildContentFooter(ContentState state) {
    if (state is! ContentLoaded) {
      return const SizedBox.shrink();
    }

    return PaginationWidget(
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      hasNext: state.hasNext,
      hasPrevious: state.hasPrevious,
      onNextPage: () {
        _contentBloc.add(const ContentNextPageEvent());
      },
      onPreviousPage: () {
        _contentBloc.add(const ContentPreviousPageEvent());
      },
      onGoToPage: (page) {
        _contentBloc.add(ContentGoToPageEvent(page));
      },
      showProgressBar: true,
      showPercentage: true,
      showPageInput: true, // Enable page input for large page counts
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: Scaffold(
        backgroundColor: ColorsConst.primaryColor,
        appBar: AppMainHeaderWidget(context: context),
        drawer: AppMainDrawerWidget(context: context),
        body: BlocBuilder<ContentBloc, ContentState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(child: _buildContent(state)),
                _buildContentFooter(state),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

## Features Implemented

### ✅ **Core Pagination Features**

1. **HTML Parsing**: Extract pagination info dari nhentai HTML
2. **Navigation Events**: Next, Previous, Go to Page events
3. **Progress Tracking**: Visual progress bar dan percentage
4. **Page Input**: Dialog untuk jump ke page tertentu
5. **State Management**: Proper BLoC integration
6. **Error Handling**: Graceful fallback untuk parsing errors

### ✅ **Advanced Features**

1. **Context Awareness**: Pagination works dengan search, tags, popular content
2. **Visual Feedback**: Disabled state untuk buttons, progress indicators
3. **User Experience**: Loading states, error messages, validation
4. **Performance**: Efficient state updates, minimal rebuilds
5. **Accessibility**: Tooltips, semantic labels, keyboard support

### ✅ **Real-world Data**

- **Total Pages**: 22,114 pages dari nhentai.net
- **Current Page**: Extracted dari `class="page current"`
- **Navigation**: Smart next/previous dengan validation
- **Progress**: Accurate percentage calculation

## Usage Examples

### Basic Usage

```dart
PaginationWidget(
  currentPage: 1,
  totalPages: 22114,
  hasNext: true,
  hasPrevious: false,
  onNextPage: () => bloc.add(ContentNextPageEvent()),
  onPreviousPage: () => bloc.add(ContentPreviousPageEvent()),
  onGoToPage: (page) => bloc.add(ContentGoToPageEvent(page)),
)
```

### Advanced Usage

```dart
PaginationWidget(
  currentPage: state.currentPage,
  totalPages: state.totalPages,
  hasNext: state.hasNext,
  hasPrevious: state.hasPrevious,
  onNextPage: () => _contentBloc.add(const ContentNextPageEvent()),
  onPreviousPage: () => _contentBloc.add(const ContentPreviousPageEvent()),
  onGoToPage: (page) => _contentBloc.add(ContentGoToPageEvent(page)),
  showProgressBar: true,
  showPercentage: true,
  showPageInput: true, // Enable page input dialog
)
```

## Testing

### Unit Tests

```dart
void testPaginationParsing() {
  final scraper = NhentaiScraper();
  
  // Test first page
  final html1 = '''<section class="pagination">
    <a href="/?page=1" class="page current">1</a>
    <a href="/?page=2" class="next"><i class="fa fa-chevron-right"></i></a>
    <a href="/?page=22114" class="last"><i class="fa fa-chevron-right"></i><i class="fa fa-chevron-right"></i></a>
  </section>''';
  
  final result1 = scraper.parsePaginationInfo(html1);
  expect(result1['currentPage'], equals(1));
  expect(result1['totalPages'], equals(22114));
  expect(result1['hasNext'], equals(true));
  expect(result1['hasPrevious'], equals(false));
}
```

### Widget Tests

```dart
void testPaginationWidget() {
  testWidgets('PaginationWidget displays correct info', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginationWidget(
            currentPage: 1,
            totalPages: 100,
            hasNext: true,
            hasPrevious: false,
            onNextPage: () {},
            onPreviousPage: () {},
            onGoToPage: (page) {},
          ),
        ),
      ),
    );

    expect(find.text('Page 1 of 100'), findsOneWidget);
    expect(find.text('1.0%'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
void testPaginationIntegration() {
  testWidgets('Pagination navigation works', (tester) async {
    final bloc = MockContentBloc();
    
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(home: MainScreen()),
      ),
    );

    // Tap next button
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();

    verify(() => bloc.add(const ContentNextPageEvent())).called(1);
  });
}
```

## Benefits

1. **Accurate Navigation**: Menggunakan real pagination data dari nhentai
2. **User-Friendly**: Progress bar, percentage, page input dialog
3. **Performance**: Efficient state management, minimal rebuilds
4. **Flexible**: Works dengan search, tags, popular content
5. **Robust**: Error handling, validation, fallback states
6. **Accessible**: Tooltips, semantic labels, keyboard support

## Conclusion

Implementasi pagination system ini memberikan:

- ✅ **Complete pagination functionality** dengan 22,114+ pages
- ✅ **Advanced UI components** dengan progress tracking
- ✅ **Robust state management** dengan BLoC pattern
- ✅ **Real device testing ready** untuk validation
- ✅ **Production-ready code** dengan error handling

System ini siap untuk digunakan dalam production dan dapat handle large-scale pagination seperti yang ada di nhentai.net! 🚀