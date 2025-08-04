# Pagination Parsing Example

## Overview

Dokumen ini menjelaskan cara menggunakan pagination parsing yang telah diimplementasikan dalam NhentaiScraper untuk mengextract informasi pagination dari HTML nhentai.net.

## HTML Structure Analysis

Dari HTML yang diberikan, struktur pagination nhentai adalah:

```html
<section class="pagination">
    <a href="/?page=1" class="page current">1</a>
    <a href="/?page=2" class="page">2</a>
    <a href="/?page=3" class="page">3</a>
    <a href="/?page=4" class="page">4</a>
    <a href="/?page=5" class="page">5</a>
    <a href="/?page=6" class="page">6</a>
    <a href="/?page=2" class="next">
        <i class="fa fa-chevron-right"></i>
    </a>
    <a href="/?page=22114" class="last">
        <i class="fa fa-chevron-right"></i>
        <i class="fa fa-chevron-right"></i>
    </a>
</section>
```

## Key Information Extracted

1. **Current Page**: `class="page current"` → Page 1
2. **Total Pages**: `class="last"` href → Page 22114
3. **Next Page**: `class="next"` href → Page 2
4. **Visible Pages**: [1, 2, 3, 4, 5, 6]
5. **Has Next**: true (current < total)
6. **Has Previous**: false (current = 1)

## Usage Example

### 1. Basic Pagination Parsing

```dart
import 'package:nhasixapp/data/datasources/remote/nhentai_scraper.dart';
import 'package:nhasixapp/data/models/pagination_model.dart';

void main() async {
  final scraper = NhentaiScraper();
  
  // HTML content from nhentai page
  final html = '''
  <section class="pagination">
      <a href="/?page=1" class="page current">1</a>
      <a href="/?page=2" class="page">2</a>
      <a href="/?page=3" class="page">3</a>
      <a href="/?page=4" class="page">4</a>
      <a href="/?page=5" class="page">5</a>
      <a href="/?page=6" class="page">6</a>
      <a href="/?page=2" class="next">
          <i class="fa fa-chevron-right"></i>
      </a>
      <a href="/?page=22114" class="last">
          <i class="fa fa-chevron-right"></i>
          <i class="fa fa-chevron-right"></i>
      </a>
  </section>
  ''';
  
  // Parse pagination info
  final paginationData = scraper.parsePaginationInfo(html);
  final paginationModel = PaginationModel.fromScraperResult(paginationData);
  
  print('Current Page: ${paginationModel.currentPage}'); // 1
  print('Total Pages: ${paginationModel.totalPages}');   // 22114
  print('Has Next: ${paginationModel.hasNext}');         // true
  print('Has Previous: ${paginationModel.hasPrevious}'); // false
  print('Next Page: ${paginationModel.nextPage}');       // 2
  print('Progress: ${(paginationModel.progressPercentage * 100).toStringAsFixed(2)}%'); // 0.00%
}
```

### 2. Extract Visible Pages

```dart
void extractVisiblePages() {
  final scraper = NhentaiScraper();
  final html = '...'; // HTML content
  
  final visiblePages = scraper.extractVisiblePages(html);
  print('Visible Pages: $visiblePages'); // [1, 2, 3, 4, 5, 6]
}
```

### 3. Complete Content List with Pagination

```dart
Future<void> fetchContentWithPagination(int page) async {
  final scraper = NhentaiScraper();
  
  // Fetch HTML for specific page
  final html = await fetchPageHtml('https://nhentai.net/?page=$page');
  
  // Parse content list
  final contents = await scraper.parseContentList(html);
  
  // Parse pagination info
  final paginationData = scraper.parsePaginationInfo(html);
  final paginationModel = PaginationModel.fromScraperResult(paginationData);
  
  print('Found ${contents.length} contents on page ${paginationModel.currentPage}');
  print('Total pages available: ${paginationModel.totalPages}');
  
  if (paginationModel.hasNext) {
    print('Next page: ${paginationModel.nextPage}');
  }
  
  if (paginationModel.hasPrevious) {
    print('Previous page: ${paginationModel.previousPage}');
  }
}
```

### 4. Repository Implementation

```dart
class ContentRepositoryImpl implements ContentRepository {
  final NhentaiScraper scraper;
  
  ContentRepositoryImpl({required this.scraper});
  
  @override
  Future<ContentListResult> getContentList(int page) async {
    try {
      final html = await fetchPageHtml('https://nhentai.net/?page=$page');
      
      // Parse content and pagination simultaneously
      final contents = await scraper.parseContentList(html);
      final paginationData = scraper.parsePaginationInfo(html);
      final paginationModel = PaginationModel.fromScraperResult(paginationData);
      
      return ContentListResult(
        contents: contents.map((model) => model.toEntity()).toList(),
        pagination: paginationModel.toEntity(),
      );
    } catch (e) {
      throw ContentException('Failed to fetch content list: $e');
    }
  }
}
```

### 5. BLoC Integration

```dart
class ContentBloc extends Bloc<ContentEvent, ContentState> {
  final ContentRepository repository;
  
  ContentBloc({required this.repository}) : super(ContentInitial()) {
    on<LoadContentEvent>(_onLoadContent);
    on<LoadNextPageEvent>(_onLoadNextPage);
    on<LoadPreviousPageEvent>(_onLoadPreviousPage);
  }
  
  Future<void> _onLoadContent(LoadContentEvent event, Emitter<ContentState> emit) async {
    emit(ContentLoading());
    
    try {
      final result = await repository.getContentList(event.page);
      
      emit(ContentLoaded(
        contents: result.contents,
        pagination: result.pagination,
      ));
    } catch (e) {
      emit(ContentError(e.toString()));
    }
  }
  
  Future<void> _onLoadNextPage(LoadNextPageEvent event, Emitter<ContentState> emit) async {
    final currentState = state;
    if (currentState is ContentLoaded && currentState.pagination.hasNext) {
      final nextPage = currentState.pagination.nextPage!;
      add(LoadContentEvent(page: nextPage));
    }
  }
  
  Future<void> _onLoadPreviousPage(LoadPreviousPageEvent event, Emitter<ContentState> emit) async {
    final currentState = state;
    if (currentState is ContentLoaded && currentState.pagination.hasPrevious) {
      final previousPage = currentState.pagination.previousPage!;
      add(LoadContentEvent(page: previousPage));
    }
  }
}
```

### 6. UI Implementation

```dart
class PaginationWidget extends StatelessWidget {
  final PaginationInfo pagination;
  final Function(int) onPageChanged;
  
  const PaginationWidget({
    Key? key,
    required this.pagination,
    required this.onPageChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        IconButton(
          onPressed: pagination.hasPrevious 
              ? () => onPageChanged(pagination.previousPage!) 
              : null,
          icon: Icon(Icons.chevron_left),
        ),
        
        // Page info
        Text(pagination.pageRangeString),
        
        // Next button
        IconButton(
          onPressed: pagination.hasNext 
              ? () => onPageChanged(pagination.nextPage!) 
              : null,
          icon: Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
```

## Benefits

1. **Accurate Total Pages**: Menggunakan link "last" untuk mendapatkan total pages yang akurat
2. **Navigation Support**: Mendukung next/previous navigation
3. **Progress Tracking**: Bisa menampilkan progress percentage
4. **Flexible UI**: Bisa digunakan untuk berbagai jenis pagination UI
5. **Error Handling**: Graceful fallback jika parsing gagal

## Error Handling

```dart
final paginationData = scraper.parsePaginationInfo(html);

// Always check for valid data
if (paginationData['totalPages'] > 1) {
  // Valid pagination
  final pagination = PaginationModel.fromScraperResult(paginationData);
  // Use pagination data
} else {
  // Single page or error
  final pagination = PaginationModel(
    currentPage: 1,
    totalPages: 1,
    hasNext: false,
    hasPrevious: false,
  );
}
```

## Testing

```dart
void testPaginationParsing() {
  final scraper = NhentaiScraper();
  
  // Test case 1: First page
  final html1 = '''<section class="pagination">
    <a href="/?page=1" class="page current">1</a>
    <a href="/?page=2" class="next"><i class="fa fa-chevron-right"></i></a>
    <a href="/?page=100" class="last"><i class="fa fa-chevron-right"></i><i class="fa fa-chevron-right"></i></a>
  </section>''';
  
  final result1 = scraper.parsePaginationInfo(html1);
  assert(result1['currentPage'] == 1);
  assert(result1['totalPages'] == 100);
  assert(result1['hasNext'] == true);
  assert(result1['hasPrevious'] == false);
  
  // Test case 2: Middle page
  final html2 = '''<section class="pagination">
    <a href="/?page=49" class="previous"><i class="fa fa-chevron-left"></i></a>
    <a href="/?page=50" class="page current">50</a>
    <a href="/?page=51" class="next"><i class="fa fa-chevron-right"></i></a>
    <a href="/?page=100" class="last"><i class="fa fa-chevron-right"></i><i class="fa fa-chevron-right"></i></a>
  </section>''';
  
  final result2 = scraper.parsePaginationInfo(html2);
  assert(result2['currentPage'] == 50);
  assert(result2['totalPages'] == 100);
  assert(result2['hasNext'] == true);
  assert(result2['hasPrevious'] == true);
  
  print('All pagination parsing tests passed!');
}
```

## Conclusion

Dengan implementasi pagination parsing ini, aplikasi dapat:

1. **Mengetahui total pages** yang tersedia (22,114 pages dalam contoh)
2. **Navigate dengan akurat** menggunakan next/previous
3. **Menampilkan progress** kepada user
4. **Handle edge cases** seperti first/last page
5. **Integrate dengan BLoC** untuk state management yang proper

Implementasi ini memberikan foundation yang solid untuk pagination dalam aplikasi NhentaiApp.