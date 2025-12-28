/// Sort options for content lists
enum SortOption {
  newest('Newest', 'recent'),
  popular('Popular', 'popular'),
  popularToday('Popular Today', 'popular-today'),
  popularWeek('Popular This Week', 'popular-week'),
  popularMonth('Popular This Month', 'popular-month');

  final String displayName;
  final String apiValue;

  const SortOption(this.displayName, this.apiValue);
}
