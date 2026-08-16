import 'dart:io';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';
import 'dns_resolver.dart';

class DnsHttpClientAdapter extends IOHttpClientAdapter {
  DnsHttpClientAdapter({
    required DnsResolver dnsResolver,
    required Logger logger,
  }) : super(
          createHttpClient: () {
            final client = HttpClient();

            client.findProxy = (Uri uri) => 'DIRECT';

            client.connectionFactory =
                (Uri uri, String? proxyHost, int? proxyPort) async {
              try {
                logger.d('Resolving ${uri.host} via DoH...');
                final addresses = await dnsResolver.lookup(uri.host);

                if (addresses.isEmpty) {
                  throw SocketException(
                      'DNS resolution failed for ${uri.host}');
                }

                final resolvedIp = addresses.first.address;
                logger.d('Resolved ${uri.host} to $resolvedIp');

                final port =
                    uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);

                // connectionFactory must not complete before Socket.startConnect
                // resolves — awaiting guarantees a connected socket is returned.
                return await Socket.startConnect(resolvedIp, port);
              } catch (e) {
                logger.e(
                    'DoH resolution failed for ${uri.host}, trying system DNS',
                    error: e);
                final port =
                    uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
                return await Socket.startConnect(uri.host, port);
              }
            };

            client.connectionTimeout = const Duration(seconds: 15);

            return client;
          },
        );
}
