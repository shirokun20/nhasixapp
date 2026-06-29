import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:logger/logger.dart';

import '../wizard/wizard_builder.dart';
import '../wizard/wizard_runner.dart';
import '../generator/config_generator.dart';
import '../discovery/http_probe.dart';
import '../discovery/cms_detector.dart';
import '../discovery/api_detector.dart';

/// Generate a Kuron source config through interactive questions or URL-assisted discovery.
class GenerateCommand extends Command<void> {
  GenerateCommand() {
    argParser
      ..addOption(
        'url',
        abbr: 'u',
        help: 'Source URL to assist generation (optional).',
      )
      ..addFlag(
        'interactive',
        abbr: 'i',
        negatable: false,
        help: 'Run in interactive wizard mode.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory for generated config.',
        defaultsTo: 'build/generated',
      )
      ..addFlag(
        'capture-fixtures',
        negatable: false,
        help: 'Save HTTP/browser fixtures for validation.',
      );
  }

  @override
  String get name => 'generate';

  @override
  String get description =>
      'Generate a source config through interactive questions or URL discovery.';

  @override
  Future<void> run() async {
    final logger = Logger(level: Level.info);
    final url = argResults?['url'] as String?;
    final interactive = argResults?['interactive'] as bool? ?? false;
    final output = argResults?['output'] as String;

    if (url == null && !interactive) {
      stderr.writeln('Error: Must specify --url or --interactive.');
      stderr.writeln(usage);
      exit(64);
    }

    logger.i('Generate command - output: $output');

    if (interactive) {
      await _runInteractiveWizard(output, logger);
    } else {
      await _runUrlAssistedGeneration(url!, output, logger);
    }
  }

  Future<void> _runInteractiveWizard(String output, Logger logger) async {
    final flow = WizardBuilder.buildFlow();
    final runner = WizardRunner(flow: flow);

    logger.i('Starting interactive wizard...\n');
    final answers = await runner.run();

    logger.i('Generating config...');
    final config = ConfigGenerator.generateConfig(answers);

    // Write config to output directory
    final outputDir = Directory(output);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final configFile = File('$output/${answers['sourceId']}-config.json');
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config),
    );

    logger.i('✓ Config generated: ${configFile.path}');
  }

  Future<void> _runUrlAssistedGeneration(
    String url,
    String output,
    Logger logger,
  ) async {
    logger.i('🔍 Probing $url...');
    final probe = await probeUrl(url);

    if (!probe.isSuccess) {
      if (probe.isBlocked) {
        logger.w('Site blocked automated probe (${probe.statusCode}). '
            'Cloudflare or WAF detected. Use --interactive to enter selectors manually.');
      } else {
        logger.e('Probe failed: ${probe.error ?? probe.statusCode}');
      }
      return;
    }

    logger.i(
        '✓ HTTP ${probe.statusCode}, ${probe.body.length} bytes received (${probe.contentType.name})');

    if (probe.contentType == ProbeContentType.json) {
      await _handleApiResponse(probe, output, logger);
      return;
    }

    // Detect CMS from HTML
    final cms = detectCms(probe.body);
    logger.i(
        '📋 CMS detected: ${cms.cmsId} (${(cms.confidence * 100).round()}% confidence)');

    if (cms.isKnown) {
      logger.i('Suggested selectors for $url (${cms.cmsId}):');
      for (final e in cms.selectors.entries) {
        logger.i('  ${e.key}: "${e.value}"');
      }
      logger.i('\nUse --interactive to enter selectors manually, '
          'or edit the generated config to adjust selectors.');
    } else {
      logger.w('Unknown CMS — selectors will be generic guesses.');
    }

    // Build wizard answers from probe
    final answers = <String, String?>{
      'sourceId': Uri.tryParse(url)?.host.replaceAll(RegExp(r'^www\.'), '') ??
          'unknown',
      'displayName': Uri.tryParse(url)?.host ?? 'Unknown',
      'homeUrl': url,
      'version': '1.0.0',
      'contentType': 'manga',
      'mode': 'scraper',
      'supportsSearch': 'y',
      'supportsChapters': 'y',
      'supportsComments': 'n',
      'needsHeaders': probe.isBlocked ? 'y' : 'n',
    };

    // Fill selectors from CMS detection where available
    if (cms.isKnown) {
      // ponytail: merge CMS selectors into wizard answer slots
      // Using the first matched selector category for each slot
      final cats = <String, String>{
        'listSelector':
            cms.selectors['list.item'] ?? cms.selectors['list.title'] ?? '',
        'detailTitleSelector': cms.selectors['detail.title'] ?? 'h1',
      };
      answers['listSelector'] = cats['listSelector'];
      answers['detailTitleSelector'] = cats['detailTitleSelector'];
    }

    // Detect chapterData script for reader mode
    final hasChapterData = RegExp(r'chapterData\s*=\s*\{').hasMatch(probe.body);
    String? cdnBase;
    if (hasChapterData) {
      final baseMatch =
          RegExp(r'"base"\s*:\s*"([^"]+)"').firstMatch(probe.body);
      cdnBase = baseMatch?.group(1);
      logger.i('📖 chapterData script detected — '
          '${cdnBase != null ? "CDN base: $cdnBase" : "no CDN base found"}');
    }

    // Fill CMS defaults into answers
    if (cms.isKnown) {
      answers['cmsThemeType'] = cms.themeType;
      answers['listSelector'] =
          cms.selectors['list.item'] ?? cms.selectors['list.title'] ?? '';
      answers['listTitleSelector'] = cms.selectors['list.title'] ?? '';
      answers['detailTitleSelector'] = cms.selectors['detail.title'] ?? 'h1';
      answers['detailCoverSelector'] = cms.selectors['detail.cover'] ?? 'img';
      answers['chapterContainer'] =
          cms.selectors['chapters.item'] ?? 'a[href*="chapter"]';
      answers['readerImageSel'] = cms.selectors['reader.image'] ?? 'img';

      if (cms.searchDefaults != null) {
        answers['searchUrl'] = cms.searchDefaults!['searchUrl'] as String?;
        answers['searchQueryParam'] =
            cms.searchDefaults!['queryParam'] as String?;
      }

      if (cms.readerDefaults != null) {
        answers['readerMode'] =
            cms.readerDefaults!['mode'] as String? ?? 'directUrl';
      } else {
        answers['readerMode'] = 'directUrl';
      }

      if (answers['readerMode'] == 'directUrl' && hasChapterData) {
        answers['readerMode'] = 'chapterDataScript';
        if (cdnBase != null) answers['cdnBase'] = cdnBase;
        logger.i(
            '📖 Using chapterDataScript reader mode${cdnBase != null ? " (base: $cdnBase)" : ""}');
      }
    }

    if (probe.isBlocked) {
      answers['needsCloudflare'] = 'y';
    }

    logger.i('Generating config...');
    final config = ConfigGenerator.generateConfig(answers);

    // Write config
    final outputDir = Directory(output);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    final sourceId = answers['sourceId'] ?? 'unknown';
    final configFile = File('$output/$sourceId-config.json');
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config),
    );

    logger.i('✓ Config generated: ${configFile.path}');
    if (cms.isKnown) {
      logger.i('💡 Review suggested selectors in the config — '
          'adjust paths, CSS classes, and image selectors as needed.');
    }
  }

  Future<void> _handleApiResponse(
    ProbeResult probe,
    String output,
    Logger logger,
  ) async {
    final url = argResults?['url'] as String;
    final json = probe.jsonBody;
    if (json == null) {
      logger.w('JSON body is empty or malformed.');
      return;
    }

    final api = inferApi(url, json);
    logger.i('📡 API mode detected — inferred structure:');
    logger.i(
        '  isList=${api.hasList} isDetail=${api.hasDetail} confidence=${(api.confidence * 100).round()}%');

    final uri = Uri.tryParse(url);
    final host = uri?.host.replaceAll(RegExp(r'^www\.'), '') ?? 'unknown';

    final answers = <String, String?>{
      'sourceId': host,
      'displayName': host,
      'homeUrl': '${uri?.scheme}://${uri?.host}',
      'version': '1.0.0',
      'contentType': 'manga',
      'mode': 'rest_json',
      'supportsSearch': 'y',
      'supportsChapters': 'n',
      'supportsComments': 'n',
      'needsHeaders': 'n',
      if (api.listEndpoint != null) 'listEndpoint': api.listEndpoint,
      if (api.detailEndpoint != null) 'detailEndpoint': api.detailEndpoint,
      'apiBase': api.baseUrl,
    };

    logger.i('Generating config with REST API mode...');
    final config = ConfigGenerator.generateConfig(answers);

    // Write config
    final outputDir = Directory(output);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    final configFile = File('$output/$host-config.json');
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config),
    );
    logger.i('✓ Config generated: ${configFile.path}');
    logger.i('💡 This is a draft — review endpoints, paths, and pagination.');
  }
}
