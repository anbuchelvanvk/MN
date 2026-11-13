
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
    this.totalSalesActual = 2291515,
    this.totalSalesTarget = 8333333,
    this.salesOrdersActual = 22,
    this.salesOrdersTarget = 100,
    this.schemeConversionsActual = 195.861,
    this.schemeConversionsTarget = 250.0,
    this.monthlySchemeActual = 63000,
    this.monthlySchemeTarget = 625000,
    this.instaContentReelActual = 17,
    int? instaContentReelTarget,
    this.instaProductReelActual = 43,
    int? instaProductReelTarget,
    this.instaStoriesActual = 96,
    this.instaStoriesTarget = 93,
    this.instaCarouselActual = 25,
    this.instaCarouselTarget = 20,
    this.instaCampaignActual = 2,
    this.instaCampaignTarget = 2,
    this.instaInfluencerActual = 2,
    this.instaInfluencerTarget = 4,
    this.webMnListingActual = 433,
    this.webMnListingTarget = 1200,
    this.webVadivamListingActual = 123,
    this.webVadivamListingTarget = 300,
    this.webCampaignActual = 2,
    this.webCampaignTarget = 2,
    this.waStoriesActual = 81,
    this.waStoriesTarget = 93,
    this.waChannelsActual = 56,
    this.waChannelsTarget = 62,
    this.waCampaignActual = 1,
    this.waCampaignTarget = 1,
    this.waBroadcastActual = 25000,
    this.waBroadcastTarget = 25000,
    this.appMnListingActual = 470,
    this.appMnListingTarget = 1200,
    this.appVadivamListingActual = 123,
    this.appVadivamListingTarget = 300,
    this.appCampaignActual = 1,
    this.appCampaignTarget = 1,
    this.appNotificationActual = 81,
    this.appNotificationTarget = 93,
    this.googleBlogsActual = 6,
    this.googleBlogsTarget = 8,
    this.googleListingActual = 335,
    this.googleListingTarget = 900,
    this.googleCampaignActual = 1,
    this.googleCampaignTarget = 1,
    this.osmSnapchatActual = 84,
    this.osmSnapchatTarget = 92,
    this.osmPinterestActual = 25,
    this.osmPinterestTarget = 20,
    this.osmShortsActual = 47,
    this.osmShortsTarget = 62,
    this.osmLinkedinActual = 25,
    this.osmLinkedinTarget = 20,
    this.osmXPostActual = 25,
    this.osmXPostTarget = 20,
    this.designResponse = 18,
    this.designFeedbackRating = 100,
    this.downloadsMnActual = 206,
    this.downloadsMnTarget = 600,
    this.downloadsVadivamActual = 3,
    this.downloadsVadivamTarget = 600,
    this.followersMnActual = 919,
    this.followersMnTarget = 2000,
    this.followersVadivamActual = 262,
    this.followersVadivamTarget = 2000,
    this.googleReviewsActual = 1,
    this.googleReviewsTarget = 195,
    this.gokulSales = 2139192,
    this.gokulSchemes = 61000,
    this.gokulGold = 195.861,
    this.kaaviyaSales = 152323,
    this.kaaviyaSchemes = 0,
    this.kaaviyaGold = 0,
    this.nishaSales = 0,
    this.nishaSchemes = 2000,
    this.nishaGold = 0,
    this.ashaSales = 0,
    this.ashaSchemes = 0,
    this.ashaGold = 0,
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

  static double _subCategoryScore(num actual, num target) {
    if (target <= 0) return 1.0;
    return (actual / target).clamp(0.0, 1.0);
  }

  // Category percentage calculations:
  // Each sub-category is considered out of 100% (max 1.0).
  // The average of all sub-categories gives the overall section percentage out of 100%.
  int get instaPercentage {
    final metrics = [
      _subCategoryScore(instaContentReelActual, instaContentReelTarget),
      _subCategoryScore(instaProductReelActual, instaProductReelTarget),
      _subCategoryScore(instaStoriesActual, instaStoriesTarget),
      _subCategoryScore(instaCarouselActual, instaCarouselTarget),
      _subCategoryScore(instaCampaignActual, instaCampaignTarget),
      _subCategoryScore(instaInfluencerActual, instaInfluencerTarget),
    ];
    final avg = (metrics.reduce((a, b) => a + b) / metrics.length) * 100;
    return avg.clamp(0, 100).round();
  }

  int get webPercentage {
    final metrics = [
      _subCategoryScore(webMnListingActual, webMnListingTarget),
      _subCategoryScore(webVadivamListingActual, webVadivamListingTarget),
      _subCategoryScore(webCampaignActual, webCampaignTarget),
    ];
    final avg = (metrics.reduce((a, b) => a + b) / metrics.length) * 100;
    return avg.clamp(0, 100).round();
  }

  int get waPercentage {
    final metrics = [
      _subCategoryScore(waStoriesActual, waStoriesTarget),
      _subCategoryScore(waChannelsActual, waChannelsTarget),
      _subCategoryScore(waCampaignActual, waCampaignTarget),
      _subCategoryScore(waBroadcastActual, waBroadcastTarget),
    ];
    final avg = (metrics.reduce((a, b) => a + b) / metrics.length) * 100;
    return avg.clamp(0, 100).round();
  }

  int get appPercentage {
    final metrics = [
      _subCategoryScore(appMnListingActual, appMnListingTarget),
      _subCategoryScore(appVadivamListingActual, appVadivamListingTarget),
      _subCategoryScore(appCampaignActual, appCampaignTarget),
      _subCategoryScore(appNotificationActual, appNotificationTarget),
    ];
    final avg = (metrics.reduce((a, b) => a + b) / metrics.length) * 100;
    return avg.clamp(0, 100).round();
  }

  int get googlePercentage {
    final metrics = [
      _subCategoryScore(googleBlogsActual, googleBlogsTarget),
      _subCategoryScore(googleListingActual, googleListingTarget),
      _subCategoryScore(googleCampaignActual, googleCampaignTarget),
    ];
    final avg = (metrics.reduce((a, b) => a + b) / metrics.length) * 100;
    return avg.clamp(0, 100).round();
  }

  int get osmPercentage {
    final metrics = [
      _subCategoryScore(osmSnapchatActual, osmSnapchatTarget),
      _subCategoryScore(osmPinterestActual, osmPinterestTarget),
      _subCategoryScore(osmShortsActual, osmShortsTarget),
      _subCategoryScore(osmLinkedinActual, osmLinkedinTarget),
      _subCategoryScore(osmXPostActual, osmXPostTarget),
    ];
    final avg = (metrics.reduce((a, b) => a + b) / metrics.length) * 100;
    return avg.clamp(0, 100).round();
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
      totalSalesActual: (json['totalSalesActual'] as num?)?.toDouble() ?? 2291515,
      totalSalesTarget: (json['totalSalesTarget'] as num?)?.toDouble() ?? 8333333,
      salesOrdersActual: json['salesOrdersActual'] ?? 22,
      salesOrdersTarget: json['salesOrdersTarget'] ?? 100,
      schemeConversionsActual: (json['schemeConversionsActual'] as num?)?.toDouble() ?? 195.861,
      schemeConversionsTarget: (json['schemeConversionsTarget'] as num?)?.toDouble() ?? 250.0,
      monthlySchemeActual: (json['monthlySchemeActual'] as num?)?.toDouble() ?? 63000,
      monthlySchemeTarget: (json['monthlySchemeTarget'] as num?)?.toDouble() ?? 625000,
      instaContentReelActual: json['instaContentReelActual'] ?? 17,
      instaContentReelTarget: json['instaContentReelTarget'],
      instaProductReelActual: json['instaProductReelActual'] ?? 43,
      instaProductReelTarget: json['instaProductReelTarget'],
      instaStoriesActual: json['instaStoriesActual'] ?? 96,
      instaStoriesTarget: json['instaStoriesTarget'] ?? 93,
      instaCarouselActual: json['instaCarouselActual'] ?? 25,
      instaCarouselTarget: json['instaCarouselTarget'] ?? 20,
      instaCampaignActual: json['instaCampaignActual'] ?? 2,
      instaCampaignTarget: json['instaCampaignTarget'] ?? 2,
      instaInfluencerActual: json['instaInfluencerActual'] ?? 2,
      instaInfluencerTarget: json['instaInfluencerTarget'] ?? 4,
      webMnListingActual: json['webMnListingActual'] ?? 433,
      webMnListingTarget: json['webMnListingTarget'] ?? 1200,
      webVadivamListingActual: json['webVadivamListingActual'] ?? 123,
      webVadivamListingTarget: json['webVadivamListingTarget'] ?? 300,
      webCampaignActual: json['webCampaignActual'] ?? 2,
      webCampaignTarget: json['webCampaignTarget'] ?? 2,
      waStoriesActual: json['waStoriesActual'] ?? 81,
      waStoriesTarget: json['waStoriesTarget'] ?? 93,
      waChannelsActual: json['waChannelsActual'] ?? 56,
      waChannelsTarget: json['waChannelsTarget'] ?? 62,
      waCampaignActual: json['waCampaignActual'] ?? 1,
      waCampaignTarget: json['waCampaignTarget'] ?? 1,
      waBroadcastActual: json['waBroadcastActual'] ?? 25000,
      waBroadcastTarget: json['waBroadcastTarget'] ?? 25000,
      appMnListingActual: json['appMnListingActual'] ?? 470,
      appMnListingTarget: json['appMnListingTarget'] ?? 1200,
      appVadivamListingActual: json['appVadivamListingActual'] ?? 123,
      appVadivamListingTarget: json['appVadivamListingTarget'] ?? 300,
      appCampaignActual: json['appCampaignActual'] ?? 1,
      appCampaignTarget: json['appCampaignTarget'] ?? 1,
      appNotificationActual: json['appNotificationActual'] ?? 81,
      appNotificationTarget: json['appNotificationTarget'] ?? 93,
      googleBlogsActual: json['googleBlogsActual'] ?? 6,
      googleBlogsTarget: json['googleBlogsTarget'] ?? 8,
      googleListingActual: json['googleListingActual'] ?? 335,
      googleListingTarget: json['googleListingTarget'] ?? 900,
      googleCampaignActual: json['googleCampaignActual'] ?? 1,
      googleCampaignTarget: json['googleCampaignTarget'] ?? 1,
      osmSnapchatActual: json['osmSnapchatActual'] ?? 84,
      osmSnapchatTarget: json['osmSnapchatTarget'] ?? 92,
      osmPinterestActual: json['osmPinterestActual'] ?? 25,
      osmPinterestTarget: json['osmPinterestTarget'] ?? 20,
      osmShortsActual: json['osmShortsActual'] ?? 47,
      osmShortsTarget: json['osmShortsTarget'] ?? 62,
      osmLinkedinActual: json['osmLinkedinActual'] ?? 25,
      osmLinkedinTarget: json['osmLinkedinTarget'] ?? 20,
      osmXPostActual: json['osmXPostActual'] ?? 25,
      osmXPostTarget: json['osmXPostTarget'] ?? 20,
      designResponse: json['designResponse'] ?? 18,
      designFeedbackRating: json['designFeedbackRating'] ?? 100,
      downloadsMnActual: json['downloadsMnActual'] ?? 206,
      downloadsMnTarget: json['downloadsMnTarget'] ?? 600,
      downloadsVadivamActual: json['downloadsVadivamActual'] ?? 3,
      downloadsVadivamTarget: json['downloadsVadivamTarget'] ?? 600,
      followersMnActual: json['followersMnActual'] ?? 919,
      followersMnTarget: json['followersMnTarget'] ?? 2000,
      followersVadivamActual: json['followersVadivamActual'] ?? 262,
      followersVadivamTarget: json['followersVadivamTarget'] ?? 2000,
      googleReviewsActual: json['googleReviewsActual'] ?? 1,
      googleReviewsTarget: json['googleReviewsTarget'] ?? 195,
      gokulSales: (json['gokulSales'] as num?)?.toDouble() ?? 2139192,
      gokulSchemes: (json['gokulSchemes'] as num?)?.toDouble() ?? 61000,
      gokulGold: (json['gokulGold'] as num?)?.toDouble() ?? 195.861,
      kaaviyaSales: (json['kaaviyaSales'] as num?)?.toDouble() ?? 152323,
      kaaviyaSchemes: (json['kaaviyaSchemes'] as num?)?.toDouble() ?? 0,
      kaaviyaGold: (json['kaaviyaGold'] as num?)?.toDouble() ?? 0,
      nishaSales: (json['nishaSales'] as num?)?.toDouble() ?? 0,
      nishaSchemes: (json['nishaSchemes'] as num?)?.toDouble() ?? 2000,
      nishaGold: (json['nishaGold'] as num?)?.toDouble() ?? 0,
      ashaSales: (json['ashaSales'] as num?)?.toDouble() ?? 0,
      ashaSchemes: (json['ashaSchemes'] as num?)?.toDouble() ?? 0,
      ashaGold: (json['ashaGold'] as num?)?.toDouble() ?? 0,
      topPerformer: json['topPerformer'] ?? 'Gokul',
    );
  }

  static MonthlyScorecardModel createSample() {
    return MonthlyScorecardModel(month: 10, year: 2026);
  }
}
