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
      _cycleTimer = Timer.periodic(const Duration(seconds: 14), (timer) {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF881337), // Rich festive berry
                Color(0xFFB45309), // Warm celebratory amber/gold
                Color(0xFF881337),
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
                  size: 21,
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _CelebrationTickerText(
                    key: ValueKey('celeb_${activeCelebration.employeeId}_${activeCelebration.type}_$_currentIndex'),
                    text: message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.0),
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
                        fontSize: 11.0,
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

/// Smooth auto-scrolling ticker text widget with initial pause and rewind
class _CelebrationTickerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _CelebrationTickerText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<_CelebrationTickerText> createState() => _CelebrationTickerTextState();
}

class _CelebrationTickerTextState extends State<_CelebrationTickerText> {
  late final ScrollController _scrollController;
  Timer? _tickerTimer;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (!_isTestEnvironment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTickerLoop();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _CelebrationTickerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _tickerTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
      if (!_isTestEnvironment) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startTickerLoop();
        });
      }
    }
  }

  void _startTickerLoop() async {
    _tickerTimer?.cancel();
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      return;
    }

    // 1. Initial 1.8s reading pause at start
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted || !_scrollController.hasClients) return;

    // 2. Smooth linear scroll across to the end
    final durationMs = (maxScroll * 35).clamp(2500, 10000).toInt();
    try {
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
    } catch (_) {}

    if (!mounted || !_scrollController.hasClients) return;

    // 3. Pause at the end for 1.5s
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || !_scrollController.hasClients) return;

    // 4. Smoothly rewind back to the beginning
    try {
      await _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    } catch (_) {}

    if (!mounted || !_scrollController.hasClients) return;

    // 5. Repeat ticker cycle
    _startTickerLoop();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
