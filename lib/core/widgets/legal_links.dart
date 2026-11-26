import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The Privacy Policy and Terms & Conditions pages (web/legal/*.html),
/// hosted with the web app.
enum LegalPage {
  privacy('Privacy Policy', 'privacy', Icons.privacy_tip_outlined),
  terms('Terms & Conditions', 'terms', Icons.gavel_rounded);

  final String title;
  final String slug;
  final IconData icon;
  const LegalPage(this.title, this.slug, this.icon);

  /// The live web app. Phones open the pages from here.
  static const String webHost = 'https://mnfamily-pi.vercel.app';

  /// On the web, the pages are on the same site as the app, so the link
  /// works on whatever domain it is served from.
  Uri get url => kIsWeb
      ? Uri.base.resolve('/legal/$slug.html')
      : Uri.parse('$webHost/legal/$slug.html');

  /// Opens the page: a new tab on the web, an in-app browser on phones.
  Future<void> open(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    bool ok = false;
    try {
      ok = await launchUrl(
        url,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
        webOnlyWindowName: '_blank',
      );
      if (!ok && !kIsWeb) {
        ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger?.showSnackBar(SnackBar(content: Text('Could not open the $title. Visit ${url.toString()}')));
    }
  }
}
