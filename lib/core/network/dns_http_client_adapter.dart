import 'dart:io';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';
import 'dns_resolver.dart';

/// Custom HTTP Client Adapter with DNS-over-HTTPS support
/// Uses IOHttpClientAdapter with custom HttpClient factory
class DnsHttpClientAdapter extends IOHttpClientAdapter {
  DnsHttpClientAdapter({
    required DnsResolver dnsResolver,
    required Logger logger,
  }) : super(
          createHttpClient: () {
            final client = HttpClient();

            // Override connection factory to use custom DNS resolver
            client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
              try {
                // Resolve hostname using DNS resolver
                final addresses = await dnsResolver.lookup(uri.host);

                if (addresses.isEmpty) {
                  throw SocketException('DNS resolution failed for ${uri.host}');
                }

                // Use first resolved IP address
                final resolvedIp = addresses.first.address;
                logger.d('Resolved ${uri.host} to $resolvedIp via DoH');

                // Create connection task with resolved IP
                return await Socket.startConnect(resolvedIp, uri.port);
              } catch (e) {
                logger.e('DNS connection factory failed for ${uri.host}', error: e);
                rethrow;
              }
            };

            // Set connection timeout
            client.connectionTimeout = const Duration(seconds: 15);

            return client;
          },
        );
}

