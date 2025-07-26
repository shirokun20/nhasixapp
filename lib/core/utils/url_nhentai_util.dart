class UrlNhentaiUtil {
  final String baseUrl;
  String? language;
  List<String>? includeTags;
  List<String>? excludeTags;
  List<String>? artists;
  int page;

  UrlNhentaiUtil(
    this.baseUrl, {
    this.language,
    this.includeTags,
    this.excludeTags,
    this.artists,
    this.page = 1,
  });

  String buildWithSearch() {
    // Mulai membangun query string
    String query = '';

    // Tambahkan parameter language jika tidak kosong
    if (language != null && language!.isNotEmpty) {
      query += '+language:"$language"';
    }

    // Tambahkan tag yang harus ada
    if (includeTags != null && includeTags!.isNotEmpty) {
      for (var tag in includeTags!) {
        query += '+tag:"$tag"';
      }
    }

    if (artists != null && artists!.isNotEmpty) {
      for (var artist in artists!) {
        query += '+artist:"$artist"';
      }
    }

    // Tambahkan tag yang harus dikecualikan
    if (excludeTags != null && excludeTags!.isNotEmpty) {
      for (var tag in excludeTags!) {
        query += '+-tag:"$tag"';
      }
    }

    // Gabungkan dengan URL dasar dan parameter halaman
    final url = '$baseUrl/search/?q=$query&page=$page';
    return url; // Encode URL agar valid
  }

  String buildWithPageOnly() {
    return '$baseUrl/?page=$page';
  }
}

// Contoh penggunaan withSearch
// UrlUtil urlUtil = UrlUtil('https://nhentai.net', language: 'english', includeTags: ['loli'], excludeTags: ['shota'], artists: ['leonat'], page: 1);
// final builtUrl = urlUtil.buildWithSearch();
// print(builtUrl);
// Output: https://nhentai.net/search/?q=+language:"english"+tag:"loli"+artist:"leonat"+-tag:"shota"&page=1

// Contoh penggunaan withPageOnly
// UrlUtil urlUtil = UrlUtil('https://nhentai.net', page: 2);
// final builtUrl = urlUtil.buildWithPageOnly();
// print(builtUrl);
// Output: https://nhentai.net/?page=2
