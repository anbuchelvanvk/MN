/// A comment or revision note on a creative media asset
class MediaReviewComment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String comment;
  final DateTime timestamp;
  final bool isExecutiveNote;

  MediaReviewComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.comment,
    required this.timestamp,
    this.isExecutiveNote = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'comment': comment,
        'timestamp': timestamp.toIso8601String(),
        'isExecutiveNote': isExecutiveNote,
      };

  factory MediaReviewComment.fromJson(Map<String, dynamic> json) {
    return MediaReviewComment(
      id: json['id']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? '',
      authorRole: json['authorRole']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isExecutiveNote: json['isExecutiveNote'] as bool? ?? false,
    );
  }
}

/// Status of a media asset in the review & approval pipeline
enum MediaAssetStatus {
  pendingReview,
  revisionsRequested,
  approvedByCeo,
  published,
}

/// Model representing a creative digital media asset in the MN DAM pipeline
class CreativeMediaAsset {
  final String id;
  final String title;
  final String description;
  final String category; // 'Reel', 'Photoshoot', 'Catalog Banner', 'YouTube Short', 'Story'
  final String collectionTag; // 'Antique & Bridal', 'Diamond & Polki', '22K Gold', 'Silver Collection', 'Daily Wear'
  final String driveUrl;
  final String? previewThumbnail;
  final String creatorId;
  final String creatorName;
  final String creatorRole;
  final List<String> targetChannels; // ['Instagram', 'YouTube', 'WhatsApp', 'Website']
  final String status; // 'pending_review', 'revisions_requested', 'approved_by_ceo', 'published'
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MediaReviewComment> comments;
  final String? publishedUrl;
  final String captionDraft;

  CreativeMediaAsset({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.collectionTag,
    required this.driveUrl,
    this.previewThumbnail,
    required this.creatorId,
    required this.creatorName,
    required this.creatorRole,
    required this.targetChannels,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.comments = const [],
    this.publishedUrl,
    this.captionDraft = '',
  });

  bool get isPendingReview => status == 'pending_review';
  bool get isRevisionsRequested => status == 'revisions_requested';
  bool get isApprovedByCeo => status == 'approved_by_ceo';
  bool get isPublished => status == 'published';

  String get displayStatus {
    switch (status) {
      case 'pending_review':
        return 'Pending CEO Review';
      case 'revisions_requested':
        return 'Revisions Requested';
      case 'approved_by_ceo':
        return 'Approved for Social Media';
      case 'published':
        return 'Live / Published';
      default:
        return 'Draft';
    }
  }

  CreativeMediaAsset copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? collectionTag,
    String? driveUrl,
    String? previewThumbnail,
    String? creatorId,
    String? creatorName,
    String? creatorRole,
    List<String>? targetChannels,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MediaReviewComment>? comments,
    String? publishedUrl,
    String? captionDraft,
  }) {
    return CreativeMediaAsset(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      collectionTag: collectionTag ?? this.collectionTag,
      driveUrl: driveUrl ?? this.driveUrl,
      previewThumbnail: previewThumbnail ?? this.previewThumbnail,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorRole: creatorRole ?? this.creatorRole,
      targetChannels: targetChannels ?? this.targetChannels,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      comments: comments ?? this.comments,
      publishedUrl: publishedUrl ?? this.publishedUrl,
      captionDraft: captionDraft ?? this.captionDraft,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'collectionTag': collectionTag,
        'driveUrl': driveUrl,
        'previewThumbnail': previewThumbnail,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorRole': creatorRole,
        'targetChannels': targetChannels,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'publishedUrl': publishedUrl,
        'captionDraft': captionDraft,
      };

  factory CreativeMediaAsset.fromJson(Map<String, dynamic> json) {
    return CreativeMediaAsset(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Reel',
      collectionTag: json['collectionTag']?.toString() ?? '22K Gold',
      driveUrl: json['driveUrl']?.toString() ?? '',
      previewThumbnail: json['previewThumbnail']?.toString(),
      creatorId: json['creatorId']?.toString() ?? '',
      creatorName: json['creatorName']?.toString() ?? '',
      creatorRole: json['creatorRole']?.toString() ?? '',
      targetChannels: (json['targetChannels'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Instagram'],
      status: json['status']?.toString() ?? 'pending_review',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      comments: (json['comments'] as List?)
              ?.map((c) =>
                  MediaReviewComment.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList() ??
          [],
      publishedUrl: json['publishedUrl']?.toString(),
      captionDraft: json['captionDraft']?.toString() ?? '',
    );
  }

  /// Default media assets - clean start with no mock data
  static List<CreativeMediaAsset> defaultSeededAssets() => const [];
}
