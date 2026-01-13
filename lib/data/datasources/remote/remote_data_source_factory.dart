import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/data/datasources/remote/cloudflare_bypass_no_webview.dart';

import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/data/datasources/remote/request_rate_manager.dart';

import 'remote_data_source.dart';
import 'nhentai_scraper.dart';
import 'anti_detection.dart';

/// Factory class for creating RemoteDataSource with all dependencies
class RemoteDataSourceFactory {
  static RemoteDataSource create({Logger? logger}) {
    final log = logger ?? Logger();

    // Create HTTP client
    final httpClient = Dio();

    // Create dependencies
    final scraper = NhentaiScraper(logger: log);
    final cloudflareBypass = CloudflareBypassNoWebView(
      httpClient: httpClient,
      logger: log,
    );
    final antiDetection = AntiDetection(logger: log);

    // Create RemoteConfigService
    final remoteConfigService = RemoteConfigService(
      dio: httpClient,
      logger: log,
    );

    // Create RequestRateManager
    final rateManager = RequestRateManager(
      remoteConfigService: remoteConfigService,
      logger: log,
    );

    // Create and return remote data source
    return RemoteDataSource(
      httpClient: httpClient,
      scraper: scraper,
      cloudflareBypass: cloudflareBypass,
      antiDetection: antiDetection,
      rateManager: rateManager,
      remoteConfigService: remoteConfigService,
      logger: log,
    );
  }
}
