import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ecosystem_provider.dart';
import 'acceptance_popup_banner.dart';

/// AppNotificationHost lives at the root MaterialApp builder and overlays
/// floating pop-up acceptance notifications on top of whichever screen the user is viewing.
class AppNotificationHost extends StatelessWidget {
  final Widget child;

  const AppNotificationHost({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EcosystemProvider>(
      builder: (context, eco, _) {
        final activePopup = eco.currentAcceptancePopupForActiveUser;

        return Stack(
          children: [
            child,

            // Floating Pop-Up Banner for Permission & Leave Acceptance
            if (activePopup != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AcceptancePopupBanner(
                  key: ValueKey(activePopup.id),
                  popup: activePopup,
                ),
              ),
          ],
        );
      },
    );
  }
}
