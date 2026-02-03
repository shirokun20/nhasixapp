// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'KomikTap';

  @override
  String get appSubtitle => 'Enhanced Reading Experience';

  @override
  String get home => '首页';

  @override
  String get search => '搜索';

  @override
  String get favorites => '收藏';

  @override
  String get downloads => '下载';

  @override
  String get history => '阅读历史';

  @override
  String get randomGallery => '随机画廊';

  @override
  String get offlineContent => '离线内容';

  @override
  String get settings => '设置';

  @override
  String get appDisguise => '应用伪装';

  @override
  String get disguiseMode => '伪装模式';

  @override
  String get offline => '离线';

  @override
  String get about => '关于';

  @override
  String get searchHint => '搜索内容...';

  @override
  String get searchPlaceholder => '输入搜索关键词';

  @override
  String get noResults => '未找到结果';

  @override
  String get searchSuggestions => '搜索建议';

  @override
  String get suggestions => '建议：';

  @override
  String get tapToLoadContent => '点击加载内容';

  @override
  String get checkInternetConnection => 'Check your internet 连接';

  @override
  String get trySwitchingNetwork => '尝试在WiFi和移动数据之间切换';

  @override
  String get restartRouter => '如果使用WiFi，请重启路由器';

  @override
  String get checkWebsiteStatus => '检查网站是否宕机';

  @override
  String get cloudflareBypassMessage => '该网站受Cloudflare保护。我们正在尝试绕过保护。';

  @override
  String get forceBypass => '强制绕过';

  @override
  String get unableToProcessData => '无法处理接收到的数据。网站结构可能已更改。';

  @override
  String get reportIssue => '报告问题';

  @override
  String serverReturnedError(int statusCode) {
    return '服务器 returned $statusCode. The service might be temporarily不可用.错误';
  }

  @override
  String get searchResults => '搜索Results';

  @override
  String get failedToOpenBrowser => '无法打开浏览器';

  @override
  String get viewDownloads => '查看下载';

  @override
  String get clearSearch => '清除搜索';

  @override
  String get clearFilters => '清除筛选';

  @override
  String get anyLanguage => '任何语言';

  @override
  String get anyCategory => '任何类别';

  @override
  String get errorOpeningFilter => '打开筛选器选择时出错';

  @override
  String get errorBrowsingTag => '浏览标签时出错';

  @override
  String get shuffleToNextGallery => '随机切换到下一个画廊';

  @override
  String get contentHidden => '内容已隐藏';

  @override
  String get tapToViewAnyway => '点击仍然查看';

  @override
  String get checkOutThisGallery => '查看这个画廊！';

  @override
  String galleriesPreloaded(int count) {
    return '$count galleries preloaded';
  }

  @override
  String get oopsSomethingWentWrong => '哎呀！出了点问题';

  @override
  String get cleanupInfo => '清理信息';

  @override
  String get loadingHistory => '加载中历史';

  @override
  String get clearingHistory => '清除历史记录...';

  @override
  String get areYouSureClearHistory => '您确定要清除所有阅读历史记录吗？此操作无法撤销。';

  @override
  String get justNow => '刚刚';

  @override
  String get artistCg => '画师 cg';

  @override
  String get gameCg => '游戏CG';

  @override
  String get manga => '漫画';

  @override
  String get doujinshi => '同人志';

  @override
  String get imageSet => '图集';

  @override
  String get cosplay => 'Cosplay';

  @override
  String get artistcg => '画师CG';

  @override
  String get gamecg => '游戏CG';

  @override
  String get bigBreasts => '巨乳';

  @override
  String get soleFemale => '单女主';

  @override
  String get soleMale => '单男主';

  @override
  String get pleaseSetStorageLocation => '请先在设置中设置下载存储位置。';

  @override
  String get schoolgirlUniform => '女学生制服';

  @override
  String get tryADifferentSearchTerm => '尝试不同的搜索词';

  @override
  String get unknownError => '未知错误';

  @override
  String get loadingOfflineContent => '加载离线内容...';

  @override
  String get excludeTags => '排除标签';

  @override
  String get excludeGroups => '排除团体';

  @override
  String get excludeCharacters => '排除角色';

  @override
  String get excludeParodies => '排除原作';

  @override
  String get excludeArtists => '排除画师';

  @override
  String get noResultsFound => '未找到结果';

  @override
  String get tryAdjustingFilters => '尝试调整您的搜索筛选器或搜索词。';

  @override
  String get tryDifferentKeywords => 'Try different keywords';

  @override
  String get networkError => '网络错误。请检查您的连接并重试。';

  @override
  String get serverError => '服务器错误';

  @override
  String get accessBlocked => '访问被阻止。正在尝试绕过保护...';

  @override
  String get tooManyRequests => '请求过多。请稍等片刻后重试。';

  @override
  String get errorProcessingResults => '处理搜索结果时出错。请重试。';

  @override
  String get invalidSearchParameters => '无效的搜索参数。请检查您的输入。';

  @override
  String get unexpectedError => '发生意外错误。请重试。';

  @override
  String get retryBypass => '重试 Bypass';

  @override
  String get retryConnection => 'Retry 连接';

  @override
  String get retrySearch => '重试 搜索';

  @override
  String get errorNetwork => '网络错误。请检查您的连接并重试。';

  @override
  String get errorServer => '服务器错误。请稍后再试。';

  @override
  String get errorCloudflare => '内容暂时被阻止 (Cloudflare)。请稍后再试。';

  @override
  String get errorParsing => '加载内容数据失败。内容可能不可用。';

  @override
  String get errorUnknown => '发生错误。请重试。';

  @override
  String get errorConnectionTimeout => '连接超时。请重试。';

  @override
  String get errorConnectionRefused => '连接被拒绝。服务器可能已关闭。';

  @override
  String get networkErrorTitle => '网络 错误';

  @override
  String get serverErrorTitle => '服务器错误';

  @override
  String get unknownErrorTitle => '未知 错误';

  @override
  String get loadingContent => '加载中内容...';

  @override
  String get refreshingContent => 'Refreshing 内容...';

  @override
  String get loadingMoreContent => '加载中 more 内容...';

  @override
  String get latestContent => 'Latest 内容';

  @override
  String get noInternetConnection => '无网络连接';

  @override
  String get serverTemporarilyUnavailable =>
      '服务器 is temporarily不可用. Please try again later.';

  @override
  String get failedToLoadContent => '无法load 内容';

  @override
  String get cloudflareProtectionDetected =>
      'Cloudflare protection detected. Please wait and try again.';

  @override
  String get tooManyRequestsWait =>
      'Too many requests. Please wait a moment before trying again.';

  @override
  String get noContentFoundMatching =>
      '未找到content matching your 搜索criteria. Try adjusting your filters.';

  @override
  String noContentFoundForTag(String tagName) {
    return '未找到content for 标签 \"$tagName\".';
  }

  @override
  String get removeSomeFilters => '移除some filters';

  @override
  String get checkSpelling => 'Check spelling';

  @override
  String get useGeneralTerms => 'Use more general 搜索terms';

  @override
  String get browsePopularContent => 'Browse 热门内容';

  @override
  String get tryBrowsingOtherTags => 'Try browsing other tags';

  @override
  String get checkPopularContent => 'Check 热门内容';

  @override
  String get useSearchFunction => 'Use the 搜索function';

  @override
  String get checkInternetConnectionSuggestion => 'Check your internet 连接';

  @override
  String get tryRefreshingPage => 'Try refreshing the 页面';

  @override
  String get browsePopularContentSuggestion => 'Browse 热门内容';

  @override
  String get failedToInitializeSearch => '无法initialize 搜索';

  @override
  String noResultsFoundFor(String query) {
    return '未找到results for \"$query\"';
  }

  @override
  String get searchingWithFilters => '搜索ing with filters...';

  @override
  String get noResultsFoundWithCurrentFilters => '未找到results with 当前 filters';

  @override
  String invalidFilter(String errors) {
    return 'Invalid filter: $errors';
  }

  @override
  String invalidSearchFilter(String errors) {
    return 'Invalid 搜索filter: $errors';
  }

  @override
  String get pages => '页数';

  @override
  String get tags => '标签';

  @override
  String get language => '语言';

  @override
  String get uploadedOn => 'Uploaded 开启';

  @override
  String get readNow => '立即阅读';

  @override
  String get featured => 'Featured';

  @override
  String get confirmDownload => '确认下载';

  @override
  String get downloadConfirmation => 'Are you sure you want to 下载?';

  @override
  String get confirmButton => '确认';

  @override
  String get download => '下载';

  @override
  String get downloading => '下载中';

  @override
  String get downloadCompleted => '下载 Completed';

  @override
  String get downloadFailed => 'Download失败';

  @override
  String get initializing => 'Initializing...';

  @override
  String get noContentToBrowse => '否内容 loaded to 打开 in 浏览器';

  @override
  String get addToFavorites => '添加到收藏';

  @override
  String get removeFromFavorites => '从收藏中移除';

  @override
  String get content => '内容';

  @override
  String get view => '查看';

  @override
  String get clearAll => '清除全部';

  @override
  String get exportList => 'Export 列表';

  @override
  String get unableToCheck => 'Unable to check 连接.';

  @override
  String get noContentAvailable => '无content可用';

  @override
  String get noContentToDownload => '无content可用 to 下载';

  @override
  String get noGalleriesFound => '未找到galleries 开启 this 页面';

  @override
  String get noContentLoadedToBrowse => '否内容 loaded to 打开 in 浏览器';

  @override
  String get showCachedContent => '显示Cached 内容';

  @override
  String get openedInBrowser => 'Opened in 浏览器';

  @override
  String get foundGalleries => 'Found Galleries';

  @override
  String get checkingDownloadStatus => 'Checking 下载状态...';

  @override
  String get allGalleriesDownloaded => '全部 Galleries Downloaded';

  @override
  String downloadStarted(String title) {
    return '下载 Started';
  }

  @override
  String get downloadNewGalleries => '下载新 Galleries';

  @override
  String get downloadProgress => '下载进度';

  @override
  String get downloadComplete => '下载 Complete';

  @override
  String get downloadError => '下载错误';

  @override
  String get verifyingFiles => '验证文件';

  @override
  String verifyingFilesWithTitle(String title) {
    return '验证 $title...';
  }

  @override
  String verifyingProgress(int progress) {
    return '验证中 ($progress%)';
  }

  @override
  String get initializingDownloads => 'Initializing downloads...';

  @override
  String get loadingDownloads => '加载中 downloads...';

  @override
  String get pauseAll => 'Pause 全部';

  @override
  String get resumeAll => 'Resume 全部';

  @override
  String get cancelAll => '取消 全部';

  @override
  String get clearCompleted => '清除 已完成';

  @override
  String get cleanupStorage => 'Cleanup 存储';

  @override
  String get all => '全部';

  @override
  String get active => '进行中';

  @override
  String get completed => '已完成';

  @override
  String get noDownloadsYet => '暂无下载';

  @override
  String get noActiveDownloads => '无active downloads';

  @override
  String get noQueuedDownloads => '无queued downloads';

  @override
  String get noCompletedDownloads => '无completed downloads';

  @override
  String get noFailedDownloads => 'No失败 downloads';

  @override
  String pdfConversionStarted(String contentId) {
    return 'PDF conversion started for $contentId';
  }

  @override
  String get cancelAllDownloads => '取消 全部 下载';

  @override
  String get cancelAllConfirmation =>
      'Are you sure you want to 取消全部 active downloads? This 操作 cannot be undone.';

  @override
  String get cancelDownload => '取消下载';

  @override
  String get cancelDownloadConfirmation =>
      'Are you sure you want to 取消 this 下载? 进度 will be lost.';

  @override
  String get removeDownload => '移除Download';

  @override
  String get removeDownloadConfirmation =>
      'Are you sure you want to 移除this 下载 from the 列表? Downloaded files will be已删除.';

  @override
  String get cleanupConfirmation =>
      'This will 移除orphaned files and clean up失败 downloads. Continue?';

  @override
  String get downloadDetails => '下载详情';

  @override
  String get status => '状态';

  @override
  String get progress => '进度';

  @override
  String get progressPercent => '进度 %';

  @override
  String get speed => '速度';

  @override
  String get size => '大小';

  @override
  String get started => 'Started';

  @override
  String get ended => 'Ended';

  @override
  String get duration => '时长';

  @override
  String get eta => 'ETA';

  @override
  String get queued => '排队中';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get resume => '继续';

  @override
  String get failed => '失败';

  @override
  String get downloadListExported => '下载列表 exported';

  @override
  String get downloadAll => '全部下载';

  @override
  String get downloadRange => '下载 Range';

  @override
  String get selectDownloadRange => '选择下载 Range';

  @override
  String get totalPages => '总计 Pages';

  @override
  String get useSliderToSelectRange => 'Use slider to 选择 range:';

  @override
  String get orEnterManually => 'Or 输入manually:';

  @override
  String get startPage => '开始页面';

  @override
  String get endPage => '结束页面';

  @override
  String get quickSelections => 'Quick selections:';

  @override
  String get allPages => '全部 页数';

  @override
  String get firstHalf => 'First Half';

  @override
  String get secondHalf => 'Second Half';

  @override
  String get first10 => 'First 10';

  @override
  String get last10 => 'Last 10';

  @override
  String countAlreadyDownloaded(int count) {
    return 'Skipped $count already downloaded';
  }

  @override
  String newGalleriesToDownload(int count) {
    return '• $count 新 galleries to 下载';
  }

  @override
  String alreadyDownloaded(int count) {
    return '• $count already downloaded (will be skipped)';
  }

  @override
  String downloadNew(int count) {
    return '下载 $count 新';
  }

  @override
  String queuedDownloads(int count) {
    return 'Queued $count 新 downloads';
  }

  @override
  String downloadInfo(int count) {
    return '下载 $count 新 galleries?\\n\\nThis may take significant 时间 and 存储 space.';
  }

  @override
  String get failedToDownload => '无法download galleries';

  @override
  String selectedPagesTo(int start, int end) {
    return 'Selected: Pages $start to $end';
  }

  @override
  String pagesPercentage(int count, String percentage) {
    return '$count pages ($percentage%)';
  }

  @override
  String rangeDownloadStarted(String title, String pageText) {
    return 'Range 下载 started: $title ($pageText)';
  }

  @override
  String opening(String title) {
    return 'Opening: $title';
  }

  @override
  String get lastUpdatedLabel => 'Updated:';

  @override
  String get rangeLabel => 'Range:';

  @override
  String get ofWord => 'of';

  @override
  String waitAndTry(int minutes) {
    return 'Wait $minutes minutes and try again';
  }

  @override
  String get serviceUnderMaintenance =>
      'The service might be under maintenance';

  @override
  String get waitForBypass => 'Wait for automatic bypass to complete';

  @override
  String get tryUsingVpn => 'Try using a VPN if可用';

  @override
  String get checkBackLater => 'Check 返回 in a few minutes';

  @override
  String get tryRefreshingContent => 'Try refreshing the 内容';

  @override
  String get checkForAppUpdate => 'Check if the 应用 needs an 更新';

  @override
  String get reportIfPersists => 'Report the issue if it persists';

  @override
  String get maintenanceTakesHours => 'Maintenance usually takes a few hours';

  @override
  String get checkSocialMedia => 'Check social media for updates';

  @override
  String get tryAgainLater => '请稍后重试';

  @override
  String get serverUnavailable =>
      'The 服务器 is currently不可用. Please try again later.';

  @override
  String get useBroaderSearchTerms => 'Use broader 搜索terms';

  @override
  String get welcomeTitle => '欢迎使用 KomikTap！';

  @override
  String get welcomeMessage => '感谢您安装我们的应用。在开始之前，请注意：';

  @override
  String get ispBlockingInfo => '🚨 ISP 封锁通知';

  @override
  String get ispBlockingMessage =>
      '如果此应用被您的 ISP（互联网服务提供商）封锁，请使用 VPN（如 Cloudflare WARP 1.1.1.1）来访问内容。';

  @override
  String get downloadWarp => '下载 1.1.1.1 VPN';

  @override
  String get permissionsRequired => '所需权限';

  @override
  String get storagePermissionInfo => '📁 存储：下载和离线保存内容所需';

  @override
  String get notificationPermissionInfo => '🔔 通知：显示下载进度和完成通知所需';

  @override
  String get grantStoragePermission => '授予存储权限';

  @override
  String get grantNotificationPermission => '授予通知权限';

  @override
  String get storageGranted => '✅ 存储权限已授予';

  @override
  String get notificationGranted => '✅ 通知权限已授予';

  @override
  String get getStarted => '开始使用';

  @override
  String get pleaseGrantAllPermissions => '请授予所有必需的权限以继续';

  @override
  String get permissionDenied => '权限被拒绝。某些功能可能无法正常工作。';

  @override
  String get loadingFavorites => '加载中收藏...';

  @override
  String get errorLoadingFavorites => '错误 加载中 收藏';

  @override
  String get removeFavorite => '移除Favorite';

  @override
  String get removeFavoriteConfirmation =>
      'Are you sure you want to 移除this 内容 from 收藏?';

  @override
  String get removeAction => '移除';

  @override
  String get deleteFavorites => '删除 收藏';

  @override
  String deleteFavoritesConfirmation(int count, String s) {
    return 'Are you sure you want to 移除$count favorite$s?';
  }

  @override
  String get exportFavorites => '导出 收藏';

  @override
  String get noFavoritesYet => '否收藏 yet. 开始 adding 内容 to your 收藏!';

  @override
  String get exportingFavorites => 'Exporting 收藏...';

  @override
  String get exportComplete => '导出 Complete';

  @override
  String exportedFavoritesCount(int count) {
    return 'Exported $count favorites成功ly.';
  }

  @override
  String exportFailed(String error) {
    return 'Export失败: $error';
  }

  @override
  String selectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get selectFavorites => '选择收藏';

  @override
  String get exportAction => '导出';

  @override
  String get refreshAction => '刷新';

  @override
  String get deleteSelected => '已选择删除项';

  @override
  String get searchFavorites => '搜索favorites...';

  @override
  String get selectAll => '全选';

  @override
  String get clearSelection => '清除';

  @override
  String get removingFromFavorites => 'Removing from 收藏...';

  @override
  String get removedFromFavorites => 'Removed from 收藏';

  @override
  String failedToRemoveFavorite(String error) {
    return '无法移除favorite: $error';
  }

  @override
  String removedFavoritesCount(int count) {
    return 'Removed $count 收藏';
  }

  @override
  String failedToRemoveFavorites(String error) {
    return '无法移除favorites: $error';
  }

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get imageQuality => '图片质量';

  @override
  String get blurThumbnails => 'Blur 缩略图s';

  @override
  String get blurThumbnailsDescription =>
      'Apply blur effect 开启卡片 images for privacy';

  @override
  String get gridColumns => '网格 Columns (竖屏)';

  @override
  String get reader => '阅读器';

  @override
  String get showSystemUIInReader => '显示System UI in Reader';

  @override
  String get historyCleanup => '历史 Cleanup';

  @override
  String get autoCleanupHistory => '自动 Cleanup 历史';

  @override
  String get automaticallyCleanOldReadingHistory =>
      'Automatically clean 旧 reading 历史';

  @override
  String get cleanupInterval => 'Cleanup Interval';

  @override
  String get howOftenToCleanupHistory => 'How often to cleanup 历史';

  @override
  String get maxHistoryDays => '最大历史 Days';

  @override
  String get maximumDaysToKeepHistory =>
      'Maximum days to keep 历史 (0 = unlimited)';

  @override
  String get cleanupOnInactivity => 'Cleanup 开启 Inactivity';

  @override
  String get cleanHistoryWhenAppUnused =>
      'Clean 历史 when 应用 is unused for several days';

  @override
  String get inactivityThreshold => 'Inactivity Threshold';

  @override
  String get daysOfInactivityBeforeCleanup =>
      'Days of inactivity before cleanup';

  @override
  String get resetToDefault => '重置 to 默认';

  @override
  String get resetToDefaults => '重置 to Defaults';

  @override
  String get generalSettings => '通用 设置';

  @override
  String get displaySettings => '显示';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get systemMode => '跟随系统';

  @override
  String get appLanguage => '应用语言';

  @override
  String get allowAnalytics => '全部ow Analytics';

  @override
  String get privacyAnalytics => '隐私 Analytics';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get termsAndConditionsSubtitle => '用户 agreement and disclaimers';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get privacyPolicySubtitle => 'How we handle your data';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Frequently asked questions';

  @override
  String get resetSettings => '重置 设置';

  @override
  String get resetReaderSettings => '重置 阅读器 设置';

  @override
  String get resetReaderSettingsConfirmation =>
      'This will 重置全部 reader设置 to their 默认 values:\n\n';

  @override
  String get readingModeLabel => '阅读模式: 水平 页数';

  @override
  String get keepScreenOnLabel => 'Keep 屏幕 On: 关闭';

  @override
  String get showUILabel => '显示UI: 开启';

  @override
  String get areYouSure => 'Are you sure you want to proceed?';

  @override
  String get readerSettingsResetSuccess => 'Reader设置 have been 重置 to defaults.';

  @override
  String failedToResetSettings(String error) {
    return '无法reset设置: $error';
  }

  @override
  String get readingHistory => 'Reading 历史';

  @override
  String get clearAllHistory => '清除 全部 历史';

  @override
  String get manualCleanup => '手动 Cleanup';

  @override
  String get cleanupSettings => 'Cleanup设置';

  @override
  String get removeFromHistory => '移除from 历史';

  @override
  String get removeFromHistoryQuestion => '移除this 项目 from reading 历史?';

  @override
  String get cleanup => 'Cleanup';

  @override
  String get failedToLoadCleanupStatus => '无法load cleanup 状态';

  @override
  String get manualCleanupConfirmation =>
      'This will perform cleanup based 开启 your current设置. Continue?';

  @override
  String get noReadingHistory => '无Reading 历史';

  @override
  String get errorLoadingHistory => '错误 加载中 历史';

  @override
  String get nextPage => '下一步 页';

  @override
  String get previousPage => '上一步 页';

  @override
  String get pageOf => 'of';

  @override
  String get fullscreen => '全屏';

  @override
  String get exitFullscreen => '退出全屏';

  @override
  String get checkingConnection => 'Checking 连接...';

  @override
  String get backOnline => '返回 online! 全部 features可用.';

  @override
  String get stillNoInternet => 'Still 无internet 连接.';

  @override
  String get unableToCheckConnection => 'Unable to check 连接.';

  @override
  String get connectionError => '连接错误';

  @override
  String get low => '低';

  @override
  String get medium => '中';

  @override
  String get high => '高';

  @override
  String get original => '原图';

  @override
  String get lowFaster => '低 (Faster)';

  @override
  String get highBetterQuality => '高 (Better 质量)';

  @override
  String get originalLargest => '原图 (Largest)';

  @override
  String get lowQuality => '低 (Faster)';

  @override
  String get mediumQuality => '中';

  @override
  String get highQuality => '高 (Better 质量)';

  @override
  String get originalQuality => '原图 (Largest)';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get amoled => 'AMOLED';

  @override
  String get english => 'English';

  @override
  String get japanese => 'Japanese';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get chinese => '中文（简体）';

  @override
  String get comfortReading => 'Comfortable Reading';

  @override
  String get sortBy => '排序方式';

  @override
  String get filterBy => '筛选 by';

  @override
  String get recent => '最近';

  @override
  String get popular => '热门';

  @override
  String get oldest => '最早';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get exitApp => '退出应用';

  @override
  String get areYouSureExit => 'Are you sure you want to 退出 the 应用?';

  @override
  String get exit => '退出';

  @override
  String get delete => '删除';

  @override
  String get confirm => '确认';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get tryAgain => '重试';

  @override
  String get save => '保存';

  @override
  String get edit => '编辑';

  @override
  String get close => '关闭';

  @override
  String get clear => '清除';

  @override
  String get remove => '移除';

  @override
  String get share => '分享';

  @override
  String get goBack => '前往 返回';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get previous => '上一步';

  @override
  String get next => '下一步';

  @override
  String get goToDownloads => '前往 to 下载';

  @override
  String get retryAction => '重试';

  @override
  String hours(int count) {
    return '${count}h';
  }

  @override
  String days(int count) {
    return '$count days';
  }

  @override
  String get unknown => '未知';

  @override
  String daysAgo(int count, String suffix) {
    return '$count$suffix ago';
  }

  @override
  String hoursAgo(int count, String suffix) {
    return '$count$suffix ago';
  }

  @override
  String minutesAgo(int count, String suffix) {
    return '$count$suffix ago';
  }

  @override
  String get noData => '无数据';

  @override
  String get unknownTitle => '未知标题';

  @override
  String get offlineContentError => 'Offline 内容错误';

  @override
  String get other => 'Other';

  @override
  String get confirmResetSettings => 'Are you sure you want to 恢复 all设置 to 默认?';

  @override
  String get reset => '重置';

  @override
  String get manageAutoCleanupDescription =>
      'Manage automatic cleanup of reading 历史 to free up 存储 space.';

  @override
  String get nextCleanup => '下一步 cleanup';

  @override
  String get historyStatistics => '历史 Statistics';

  @override
  String get totalItems => '总计 items';

  @override
  String get lastCleanup => 'Last cleanup';

  @override
  String get lastAppAccess => 'Last 应用 access';

  @override
  String get oneDay => '1 day';

  @override
  String get twoDays => '2 days';

  @override
  String get oneWeek => '1 week';

  @override
  String get privacyInfoText =>
      '• Data is stored 开启 your device\n• Not sent to external servers\n• Only to improve 应用 performance\n• Can be disabled anytime';

  @override
  String get unlimited => 'Unlimited';

  @override
  String daysValue(int days) {
    return '$days days';
  }

  @override
  String get analyticsSubtitle =>
      'Helps 应用 development with 本地 data (not shared)';

  @override
  String get loadingError => '加载中 错误';

  @override
  String get jumpToPage => 'Jump to 页面';

  @override
  String pageInputLabel(int maxPages) {
    return '页面 (1-$maxPages)';
  }

  @override
  String pageOfPages(int current, int total) {
    return '页面 $current of $total';
  }

  @override
  String get jump => '跳转';

  @override
  String get readerSettings => '阅读器 设置';

  @override
  String get readingMode => '阅读模式';

  @override
  String get horizontalPages => '水平 页数';

  @override
  String get verticalPages => '垂直 页数';

  @override
  String get continuousScroll => '连续 Scroll';

  @override
  String get keepScreenOn => '保持屏幕常亮';

  @override
  String get keepScreenOnDescription =>
      'Prevent 屏幕 from turning 关闭 while reading';

  @override
  String get platformNotSupported => 'Platform 否t Supported';

  @override
  String get platformNotSupportedBody =>
      'KomikTap is designed exclusively for Android devices.';

  @override
  String get platformNotSupportedInstall =>
      'Please 安装 and run this 应用开启 an Android device.';

  @override
  String get storagePermissionRequired =>
      '需要Storage 权限 is for downloads. Please grant 存储权限 in app设置.';

  @override
  String get storagePermissionExplanation =>
      'This 应用 needs 存储权限 to 下载 files to your device. Files will be已保存 to the Downloads/nhasix folder.';

  @override
  String get grantPermission => 'Grant 权限';

  @override
  String get permissionRequired => '需要权限';

  @override
  String get storagePermissionSettingsPrompt =>
      '需要Storage 权限 is to 下载 files. Please grant 存储权限 in app设置.';

  @override
  String get openSettings => '打开 设置';

  @override
  String get readingHistoryMessage =>
      'Your reading 历史 will appear here as you read 内容.';

  @override
  String get startReading => '开始阅读';

  @override
  String get searchSomethingInteresting => '搜索for something interesting';

  @override
  String get checkOutFeaturedItems => 'Check out featured items';

  @override
  String get appSubtitleDescription => 'KomikTap Mobile 客户端';

  @override
  String get downloadedGalleries => 'Downloaded galleries';

  @override
  String get favoriteGalleries => 'Favorite galleries';

  @override
  String get viewHistory => '查看历史';

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get downloadAllGalleries => '下载此页面中的所有画廊';

  @override
  String get featureDisabledTitle => '功能不可用';

  @override
  String get downloadFeatureDisabled => '此来源不支持下载功能';

  @override
  String get favoriteFeatureDisabled => '此来源不支持收藏功能';

  @override
  String get featureNotAvailable => '此功能当前不可用';

  @override
  String get chaptersTitle => '章节';

  @override
  String chapterCount(int count) {
    return '$count chapters';
  }

  @override
  String get readChapter => '阅读';

  @override
  String get downloadChapter => '下载章节';

  @override
  String enterPageNumber(int totalPages) {
    return '输入page number (1 - $totalPages)';
  }

  @override
  String get pageNumber => '页面 number';

  @override
  String get go => '前往';

  @override
  String validPageNumberError(int totalPages) {
    return 'Please 输入a valid 页面 number between 1 and $totalPages';
  }

  @override
  String get tapToJump => 'Tap to jump';

  @override
  String get goToPage => 'Go to 页面';

  @override
  String get previousPageTooltip => '上一步页面';

  @override
  String get nextPageTooltip => '下一步页面';

  @override
  String get tapToJumpToPage => 'Tap to jump to 页面';

  @override
  String get loadingContentTitle => '加载中内容';

  @override
  String get loadingContentDetails => '加载中内容详情';

  @override
  String get fetchingMetadata => 'Fetching metadata and images...';

  @override
  String get thisMayTakeMoments => 'This may take a few moments';

  @override
  String get youAreOffline => 'You are offline. Some features may be limited.';

  @override
  String get goOnline => '前往 在线';

  @override
  String get youAreOfflineTapToGoOnline => 'You are offline. Tap to go online.';

  @override
  String get contentInformation => '内容 Information';

  @override
  String get copyLink => '复制链接';

  @override
  String get moreOptions => 'More 选项';

  @override
  String get moreLikeThis => 'More Like This';

  @override
  String get statistics => 'Statistics';

  @override
  String get shareContent => '分享内容';

  @override
  String get sharePanelOpened => '分享 panel opened成功ly!';

  @override
  String get shareFailed => 'Share失败, but 链接 copied to clipboard';

  @override
  String downloadStartedFor(String title) {
    return '下载 started for \"$title\"';
  }

  @override
  String get viewDownloadsAction => '查看';

  @override
  String failedToStartDownload(String error) {
    return '无法start download: $error';
  }

  @override
  String get linkCopiedToClipboard => '链接 copied to clipboard';

  @override
  String get failedToCopyLink => '无法copy 链接. Please try again.';

  @override
  String get copiedLink => 'Copied 链接';

  @override
  String get linkCopiedToClipboardDescription =>
      'The following 链接 has been copied to your clipboard:';

  @override
  String get closeDialog => '关闭';

  @override
  String get goOnlineDialogTitle => '前往 在线';

  @override
  String get goOnlineDialogContent =>
      'You are currently in offline模式. Would you like to go online to access the latest 内容?';

  @override
  String get goingOnline => '前往ing online...';

  @override
  String get idLabel => 'ID';

  @override
  String get pagesLabel => '页数';

  @override
  String get languageLabel => '语言';

  @override
  String get artistLabel => '画师';

  @override
  String get charactersLabel => '角色';

  @override
  String get parodiesLabel => '原作';

  @override
  String get groupsLabel => '社团';

  @override
  String get uploadedLabel => 'Uploaded';

  @override
  String get viewAllChapters => '查看所有章节';

  @override
  String get searchChapters => '搜索章节...';

  @override
  String get noChaptersFound => '未找到章节';

  @override
  String get favoritesLabel => '收藏';

  @override
  String get tagsLabel => '标签';

  @override
  String get artistsLabel => '画师';

  @override
  String get relatedLabel => 'Related';

  @override
  String yearAgo(int count, String plural) {
    return '$count year$plural ago';
  }

  @override
  String monthAgo(int count, String plural) {
    return '$count month$plural ago';
  }

  @override
  String dayAgo(int count, String plural) {
    return '$count day$plural ago';
  }

  @override
  String hourAgo(int count, String plural) {
    return '$count hour$plural ago';
  }

  @override
  String get selectFavoritesTooltip => '选择收藏';

  @override
  String get deleteSelectedTooltip => '已选择删除项';

  @override
  String get selectAllAction => '全选';

  @override
  String get clearAction => '清除';

  @override
  String selectedCountFormat(int selected, int total) {
    return '$selected / $total';
  }

  @override
  String get loadingFavoritesMessage => '加载中收藏...';

  @override
  String get deletingFavoritesMessage => 'Deleting 收藏...';

  @override
  String get removingFromFavoritesMessage => 'Removing from 收藏...';

  @override
  String get favoritesDeletedMessage => 'Favorites已删除成功ly';

  @override
  String get failedToDeleteFavoritesMessage => '无法删除favorites';

  @override
  String get confirmDeleteFavoritesTitle => '删除 收藏';

  @override
  String confirmDeleteFavoritesMessage(int count, String plural) {
    return 'Are you sure you want to 删除$count favorite$plural?';
  }

  @override
  String get exportFavoritesTitle => '导出 收藏';

  @override
  String get exportingFavoritesMessage => 'Exporting 收藏...';

  @override
  String get favoritesExportedMessage => '收藏 exported成功ly';

  @override
  String get failedToExportFavoritesMessage => '无法export 收藏';

  @override
  String get searchFavoritesHint => '搜索favorites...';

  @override
  String get searchOfflineContentHint => '搜索offline 内容...';

  @override
  String failedToLoadPage(int pageNumber) {
    return '无法load 页面 $pageNumber';
  }

  @override
  String get failedToLoad => '加载失败';

  @override
  String get loginRequiredForAction => '需要Login for this 操作';

  @override
  String get login => '登录';

  @override
  String get offlineContentTitle => 'Offline 内容';

  @override
  String get favorited => 'Favorited';

  @override
  String get favorite => 'Favorite';

  @override
  String get errorLoadingFavoritesTitle => '错误 加载中 收藏';

  @override
  String get filterDataTitle => '筛选 Data';

  @override
  String get clearAllAction => '清除全部';

  @override
  String searchFilterHint(String filterType) {
    return '搜索$filterType...';
  }

  @override
  String selectedCountFormat2(int count) {
    return 'Selected ($count)';
  }

  @override
  String get errorLoadingFilterDataTitle => '加载中筛选 data错误';

  @override
  String noFilterTypeAvailable(String filterType) {
    return '无$filterType可用';
  }

  @override
  String noResultsFoundForQuery(String query) {
    return '未找到results for \"$query\"';
  }

  @override
  String get contentNotFoundTitle => '内容 Not Found';

  @override
  String contentNotFoundMessage(String contentId) {
    return '内容 with ID \"$contentId\" was not found.';
  }

  @override
  String get filterCategoriesTitle => '筛选 分类';

  @override
  String get searchTitle => '搜索';

  @override
  String get advancedSearchTitle => '高级 搜索';

  @override
  String get enterSearchQueryHint => '输入搜索query (e.g. \"big breasts english\")';

  @override
  String get popularSearchesTitle => '热门 Searches';

  @override
  String get recentSearchesTitle => '最近 Searches';

  @override
  String get pressSearchButtonMessage =>
      'Press the 搜索button to find 内容 with your 当前 filters';

  @override
  String get searchingMessage => '搜索ing...';

  @override
  String resultsCountFormat(String count) {
    return '$count results';
  }

  @override
  String get viewInMainAction => '查看 in 主页';

  @override
  String get searchErrorTitle => '搜索 错误';

  @override
  String get noResultsFoundTitle => '未找到结果';

  @override
  String pageText(int pageNumber) {
    return '页面 $pageNumber';
  }

  @override
  String pagesText(int startPage, int endPage) {
    return 'pages $startPage-$endPage';
  }

  @override
  String get offlineStatus => '离线';

  @override
  String get onlineStatus => '在线';

  @override
  String get errorOccurred => '发生错误';

  @override
  String get tapToRetry => '点击重试';

  @override
  String get helpTitle => '帮助';

  @override
  String get helpNoResults => '未找到results for your 搜索';

  @override
  String get helpTryDifferent =>
      'Try using different keywords or check your spelling';

  @override
  String get helpUseFilters => 'Use filters to narrow down your 搜索';

  @override
  String get helpCheckConnection => 'Check your internet 连接';

  @override
  String get sendReportText => 'Send Report';

  @override
  String get technicalDetailsTitle => 'Technical 详情';

  @override
  String get reportSentText => 'Report sent!';

  @override
  String get suggestionCheckConnection => 'Check your internet 连接';

  @override
  String get suggestionTryWifiMobile =>
      'Try switching between WiFi and mobile data';

  @override
  String get suggestionRestartRouter => 'Restart your router if using WiFi';

  @override
  String get suggestionCheckWebsite => 'Check if the website is down';

  @override
  String noContentFoundWithQuery(String query) {
    return '未找到content for \"$query\". Try adjusting your 搜索terms or filters.';
  }

  @override
  String get noContentFound =>
      '未找到content. Try adjusting your 搜索terms or filters.';

  @override
  String get suggestionTryDifferentKeywords => 'Try different keywords';

  @override
  String get suggestionRemoveFilters => '移除some filters';

  @override
  String get suggestionCheckSpelling => 'Check spelling';

  @override
  String get suggestionUseBroaderTerms => 'Use broader 搜索terms';

  @override
  String get underMaintenanceTitle => 'Under Maintenance';

  @override
  String get underMaintenanceMessage =>
      'The service is currently under maintenance. Please check 返回 later.';

  @override
  String get suggestionMaintenanceHours =>
      'Maintenance usually takes a few hours';

  @override
  String get suggestionCheckSocial => 'Check social media for updates';

  @override
  String get suggestionTryLater => '请稍后重试';

  @override
  String get includeFilter => 'Include';

  @override
  String get excludeFilter => 'Exclude';

  @override
  String get overallProgress => 'Overall 进度';

  @override
  String get total => '总计';

  @override
  String get done => '完成';

  @override
  String downloadsFailed(int count, String plural) {
    return '$count download$plural失败';
  }

  @override
  String get processing => 'Processing...';

  @override
  String get readingCompleted => '已完成';

  @override
  String get readAgain => 'Read Again';

  @override
  String get continueReading => '继续阅读';

  @override
  String get lessThanOneMinute => 'Less than 1 minute';

  @override
  String get readingTime => 'reading 时间';

  @override
  String get downloadActions => '下载 Actions';

  @override
  String get pause => '暂停';

  @override
  String get convertToPdf => 'Convert to PDF';

  @override
  String get details => '详情';

  @override
  String get downloadActionPause => '暂停';

  @override
  String get downloadActionResume => '继续';

  @override
  String get downloadActionCancel => '取消';

  @override
  String get downloadActionRetry => '重试';

  @override
  String get downloadActionConvertToPdf => 'Convert to PDF';

  @override
  String get downloadActionDetails => '详情';

  @override
  String get downloadActionRemove => '移除';

  @override
  String downloadPagesRangeFormat(
      int downloaded, int total, int start, int end, int totalPages) {
    return '$downloaded/$total (页数 $start-$end of $totalPages)';
  }

  @override
  String downloadPagesFormat(int downloaded, int total) {
    return '$downloaded/$total';
  }

  @override
  String downloadContentTitle(String contentId) {
    return '内容 $contentId';
  }

  @override
  String downloadEtaLabel(String duration) {
    return 'ETA: $duration';
  }

  @override
  String get downloadSettingsTitle => 'Download设置';

  @override
  String get performanceSection => 'Performance';

  @override
  String get maxConcurrentDownloads => '最大 Concurrent Downloads';

  @override
  String get concurrentDownloadsWarning =>
      '高er values may consume more bandwidth and device resources';

  @override
  String get imageQualityLabel => '图片质量';

  @override
  String get autoRetrySection => '自动 重试';

  @override
  String get autoRetryFailedDownloads => '自动 重试 失败 下载';

  @override
  String get autoRetryDescription => 'Automatically retry失败 downloads';

  @override
  String get maxRetryAttempts => '最大 Retry Attempts';

  @override
  String get networkSection => '网络';

  @override
  String get wifiOnlyLabel => 'WiFi Only';

  @override
  String get wifiOnlyDescription => 'Only 下载 when connected to WiFi';

  @override
  String get downloadTimeoutLabel => '下载 Timeout';

  @override
  String get notificationsSection => '通知';

  @override
  String get enableNotificationsLabel => '启用Notifications';

  @override
  String get enableNotificationsDescription => '显示notifications for 下载进度';

  @override
  String get minutesUnit => '最小';

  @override
  String get searchContentHint => '搜索content...';

  @override
  String get hideFiltersTooltip => '隐藏filters';

  @override
  String get showMoreFiltersTooltip => '显示more filters';

  @override
  String get advancedFiltersTitle => '高级 筛选s';

  @override
  String get sortByLabel => '排序方式';

  @override
  String get categoryLabel => '分类';

  @override
  String get includeTagsLabel => 'Include tags (comma separated)';

  @override
  String get includeTagsHint => 'e.g., romance, comedy, school';

  @override
  String get excludeTagsLabel => 'Exclude 标签';

  @override
  String get excludeTagsHint => 'e.g., horror, violence';

  @override
  String get artistsHint => 'e.g., artist1, artist2';

  @override
  String get pageCountRangeTitle => '页面数量 Range';

  @override
  String get minPagesLabel => '最小 pages';

  @override
  String get maxPagesLabel => '最大 pages';

  @override
  String get rangeToSeparator => 'to';

  @override
  String get popularTagsTitle => '热门 Tags';

  @override
  String get filtersActiveLabel => '进行中';

  @override
  String get clearAllFilters => '清除全部';

  @override
  String get initializingApp => 'Initializing Application...';

  @override
  String get settingUpComponents => 'Setting up components and checking 连接...';

  @override
  String get bypassingProtection =>
      'Bypassing protection and establishing 连接...';

  @override
  String get connectionFailed => 'Connection失败';

  @override
  String get readyToGo => 'Ready to 前往!';

  @override
  String get launchingApp => 'Launching 主页 application...';

  @override
  String get imageNotAvailable => '图片 not可用';

  @override
  String loadingPage(int pageNumber) {
    return '加载中页面 $pageNumber...';
  }

  @override
  String selectedItemsCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get noImage => '否图片';

  @override
  String get youAreOfflineShort => 'You are offline';

  @override
  String get someFeaturesLimited =>
      'Some features are limited. Connect to internet for full access.';

  @override
  String get wifi => 'WIFI';

  @override
  String get ethernet => 'ETHERNET';

  @override
  String get mobile => 'MOBILE';

  @override
  String get online => '在线';

  @override
  String get offlineMode => 'Offline模式';

  @override
  String get applySearch => 'Apply 搜索';

  @override
  String get addFiltersToSearch => '添加 filters above to 启用search';

  @override
  String get startSearching => '开始 searching';

  @override
  String get enterKeywordsAdvancedHint =>
      '输入keywords, tags, or use advanced filters to find 内容';

  @override
  String get filtersReady => '筛选s Ready';

  @override
  String get clearAllFiltersTooltip => '清除all filters';

  @override
  String get offlineSomeFeaturesUnavailable =>
      'You are offline. Some features may not be可用.';

  @override
  String get usingDownloadedContentOnly => 'Using downloaded 内容 only';

  @override
  String get onlineModeWithNetworkAccess => 'Online模式 with 网络 access';

  @override
  String get tagsScreenPlaceholder => 'Tags 屏幕 - To be implemented';

  @override
  String get artistsScreenPlaceholder => 'Artists 屏幕 - To be implemented';

  @override
  String get statusScreenPlaceholder => '状态屏幕 - To be implemented';

  @override
  String get pageNotFound => '页面 Not Found';

  @override
  String pageNotFoundWithUri(String uri) {
    return '页面 not found: $uri';
  }

  @override
  String get goHome => '前往 首页';

  @override
  String get debugThemeInfo => 'DEBUG: 主题信息';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get amoledTheme => 'AMOLED';

  @override
  String get systemMessages => '系统 Messages and Background Services';

  @override
  String get notificationMessages => '通知 Messages';

  @override
  String get convertingToPdf => 'Converting to PDF...';

  @override
  String convertingToPdfWithTitle(String title) {
    return 'Converting $title to PDF...';
  }

  @override
  String convertingToPdfProgress(Object progress) {
    return 'Converting to PDF ($progress%)';
  }

  @override
  String convertingToPdfProgressWithTitle(String title, int progress) {
    return 'Converting $title to PDF ($progress%)';
  }

  @override
  String get pdfCreatedSuccessfully => 'PDF Created成功ly';

  @override
  String pdfCreatedWithParts(String title, int partsCount) {
    return '$title converted to $partsCount PDF files';
  }

  @override
  String pdfConversionFailed(String contentId, String error) {
    return 'PDF conversion失败 for $contentId: $error';
  }

  @override
  String pdfConversionFailedWithError(String title, String error) {
    return 'PDF conversion失败 for $title: $error';
  }

  @override
  String downloadingWithTitle(String title) {
    return 'Downloading: $title';
  }

  @override
  String downloadingProgress(Object progress) {
    return '下载中 ($progress%)';
  }

  @override
  String downloadedWithTitle(String title) {
    return 'Downloaded: $title';
  }

  @override
  String downloadFailedWithTitle(String title) {
    return 'Failed: $title';
  }

  @override
  String get downloadPaused => '已暂停';

  @override
  String get downloadResumed => 'Resumed';

  @override
  String get downloadCancelled => '取消led';

  @override
  String get downloadRetry => '重试';

  @override
  String get downloadOpen => '打开';

  @override
  String get pdfOpen => '打开 PDF';

  @override
  String get pdfShare => '分享';

  @override
  String get pdfRetry => '重试 PDF';

  @override
  String get downloadServiceMessages => '下载 Service Messages';

  @override
  String downloadRangeInfo(int startPage, int endPage) {
    return ' (页数 $startPage-$endPage)';
  }

  @override
  String downloadRangeComplete(int startPage, int endPage) {
    return ' (页数 $startPage-$endPage)';
  }

  @override
  String invalidPageRange(int start, int end, int total) {
    return 'Invalid 页面 range: $start-$end (total: $total)';
  }

  @override
  String noDataReceived(String url) {
    return '无data received for image: $url';
  }

  @override
  String createdNoMediaFile(String path) {
    return 'Created .nomedia 文件 for privacy: $path';
  }

  @override
  String get privacyProtectionEnsured =>
      '隐私 protection ensured for existing downloads';

  @override
  String get pdfConversionMessages => 'PDF Conversion Service Messages';

  @override
  String pdfConversionCompleted(String contentId) {
    return 'PDF conversion completed成功ly for $contentId';
  }

  @override
  String pdfPartProcessing(int part) {
    return 'Processing part $part in isolate...';
  }

  @override
  String get pdfSingleProcessing => 'Processing single PDF in isolate...';

  @override
  String pdfSplitRequired(int totalParts, int totalPages) {
    return 'Splitting into $totalParts parts ($totalPages pages)';
  }

  @override
  String pdfCreatedFiles(int partsCount, int pageCount) {
    return 'Created $partsCount PDF file(s) with $pageCount 总计 pages';
  }

  @override
  String get pdfNoImagesProvided => '无images provided for PDF conversion';

  @override
  String pdfFailedToCreatePart(int part, String error) {
    return '无法create PDF part $part: $error';
  }

  @override
  String pdfFailedToCreate(String error) {
    return '无法create PDF: $error';
  }

  @override
  String pdfOutputDirectoryCreated(String path) {
    return 'Created PDF output directory: $path';
  }

  @override
  String pdfUsingFallbackDirectory(String path) {
    return 'Using fallback directory: $path';
  }

  @override
  String pdfInfoSaved(String contentId, int partsCount, int pageCount) {
    return 'PDF info已保存 for $contentId ($partsCount parts, $pageCount pages)';
  }

  @override
  String pdfExistsForContent(String contentId, String exists) {
    return 'PDF exists for $contentId: $exists';
  }

  @override
  String pdfFoundFiles(String contentId, int count) {
    return 'Found $count PDF file(s) for $contentId';
  }

  @override
  String pdfDeletedFiles(String contentId, int count) {
    return 'Successfully已删除 $count PDF file(s) for $contentId';
  }

  @override
  String pdfTotalSize(String contentId, int sizeBytes) {
    return '总计 PDF 大小 for $contentId: $sizeBytes bytes';
  }

  @override
  String pdfCleanupStarted(int maxAge) {
    return 'Starting PDF cleanup, deleting files older than $maxAge days';
  }

  @override
  String pdfCleanupCompleted(int deletedCount) {
    return 'Cleanup completed,已删除 $deletedCount 旧 PDF files';
  }

  @override
  String pdfStatistics(Object averageFilesPerContent, Object totalFiles,
      Object totalSizeFormatted, Object uniqueContents) {
    return 'PDF statistics - $totalFiles files, $totalSizeFormatted 总计大小, $uniqueContents unique contents, $averageFilesPerContent avg files per 内容';
  }

  @override
  String get historyCleanupMessages => '历史 Cleanup Service Messages';

  @override
  String get historyCleanupServiceInitialized =>
      '历史 Cleanup Service initialized';

  @override
  String get historyCleanupServiceDisposed => '历史 Cleanup Service disposed';

  @override
  String get autoCleanupDisabled => '自动 cleanup 历史 is disabled';

  @override
  String cleanupServiceStarted(int intervalHours) {
    return 'Cleanup service started with ${intervalHours}h interval';
  }

  @override
  String performingHistoryCleanup(String reason) {
    return 'Performing 历史 cleanup: $reason';
  }

  @override
  String historyCleanupCompleted(int clearedCount, String reason) {
    return '历史 cleanup completed: cleared $clearedCount entries ($reason)';
  }

  @override
  String get manualHistoryCleanup => 'Performing 手动历史 cleanup';

  @override
  String get updatedLastAppAccess => 'Updated last 应用 access 时间';

  @override
  String get updatedLastCleanupTime => 'Updated last cleanup 时间';

  @override
  String intervalCleanup(int intervalHours) {
    return 'Interval cleanup (${intervalHours}h)';
  }

  @override
  String inactivityCleanup(int inactivityDays) {
    return 'Inactivity cleanup ($inactivityDays days)';
  }

  @override
  String maxAgeCleanup(int maxDays) {
    return '最大 age cleanup ($maxDays days)';
  }

  @override
  String get initialCleanupSetup => 'Initial cleanup setup';

  @override
  String shouldCleanupOldHistory(String shouldCleanup) {
    return 'Should cleanup 旧 history: $shouldCleanup';
  }

  @override
  String get analyticsMessages => 'Analytics Service Messages';

  @override
  String analyticsServiceInitialized(String enabled) {
    return 'Analytics service initialized - tracking $enabled';
  }

  @override
  String get analyticsTrackingEnabled => 'Analytics tracking enabled by 用户';

  @override
  String get analyticsTrackingDisabled =>
      'Analytics tracking disabled by 用户 - data cleared';

  @override
  String get analyticsDataCleared => 'Analytics data cleared by 用户 request';

  @override
  String get analyticsServiceDisposed => 'Analytics service disposed';

  @override
  String analyticsEventTracked(String eventType, String eventName) {
    return '📊 Analytics: $eventType - $eventName';
  }

  @override
  String get appStartedEvent => '应用 started event tracked';

  @override
  String sessionEndEvent(int minutes) {
    return 'Session 结束 event tracked ($minutes minutes)';
  }

  @override
  String get analyticsEnabledEvent => 'Analytics enabled event tracked';

  @override
  String get analyticsDisabledEvent => 'Analytics disabled event tracked';

  @override
  String screenViewEvent(String screenName) {
    return '屏幕查看 tracked: $screenName';
  }

  @override
  String userActionEvent(String action) {
    return '用户操作 tracked: $action';
  }

  @override
  String performanceEvent(String operation, int durationMs) {
    return 'Performance tracked: $operation (${durationMs}ms)';
  }

  @override
  String errorEvent(String errorType, String errorMessage) {
    return 'tracked: $errorType - $errorMessage错误';
  }

  @override
  String featureUsageEvent(String feature) {
    return 'Feature usage tracked: $feature';
  }

  @override
  String readingSessionEvent(String contentId, int minutes, int pages) {
    return 'Reading session tracked: $contentId (${minutes}min, $pages pages)';
  }

  @override
  String get offlineManagerMessages => 'Offline 内容 Manager Messages';

  @override
  String offlineContentAvailable(String contentId, String available) {
    return '内容 $contentId is可用 offline: $available';
  }

  @override
  String offlineContentPath(String contentId, String path) {
    return 'Offline 内容 path for $contentId: $path';
  }

  @override
  String foundExistingFiles(int count) {
    return 'Found $count existing downloaded files';
  }

  @override
  String offlineImageUrlsFound(String contentId, int count) {
    return 'Found $count offline 图片 URLs for $contentId';
  }

  @override
  String offlineContentIdsFound(int count) {
    return 'Found $count offline 内容 IDs';
  }

  @override
  String searchingOfflineContent(String query) {
    return 'Searching offline 内容 for: $query';
  }

  @override
  String offlineContentMetadata(String contentId, String source) {
    return 'Offline 内容 metadata for $contentId: $source';
  }

  @override
  String offlineContentCreated(String contentId) {
    return 'Offline 内容 created for $contentId';
  }

  @override
  String offlineStorageUsage(int sizeBytes) {
    return 'Offline 存储 usage: $sizeBytes bytes';
  }

  @override
  String get cleanupOrphanedFilesStarted =>
      'Starting cleanup of orphaned offline files';

  @override
  String get cleanupOrphanedFilesCompleted =>
      'Cleanup of orphaned offline files completed';

  @override
  String removedOrphanedDirectory(String path) {
    return '移除d orphaned directory: $path';
  }

  @override
  String get queryLabel => 'Query';

  @override
  String get excludeGroupsLabel => 'Exclude 社团';

  @override
  String get excludeCharactersLabel => 'Exclude 角色';

  @override
  String get excludeParodiesLabel => 'Exclude 原作';

  @override
  String get excludeArtistsLabel => 'Exclude 画师';

  @override
  String minutes(int count) {
    return '${count}m';
  }

  @override
  String seconds(int count) {
    return '${count}s';
  }

  @override
  String get loadingUserPreferences => '加载中用户 preferences';

  @override
  String get successfullyLoadedUserPreferences =>
      'Successfully loaded 用户 preferences';

  @override
  String invalidColumnsPortraitValue(int value) {
    return 'Invalid columns 竖屏 value: $value';
  }

  @override
  String invalidColumnsLandscapeValue(int value) {
    return 'Invalid columns 横屏 value: $value';
  }

  @override
  String get updatingSettingsViaPreferencesService =>
      'Updating设置 via PreferencesService';

  @override
  String get successfullyUpdatedSettings => 'Successfully已更新设置';

  @override
  String failedToUpdateSetting(String error) {
    return '无法update setting: $error';
  }

  @override
  String get resettingAllSettingsToDefaults => 'Resetting all设置 to defaults';

  @override
  String get successfullyResetAllSettingsToDefaults =>
      'Successfully 重置 all设置 to defaults';

  @override
  String get settingsNotLoaded => '设置 not loaded';

  @override
  String get exportingSettings => 'Exporting设置';

  @override
  String get successfullyExportedSettings => 'Successfully exported设置';

  @override
  String failedToExportSettings(String error) {
    return '无法export设置: $error';
  }

  @override
  String get importingSettings => 'Importing设置';

  @override
  String get successfullyImportedSettings => 'Successfully imported设置';

  @override
  String failedToImportSettings(String error) {
    return '无法import设置: $error';
  }

  @override
  String get unableToSyncSettings =>
      'Unable to sync设置. Changes will be已保存 locally.';

  @override
  String get unableToSaveSettings =>
      'Unable to save设置. Please check device 存储.';

  @override
  String get failedToUpdateSettings => '无法update设置. Please try again.';

  @override
  String get noHistoryFound => '未找到history';

  @override
  String loadedHistoryEntries(int count) {
    return 'Loaded $count 历史 entries';
  }

  @override
  String failedToLoadHistory(String error) {
    return '无法load history: $error';
  }

  @override
  String loadingMoreHistory(int page) {
    return '加载中 more 历史 (页面 $page)';
  }

  @override
  String loadedMoreHistoryEntries(int count, int total) {
    return 'Loaded $count more entries, total: $total';
  }

  @override
  String get refreshingHistory => 'Refreshing 历史';

  @override
  String refreshedHistoryWithEntries(int count) {
    return 'Refreshed 历史 with $count entries';
  }

  @override
  String failedToRefreshHistory(String error) {
    return '无法refresh history: $error';
  }

  @override
  String get clearingAllHistory => 'Clearing 全部历史';

  @override
  String get allHistoryCleared => '全部历史 cleared';

  @override
  String failedToClearHistory(String error) {
    return '无法清除history: $error';
  }

  @override
  String removingHistoryItem(String contentId) {
    return 'Removing 历史 item: $contentId';
  }

  @override
  String removedHistoryItem(String contentId) {
    return 'Removed 历史 item: $contentId';
  }

  @override
  String failedToRemoveHistoryItem(String error) {
    return '无法移除history item: $error';
  }

  @override
  String get performingManualHistoryCleanup => 'Performing 手动历史 cleanup';

  @override
  String get manualCleanupCompleted => '手动 cleanup completed';

  @override
  String failedToPerformCleanup(String error) {
    return '无法perform cleanup: $error';
  }

  @override
  String get updatingCleanupSettings => 'Updating cleanup设置';

  @override
  String get cleanupSettingsUpdated => 'Cleanup设置已更新';

  @override
  String addingContentToFavorites(String title) {
    return 'Adding 内容 to favorites: $title';
  }

  @override
  String successfullyAddedToFavorites(String title) {
    return 'Successfully added to favorites: $title';
  }

  @override
  String contentNotInFavorites(String contentId) {
    return '内容 $contentId is not in 收藏, skipping removal';
  }

  @override
  String callingRemoveFromFavoritesUseCase(String params) {
    return 'Calling removeFrom收藏UseCase with params: $params';
  }

  @override
  String get successfullyCalledRemoveFromFavoritesUseCase =>
      '成功fully called removeFrom收藏UseCase';

  @override
  String updatingFavoritesListInState(String contentId) {
    return 'Updating 收藏列表 in state, removing contentId: $contentId';
  }

  @override
  String favoritesCountBeforeAfter(int before, int after) {
    return '收藏 count: before=$before, after=$after';
  }

  @override
  String get stateUpdatedSuccessfully => 'State已更新成功ly';

  @override
  String successfullyRemovedFromFavorites(String contentId) {
    return '成功fully removed from favorites: $contentId';
  }

  @override
  String errorRemovingContentFromFavorites(String contentId, String error) {
    return 'removing 内容 $contentId from favorites: $error错误';
  }

  @override
  String removingFavoritesInBatch(int count) {
    return 'Removing $count 收藏 in batch';
  }

  @override
  String successfullyRemovedFavoritesInBatch(int count) {
    return 'Successfully removed $count 收藏 in batch';
  }

  @override
  String searchingFavoritesWithQuery(String query) {
    return 'Searching 收藏 with query: $query';
  }

  @override
  String foundFavoritesMatchingQuery(int count) {
    return 'Found $count 收藏 matching query';
  }

  @override
  String get clearingFavoritesSearch => 'Clearing 收藏搜索';

  @override
  String get exportingFavoritesData => 'Exporting 收藏 data';

  @override
  String successfullyExportedFavorites(int count) {
    return 'Successfully exported $count 收藏';
  }

  @override
  String get importingFavoritesData => 'Importing 收藏 data';

  @override
  String successfullyImportedFavorites(int count) {
    return 'Successfully imported $count 收藏';
  }

  @override
  String failedToImportFavorite(String error) {
    return '无法import favorite: $error';
  }

  @override
  String get retryingFavoritesLoading => 'Retrying 收藏加载中';

  @override
  String get refreshingFavorites => 'Refreshing 收藏';

  @override
  String failedToLoadFavorites(String error) {
    return '无法load favorites: $error';
  }

  @override
  String failedToInitializeDownloadManager(String error) {
    return '无法initialize 下载 manager: $error';
  }

  @override
  String get waitingForWifiConnection => 'Waiting for WiFi 连接';

  @override
  String failedToQueueDownload(String error) {
    return '无法queue download: $error';
  }

  @override
  String retryingDownload(int current, int total) {
    return '重试ing... ($current/$total)';
  }

  @override
  String get downloadCancelledByUser => '下载 cancelled by 用户';

  @override
  String failedToPauseDownload(String error) {
    return '无法pause download: $error';
  }

  @override
  String failedToCancelDownload(String error) {
    return '无法cancel download: $error';
  }

  @override
  String failedToRetryDownload(String error) {
    return '无法retry download: $error';
  }

  @override
  String failedToResumeDownload(String error) {
    return '无法resume download: $error';
  }

  @override
  String failedToRemoveDownload(String error) {
    return '无法移除download: $error';
  }

  @override
  String failedToRefreshDownloads(String error) {
    return '无法refresh downloads: $error';
  }

  @override
  String failedToUpdateDownloadSettings(String error) {
    return '无法update download设置: $error';
  }

  @override
  String get pausingAllDownloads => 'Pausing 全部 downloads';

  @override
  String get resumingAllDownloads => 'Resuming 全部 downloads';

  @override
  String get cancellingAllDownloads => 'Cancelling 全部 downloads';

  @override
  String get clearingCompletedDownloads => '清除ing completed downloads';

  @override
  String failedToPauseAllDownloads(String error) {
    return '无法pause 全部 downloads: $error';
  }

  @override
  String failedToResumeAllDownloads(String error) {
    return '无法resume 全部 downloads: $error';
  }

  @override
  String failedToCancelAllDownloads(String error) {
    return '无法cancel 全部 downloads: $error';
  }

  @override
  String failedToQueueRangeDownload(String error) {
    return '无法queue range download: $error';
  }

  @override
  String failedToClearCompletedDownloads(String error) {
    return '无法清除completed downloads: $error';
  }

  @override
  String get downloadNotCompletedYet => '下载 is not completed yet';

  @override
  String get noImagesFoundForConversion => '未找到images for conversion';

  @override
  String storageCleanupCompleted(int cleanedFiles, String freedSpace) {
    return '存储 cleanup completed. Cleaned $cleanedFiles directories, freed $freedSpace MB';
  }

  @override
  String storageCleanupComplete(int cleanedFiles, String freedSpace) {
    return '存储 Cleanup Complete: Cleaned $cleanedFiles items, freed $freedSpace MB';
  }

  @override
  String storageCleanupFailed(String error) {
    return '存储 Cleanup失败: $error';
  }

  @override
  String exportDownloadsComplete(String fileName) {
    return '导出 Complete: 下载 exported to $fileName';
  }

  @override
  String failedToDeleteDirectory(String path, String error) {
    return '无法删除directory: $path, error: $error';
  }

  @override
  String failedToDeleteTempFile(String path, String error) {
    return '无法删除temp file: $path, error: $error';
  }

  @override
  String downloadDirectoryNotFound(String path) {
    return '下载 directory not found: $path';
  }

  @override
  String cannotOpenIncompleteDownload(String contentId) {
    return 'Cannot 打开 - 下载 not completed or path missing for $contentId';
  }

  @override
  String errorOpeningDownloadedContent(String error) {
    return 'opening downloaded content: $error错误';
  }

  @override
  String allStrategiesFailedToOpenDownload(String contentId) {
    return '全部 strategies 无法open downloaded 内容 for $contentId';
  }

  @override
  String failedToSaveProgressToDatabase(String error) {
    return '无法save 进度 to database: $error';
  }

  @override
  String failedToUpdatePauseNotification(String error) {
    return '无法update pause notification: $error';
  }

  @override
  String failedToUpdateResumeNotification(String error) {
    return '无法update resume notification: $error';
  }

  @override
  String failedToUpdateNotificationProgress(String error) {
    return '无法update 通知 progress: $error';
  }

  @override
  String errorCalculatingDirectorySize(String error) {
    return 'calculating directory size: $error错误';
  }

  @override
  String errorCleaningTempFiles(String path, String error) {
    return 'cleaning temp files in: $path, error: $error错误';
  }

  @override
  String errorDetectingDownloadsDirectory(String error) {
    return 'detecting Downloads directory: $error错误';
  }

  @override
  String usingEmergencyFallbackDirectory(String path) {
    return 'Using emergency fallback directory: $path';
  }

  @override
  String get errorDuringStorageCleanup => 'during 存储 cleanup错误';

  @override
  String get errorDuringExport => 'during export错误';

  @override
  String errorDuringPdfConversion(String contentId) {
    return 'during PDF conversion for $contentId错误';
  }

  @override
  String errorRetryingPdfConversion(String error) {
    return 'retrying PDF conversion: $error错误';
  }

  @override
  String get importBackupFolder => '导入 返回up Folder';

  @override
  String get importBackupFolderDescription =>
      '输入the path to your backup folder containing nhasix 内容 folders:';

  @override
  String get scanningBackupFolder => 'Scanning backup folder...';

  @override
  String backupContentFound(int count) {
    return 'Found $count backup items';
  }

  @override
  String get noBackupContentFound => '未找到valid 内容 in backup folder';

  @override
  String errorScanningBackup(String error) {
    return 'scanning backup: $error错误';
  }

  @override
  String get themeDescription => '选择 your preferred 颜色主题 for the 应用 interface.';

  @override
  String get imageQualityDescription =>
      '选择图片质量 for downloads. Higher 质量 uses more 存储 and data.';

  @override
  String get gridColumnsDescription =>
      '选择 how many columns to 显示内容 in portrait模式. More columns 显示more 内容 but smaller items.';

  @override
  String get gridPreview => '网格预览';

  @override
  String get autoCleanupDescription =>
      'Manage automatic cleanup of reading 历史 to free up 存储 space.';

  @override
  String get testCacheClearing => 'Test 应用更新 Cache Clearing';

  @override
  String get testCacheClearingDescription =>
      'Simulate 应用更新 and test cache clearing behavior.';

  @override
  String get forceClearCache => 'Force 清除All Caches';

  @override
  String get forceClearCacheDescription => 'Manually 清除all 图片 caches.';

  @override
  String get runTest => 'Run Test';

  @override
  String get clearCacheButton => '清除缓存';

  @override
  String get disguiseModeDescription =>
      '选择 how the 应用 appears in your launcher for privacy.';

  @override
  String get applyingDisguiseMode => 'Applying disguise模式 changes...';

  @override
  String get disguiseDefault => '默认';

  @override
  String get disguiseCalculator => 'Calculator';

  @override
  String get disguiseNotes => '否tes';

  @override
  String get disguiseWeather => 'Weather';

  @override
  String get storagePermissionScan => '需要Storage 权限 to scan backup folders';

  @override
  String syncResult(int synced, int updated) {
    return 'Sync Result: $synced imported, $updated已更新';
  }

  @override
  String get exportingLibrary => 'Exporting 书库';

  @override
  String get libraryExportSuccess => '书库 exported成功ly!';

  @override
  String get browseDownloads => 'Browse 下载';

  @override
  String deletingContent(String title) {
    return 'Deleting $title...';
  }

  @override
  String contentDeletedFreed(String title, String size) {
    return '$title已删除. Freed $size MB';
  }

  @override
  String failedToDeleteContent(String title) {
    return '无法删除$title';
  }

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get contentDeleted => 'Content已删除';

  @override
  String get cacheManagementDebug => '🚀 Cache Management (Debug)';

  @override
  String get syncStarted => 'Syncing 返回up...';

  @override
  String get syncStartedMessage => 'Scanning and importing offline 内容';

  @override
  String syncInProgress(int percent) {
    return 'Syncing 返回up ($percent%)';
  }

  @override
  String syncProgressMessage(int processed, int total) {
    return 'Processed $processed of $total items';
  }

  @override
  String get syncCompleted => 'Sync 已完成';

  @override
  String syncCompletedMessage(int synced, int updated) {
    return 'Imported: $synced,已更新: $updated';
  }

  @override
  String get storageSection => '存储位置';

  @override
  String get storageLocation => '自定义下载文件夹';

  @override
  String get defaultStorage => '默认（内部存储）';

  @override
  String get storageDescription => '选择保存下载的文件夹';

  @override
  String get backupNotFound => '未找到备份';

  @override
  String get backupNotFoundMessage =>
      '在默认位置未找到\'nhasix\'备份文件夹。您想选择包含备份的自定义文件夹吗？';

  @override
  String get selectFolder => '选择文件夹';

  @override
  String get premiumFeature => 'Premium Feature';

  @override
  String get premiumRequired => '需要高级版';

  @override
  String get premiumRequiredMessage => '此功能仅适用于高级用户。立即升级以解锁所有功能！';

  @override
  String get upgradeToPremium => '升级到高级版';

  @override
  String currentSubscription(String planName, String expiryDate) {
    return '您目前正在使用 $planName，有效期至 $expiryDate';
  }

  @override
  String currentSubscriptionLifetime(String planName) {
    return '您目前正在使用 $planName，终身有效';
  }
}
