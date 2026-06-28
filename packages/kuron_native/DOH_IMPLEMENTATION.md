# DNS over HTTPS (DoH) Implementation

## Overview

DNS bypass implementation using OkHttp's DNS-over-HTTPS on Android. Allows bypassing DNS censorship similar to TachiyomiSY.

## Architecture

```
Dart (Dio) → Native Bridge → OkHttp + DoH → Target Server
```

## Ownership

Native DNS owns:
- `KuronNative.instance.makeHttpRequest()`
- `KuronNative.instance.downloadBinary()`
- `KuronNativePlugin` OkHttp-backed native request paths

Native DNS does not own:
- Flutter `Dio` traffic
- Dart-side `DnsResolver` transport path

## Usage

### 1. Set DoH Provider

```dart
import 'package:kuron_native/kuron_native.dart';

// Enable Cloudflare DoH
await KuronNative.instance.setDohProvider(DohProvider.cloudflare);

// Available providers:
// - DohProvider.disabled (-1)
// - DohProvider.cloudflare (1)
// - DohProvider.google (2)
// - DohProvider.adguard (3)
// - DohProvider.quad9 (4)
```

### 2. Get Current Provider

```dart
final provider = await KuronNative.instance.getDohProvider();
print('Current DoH: ${DohProvider.getName(provider)}');
```

### 3. Make HTTP Request with DoH

```dart
final response = await KuronNative.instance.makeHttpRequest(
  url: 'https://example.com/api/data',
  method: 'GET',
  headers: {
    'User-Agent': 'MyApp/1.0',
    'Accept': 'application/json',
  },
);

print('Status: ${response['statusCode']}');
print('Body: ${response['body']}');
```

### 4. POST Request

```dart
final response = await KuronNative.instance.makeHttpRequest(
  url: 'https://api.example.com/login',
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: '{"username":"user","password":"pass"}',
);
```

## Integration with Dio

Create adapter wrapper:

```dart
class DohRestAdapter extends RestAdapter {
  final bool useDoH;
  
  DohRestAdapter({this.useDoH = false});
  
  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    if (!useDoH) {
      return super.get(path, queryParameters: queryParameters);
    }
    
    final url = Uri.parse(baseUrl + path).replace(queryParameters: queryParameters).toString();
    final nativeResponse = await KuronNative.instance.makeHttpRequest(
      url: url,
      method: 'GET',
      headers: headers,
    );
    
    return Response(
      data: nativeResponse['body'],
      statusCode: nativeResponse['statusCode'],
      headers: Headers.fromMap(nativeResponse['headers']),
    );
  }
}
```

## Settings UI Example

```dart
class DnsSettingsPage extends StatefulWidget {
  @override
  _DnsSettingsPageState createState() => _DnsSettingsPageState();
}

class _DnsSettingsPageState extends State<DnsSettingsPage> {
  int _currentProvider = DohProvider.disabled;
  
  @override
  void initState() {
    super.initState();
    _loadProvider();
  }
  
  Future<void> _loadProvider() async {
    final provider = await KuronNative.instance.getDohProvider();
    setState(() => _currentProvider = provider);
  }
  
  Future<void> _setProvider(int provider) async {
    await KuronNative.instance.setDohProvider(provider);
    setState(() => _currentProvider = provider);
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: DohProvider.all.map((provider) {
        return RadioListTile<int>(
          title: Text(DohProvider.getName(provider)),
          value: provider,
          groupValue: _currentProvider,
          onChanged: (value) => _setProvider(value!),
        );
      }).toList(),
    );
  }
}
```

## Technical Details

### Android Implementation

- **OkHttp 4.12.0** with `okhttp-dnsoverhttps` module
- **Bootstrap DNS**: Hardcoded IPs to resolve DoH server itself
- **Caching**: Client cached per provider, recreated on change
- **Thread Safety**: SharedPreferences for persistence

### DoH Providers

| Provider | URL | Bootstrap IPs |
|----------|-----|---------------|
| Cloudflare | cloudflare-dns.com | 1.1.1.1, 1.0.0.1 |
| Google | dns.google | 8.8.8.8, 8.8.4.4 |
| AdGuard | dns-unfiltered.adguard.com | 94.140.14.140 |
| Quad9 | dns.quad9.net | 9.9.9.9 |

### Performance

- **First Request**: ~200-500ms (DoH handshake)
- **Subsequent**: ~50-100ms (cached DNS)
- **Overhead**: +10-20ms vs system DNS

## Limitations

- **Android Only**: iOS not implemented
- **No Dio Integration**: Manual bridge required
- **No Certificate Pinning**: Uses system trust store
- **No Custom DoH**: Only predefined providers

## Future Enhancements

1. **Dio Interceptor**: Transparent DoH for all Dio requests
2. **Custom DoH Server**: User-defined DoH URL
3. **DNS Cache Control**: TTL management
4. **Fallback Strategy**: Auto-disable on DoH failure
5. **iOS Support**: Network.framework DNS override

## References

- [TachiyomiSY Implementation](https://github.com/jobobby04/TachiyomiSY)
- [OkHttp DNS-over-HTTPS](https://square.github.io/okhttp/features/dnsoverhttps/)
- [RFC 8484 - DNS Queries over HTTPS](https://datatracker.ietf.org/doc/html/rfc8484)
