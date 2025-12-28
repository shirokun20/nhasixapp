/// Popular content timeframe options
enum PopularTimeframe {
  allTime('All Time', 'all'),
  week('This Week', 'week'),
  today('Today', 'today');

  final String displayName;
  final String apiValue;

  const PopularTimeframe(this.displayName, this.apiValue);
}
