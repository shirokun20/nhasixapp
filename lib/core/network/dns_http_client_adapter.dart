import 'dart:io';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';
import 'dns_resolver.dart';

/// Custom HTTP Client Adapter with DNS-over-HTTPS support
/// Uses connectionFactory override to perform custom DNS resolution
class DnsHttpClientAdapter extends IOHttpClientAdapter {
  DnsHttpClientAdapter({
    required DnsResolver dnsResolver,
    required Logger logger,
  }) : super(
          createHttpClient: () {
            final client = HttpClient();

            // Override findProxyFromEnvironment to return DIRECT (no proxy)
            client.findProxy = (Uri uri) => 'DIRECT';

            // Override connection factory to use custom DNS resolver
            client.connectionFactory =
                (Uri uri, String? proxyHost, int? proxyPort) async {
              try {
                // Resolve hostname using DoH
                logger.d('Resolving ${uri.host} via DoH...');
                final addresses = await dnsResolver.lookup(uri.host);

                if (addresses.isEmpty) {
                  throw SocketException(
                      'DNS resolution failed for ${uri.host}');
                }

                // Use first resolved IP address
                final resolvedIp = addresses.first.address;
                logger.d('Resolved ${uri.host} to $resolvedIp');

                // Determine the port (default to 443 for https, 80 for http)
                final port =
                    uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);

                // Use Socket.startConnect which returns ConnectionTask<Socket>
                // This allows the connection to be properly managed and cancelled
                return Socket.startConnect(resolvedIp, port);
              } catch (e) {
                logger.e(
                    'DoH resolution failed for ${uri.host}, trying system DNS',
                    error: e);
                // Fallback to system DNS
                final port =
                    uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
                return Socket.startConnect(uri.host, port);
              }
            };

            // Set connection timeout
            client.connectionTimeout = const Duration(seconds: 15);

            return client;
          },
        );
}
