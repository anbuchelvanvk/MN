class KonarSection {
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final List<String> keyRules;

  KonarSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    this.keyRules = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'content': content,
    'keyRules': keyRules,
  };

  factory KonarSection.fromJson(Map<String, dynamic> json) {
    return KonarSection(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      keyRules: (json['keyRules'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class KonarBookModel {
  final String id;
  final String department;
  final String departmentCode;
  final String title;
  final String description;
  final String version;
  final DateTime lastUpdated;
  final String updatedByName;
  final String updatedByRole;
  final String updatedByEmpId;
  final List<KonarSection> sections;
  final String? pdfBase64;
  final String? pdfUrl;
  final String? attachmentFileName;
  final bool hasPdfAttachment;
  final int? totalPdfChunks;
  final int? pdfFileSize;
  final bool isVisible;

  KonarBookModel({
    required this.id,
    required this.department,
    required this.departmentCode,
    required this.title,
    required this.description,
    required this.version,
    required this.lastUpdated,
    required this.updatedByName,
    required this.updatedByRole,
    required this.updatedByEmpId,
    required this.sections,
    this.pdfBase64,
    this.pdfUrl,
    this.attachmentFileName,
    this.hasPdfAttachment = false,
    this.totalPdfChunks,
    this.pdfFileSize,
    this.isVisible = true,
  });

  KonarBookModel copyWith({
    String? id,
    String? department,
    String? departmentCode,
    String? title,
    String? description,
    String? version,
    DateTime? lastUpdated,
    String? updatedByName,
    String? updatedByRole,
    String? updatedByEmpId,
    List<KonarSection>? sections,
    String? pdfBase64,
    String? pdfUrl,
    String? attachmentFileName,
    bool? hasPdfAttachment,
    int? totalPdfChunks,
    int? pdfFileSize,
    bool? isVisible,
  }) {
    return KonarBookModel(
      id: id ?? this.id,
      department: department ?? this.department,
      departmentCode: departmentCode ?? this.departmentCode,
      title: title ?? this.title,
      description: description ?? this.description,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedByName: updatedByName ?? this.updatedByName,
      updatedByRole: updatedByRole ?? this.updatedByRole,
      updatedByEmpId: updatedByEmpId ?? this.updatedByEmpId,
      sections: sections ?? this.sections,
      pdfBase64: pdfBase64 ?? this.pdfBase64,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      attachmentFileName: attachmentFileName ?? this.attachmentFileName,
      hasPdfAttachment: hasPdfAttachment ?? this.hasPdfAttachment,
      totalPdfChunks: totalPdfChunks ?? this.totalPdfChunks,
      pdfFileSize: pdfFileSize ?? this.pdfFileSize,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson({bool includePdfBase64 = false}) => {
    'id': id,
    'department': department,
    'departmentCode': departmentCode,
    'title': title,
    'description': description,
    'version': version,
    'lastUpdated': lastUpdated.toIso8601String(),
    'updatedByName': updatedByName,
    'updatedByRole': updatedByRole,
    'updatedByEmpId': updatedByEmpId,
    'sections': sections.map((s) => s.toJson()).toList(),
    'pdfUrl': pdfUrl,
    'attachmentFileName': attachmentFileName,
    'hasPdfAttachment': hasPdfAttachment,
    'totalPdfChunks': totalPdfChunks,
    'pdfFileSize': pdfFileSize,
    'isVisible': isVisible,
    if (includePdfBase64 && pdfBase64 != null && pdfBase64!.length < 350000)
      'pdfBase64': pdfBase64,
  };

  factory KonarBookModel.fromJson(Map<String, dynamic> json) {
    final rawBase64 = json['pdfBase64']?.toString();
    final hasChunks = json['hasPdfAttachment'] as bool? ??
        (rawBase64 != null && rawBase64.isNotEmpty);

    return KonarBookModel(
      id: json['id']?.toString() ?? 'online_department',
      department: json['department']?.toString() ?? 'Online Department',
      departmentCode: json['departmentCode']?.toString() ?? 'OTM',
      title: json['title']?.toString() ?? 'Online Department Official KONAR Book',
      description: json['description']?.toString() ??
          'Official standard operating procedures, catalog management guidelines, sales engagement scripts, and online workflows for MN Jewel Park.',
      version: json['version']?.toString() ?? 'v2.4',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedByName: json['updatedByName']?.toString() ?? 'M N Naveenraaj',
      updatedByRole: json['updatedByRole']?.toString() ?? 'Managing Director & CEO',
      updatedByEmpId: json['updatedByEmpId']?.toString() ?? 'MN-CEO01',
      sections: (json['sections'] as List?)
              ?.map((s) => KonarSection.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          [],
      pdfBase64: rawBase64,
      pdfUrl: json['pdfUrl']?.toString(),
      attachmentFileName: json['attachmentFileName']?.toString() ?? 'Online_Department_KONAR_Book.pdf',
      hasPdfAttachment: hasChunks,
      totalPdfChunks: (json['totalPdfChunks'] as num?)?.toInt(),
      pdfFileSize: (json['pdfFileSize'] as num?)?.toInt(),
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }

  /// Factory providing default official Online Department Konar Book seeded from real business catalog
  factory KonarBookModel.defaultOnlineDepartment() {
    return KonarBookModel(
      id: 'online_department',
      department: 'Online Department',
      departmentCode: 'OTM',
      title: 'Online Department Official KONAR Book',
      description: 'Comprehensive operational manual, role SLAs, photography rules, sales workflows, logistics protocols, and management guidelines for MN Jewel Park.',
      version: 'v2.4',
      lastUpdated: DateTime(2026, 11, 15, 10, 0),
      updatedByName: 'M N Naveenraaj',
      updatedByRole: 'Managing Director & CEO',
      updatedByEmpId: 'MN-CEO01',
      attachmentFileName: 'Online_Department_KONAR_Book.pdf',
      sections: [
        KonarSection(
          id: 'sec_1',
          title: '01 PURPOSE',
          subtitle: 'Global Platform, Doorstep Delivery & Bespoke Jewelry Craftsmanship',
          content: 'A global platform that connects customers worldwide with our fine jewelry and provides convenient, secure doorstep delivery. Customers choose our platform for customized and personalized jewelry carrying profound emotional value. Our online team serves as a high-velocity sales funnel, driving company growth, customer engagement, brand presence, and loyal community building. Our purpose is to deliver exceptional designs that exceed customer expectations and turn dreams into reality through advanced technology, expert craftsmanship, and human creativity.',
          keyRules: [
            'Global Reach: Provide reliable worldwide doorstep delivery for certified 916 BIS hallmark gold, silver, and diamond jewelry.',
            'Emotional Customization: Deliver bespoke, personalized jewelry pieces carrying personal stories and deep family sentiment.',
            'Core Sales Funnel: Serve as the primary digital sales funnel driving high-volume inquiries and sustainable company growth.',
            'Brand & Community: Cultivate trust and active engagement across Instagram, WhatsApp Business, YouTube, and digital channels.',
            'Creative Harmony: Combine Artificial Intelligence, Photoshop, CAD modeling, and master goldsmith craftsmanship.',
          ],
        ),
        KonarSection(
          id: 'sec_2',
          title: '02 GOALS',
          subtitle: '12-Month Omnichannel Key Results, Platform Targets & 24-Hour Design SLA',
          content: 'Strategic 12-month measurable objectives established for the Online & Design Department across social channels, e-commerce portals, mobile apps, search engines, and custom design production.',
          keyRules: [
            'Instagram Goal: Scale followers from 58K to 100K within 12 months via 7 content reels/week, 3 daily stories, 5 carousels/week, and 4 monthly influencer collaborations.',
            'Websites (MN & Vadivam): Grow online sales by 50% and achieve min 100 online orders/month with min 400 monthly asset updates.',
            'WhatsApp Business: Acquire 1,000 new contacts, 300 qualified inquiries/month, 20% conversion (60 sales/month), and 25 monthly scheme enrollments.',
            'Mobile App Adoption: Attain 25,000 downloads, 10,000 monthly active users (MAU), 100 scheme conversions/month, and 500 app orders/month.',
            'Google Visibility: Achieve Top 5 ranking in jewelry search terms, 500 qualified leads/month, 50% organic growth, and 5 monthly SEO blogs.',
            'Alternative Platforms: Gain 10,000 followers across YouTube, LinkedIn, X, and Snapchat (28 shorts + 4 videos/month, 5 LinkedIn posts/week, 3 X posts/week).',
            '24-Hour Custom Design SLA: Deliver personalized concept designs within 24 hours of receiving an inquiry; refresh offline banners every 90 days.',
          ],
        ),
        KonarSection(
          id: 'sec_3',
          title: '03 PROCESS',
          subtitle: '5-Stage Content Pipeline, Lead Funnels, 11-Stage Labelling & Offline Design Flow',
          content: 'End-to-end standard operating workflows governing content creation, incoming lead qualification, order processing, and custom design generation.',
          keyRules: [
            '5-Stage Content Pipeline: Product Selection -> Brainstorming (FIFO product pipeline) -> Spot/Day/Time scheduling -> Production (Shoot/Edit) -> Dual Sign-off (OSH/VPE internal, CEO final).',
            'Lead Qualification SLA: Strict under 3-minute first response time for all digital inquiries during showroom operating hours.',
            '11-Stage Labelling Workflow: New Lead -> Scheme/Direct Sale Discussion -> Estimation Sent -> Order Confirmation -> CADD Confirmation -> Internal QC -> Billing & Payment Check -> Secure Packing -> Dispatch -> Delivery Confirmation -> Happy Customer.',
            'Ready Stock vs Against Order: Immediate billing and dispatch for ready stock; structured CAD/CAM modeling, casting, and QC for custom against-order pieces.',
            'Offline Design Workflow: Designer availability check -> 1-on-1 briefing -> WhatsApp group output -> mandatory star rating before processing next design.',
          ],
        ),
        KonarSection(
          id: 'sec_4',
          title: '04 STRUCTURE',
          subtitle: 'Multi-Floor Sourcing, Cross-Functional Approvals & Platform Roles',
          content: 'Organizational governance defining how floor salespersons, creative specialists, digital marketers, billing officers, and packaging heads interact seamlessly.',
          keyRules: [
            'Showroom Counter Coordination: VPE/Ass.VPE coordinate with ground floor, 1st floor chain/haram, 2nd floor silver, and diamond counter salespersons; 3-day stock audits by OTM.',
            'Website Listing Protocol: 7-stage gate (Asset Master -> Stock Active/Inactive Filter -> Product Attributes & MC/VA Check -> OSH Verification -> Listing -> Organic Promotion -> Paid Retargeting).',
            'WhatsApp Network: Simultaneous asset broadcasting across official numbers (80567 36999 / 89258 68077), internal office groups, and staff personal WhatsApp status.',
            'Mobile App Scheme Operations: Unified scheme promotions, in-app catalog updates, Gallabox re-estimation verification, and OTP/push notification delivery.',
            'Google Search & Local SEO: Active Google Business Profile maintenance, keyword optimization (Planner/Trends), PMax campaigns, and mandatory QR-code review collection at checkout counters.',
            'Designing Requirement Box: Dedicated WhatsApp Design Group; requests captured via Google Forms/internal briefing with zero unapproved rework.',
          ],
        ),
        KonarSection(
          id: 'sec_5',
          title: '05 SYSTEM',
          subtitle: 'Monthly Cadence, Budget Allocations, Retargeting & Rating Matrices',
          content: 'Continuous accountability mechanisms, SLA enforcement, advertising budget governance, and customer satisfaction audits.',
          keyRules: [
            'Instagram System: Daily ad budget monitoring, lead conversion tracking, and monthly review reports submitted by AC to CEO.',
            'Website Cadence: 400 new asset listings/month for MN Jewel Park + 200 for Vadivam; 4 retargeting ad campaigns/month; bi-daily gold rate updates (10:30 AM & 4:00 PM).',
            'WhatsApp Metrics: 1,000 new contacts, 25,000 broadcast reach, 90 channel updates, and min 2 monthly automated broadcast campaigns.',
            'Mobile App System: 400 MN assets + 200 Vadivam assets/month, 90 push notifications, and 2 active scheme acquisition campaigns.',
            'Google System: 30 new Google/GMB listings/month, 500 qualified leads/month, weekly performance scorecards submitted by AC.',
            'Designing Rating System: 5-star customer rating and 5-star concerned team rating (On-Time Delivery, Communication, Design Perfection); no new design initiated without previous rating.',
          ],
        ),
      ],
    );
  }
}
