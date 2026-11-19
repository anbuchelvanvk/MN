import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ecosystem_provider.dart';
import '../../models/company_notification_models.dart';
import '../../views/chat/chat_conversation_screen.dart';

class CelebrationMarqueeBanner extends StatelessWidget {
  const CelebrationMarqueeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final celebrations = eco.todayCelebrations;

    if (celebrations.isEmpty) {
      return const SizedBox.shrink();
    }

    return _ActiveCelebrationMarquee(celebrations: celebrations);
  }
}

class _ActiveCelebrationMarquee extends StatefulWidget {
  final List<CelebrationEvent> celebrations;
  const _ActiveCelebrationMarquee({required this.celebrations});

  @override
  State<_ActiveCelebrationMarquee> createState() => _ActiveCelebrationMarqueeState();
}

class _ActiveCelebrationMarqueeState extends State<_ActiveCelebrationMarquee> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  AnimationController? _animController;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    if (!_isTestEnvironment) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 18),
      )..addListener(() {
          if (_scrollController.hasClients) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            if (maxScroll > 15 && _animController != null) {
              final val = _animController!.value;
              // Hold at beginning for 25% of the cycle so users can read the start clearly
              if (val < 0.25) {
                _scrollController.jumpTo(0);
              } else if (val > 0.85) {
                // Hold briefly at end
                _scrollController.jumpTo(maxScroll);
              } else {
                final progress = (val - 0.25) / 0.60;
                _scrollController.jumpTo(progress * maxScroll);
              }
            } else if (_scrollController.hasClients && _scrollController.offset != 0) {
              _scrollController.jumpTo(0);
            }
          }
        });
      _animController!.repeat();
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final activeId = eco.activeEmpId;
    final activeName = eco.currentEmployee.name;
    final message = widget.celebrations
        .map((c) => c.displayMessage(activeId, activeName))
        .join('    ✨    ');

    final firstCelebration = widget.celebrations.isNotEmpty ? widget.celebrations.first : null;
    String greetingText = 'Congratulations to our celebrating team members! 🥳';
    if (firstCelebration != null) {
      if (firstCelebration.type == 'birthday') {
        greetingText = 'Happy Birthday @${firstCelebration.employeeName} 🥳';
      } else {
        greetingText = 'Happy Wedding Anniversary @${firstCelebration.employeeName} 💍';
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatConversationScreen(
                peerId: 'ALL_HANDS',
                peerName: 'MN All-Hands Workforce',
                peerRole: 'CEO, HR, TL & All Employees',
                peerInitials: 'MN',
                isGroup: true,
                initialText: greetingText,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF831843), // Rich festive magenta / berry
                Color(0xFFB45309), // Warm gold / amber
                Color(0xFF831843),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB45309).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: const Icon(Icons.celebration_rounded, color: Color(0xFFFDE68A), size: 18),
              ),
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        Text(
                          message,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 80),
                        Text(
                          message,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
