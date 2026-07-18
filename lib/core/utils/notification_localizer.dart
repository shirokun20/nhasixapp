import '../../l10n/app_localizations.dart';

String? _arg(Map<String, dynamic>? args, String key, [String? fallback]) {
  if (args == null || !args.containsKey(key)) return fallback;
  final v = args[key];
  return v?.toString() ?? fallback;
}

Object _objArg(Map<String, dynamic>? args, String key, [Object fallback = 0]) {
  if (args == null || !args.containsKey(key)) return fallback;
  return args[key] ?? fallback;
}

String? localizeNotification(
    AppLocalizations l10n, String key, Map<String, dynamic>? args) {
  switch (key) {
    case 'downloadStarted':
      return l10n.downloadStarted(_arg(args, 'title', '')!);
    case 'downloadingWithTitle':
      return l10n.downloadingWithTitle(_arg(args, 'title', '')!);
    case 'downloadingProgress':
      return l10n.downloadingProgress(_objArg(args, 'progress'));
    case 'downloadComplete':
      return l10n.downloadComplete;
    case 'downloadedWithTitle':
      return l10n.downloadedWithTitle(_arg(args, 'title', '')!);
    case 'downloadFailed':
      return l10n.downloadFailed;
    case 'downloadFailedWithTitle':
      return l10n.downloadFailedWithTitle(_arg(args, 'title', '')!);
    case 'downloadPaused':
      return l10n.downloadPaused;

    case 'convertingToPdfWithTitle':
      return l10n.convertingToPdfWithTitle(_arg(args, 'title', '')!);
    case 'convertingToPdfProgress':
      return l10n.convertingToPdfProgress(_objArg(args, 'progress'));
    case 'convertingToPdfProgressWithTitle':
      return l10n.convertingToPdfProgressWithTitle(
          _arg(args, 'title', '')!, _intArg(args, 'progress') ?? 0);
    case 'pdfCreatedSuccessfully':
      return l10n.pdfCreatedSuccessfully;
    case 'pdfCreatedWithParts':
      return l10n.pdfCreatedWithParts(
          _arg(args, 'title', '')!, _intArg(args, 'partsCount') ?? 1);

    case 'verifyingFilesWithTitle':
      return l10n.verifyingFilesWithTitle(_arg(args, 'title', '')!);
    case 'verifyingProgress':
      return l10n.verifyingProgress(_intArg(args, 'progress') ?? 0);

    default:
      return null;
  }
}

int? _intArg(Map<String, dynamic>? args, String key) {
  if (args == null || !args.containsKey(key)) return null;
  final v = args[key];
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
