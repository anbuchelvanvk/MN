import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ecosystem_provider.dart';
import 'chat_conversation_screen.dart';
import 'chat_hub_screen.dart';

/// What the floating chat window opens to.
enum FloatingChatStart { hub, allHands, allHandsEmoji, allHandsAttach }

/// Team chat as a floating window over the current screen (instead of a
/// full-page route). Conversations open inside the window; the system back
/// button steps back within the window first, then closes it.
class FloatingChatWindow {
  static Future<void> show(
    BuildContext context, {
    FloatingChatStart start = FloatingChatStart.hub,
  }) {
    final eco = context.read<EcosystemProvider>();
    final navKey = GlobalKey<NavigatorState>();

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close chat',
      barrierColor: const Color(0x662A0F22),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogCtx, _, __) {
        void close() => Navigator.of(dialogCtx).pop();

        Widget first;
        switch (start) {
          case FloatingChatStart.hub:
            first = ChatHubScreen(onClose: close);
            break;
          case FloatingChatStart.allHands:
          case FloatingChatStart.allHandsEmoji:
          case FloatingChatStart.allHandsAttach:
            first = ChatConversationScreen(
              peerId: 'ALL_HANDS',
              peerName: 'MN All-Hands Workforce',
              peerRole: 'CEO, HR, TL & All Employees',
              peerInitials: 'ALL',
              isGroup: true,
              onClose: close,
              autoOpenEmoji: start == FloatingChatStart.allHandsEmoji,
              autoOpenAttachments: start == FloatingChatStart.allHandsAttach,
            );
        }

        final media = MediaQuery.of(dialogCtx);
        final keyboard = media.viewInsets.bottom;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            final nav = navKey.currentState;
            if (nav != null && nav.canPop()) {
              nav.pop();
            } else {
              close();
            }
          },
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 28, 10, 10 + keyboard),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Material(
                    color: Colors.white,
                    elevation: 18,
                    shadowColor: const Color(0x55881337),
                    borderRadius: BorderRadius.circular(26),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: (media.size.height - keyboard) * 0.86,
                      child: Column(
                        children: [
                          // Grab handle + close
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(16, 8, 6, 0),
                            child: Row(
                              children: [
                                const Spacer(),
                                Container(
                                  width: 42,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEADCE4),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Close chat',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFF756A80)),
                                  onPressed: close,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            // The window already sits above the keyboard (padding and
                            // height above). Without this, the chat screen inside also
                            // shrank for the keyboard, a second time, leaving no room for
                            // the message list: messages vanished and sent ones seemed lost.
                            child: MediaQuery.removeViewInsets(
                              context: dialogCtx,
                              removeBottom: true,
                              child: ChangeNotifierProvider<EcosystemProvider>.value(
                                value: eco,
                                child: Navigator(
                                  key: navKey,
                                  onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => first),
                                ),
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
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
              alignment: Alignment.bottomRight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
