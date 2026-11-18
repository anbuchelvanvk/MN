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
          title: 'Chapter 1: Department Mission & Role Hierarchy',
          subtitle: 'Leadership, Core Objectives & Chain of Command',
          content: 'The MN Jewel Park Online Department manages global client outreach, digital catalog presentations, high-value jewelry sales, and omnichannel customer satisfaction. Every staff member represents the MN brand integrity.',
          keyRules: [
            'Team Leader: Mr. M. Praveen Kumar (OTM) oversees daily SLAs, content publishing, and escalation workflows.',
            'Executive Management: MD & CEO (Mr. M N Naveenraaj) and HR Manager (Mr. Mohankumar G) maintain final administrative authority.',
            'Daily shift check-ins and evening task reviews are mandatory for all team members.',
          ],
        ),
        KonarSection(
          id: 'sec_2',
          title: 'Chapter 2: Photography & Videography Master Protocols (VPE & Ass.VPE)',
          subtitle: 'Studio Staging, Lighting, Counter Selection & Reel Production',
          content: 'Visual fidelity is our primary sales catalyst. Photography and reels must highlight purity, 916 BIS hallmark stamps, intricate craftsmanship, and natural gemstone luster.',
          keyRules: [
            'Daily product selections must occur before 11:30 AM across Ground Floor, 1st Floor, 2nd Floor, and Diamond Counters.',
            'Minimum weekly target: 7 high-production content reels and 21 catalog asset shoots.',
            'All reels and product media require final sign-off from OTM and CEO before publishing.',
            'Ass.VPE coordinates floor salespersons (Sandhiya, Suganya, Lakshmipriya) for live model shoots.',
          ],
        ),
        KonarSection(
          id: 'sec_3',
          title: 'Chapter 3: Online Sales Engagement & Inquiry SLAs (OSH, OS1, OS2)',
          subtitle: 'WhatsApp Business, Instagram DMs, Client Calls & Conversions',
          content: 'Rapid, polite, and authoritative customer engagement converts inquiries into lifelong patrons. Never delay customer responses during business hours.',
          keyRules: [
            'Inquiry First Response Time SLA: Strictly under 3 minutes during working hours.',
            'Always send authentic certificate cards, exact weight breakdowns, and making charges clearly.',
            'Maintain personalized client follow-up logs on WhatsApp without aggressive sales pressure.',
            'Confirm payment gateway verification before marking orders as confirmed.',
          ],
        ),
        KonarSection(
          id: 'sec_4',
          title: 'Chapter 4: Secure Packaging, Dispatch & Delivery (AC & DVP)',
          subtitle: 'Invoicing, Tamper-Evident Packaging, Insurance & Transit Tracking',
          content: 'Every jewelry dispatch must follow tamper-proof security protocols. Customer trust depends on flawless, secure parcel handovers.',
          keyRules: [
            'Accountant (Mr. Midhun Kumar) must verify 100% payment receipt before invoice generation.',
            'Parcels must use dual-layer tamper-evident envelopes with serial-numbered holographic security tape.',
            'Delivery Person (Mr. Vimal) must verify OTP and physical signature upon final parcel handover.',
            'Real-time tracking links must be communicated to customers immediately after courier dispatch.',
          ],
        ),
        KonarSection(
          id: 'sec_5',
          title: 'Chapter 5: Post-Sales Care & Feedback Management (CC & OSS)',
          subtitle: 'Order Tracking, Customer Feedback Calls & Exchange Protocols',
          content: 'Post-sales care defines the MN Jewel Park family culture. Customer satisfaction is our highest metric.',
          keyRules: [
            'Customer Care (Mr. Sam Roy) conducts courtesy calls within 48 hours of product delivery.',
            'Record ring sizing, polish requests, and maintenance feedback in the client dossier.',
            'Resolve all return, exchange, or sizing queries within a 24-hour SLA window.',
          ],
        ),
        KonarSection(
          id: 'sec_6',
          title: 'Chapter 6: Social Media Publishing Schedules & Handover (OTM)',
          subtitle: 'Timetable, Platform SLAs & Shift Close Protocols',
          content: 'Strict adherence to publishing hours maximizes organic reach across Instagram, YouTube, X, and Pinterest.',
          keyRules: [
            '08:00 AM: Morning gold carousel and multi-platform distribution.',
            '10:00 AM & 03:00 PM: Daily Instagram Stories featuring trending designs.',
            '02:00 PM: Gold product showcase reel.',
            '04:00 PM: Silver jewelry reel and Vadivam collection showcase.',
            '07:00 PM: Prime evening brand reel and final daily metric review.',
          ],
        ),
      ],
    );
  }
}
