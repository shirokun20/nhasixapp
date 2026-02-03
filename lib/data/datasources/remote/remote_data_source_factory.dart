import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/data/datasources/remote/cloudflare_bypass_no_webview.dart';

import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/data/datasources/remote/request_rate_manager.dart';

import 'remote_data_source.dart';
import 'nhentai_scraper.dart';
import 'anti_detection.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Factory class for creating RemoteDataSource with all dependencies
class RemoteDataSourceFactory {
  static Future<RemoteDataSource> create({Logger? logger}) async {
    final log = logger ?? Logger();

    // Create HTTP client
    final httpClient = Dio();
    final prefs = await SharedPreferences.getInstance();

    // Create RemoteConfigService (configs from assets, tags from remote)
    final remoteConfigService = RemoteConfigService(
      dio: httpClient,
      logger: log,
      prefs: prefs,
    );

    // Create dependencies
    final scraper = NhentaiScraper(
      logger: log,
      remoteConfigService: remoteConfigService,
    );
    final cloudflareBypass = CloudflareBypassNoWebView(
      httpClient: httpClient,
      logger: log,
    );
    final antiDetection = AntiDetection(logger: log);

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
