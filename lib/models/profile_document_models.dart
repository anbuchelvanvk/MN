import 'package:flutter/material.dart';

/// Status of an original document submitted to the company vault
enum DocumentSubmissionStatus {
  submitted, // Original safely stored in company vault
  pending,   // Pending submission by employee
  verifying, // Under HR & legal verification
}

/// Original document custody item submitted by the employee
class OriginalDocumentItem {
  final String id;
  final String title;
  final String category; // 'Academic Marksheet', 'Degree Certificate', 'Identity Proof', 'Employment Record', 'Trade License'
  final String certificateNumber;
  final DocumentSubmissionStatus status;
  final String submissionDate;
  final String vaultLockerRef;
  final bool isMandatory;
  final String iconEmoji;
  final String? remarks;

  OriginalDocumentItem({
    required this.id,
    required this.title,
    required this.category,
    this.certificateNumber = 'N/A',
    required this.status,
    required this.submissionDate,
    this.vaultLockerRef = '',
    this.isMandatory = true,
    this.iconEmoji = '📜',
    this.remarks,
  });

  OriginalDocumentItem copyWith({
    String? id,
    String? title,
    String? category,
    String? certificateNumber,
    DocumentSubmissionStatus? status,
    String? submissionDate,
    String? vaultLockerRef,
    bool? isMandatory,
    String? iconEmoji,
    String? remarks,
  }) {
    return OriginalDocumentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      status: status ?? this.status,
      submissionDate: submissionDate ?? this.submissionDate,
      vaultLockerRef: vaultLockerRef ?? this.vaultLockerRef,
      isMandatory: isMandatory ?? this.isMandatory,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      remarks: remarks ?? this.remarks,
    );
  }

  String get statusLabel {
    switch (status) {
      case DocumentSubmissionStatus.submitted:
        return 'Submitted (In Safe Vault)';
      case DocumentSubmissionStatus.pending:
        return 'Pending Submission';
      case DocumentSubmissionStatus.verifying:
        return 'Under HR Verification';
    }
  }

  Color get statusColor {
    switch (status) {
      case DocumentSubmissionStatus.submitted:
        return const Color(0xFF10B981); // Emerald Green
      case DocumentSubmissionStatus.pending:
        return const Color(0xFFEF4444); // Red
      case DocumentSubmissionStatus.verifying:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'certificateNumber': certificateNumber,
      'status': status.name,
      'submissionDate': submissionDate,
      'vaultLockerRef': vaultLockerRef,
      'isMandatory': isMandatory,
      'iconEmoji': iconEmoji,
      'remarks': remarks,
    };
  }

  factory OriginalDocumentItem.fromMap(Map<String, dynamic> map) {
    DocumentSubmissionStatus parsedStatus = DocumentSubmissionStatus.submitted;
    if (map['status'] == 'pending') {
      parsedStatus = DocumentSubmissionStatus.pending;
    } else if (map['status'] == 'verifying') {
      parsedStatus = DocumentSubmissionStatus.verifying;
    }

    return OriginalDocumentItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      certificateNumber: map['certificateNumber'] ?? 'N/A',
      status: parsedStatus,
      submissionDate: map['submissionDate'] ?? '',
      vaultLockerRef: map['vaultLockerRef'] ?? '',
      isMandatory: map['isMandatory'] ?? true,
      iconEmoji: map['iconEmoji'] ?? '📜',
      remarks: map['remarks'],
    );
  }
}

/// Pre-filled templates for standard original documents required by the company
class DocumentTemplates {
  static const List<Map<String, String>> standardOptions = [
    {
      'title': '10th Standard Original Marksheet (SSLC/CBSE/ICSE)',
      'category': 'Academic Marksheet',
      'emoji': '📜',
      'mandatory': 'true',
    },
    {
      'title': '12th / Higher Secondary Original Marksheet (HSC/CBSE)',
      'category': 'Academic Marksheet',
      'emoji': '📜',
      'mandatory': 'true',
    },
    {
      'title': 'Undergraduate Degree / Diploma Original Certificate',
      'category': 'Degree Certificate',
      'emoji': '🎓',
      'mandatory': 'true',
    },
    {
      'title': 'Transfer Certificate (TC) / Migration Certificate',
      'category': 'Academic Record',
      'emoji': '📑',
      'mandatory': 'true',
    },
    {
      'title': 'Aadhaar Card / Government Identity Proof',
      'category': 'Identity Proof',
      'emoji': '🪪',
      'mandatory': 'true',
    },
    {
      'title': 'Permanent Account Number (PAN) Card',
      'category': 'Identity Proof',
      'emoji': '💳',
      'mandatory': 'true',
    },
    {
      'title': 'Previous Experience & Relieving Certificate',
      'category': 'Employment Record',
      'emoji': '📄',
      'mandatory': 'false',
    },
    {
      'title': 'Gold Hallmarking / Artisan Craft Trade Certificate',
      'category': 'Trade License',
      'emoji': '💍',
      'mandatory': 'false',
    },
    {
      'title': 'Passport Original / Police Verification Certificate',
      'category': 'Verification Record',
      'emoji': '🛂',
      'mandatory': 'false',
    },
    {
      'title': 'Medical Fitness & Blood Group Certification',
      'category': 'Health Record',
      'emoji': '🏥',
      'mandatory': 'false',
    },
  ];
}

/// Tier rating levels for Pillar 4
enum PillarTierLevel {
  green,  // High performance, pristine balance (Tier 1)
  yellow, // Moderate performance, slight lag in 1-2 areas (Tier 2)
  red,    // Compromised performance, critical improvement required (Tier 3)
}

/// Breakdown lag item for Pillar 4 audit
class PillarLagItem {
  final String pillarTitle;
  final String status;
  final String description;
  final String improvementAction;
  final bool isCompromised; // true = red/yellow lag, false = green strong point
  final Color indicatorColor;
  final IconData icon;

  PillarLagItem({
    required this.pillarTitle,
    required this.status,
    required this.description,
    required this.improvementAction,
    required this.isCompromised,
    required this.indicatorColor,
    required this.icon,
  });
}
