/// Last two labels of a host, e.g. `sub.komiktap.info` -> `komiktap.info`.
///
/// ponytail: naive last-two-labels; co.uk-type multi-label TLDs out of scope
/// per spec (no PublicSuffixDatabase) — add one if such hosts appear.
String? registrableDomain(Uri uri) {
  final labels = uri.host.split('.');
  if (labels.length < 2) {
    return uri.host.isEmpty ? null : uri.host;
  }
  return labels.sublist(labels.length - 2).join('.');
}
