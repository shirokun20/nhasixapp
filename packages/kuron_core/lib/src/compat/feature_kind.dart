/// Feature kinds that a Source Config can declare or support.
///
/// Used by [FeatureContract], [ValidationReport], and runtime page/download
/// pipelines to identify which capability a status, diagnostic, or
/// resolved request belongs to.
enum FeatureKind {
  home,
  search,
  dynamicForm,
  contentByTag,
  detail,
  chapters,
  reader,
  download,
  comments,
  related,
  headers,
  auth,
}
