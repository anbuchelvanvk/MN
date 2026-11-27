import 'package:flutter/material.dart';

import '../../views/legal/legal_screen.dart';
import '../legal/legal_content.dart';

/// The Privacy Policy and Terms & Conditions. For now they are built into
/// the app (see core/legal/legal_content.dart) and open in an in-app screen.
/// The same text is also in web/legal/*.html for the website.
enum LegalPage {
  privacy('Privacy Policy', 'privacy', Icons.privacy_tip_outlined),
  terms('Terms & Conditions', 'terms', Icons.gavel_rounded);

  final String title;
  final String slug;
  final IconData icon;
  const LegalPage(this.title, this.slug, this.icon);

  LegalDocument get document => this == LegalPage.privacy ? privacyPolicy : termsAndConditions;

  /// Opens the in-app reading screen.
  Future<void> open(BuildContext context) => LegalScreen.open(context, document);
}
