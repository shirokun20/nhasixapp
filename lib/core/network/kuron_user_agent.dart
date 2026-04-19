import 'package:package_info_plus/package_info_plus.dart';

class KuronUserAgent {
  const KuronUserAgent._();

  static const String appName = 'Kuron';
  static const String repositoryUrl = 'https://github.com/shirokun20/nhasixapp';

  static String fromPackageInfo(PackageInfo packageInfo) {
    final version = _normalizeVersion(
      packageInfo.version,
      packageInfo.buildNumber,
    );
    return '$appName/$version (+$repositoryUrl)';
  }

  static String _normalizeVersion(String version, String buildNumber) {
    final normalizedVersion = version.trim();
    final normalizedBuild = buildNumber.trim();

    if (normalizedVersion.isEmpty && normalizedBuild.isEmpty) {
      return 'unknown';
    }

    if (normalizedBuild.isEmpty ||
        normalizedVersion.endsWith('+$normalizedBuild')) {
      return normalizedVersion.isEmpty ? normalizedBuild : normalizedVersion;
    }

    if (normalizedVersion.isEmpty) {
      return normalizedBuild;
    }

    return '$normalizedVersion+$normalizedBuild';
  }
}
