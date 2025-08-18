# Tutorial Penggunaan Scraper dan Cache System

## Ringkasan Perubahan

### 1. Bug Cache Sudah Diperbaiki ✅
Sebelumnya cache selalu dianggap expired karena bug di method `_isCacheExpired()`. Sekarang cache akan bekerja dengan benar:
- Cache fresh (< 6 jam) → Gunakan cache
- Cache expired (> 6 jam) → Fetch dari remote
- Tidak ada cache → Fetch dari remote

### 2. Scraper Homepage Sudah Ditingkatkan ✅
Scraper sekarang bisa memisahkan content berdasarkan section di homepage:
- **Popular Now** section
- **New Uploads** section
- Hanya ambil dari `.container.index-container`

## Cara Penggunaan

### A. Menggunakan Repository (Recommended)

```dart
// 1. Mendapatkan content list biasa (dengan cache otomatis)
final contentResult = await contentRepository.getContentList(page: 1);
final contents = contentResult.contents; // List<Content>

// 2. Mendapatkan content dari cache saja
final cachedResult = await contentRepository.getCachedContent(page: 1);
final cachedContents = cachedResult.contents;
```

### B. Menggunakan Remote Data Source Langsung

```dart
// 1. Mendapatkan content dari homepage (semua index containers)
final contents = await remoteDataSource.getContentList(page: 1);
// Returns: List<ContentModel>

// 2. Mendapatkan content terpisah per section
final homepage = await remoteDataSource.getHomepageContent();
final popularContents = homepage['popular']!;     // List<ContentModel>
final newUploads = homepage['new_uploads']!;      // List<ContentModel>

print('Popular: ${popularContents.length} items');
print('New Uploads: ${newUploads.length} items');
```

### C. Menggunakan Scraper Langsung

```dart
// 1. Parse homepage dengan section terpisah
final homepageData = scraper.parseHomepage(htmlString);
final popular = homepageData['popular']!;
final newUploads = homepageData['new_uploads']!;

// 2. Parse hanya dari index containers
final allContents = scraper.parseFromIndexContainers(htmlString);

// 3. Parse content list biasa (untuk halaman selain homepage)
final contents = scraper.parseContentList(htmlString);
```

## Struktur HTML yang Diparsing

### Homepage Structure:
```html
<!-- Popular Section -->
<div class="container index-container index-popular">
  <h2>Popular Now</h2>
  <div class="gallery" data-tags="1818 2937">
    <a href="/g/587477/" class="cover">
      <img data-src="//t9.nhentai.net/galleries/3464825/thumb.webp" />
      <div class="caption">Title Here</div>
    </a>
  </div>
</div>

<!-- New Uploads Section -->
<div class="container index-container">
  <h2>New Uploads</h2>
  <div class="gallery" data-tags="6346 17249">
    <a href="/g/587584/" class="cover">
      <img data-src="//t9.nhentai.net/galleries/3465447/thumb.webp" />
      <div class="caption">Title Here</div>
    </a>
  </div>
</div>
```

## Method Scraper yang Tersedia

| Method | Input | Output | Kegunaan |
|--------|-------|--------|----------|
| `parseHomepage()` | HTML String | `Map<String, List<ContentModel>>` | Parse homepage dengan section terpisah |
| `parseFromIndexContainers()` | HTML String | `List<ContentModel>` | Parse semua content dari index containers |
| `parseContentList()` | HTML String | `List<ContentModel>` | Parse content list biasa |
| `parseContentDetail()` | HTML String, ID | `ContentModel` | Parse detail content |
| `parseSearchResults()` | HTML String | `List<ContentModel>` | Parse hasil search |

## Contoh Implementasi di UI

### 1. Homepage dengan BLoC Pattern

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContentBloc(
        contentRepository: context.read<ContentRepository>(),
      )..add(LoadHomepageContent()),
      child: HomePageView(),
    );
  }
}

class HomePageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NHentai Clone'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<ContentBloc>().add(RefreshContent());
            },
          ),
        ],
      ),
      body: BlocBuilder<ContentBloc, ContentState>(
        builder: (context, state) {
          if (state is ContentLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (state is HomepageContentLoaded) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Popular Section
                  _buildSectionHeader('🔥 Popular Now'),
                  _buildHorizontalList(state.popularContents),
                  
                  SizedBox(height: 20),
                  
                  // New Uploads Section
                  _buildSectionHeader('📦 New Uploads'),
                  _buildGridList(state.newUploads),
                ],
              ),
            );
          }
          
          if (state is ContentError) {
            return _buildErrorWidget(context, state);
          }
          
          return Center(child: Text('Tap refresh to load content'));
        },
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildHorizontalList(List<Content> contents) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: contents.length,
        itemBuilder: (context, index) {
          return ContentCard(content: contents[index]);
        },
      ),
    );
  }
  
  Widget _buildGridList(List<Content> contents) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        return ContentCard(content: contents[index]);
      },
    );
  }
  
  Widget _buildErrorWidget(BuildContext context, ContentError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error: ${state.message}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
          SizedBox(height: 16),
          if (state.hasCache) ...[
            Text('Showing cached content:'),
            SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                ),
                itemCount: state.cachedContents.length,
                itemBuilder: (context, index) {
                  return ContentCard(content: state.cachedContents[index]);
                },
              ),
            ),
          ],
          ElevatedButton(
            onPressed: () {
              context.read<ContentBloc>().add(LoadHomepageContent());
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

### 2. Content List Page dengan Pagination

```dart
class ContentListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContentBloc(
        contentRepository: context.read<ContentRepository>(),
      )..add(LoadContentList()),
      child: ContentListView(),
    );
  }
}

class ContentListView extends StatefulWidget {
  @override
  _ContentListViewState createState() => _ContentListViewState();
}

class _ContentListViewState extends State<ContentListView> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ContentBloc>().add(LoadContentList(page: ++_currentPage));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Content')),
      body: BlocBuilder<ContentBloc, ContentState>(
        builder: (context, state) {
          if (state is ContentLoading && _currentPage == 1) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is ContentLoaded) {
            return GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: state.hasReachedMax 
                  ? state.contents.length 
                  : state.contents.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.contents.length) {
                  return Center(child: CircularProgressIndicator());
                }
                return ContentCard(content: state.contents[index]);
              },
            );
          }

          if (state is ContentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: () {
                      _currentPage = 1;
                      context.read<ContentBloc>().add(LoadContentList());
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Center(child: Text('No content available'));
        },
      ),
    );
  }
}
```

### 3. Content Card Widget

```dart
class ContentCard extends StatelessWidget {
  final Content content;

  const ContentCard({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                content.coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '${content.pageCount} pages',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (content.artists.isNotEmpty)
                  Text(
                    content.artists.join(', '),
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Tips Penggunaan

### 1. Cache Management
```dart
// Cek apakah ada cache
final cachedResult = await contentRepository.getCachedContent();
if (cachedResult.contents.isNotEmpty) {
  // Gunakan cache untuk loading cepat
  setState(() => contents = cachedResult.contents);
}

// Kemudian fetch data fresh di background
contentRepository.getContentList().then((freshResult) {
  setState(() => contents = freshResult.contents);
});
```

### 2. Error Handling
```dart
try {
  final result = await contentRepository.getContentList();
  // Success
} catch (e) {
  if (e is NetworkException) {
    // Tampilkan pesan "No internet connection"
  } else if (e is CloudflareException) {
    // Tampilkan pesan "Website blocked"
  } else {
    // Error lainnya
  }
}
```

### 3. BLoC Pattern Implementation
```dart
// Events
abstract class ContentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadContentList extends ContentEvent {
  final int page;
  LoadContentList({this.page = 1});
  
  @override
  List<Object?> get props => [page];
}

class LoadHomepageContent extends ContentEvent {}

class RefreshContent extends ContentEvent {}

// States
abstract class ContentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ContentInitial extends ContentState {}

class ContentLoading extends ContentState {}

class ContentLoaded extends ContentState {
  final List<Content> contents;
  final bool hasReachedMax;
  
  ContentLoaded({
    required this.contents,
    this.hasReachedMax = false,
  });
  
  @override
  List<Object?> get props => [contents, hasReachedMax];
}

class HomepageContentLoaded extends ContentState {
  final List<Content> popularContents;
  final List<Content> newUploads;
  
  HomepageContentLoaded({
    required this.popularContents,
    required this.newUploads,
  });
  
  @override
  List<Object?> get props => [popularContents, newUploads];
}

class ContentError extends ContentState {
  final String message;
  final bool hasCache;
  final List<Content> cachedContents;
  
  ContentError({
    required this.message,
    this.hasCache = false,
    this.cachedContents = const [],
  });
  
  @override
  List<Object?> get props => [message, hasCache, cachedContents];
}

// BLoC
class ContentBloc extends Bloc<ContentEvent, ContentState> {
  final ContentRepository contentRepository;
  
  ContentBloc({required this.contentRepository}) : super(ContentInitial()) {
    on<LoadContentList>(_onLoadContentList);
    on<LoadHomepageContent>(_onLoadHomepageContent);
    on<RefreshContent>(_onRefreshContent);
  }
  
  Future<void> _onLoadContentList(
    LoadContentList event,
    Emitter<ContentState> emit,
  ) async {
    try {
      emit(ContentLoading());
      
      final result = await contentRepository.getContentList(page: event.page);
      
      emit(ContentLoaded(
        contents: result.contents,
        hasReachedMax: !result.hasNext,
      ));
    } catch (e) {
      // Try to get cached content as fallback
      try {
        final cachedResult = await contentRepository.getCachedContent(page: event.page);
        emit(ContentError(
          message: e.toString(),
          hasCache: cachedResult.contents.isNotEmpty,
          cachedContents: cachedResult.contents,
        ));
      } catch (_) {
        emit(ContentError(message: e.toString()));
      }
    }
  }
  
  Future<void> _onLoadHomepageContent(
    LoadHomepageContent event,
    Emitter<ContentState> emit,
  ) async {
    try {
      emit(ContentLoading());
      
      // Untuk sementara gunakan getContentList, nanti bisa diganti dengan getHomepageContent
      final result = await contentRepository.getContentList(page: 1);
      
      // Simulasi pemisahan popular dan new uploads
      final popular = result.contents.take(10).toList();
      final newUploads = result.contents.skip(10).toList();
      
      emit(HomepageContentLoaded(
        popularContents: popular,
        newUploads: newUploads,
      ));
    } catch (e) {
      emit(ContentError(message: e.toString()));
    }
  }
  
  Future<void> _onRefreshContent(
    RefreshContent event,
    Emitter<ContentState> emit,
  ) async {
    // Clear cache and reload
    try {
      await contentRepository.clearCache();
      add(LoadContentList());
    } catch (e) {
      emit(ContentError(message: e.toString()));
    }
  }
}
```

## Kesimpulan

Dengan perubahan ini:
1. ✅ Cache bekerja dengan benar (tidak selalu fetch dari remote)
2. ✅ Scraper bisa memisahkan content berdasarkan section
3. ✅ Parsing lebih akurat sesuai struktur HTML nhentai
4. ✅ API yang mudah digunakan untuk berbagai kebutuhan

Sekarang kamu bisa fokus ke development UI tanpa khawatir masalah cache dan parsing!