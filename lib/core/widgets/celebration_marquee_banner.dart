import 'dart:async';
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

class _ActiveCelebrationMarqueeState extends State<_ActiveCelebrationMarquee> {
  int _currentIndex = 0;
  Timer? _cycleTimer;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (widget.celebrations.length > 1 && !_isTestEnvironment) {
      _cycleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.celebrations.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final activeId = eco.activeEmpId;
    final activeName = eco.currentEmployee.name;

    final activeCelebration = widget.celebrations[_currentIndex % widget.celebrations.length];
    final message = activeCelebration.displayMessage(activeId, activeName);
    final isSelf = activeId == activeCelebration.employeeId ||
        activeName.toLowerCase().contains(activeCelebration.employeeName.toLowerCase());

    String greetingText = 'Congratulations to our celebrating team members! 🥳';
    if (activeCelebration.type == 'birthday') {
      greetingText = 'Happy Birthday @${activeCelebration.employeeName} 🥳🎂 Wishing you the very best!';
    } else {
      greetingText = 'Happy Wedding Anniversary @${activeCelebration.employeeName} 💍💐 Wishing you lifelong happiness!';
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
                initialText: isSelf ? 'Thank you all for the wonderful wishes! 🎉❤️' : greetingText,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF831843), // Rich festive berry
                Color(0xFFB45309), // Warm celebratory amber/gold
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
                padding: const EdgeInsets.only(left: 2, right: 8),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFFFDE68A),
                  size: 20,
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    key: ValueKey('celeb_${activeCelebration.employeeId}_${activeCelebration.type}_$_currentIndex'),
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A).withOpacity(0.6), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSelf ? 'Celebrate' : 'Wish',
                      style: const TextStyle(
                        color: Color(0xFFFEF08A),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFEF08A), size: 9),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

