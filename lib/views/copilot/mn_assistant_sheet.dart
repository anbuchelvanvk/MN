import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ecosystem_provider.dart';
import '../../services/mn_ai_copilot_service.dart';
import '../../services/vantura_agent_service.dart';
import '../media/creative_media_review_board_screen.dart';
import '../konar/konar_books_directory_screen.dart';
import '../orders/online_orders_handler_screen.dart';
import '../chat/chat_hub_screen.dart';
import '../../core/widgets/emergency_permission_modal.dart';
import '../../core/widgets/emergency_medical_leave_modal.dart';
import '../hr/hr_portal_subpages.dart';
import '../employee/employee_subpages.dart';

class ChatBubbleMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final CopilotActionType actionType;
  final String? actionLabel;

  ChatBubbleMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionType = CopilotActionType.none,
    this.actionLabel,
  });
}

class MnAssistantSheet extends StatefulWidget {
  const MnAssistantSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MnAssistantSheet(),
    );
  }

  @override
  State<MnAssistantSheet> createState() => _MnAssistantSheetState();
}

class _MnAssistantSheetState extends State<MnAssistantSheet> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VanturaAgentService _vanturaService = VanturaAgentService();
  bool _isProcessing = false;

  final List<ChatBubbleMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final eco = Provider.of<EcosystemProvider>(context, listen: false);
      final welcome = MnAiCopilotService.buildWelcomeMessage(eco);
      setState(() {
        _messages.add(
          ChatBubbleMessage(
            text: welcome,
            isUser: false,
            timestamp: DateTime.now(),
            actionType: CopilotActionType.none,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitPrompt([String? explicitText]) async {
    final text = (explicitText ?? _promptController.text).trim();
    if (text.isEmpty || _isProcessing) return;

    final eco = Provider.of<EcosystemProvider>(context, listen: false);

    setState(() {
      _messages.add(
        ChatBubbleMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _promptController.clear();
      _isProcessing = true;
    });
    _scrollToBottom();

    try {
      final response = await _vanturaService.runAgent(
        prompt: text,
        eco: eco,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _messages.add(
          ChatBubbleMessage(
            text: response.text,
            isUser: false,
            timestamp: DateTime.now(),
            actionType: response.actionType,
            actionLabel: response.actionLabel,
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      final local = MnAiCopilotService.processQuery(query: text, eco: eco);
      setState(() {
        _isProcessing = false;
        _messages.add(
          ChatBubbleMessage(
            text: local.text,
            isUser: false,
            timestamp: DateTime.now(),
            actionType: local.actionType,
            actionLabel: local.actionLabel,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _handleAction(BuildContext context, CopilotActionType action) {
    switch (action) {
      case CopilotActionType.openEmergencyPermission:
        Navigator.pop(context);
        EmergencyPermissionModal.show(context);
        break;
      case CopilotActionType.openEmergencyMedicalLeave:
        Navigator.pop(context);
        EmergencyMedicalLeaveModal.show(context);
        break;
      case CopilotActionType.openMediaReviewBoard:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CreativeMediaReviewBoardScreen()),
        );
        break;
      case CopilotActionType.openKonarBook:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const KonarBooksDirectoryScreen()),
        );
        break;
      case CopilotActionType.openOnlineOrders:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const OnlineOrdersHandlerScreen()),
        );
        break;
      case CopilotActionType.openStaffDirectory:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const HrStaffDirectoryScreen()),
        );
        break;
      case CopilotActionType.openChatHub:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatHubScreen()),
        );
        break;
      case CopilotActionType.openTaskList:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeThingsToDoScreen()),
        );
        break;
      case CopilotActionType.openCrossDeptBlockers:
      case CopilotActionType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                // Radiant Gold AI Logo
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MN Assistant',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Live SOP & Policy Knowledge Engine',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Reset Conversation',
                  onPressed: () {
                    _vanturaService.resetMemory();
                    setState(() {
                      _messages.clear();
                      _messages.add(
                        ChatBubbleMessage(
                          text: MnAiCopilotService.buildWelcomeMessage(eco),
                          isUser: false,
                          timestamp: DateTime.now(),
                        ),
                      );
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Chat Messages View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageRow(msg);
              },
            ),
          ),

          // Processing Indicator
          if (_isProcessing) ...[
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFD97706)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MN Assistant is analyzing your profile & records...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Input Box (Direct natural typing - no preloaded options)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _promptController,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Type any question about your tasks, SOPs, permissions...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: const Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submitPrompt(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _submitPrompt,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(ChatBubbleMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Assistant Message with Rich Structured Parser
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 28),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 13, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  'MN ASSISTANT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Rich Structured Content View (No raw markdown asterisks or hashes)
            _StructuredMessageContent(rawText: msg.text),

            // Deep-link Action Button
            if (msg.actionType != CopilotActionType.none &&
                msg.actionLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: Text(msg.actionLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _handleAction(context, msg.actionType),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rich Structured Message Content Widget
/// Parses markdown-like text lines into native, beautifully styled Flutter widgets:
/// - Headers (### ...) rendered as clean badge banners with icons
/// - Blockquotes (> ...) rendered as soft-tinted policy callout cards
/// - Bullet items (* ... or 1. ...) rendered with native bullet indicators and bold text
/// - Inline bolding (**...**) rendered seamlessly without raw asterisks
class _StructuredMessageContent extends StatelessWidget {
  final String rawText;

  const _StructuredMessageContent({required this.rawText});

  @override
  Widget build(BuildContext context) {
    final lines = rawText.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // 1. Header Banner (### ...)
      if (line.startsWith('###')) {
        final cleanHeader = line.replaceAll('###', '').replaceAll('**', '').trim();
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              cleanHeader,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        );
        continue;
      }

      // 2. Policy / Guideline Callout Quote (> ...)
      if (line.startsWith('>')) {
        final cleanQuote = line.replaceFirst(RegExp(r'>\s*'), '').trim();
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3.5,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInlineRichText(
                    cleanQuote,
                    defaultColor: const Color(0xFF92400E),
                    boldColor: const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 3. Bullet Point (* ... or - ...)
      if (line.startsWith('* ') || line.startsWith('- ')) {
        final content = line.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: _buildInlineRichText(content),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 4. Numbered List Item (1. ... to 12. ...)
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final content = numMatch.group(2)!;
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 1, right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    numStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildInlineRichText(content),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 5. Standard Text Paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildInlineRichText(line),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Parses inline bolding (**bold**), code blocks (`code`), and italics (*italic*)
  /// returning a rich Text widget with clean typography and zero raw asterisks
  Widget _buildInlineRichText(
    String text, {
    Color defaultColor = const Color(0xFF334155),
    Color boldColor = const Color(0xFF0F172A),
  }) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)');

    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              height: 1.45,
              color: defaultColor,
            ),
          ),
        );
      }

      final matchStr = match.group(0)!;
      if (matchStr.startsWith('**') && matchStr.endsWith('**')) {
        final content = matchStr.substring(2, matchStr.length - 2);
        spans.add(
          TextSpan(
            text: content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              height: 1.45,
              color: boldColor,
            ),
          ),
        );
      } else if (matchStr.startsWith('`') && matchStr.endsWith('`')) {
        final content = matchStr.substring(1, matchStr.length - 1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      } else if (matchStr.startsWith('*') && matchStr.endsWith('*')) {
        final content = matchStr.substring(1, matchStr.length - 1);
        spans.add(
          TextSpan(
            text: content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              height: 1.45,
              color: defaultColor,
            ),
          ),
        );
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            height: 1.45,
            color: defaultColor,
          ),
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }
}
