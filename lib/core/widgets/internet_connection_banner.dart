import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/network_connectivity_service.dart';

/// InternetConnectionBanner sits at the root of the app and automatically displays
/// a prominent warning banner at the top of the screen whenever the device is disconnected.
/// Displays the exact warning: "Check your Internet Connection" with a FontAwesome X symbol.
class InternetConnectionBanner extends StatelessWidget {
  final Widget child;

  const InternetConnectionBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NetworkConnectivityService(),
      builder: (context, _) {
        final isOnline = NetworkConnectivityService().isOnline;
        final isChecking = NetworkConnectivityService().isChecking;

        return Stack(
          children: [
            child,

            // Top Warning Banner - only rendered at the top when offline
            if (!isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 12,
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB91C1C), // Prominent warning crimson
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFF59E0B), width: 1.5), // Gold border
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            // X fa fa symbol
                            const Icon(
                              Icons.cancel_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Check your Internet Connection',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => NetworkConnectivityService().checkConnection(),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isChecking)
                                      const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    else
                                      const Icon(Icons.refresh, color: Colors.white, size: 15),
                                    const SizedBox(width: 4),
                                    Text(
                                      isChecking ? 'Checking' : 'Retry',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
