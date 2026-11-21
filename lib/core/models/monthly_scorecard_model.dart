
class MonthlyScorecardModel {
  int month; // 1-12
  int year;  // e.g. 2026

  // 1. Top 4 Summary Cards
  double totalSalesActual;
  double totalSalesTarget;
  int salesOrdersActual;
  int salesOrdersTarget;
  double schemeConversionsActual; // in grams (g)
  double schemeConversionsTarget;
  double monthlySchemeActual;
  double monthlySchemeTarget;

  // 2. Instagram
  int instaContentReelActual;
  int instaContentReelTarget;
  int instaProductReelActual;
  int instaProductReelTarget;
  int instaStoriesActual;
  int instaStoriesTarget;
  int instaCarouselActual;
  int instaCarouselTarget;
  int instaCampaignActual;
  int instaCampaignTarget;
  int instaInfluencerActual;
  int instaInfluencerTarget;

  // 3. Website
  int webMnListingActual;
  int webMnListingTarget;
  int webVadivamListingActual;
  int webVadivamListingTarget;
  int webCampaignActual;
  int webCampaignTarget;

  // 4. WhatsApp
  int waStoriesActual;
  int waStoriesTarget;
  int waChannelsActual;
  int waChannelsTarget;
  int waCampaignActual;
  int waCampaignTarget;
  int waBroadcastActual;
  int waBroadcastTarget;

  // 5. Mobile App
  int appMnListingActual;
  int appMnListingTarget;
  int appVadivamListingActual;
  int appVadivamListingTarget;
  int appCampaignActual;
  int appCampaignTarget;
  int appNotificationActual;
  int appNotificationTarget;

  // 6. Google
  int googleBlogsActual;
  int googleBlogsTarget;
  int googleListingActual;
  int googleListingTarget;
  int googleCampaignActual;
  int googleCampaignTarget;

  // 7. Other Social Media
  int osmSnapchatActual;
  int osmSnapchatTarget;
  int osmPinterestActual;
  int osmPinterestTarget;
  int osmShortsActual;
  int osmShortsTarget;
  int osmLinkedinActual;
  int osmLinkedinTarget;
  int osmXPostActual;
  int osmXPostTarget;

  // 8. Designing
  int designResponse;
  int designFeedbackRating;

  // 9. Other Targets
  int downloadsMnActual;
  int downloadsMnTarget;
  int downloadsVadivamActual;
  int downloadsVadivamTarget;
  int followersMnActual;
  int followersMnTarget;
  int followersVadivamActual;
  int followersVadivamTarget;
  int googleReviewsActual;
  int googleReviewsTarget;

  // 10. Performance of Team Members
  double gokulSales;
  double gokulSchemes;
  double gokulGold;

  double kaaviyaSales;
  double kaaviyaSchemes;
  double kaaviyaGold;

  double nishaSales;
  double nishaSchemes;
  double nishaGold;

  double ashaSales;
  double ashaSchemes;
  double ashaGold;

  String topPerformer; // 'Gokul', 'Kaaviya', 'Nisha', 'Asha'

  MonthlyScorecardModel({
    required this.month,
    required this.year,
    this.totalSalesActual = 0.0,
    this.totalSalesTarget = 0.0,
    this.salesOrdersActual = 0,
    this.salesOrdersTarget = 0,
    this.schemeConversionsActual = 0.0,
    this.schemeConversionsTarget = 0.0,
    this.monthlySchemeActual = 0.0,
    this.monthlySchemeTarget = 0.0,
    this.instaContentReelActual = 0,
    int? instaContentReelTarget,
    this.instaProductReelActual = 0,
    int? instaProductReelTarget,
    this.instaStoriesActual = 0,
    this.instaStoriesTarget = 0,
    this.instaCarouselActual = 0,
    this.instaCarouselTarget = 0,
    this.instaCampaignActual = 0,
    this.instaCampaignTarget = 0,
    this.instaInfluencerActual = 0,
    this.instaInfluencerTarget = 0,
    this.webMnListingActual = 0,
    this.webMnListingTarget = 0,
    this.webVadivamListingActual = 0,
    this.webVadivamListingTarget = 0,
    this.webCampaignActual = 0,
    this.webCampaignTarget = 0,
    this.waStoriesActual = 0,
    this.waStoriesTarget = 0,
    this.waChannelsActual = 0,
    this.waChannelsTarget = 0,
    this.waCampaignActual = 0,
    this.waCampaignTarget = 0,
    this.waBroadcastActual = 0,
    this.waBroadcastTarget = 0,
    this.appMnListingActual = 0,
    this.appMnListingTarget = 0,
    this.appVadivamListingActual = 0,
    this.appVadivamListingTarget = 0,
    this.appCampaignActual = 0,
    this.appCampaignTarget = 0,
    this.appNotificationActual = 0,
    this.appNotificationTarget = 0,
    this.googleBlogsActual = 0,
    this.googleBlogsTarget = 0,
    this.googleListingActual = 0,
    this.googleListingTarget = 0,
    this.googleCampaignActual = 0,
    this.googleCampaignTarget = 0,
    this.osmSnapchatActual = 0,
    this.osmSnapchatTarget = 0,
    this.osmPinterestActual = 0,
    this.osmPinterestTarget = 0,
    this.osmShortsActual = 0,
    this.osmShortsTarget = 0,
    this.osmLinkedinActual = 0,
    this.osmLinkedinTarget = 0,
    this.osmXPostActual = 0,
    this.osmXPostTarget = 0,
    this.designResponse = 0,
    this.designFeedbackRating = 0,
    this.downloadsMnActual = 0,
    this.downloadsMnTarget = 0,
    this.downloadsVadivamActual = 0,
    this.downloadsVadivamTarget = 0,
    this.followersMnActual = 0,
    this.followersMnTarget = 0,
    this.followersVadivamActual = 0,
    this.followersVadivamTarget = 0,
    this.googleReviewsActual = 0,
    this.googleReviewsTarget = 0,
    this.gokulSales = 0.0,
    this.gokulSchemes = 0.0,
    this.gokulGold = 0.0,
    this.kaaviyaSales = 0.0,
    this.kaaviyaSchemes = 0.0,
    this.kaaviyaGold = 0.0,
    this.nishaSales = 0.0,
    this.nishaSchemes = 0.0,
    this.nishaGold = 0.0,
    this.ashaSales = 0.0,
    this.ashaSchemes = 0.0,
    this.ashaGold = 0.0,
    this.topPerformer = 'Gokul',
  })  : instaContentReelTarget = instaContentReelTarget ?? DateTime(year, month + 1, 0).day,
        instaProductReelTarget = instaProductReelTarget ?? DateTime(year, month + 1, 0).day;

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  String get shortMonthName => monthName.substring(0, 3);

  String get daySuffix {
    final d = daysInMonth;
    if (d >= 11 && d <= 13) return 'th';
    switch (d % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  String get dateRangeTitle => '1st $shortMonthName to $daysInMonth$daySuffix $year, Total Score';

  static String formatTwoDigits(num val) {
    if (val >= 0 && val < 10 && val == val.roundToDouble()) {
      return '0${val.toInt()}';
    }
    return val.toString();
  }

  static double? _subCategoryScore(num actual, num target) {
    if (target <= 0) return actual > 0 ? 1.0 : null;
    return (actual / target).clamp(0.0, 1.0);
  }

  static int _calculateAveragePercentage(List<double?> metrics) {
    final active = metrics.whereType<double>().toList();
    if (active.isEmpty) return 0;
    final avg = (active.reduce((a, b) => a + b) / active.length) * 100;
    return avg.clamp(0, 100).round();
  }

  // Category percentage calculations:
  // Each sub-category is considered out of 100% (max 1.0).
  // The average of all active sub-categories gives the overall section percentage out of 100%.
  int get instaPercentage {
    final metrics = [
      _subCategoryScore(instaContentReelActual, instaContentReelTarget),
      _subCategoryScore(instaProductReelActual, instaProductReelTarget),
      _subCategoryScore(instaStoriesActual, instaStoriesTarget),
      _subCategoryScore(instaCarouselActual, instaCarouselTarget),
      _subCategoryScore(instaCampaignActual, instaCampaignTarget),
      _subCategoryScore(instaInfluencerActual, instaInfluencerTarget),
    ];
    return _calculateAveragePercentage(metrics);
  }

  int get webPercentage {
    final metrics = [
      _subCategoryScore(webMnListingActual, webMnListingTarget),
      _subCategoryScore(webVadivamListingActual, webVadivamListingTarget),
      _subCategoryScore(webCampaignActual, webCampaignTarget),
    ];
    return _calculateAveragePercentage(metrics);
  }

  int get waPercentage {
    final metrics = [
      _subCategoryScore(waStoriesActual, waStoriesTarget),
      _subCategoryScore(waChannelsActual, waChannelsTarget),
      _subCategoryScore(waCampaignActual, waCampaignTarget),
      _subCategoryScore(waBroadcastActual, waBroadcastTarget),
    ];
    return _calculateAveragePercentage(metrics);
  }

  int get appPercentage {
    final metrics = [
      _subCategoryScore(appMnListingActual, appMnListingTarget),
      _subCategoryScore(appVadivamListingActual, appVadivamListingTarget),
      _subCategoryScore(appCampaignActual, appCampaignTarget),
      _subCategoryScore(appNotificationActual, appNotificationTarget),
    ];
    return _calculateAveragePercentage(metrics);
  }

  int get googlePercentage {
    final metrics = [
      _subCategoryScore(googleBlogsActual, googleBlogsTarget),
      _subCategoryScore(googleListingActual, googleListingTarget),
      _subCategoryScore(googleCampaignActual, googleCampaignTarget),
    ];
    return _calculateAveragePercentage(metrics);
  }

  int get osmPercentage {
    final metrics = [
      _subCategoryScore(osmSnapchatActual, osmSnapchatTarget),
      _subCategoryScore(osmPinterestActual, osmPinterestTarget),
      _subCategoryScore(osmShortsActual, osmShortsTarget),
      _subCategoryScore(osmLinkedinActual, osmLinkedinTarget),
      _subCategoryScore(osmXPostActual, osmXPostTarget),
    ];
    return _calculateAveragePercentage(metrics);
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'year': year,
    'totalSalesActual': totalSalesActual,
    'totalSalesTarget': totalSalesTarget,
    'salesOrdersActual': salesOrdersActual,
    'salesOrdersTarget': salesOrdersTarget,
    'schemeConversionsActual': schemeConversionsActual,
    'schemeConversionsTarget': schemeConversionsTarget,
    'monthlySchemeActual': monthlySchemeActual,
    'monthlySchemeTarget': monthlySchemeTarget,
    'instaContentReelActual': instaContentReelActual,
    'instaContentReelTarget': instaContentReelTarget,
    'instaProductReelActual': instaProductReelActual,
    'instaProductReelTarget': instaProductReelTarget,
    'instaStoriesActual': instaStoriesActual,
    'instaStoriesTarget': instaStoriesTarget,
    'instaCarouselActual': instaCarouselActual,
    'instaCarouselTarget': instaCarouselTarget,
    'instaCampaignActual': instaCampaignActual,
    'instaCampaignTarget': instaCampaignTarget,
    'instaInfluencerActual': instaInfluencerActual,
    'instaInfluencerTarget': instaInfluencerTarget,
    'webMnListingActual': webMnListingActual,
    'webMnListingTarget': webMnListingTarget,
    'webVadivamListingActual': webVadivamListingActual,
    'webVadivamListingTarget': webVadivamListingTarget,
    'webCampaignActual': webCampaignActual,
    'webCampaignTarget': webCampaignTarget,
    'waStoriesActual': waStoriesActual,
    'waStoriesTarget': waStoriesTarget,
    'waChannelsActual': waChannelsActual,
    'waChannelsTarget': waChannelsTarget,
    'waCampaignActual': waCampaignActual,
    'waCampaignTarget': waCampaignTarget,
    'waBroadcastActual': waBroadcastActual,
    'waBroadcastTarget': waBroadcastTarget,
    'appMnListingActual': appMnListingActual,
    'appMnListingTarget': appMnListingTarget,
    'appVadivamListingActual': appVadivamListingActual,
    'appVadivamListingTarget': appVadivamListingTarget,
    'appCampaignActual': appCampaignActual,
    'appCampaignTarget': appCampaignTarget,
    'appNotificationActual': appNotificationActual,
    'appNotificationTarget': appNotificationTarget,
    'googleBlogsActual': googleBlogsActual,
    'googleBlogsTarget': googleBlogsTarget,
    'googleListingActual': googleListingActual,
    'googleListingTarget': googleListingTarget,
    'googleCampaignActual': googleCampaignActual,
    'googleCampaignTarget': googleCampaignTarget,
    'osmSnapchatActual': osmSnapchatActual,
    'osmSnapchatTarget': osmSnapchatTarget,
    'osmPinterestActual': osmPinterestActual,
    'osmPinterestTarget': osmPinterestTarget,
    'osmShortsActual': osmShortsActual,
    'osmShortsTarget': osmShortsTarget,
    'osmLinkedinActual': osmLinkedinActual,
    'osmLinkedinTarget': osmLinkedinTarget,
    'osmXPostActual': osmXPostActual,
    'osmXPostTarget': osmXPostTarget,
    'designResponse': designResponse,
    'designFeedbackRating': designFeedbackRating,
    'downloadsMnActual': downloadsMnActual,
    'downloadsMnTarget': downloadsMnTarget,
    'downloadsVadivamActual': downloadsVadivamActual,
    'downloadsVadivamTarget': downloadsVadivamTarget,
    'followersMnActual': followersMnActual,
    'followersMnTarget': followersMnTarget,
    'followersVadivamActual': followersVadivamActual,
    'followersVadivamTarget': followersVadivamTarget,
    'googleReviewsActual': googleReviewsActual,
    'googleReviewsTarget': googleReviewsTarget,
    'gokulSales': gokulSales,
    'gokulSchemes': gokulSchemes,
    'gokulGold': gokulGold,
    'kaaviyaSales': kaaviyaSales,
    'kaaviyaSchemes': kaaviyaSchemes,
    'kaaviyaGold': kaaviyaGold,
    'nishaSales': nishaSales,
    'nishaSchemes': nishaSchemes,
    'nishaGold': nishaGold,
    'ashaSales': ashaSales,
    'ashaSchemes': ashaSchemes,
    'ashaGold': ashaGold,
    'topPerformer': topPerformer,
  };

  factory MonthlyScorecardModel.fromJson(Map<String, dynamic> json) {
    return MonthlyScorecardModel(
      month: json['month'] ?? 10,
      year: json['year'] ?? 2026,
      totalSalesActual: (json['totalSalesActual'] as num?)?.toDouble() ?? 0.0,
      totalSalesTarget: (json['totalSalesTarget'] as num?)?.toDouble() ?? 0.0,
      salesOrdersActual: json['salesOrdersActual'] ?? 0,
      salesOrdersTarget: json['salesOrdersTarget'] ?? 0,
      schemeConversionsActual: (json['schemeConversionsActual'] as num?)?.toDouble() ?? 0.0,
      schemeConversionsTarget: (json['schemeConversionsTarget'] as num?)?.toDouble() ?? 0.0,
      monthlySchemeActual: (json['monthlySchemeActual'] as num?)?.toDouble() ?? 0.0,
      monthlySchemeTarget: (json['monthlySchemeTarget'] as num?)?.toDouble() ?? 0.0,
      instaContentReelActual: json['instaContentReelActual'] ?? 0,
      instaContentReelTarget: json['instaContentReelTarget'],
      instaProductReelActual: json['instaProductReelActual'] ?? 0,
      instaProductReelTarget: json['instaProductReelTarget'],
      instaStoriesActual: json['instaStoriesActual'] ?? 0,
      instaStoriesTarget: json['instaStoriesTarget'] ?? 0,
      instaCarouselActual: json['instaCarouselActual'] ?? 0,
      instaCarouselTarget: json['instaCarouselTarget'] ?? 0,
      instaCampaignActual: json['instaCampaignActual'] ?? 0,
      instaCampaignTarget: json['instaCampaignTarget'] ?? 0,
      instaInfluencerActual: json['instaInfluencerActual'] ?? 0,
      instaInfluencerTarget: json['instaInfluencerTarget'] ?? 0,
      webMnListingActual: json['webMnListingActual'] ?? 0,
      webMnListingTarget: json['webMnListingTarget'] ?? 0,
      webVadivamListingActual: json['webVadivamListingActual'] ?? 0,
      webVadivamListingTarget: json['webVadivamListingTarget'] ?? 0,
      webCampaignActual: json['webCampaignActual'] ?? 0,
      webCampaignTarget: json['webCampaignTarget'] ?? 0,
      waStoriesActual: json['waStoriesActual'] ?? 0,
      waStoriesTarget: json['waStoriesTarget'] ?? 0,
      waChannelsActual: json['waChannelsActual'] ?? 0,
      waChannelsTarget: json['waChannelsTarget'] ?? 0,
      waCampaignActual: json['waCampaignActual'] ?? 0,
      waCampaignTarget: json['waCampaignTarget'] ?? 0,
      waBroadcastActual: json['waBroadcastActual'] ?? 0,
      waBroadcastTarget: json['waBroadcastTarget'] ?? 0,
      appMnListingActual: json['appMnListingActual'] ?? 0,
      appMnListingTarget: json['appMnListingTarget'] ?? 0,
      appVadivamListingActual: json['appVadivamListingActual'] ?? 0,
      appVadivamListingTarget: json['appVadivamListingTarget'] ?? 0,
      appCampaignActual: json['appCampaignActual'] ?? 0,
      appCampaignTarget: json['appCampaignTarget'] ?? 0,
      appNotificationActual: json['appNotificationActual'] ?? 0,
      appNotificationTarget: json['appNotificationTarget'] ?? 0,
      googleBlogsActual: json['googleBlogsActual'] ?? 0,
      googleBlogsTarget: json['googleBlogsTarget'] ?? 0,
      googleListingActual: json['googleListingActual'] ?? 0,
      googleListingTarget: json['googleListingTarget'] ?? 0,
      googleCampaignActual: json['googleCampaignActual'] ?? 0,
      googleCampaignTarget: json['googleCampaignTarget'] ?? 0,
      osmSnapchatActual: json['osmSnapchatActual'] ?? 0,
      osmSnapchatTarget: json['osmSnapchatTarget'] ?? 0,
      osmPinterestActual: json['osmPinterestActual'] ?? 0,
      osmPinterestTarget: json['osmPinterestTarget'] ?? 0,
      osmShortsActual: json['osmShortsActual'] ?? 0,
      osmShortsTarget: json['osmShortsTarget'] ?? 0,
      osmLinkedinActual: json['osmLinkedinActual'] ?? 0,
      osmLinkedinTarget: json['osmLinkedinTarget'] ?? 0,
      osmXPostActual: json['osmXPostActual'] ?? 0,
      osmXPostTarget: json['osmXPostTarget'] ?? 0,
      designResponse: json['designResponse'] ?? 0,
      designFeedbackRating: json['designFeedbackRating'] ?? 0,
      downloadsMnActual: json['downloadsMnActual'] ?? 0,
      downloadsMnTarget: json['downloadsMnTarget'] ?? 0,
      downloadsVadivamActual: json['downloadsVadivamActual'] ?? 0,
      downloadsVadivamTarget: json['downloadsVadivamTarget'] ?? 0,
      followersMnActual: json['followersMnActual'] ?? 0,
      followersMnTarget: json['followersMnTarget'] ?? 0,
      followersVadivamActual: json['followersVadivamActual'] ?? 0,
      followersVadivamTarget: json['followersVadivamTarget'] ?? 0,
      googleReviewsActual: json['googleReviewsActual'] ?? 0,
      googleReviewsTarget: json['googleReviewsTarget'] ?? 0,
      gokulSales: (json['gokulSales'] as num?)?.toDouble() ?? 0.0,
      gokulSchemes: (json['gokulSchemes'] as num?)?.toDouble() ?? 0.0,
      gokulGold: (json['gokulGold'] as num?)?.toDouble() ?? 0.0,
      kaaviyaSales: (json['kaaviyaSales'] as num?)?.toDouble() ?? 0.0,
      kaaviyaSchemes: (json['kaaviyaSchemes'] as num?)?.toDouble() ?? 0.0,
      kaaviyaGold: (json['kaaviyaGold'] as num?)?.toDouble() ?? 0.0,
      nishaSales: (json['nishaSales'] as num?)?.toDouble() ?? 0.0,
      nishaSchemes: (json['nishaSchemes'] as num?)?.toDouble() ?? 0.0,
      nishaGold: (json['nishaGold'] as num?)?.toDouble() ?? 0.0,
      ashaSales: (json['ashaSales'] as num?)?.toDouble() ?? 0.0,
      ashaSchemes: (json['ashaSchemes'] as num?)?.toDouble() ?? 0.0,
      ashaGold: (json['ashaGold'] as num?)?.toDouble() ?? 0.0,
      topPerformer: json['topPerformer'] ?? 'Gokul',
    );
  }

  static MonthlyScorecardModel createSample() {
    return MonthlyScorecardModel(month: 10, year: 2026);
  }
}
