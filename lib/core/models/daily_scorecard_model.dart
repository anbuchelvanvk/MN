/// One counted item on the daily scorecard, e.g. "Content Reel 1 of 1".
class ScoreItem {
  final String key;
  final String label;
  int done;
  int target;
  ScoreItem({required this.key, required this.label, this.done = 0, required this.target});

  double get ratio => target <= 0 ? 1.0 : (done / target).clamp(0.0, 1.0);
  bool get met => done >= target;

  Map<String, dynamic> toJson() => {'key': key, 'label': label, 'done': done, 'target': target};
  factory ScoreItem.fromJson(Map<String, dynamic> j) => ScoreItem(
        key: '${j['key']}',
        label: '${j['label']}',
        done: (j['done'] as num?)?.toInt() ?? 0,
        target: (j['target'] as num?)?.toInt() ?? 0,
      );
}

/// A channel (Instagram, Listing, ...) worth [weight] points out of 100.
class ScoreChannel {
  final String key;
  final String name;
  final int weight;
  final String targetText;
  final List<ScoreItem> items;

  /// When set, the OTM's own score for this channel; otherwise it is
  /// worked out from the items.
  int? scoreOverride;

  ScoreChannel({
    required this.key,
    required this.name,
    required this.weight,
    required this.targetText,
    required this.items,
    this.scoreOverride,
  });

  /// Average of each item's progress (capped at its target) × weight.
  int get autoScore {
    if (items.isEmpty) return 0;
    final avg = items.fold(0.0, (s, i) => s + i.ratio) / items.length;
    return (avg * weight).round();
  }

  int get score => (scoreOverride ?? autoScore).clamp(0, weight);

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'weight': weight,
        'targetText': targetText,
        'items': items.map((i) => i.toJson()).toList(),
        if (scoreOverride != null) 'scoreOverride': scoreOverride,
      };

  factory ScoreChannel.fromJson(Map<String, dynamic> j) => ScoreChannel(
        key: '${j['key']}',
        name: '${j['name']}',
        weight: (j['weight'] as num?)?.toInt() ?? 0,
        targetText: '${j['targetText'] ?? ''}',
        items: ((j['items'] as List?) ?? [])
            .map((e) => ScoreItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        scoreOverride: (j['scoreOverride'] as num?)?.toInt(),
      );
}

/// The online team's Daily Scorecard (same layout as the shared PDF).
class DailyScorecardModel {
  final DateTime date;
  final List<ScoreChannel> channels;

  /// Design feedback rating in percent and number of responses.
  int feedbackRating;
  int feedbackResponses;
  bool onTime;
  bool qualityDesign;
  bool designPerfection;

  /// Short line under the score, e.g. "Let's Improve Google Tomorrow."
  String? remark;

  /// 'draft' while the OTM is filling it in; 'published' once shared.
  String status;
  String? updatedBy;
  DateTime? updatedAt;
  String? publishedBy;
  DateTime? publishedAt;

  DailyScorecardModel({
    required this.date,
    required this.channels,
    this.feedbackRating = 100,
    this.feedbackResponses = 0,
    this.onTime = true,
    this.qualityDesign = true,
    this.designPerfection = true,
    this.remark,
    this.status = 'draft',
    this.updatedBy,
    this.updatedAt,
    this.publishedBy,
    this.publishedAt,
  });

  bool get isPublished => status == 'published';

  static String idFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String get id => idFor(date);

  int get totalScore => channels.fold(0, (s, c) => s + c.score).clamp(0, 100);

  String get grade {
    final t = totalScore;
    if (t >= 95) return 'Outstanding';
    if (t >= 80) return 'Good Effort';
    if (t >= 60) return 'Fair';
    return 'Needs Work';
  }

  /// The remark shown under the score; suggests the weakest channel.
  String get effectiveRemark {
    if (remark != null && remark!.trim().isNotEmpty) return remark!.trim();
    final weakest = channels.where((c) => c.score < c.weight).toList()
      ..sort((a, b) => (a.score / a.weight).compareTo(b.score / b.weight));
    if (weakest.isEmpty) return 'Perfect day. Keep it up!';
    final name = weakest.first.name.split(' ').first;
    return "Let's Improve $name Tomorrow.";
  }

  ScoreItem? item(String channelKey, String itemKey) {
    for (final c in channels) {
      if (c.key != channelKey) continue;
      for (final i in c.items) {
        if (i.key == itemKey) return i;
      }
    }
    return null;
  }

  /// The day's template, with the targets from the scorecard PDF.
  factory DailyScorecardModel.blank(DateTime date) => DailyScorecardModel(
        date: DateTime(date.year, date.month, date.day),
        channels: [
          ScoreChannel(
            key: 'instagram',
            name: 'Instagram',
            weight: 20,
            targetText: 'Content, Product, Stories, Carousel, Influencer, Campaign',
            items: [
              ScoreItem(key: 'contentReel', label: 'Content Reel', target: 1),
              ScoreItem(key: 'productReel', label: 'Product Reel', target: 1),
              ScoreItem(key: 'stories', label: 'Stories', target: 3),
              ScoreItem(key: 'carousel', label: 'Carousel Post', target: 1),
              ScoreItem(key: 'campaign', label: 'Active Campaign', target: 2),
            ],
          ),
          ScoreChannel(
            key: 'listing',
            name: 'Listing',
            weight: 20,
            targetText: 'Listing, Orders, Campaign, Retargeting',
            items: [
              ScoreItem(key: 'website', label: 'Website', target: 17),
              ScoreItem(key: 'app', label: 'App', target: 17),
              ScoreItem(key: 'meta', label: 'Meta', target: 17),
              ScoreItem(key: 'google', label: 'Google', target: 17),
            ],
          ),
          ScoreChannel(
            key: 'whatsapp',
            name: 'Whatsapp',
            weight: 15,
            targetText: 'Stories, Broadcast, Channels, Campaign',
            items: [
              ScoreItem(key: 'stories', label: 'Stories', target: 3),
              ScoreItem(key: 'channels', label: 'Channels', target: 2),
              ScoreItem(key: 'campaign', label: 'Campaign', target: 1),
            ],
          ),
          ScoreChannel(
            key: 'mobileApp',
            name: 'Mobile App',
            weight: 10,
            targetText: 'Downloads, Listing, Notification, Review',
            items: [
              ScoreItem(key: 'campaign', label: 'Campaign', target: 1),
              ScoreItem(key: 'notification', label: 'Notification', target: 3),
            ],
          ),
          ScoreChannel(
            key: 'google',
            name: 'Google',
            weight: 20,
            targetText: 'Listing, Campaign',
            items: [
              ScoreItem(key: 'blog', label: 'Blog', target: 8),
              ScoreItem(key: 'campaign', label: 'Campaign', target: 1),
            ],
          ),
          ScoreChannel(
            key: 'otherSocial',
            name: 'Other Social Media',
            weight: 15,
            targetText: 'SnapChat, Blogs, Pinterest, Shorts, Linkedin, X post',
            items: [
              ScoreItem(key: 'snapchat', label: 'SnapChat', target: 2),
              ScoreItem(key: 'pinterest', label: 'Pinterest', target: 1),
              ScoreItem(key: 'shorts', label: 'Shorts', target: 2),
              ScoreItem(key: 'linkedin', label: 'Linkedin', target: 1),
              ScoreItem(key: 'xpost', label: 'X Post', target: 1),
            ],
          ),
        ],
      );

  Map<String, dynamic> toJson() => {
        'date': id,
        'year': date.year,
        'month': date.month,
        'day': date.day,
        'channels': channels.map((c) => c.toJson()).toList(),
        'feedbackRating': feedbackRating,
        'feedbackResponses': feedbackResponses,
        'onTime': onTime,
        'qualityDesign': qualityDesign,
        'designPerfection': designPerfection,
        if (remark != null) 'remark': remark,
        'status': status,
        'totalScore': totalScore,
        if (updatedBy != null) 'updatedBy': updatedBy,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (publishedBy != null) 'publishedBy': publishedBy,
        if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      };

  factory DailyScorecardModel.fromJson(Map<String, dynamic> j) {
    final y = (j['year'] as num?)?.toInt();
    final m = (j['month'] as num?)?.toInt();
    final d = (j['day'] as num?)?.toInt();
    final date = (y != null && m != null && d != null)
        ? DateTime(y, m, d)
        : (DateTime.tryParse('${j['date']}') ?? DateTime.now());
    final blank = DailyScorecardModel.blank(date);
    final stored = ((j['channels'] as List?) ?? [])
        .map((e) => ScoreChannel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return DailyScorecardModel(
      date: date,
      channels: stored.isEmpty ? blank.channels : stored,
      feedbackRating: (j['feedbackRating'] as num?)?.toInt() ?? 100,
      feedbackResponses: (j['feedbackResponses'] as num?)?.toInt() ?? 0,
      onTime: j['onTime'] as bool? ?? true,
      qualityDesign: j['qualityDesign'] as bool? ?? true,
      designPerfection: j['designPerfection'] as bool? ?? true,
      remark: j['remark'] as String?,
      status: '${j['status'] ?? 'draft'}',
      updatedBy: j['updatedBy'] as String?,
      updatedAt: DateTime.tryParse('${j['updatedAt']}'),
      publishedBy: j['publishedBy'] as String?,
      publishedAt: DateTime.tryParse('${j['publishedAt']}'),
    );
  }
}
