# DoH Integration Guide

## Quick Start

### 1. Enable DoH in App

```dart
import 'package:kuron_native/kuron_native.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable DoH on startup
  await KuronNative.instance.setDohProvider(DohProvider.cloudflare);
  
  runApp(MyApp());
}
```

### 2. Create DoH Settings Page

```dart
class DnsSettingsPage extends StatefulWidget {
  @override
  _DnsSettingsPageState createState() => _DnsSettingsPageState();
}

class _DnsSettingsPageState extends State<DnsSettingsPage> {
  int _selectedProvider = DohProvider.disabled;
  
  @override
  void initState() {
    super.initState();
    _loadProvider();
  }
  
  Future<void> _loadProvider() async {
    final provider = await KuronNative.instance.getDohProvider();
    setState(() => _selectedProvider = provider);
  }
  
  Future<void> _setProvider(int provider) async {
    await KuronNative.instance.setDohProvider(provider);
    setState(() => _selectedProvider = provider);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DNS Settings')),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'DNS over HTTPS (DoH) bypasses DNS censorship',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ...DohProvider.all.map((provider) {
            return RadioListTile<int>(
              title: Text(DohProvider.getName(provider)),
              subtitle: provider == DohProvider.disabled
                  ? Text('Use system DNS')
                  : null,
              value: provider,
              groupValue: _selectedProvider,
              onChanged: (value) => _setProvider(value!),
            );
          }).toList(),
        ],
      ),
    );
  }
}
```

### 3. Integrate with GenericRestAdapter

```dart
class DohRestAdapter extends GenericRestAdapter {
  final bool useDoh;
  
  DohRestAdapter({
    required super.baseUrl,
    this.useDoh = false,
  });
  
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (!useDoh) {
      return super.get(path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    }
    
    final url = Uri.parse(baseUrl + path)
        .replace(queryParameters: queryParameters)
        .toString();
    
    final nativeResponse = await KuronNative.instance.makeHttpRequest(
      url: url,
      method: 'GET',
      headers: options?.headers?.cast<String, String>(),
    );
    
    return Response(
      data: nativeResponse['body'],
      statusCode: nativeResponse['statusCode'],
      headers: Headers.fromMap(
        (nativeResponse['headers'] as Map).cast<String, List<String>>(),
      ),
      requestOptions: RequestOptions(path: path),
    );
  }
  
  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (!useDoh) {
      return super.post(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    }
    
    final url = Uri.parse(baseUrl + path)
        .replace(queryParameters: queryParameters)
        .toString();
    
    String? body;
    if (data is String) {
      body = data;
    } else if (data is Map) {
      body = jsonEncode(data);
    }
    
    final nativeResponse = await KuronNative.instance.makeHttpRequest(
      url: url,
      method: 'POST',
      headers: options?.headers?.cast<String, String>(),
      body: body,
    );
    
    return Response(
      data: nativeResponse['body'],
      statusCode: nativeResponse['statusCode'],
      headers: Headers.fromMap(
        (nativeResponse['headers'] as Map).cast<String, List<String>>(),
      ),
      requestOptions: RequestOptions(path: path),
    );
  }
}
```

### 4. Register in DI

```dart
// In service_locator.dart
void setupServiceLocator() {
  // DNS resolver
  final dohEnabled = getIt<PreferencesRepository>().isDohEnabled;
  
  getIt.registerSingleton<RestAdapter>(
    DohRestAdapter(
      baseUrl: 'https://api.example.com',
      useDoh: dohEnabled,
    ),
  );
}
```

### 5. Use in Repository

```dart
class MangaRepository extends Repository {
  final RestAdapter _restAdapter;
  
  MangaRepository(this._restAdapter);
  
  Future<DataState<List<Manga>>> getMangaList() async {
    try {
      final response = await _restAdapter.get('/manga/list');
      
      if (response.statusCode == 200) {
        final data = List<Manga>.from(
          (jsonDecode(response.data) as List)
              .map((x) => Manga.fromJson(x))
        );
        return DataSuccess(data);
      }
      
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/manga/list'),
          response: response,
          type: DioExceptionType.badResponse,
        ),
      );
    } catch (e) {
      return DataFailed(e as Exception);
    }
  }
}
```

## Testing

```dart
test('DoH provider can be set and retrieved', () async {
  await KuronNative.instance.setDohProvider(DohProvider.cloudflare);
  final provider = await KuronNative.instance.getDohProvider();
  expect(provider, equals(DohProvider.cloudflare));
});

test('HTTP request with DoH returns valid response', () async {
  await KuronNative.instance.setDohProvider(DohProvider.google);
  
  final response = await KuronNative.instance.makeHttpRequest(
    url: 'https://httpbin.org/get',
    method: 'GET',
  );
  
  expect(response['statusCode'], equals(200));
  expect(response['body'], isNotEmpty);
});
```

## Troubleshooting

### DoH Not Working
- Check Android API level ≥ 24
- Verify internet permission in AndroidManifest.xml
- Test with different DoH provider

### Slow Requests
- First request slower (DoH handshake)
- Subsequent requests cached
- Try different provider if slow

### Certificate Errors
- Uses system trust store
- Add custom CA if needed via Android config

## Performance Notes

- **Disabled**: ~0ms overhead
- **First Request**: +200-500ms (DoH handshake)
- **Cached**: +10-20ms overhead
- **Bootstrap**: Hardcoded IPs prevent circular DNS

## Security

- DoH queries encrypted end-to-end
- Provider sees domain, not content
- No certificate pinning (uses system trust)
- Consider privacy implications of provider choice
