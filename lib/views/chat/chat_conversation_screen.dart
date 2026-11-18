import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message_model.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';

/// Custom TextEditingController that dynamically styles mentioned names in signature Magenta
class MentionTextEditingController extends TextEditingController {
  final List<String> Function() getEmployeeNames;

  MentionTextEditingController({
    super.text,
    required this.getEmployeeNames,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    if (!text.contains('@')) {
      return TextSpan(text: text, style: style);
    }

    final spans = <TextSpan>[];
    final defaultStyle = style ?? const TextStyle(fontSize: 13.5, color: AppColors.textDark);
    final mentionStyle = defaultStyle.copyWith(
      color: AppColors.magentaPrimary,
      fontWeight: FontWeight.bold,
      backgroundColor: const Color(0xFFFDF2F8),
    );

    final rawNames = getEmployeeNames();
    final names = rawNames
        .where((n) => n.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length)); // Longest names first

    final patternParts = <String>[];
    for (final name in names) {
      patternParts.add('@${RegExp.escape(name)}');
    }
    patternParts.add(r'@[A-Za-z0-9_]+');
    final regex = RegExp('(${patternParts.join('|')})');

    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: mentionStyle,
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    return TextSpan(children: spans);
  }
}

class ChatConversationScreen extends StatefulWidget {
  final String peerId; // 'ALL_HANDS' or specific employeeId
  final String peerName;
  final String peerRole;
  final String peerInitials;
  final bool isGroup;
  final String? initialText;

  const ChatConversationScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.peerRole,
    required this.peerInitials,
    this.isGroup = false,
    this.initialText,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  late final MentionTextEditingController _textController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  // Reply tracking
  ChatMessage? _replyingTo;

  // @ Mention tracking
  bool _showMentionSuggestions = false;
  List<Employee> _mentionMatches = [];

  final List<String> _quickReplies = [
    '👍 Understood',
    '✅ On it!',
    '🎉 Congratulations!',
    '📞 Calling shortly',
    '🙏 Thank you!',
    '⭐ Great work',
  ];

  @override
  void initState() {
    super.initState();
    _textController = MentionTextEditingController(
      text: widget.initialText ?? '',
      getEmployeeNames: () {
        if (!mounted) return [];
        final eco = Provider.of<EcosystemProvider>(context, listen: false);
        return eco.allEmployees.map((e) => e.name).toList();
      },
    );

    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eco = Provider.of<EcosystemProvider>(context, listen: false);
      eco.markConversationAsRead(widget.peerId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged([String? _]) {
    final text = _textController.text;
    final selection = _textController.selection;
    final cursorOffset = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
    if (cursorOffset <= 0) {
      if (_showMentionSuggestions) setState(() => _showMentionSuggestions = false);
      return;
    }

    final textBeforeCursor = text.substring(0, cursorOffset);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      final query = textBeforeCursor.substring(lastAtIndex + 1);
      // Query should not span multiple lines or multiple words
      if (!query.contains('\n') && !query.contains('  ')) {
        final eco = Provider.of<EcosystemProvider>(context, listen: false);
        final q = query.trim().toLowerCase();
        final matches = eco.allEmployees.where((e) {
          if (q.isEmpty) return true; // Show all on bare @
          return e.name.toLowerCase().contains(q) ||
              e.straightCutRole.toLowerCase().contains(q);
        }).toList();

        if (!_showMentionSuggestions || _mentionMatches.length != matches.length) {
          setState(() {
            _mentionMatches = matches;
            _showMentionSuggestions = matches.isNotEmpty;
          });
        }
        return;
      }
    }

    if (_showMentionSuggestions) {
      setState(() => _showMentionSuggestions = false);
    }
  }

  void _insertMention(Employee emp) {
    final text = _textController.text;
    final selection = _textController.selection;
    final cursorOffset = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
    final textBeforeCursor = text.substring(0, cursorOffset);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      final beforeAt = text.substring(0, lastAtIndex);
      final afterCursor = text.substring(cursorOffset);
      final inserted = '@${emp.name} ';
      final newText = '$beforeAt$inserted$afterCursor';

      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: beforeAt.length + inserted.length),
      );
    }

    setState(() {
      _showMentionSuggestions = false;
      _mentionMatches = [];
    });
    _focusNode.requestFocus();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(EcosystemProvider eco, [String? presetText]) async {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final reply = _replyingTo;

    setState(() {
      _isSending = true;
      _replyingTo = null;
      _showMentionSuggestions = false;
    });

    await eco.sendChatMessage(
      receiverId: widget.peerId,
      text: text,
      replyToId: reply?.id,
      replyToSenderName: reply?.senderName,
      replyToText: reply?.text,
    );

    if (presetText == null) {
      _textController.clear();
    }
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  String _formatMsgTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  void _showGroupRecipientsSheet(BuildContext context, EcosystemProvider eco) {
    final employees = eco.allEmployees;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFB45309), Color(0xFF831843)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MN All-Hands Workforce',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${employees.length} Group Recipients & Collaborators',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, idx) {
                    final emp = employees[idx];
                    final initials = emp.name.isNotEmpty
                        ? emp.name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
                        : '??';
                    final isSelf = emp.id.toLowerCase() == eco.activeEmpId.toLowerCase();

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelf ? const Color(0xFFFDF2F8) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelf ? const Color(0xFFFBCFE8) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isSelf ? AppColors.magentaPrimary : const Color(0xFF475569),
                            child: Text(
                              initials,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        emp.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelf) ...[
                                      const SizedBox(width: 4),
                                      const Text(
                                        '(You)',
                                        style: TextStyle(fontSize: 10.5, color: AppColors.magentaPrimary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${emp.straightCutRole} • ${emp.dept}',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!isSelf)
                            InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatConversationScreen(
                                      peerId: emp.id,
                                      peerName: emp.name,
                                      peerRole: emp.straightCutRole,
                                      peerInitials: initials,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF475569)),
                                    SizedBox(width: 4),
                                    Text('Direct', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPeerInfoSheet(BuildContext context, EcosystemProvider eco) {
    final emp = eco.allEmployees.firstWhere(
      (e) => e.id.toLowerCase() == widget.peerId.toLowerCase(),
      orElse: () => Employee(
        id: widget.peerId,
        name: widget.peerName,
        role: widget.peerRole,
        roleType: 'employee',
        dept: 'Jewelry Operations',
        phone: '',
        email: '',
        avatar: '',
        initials: widget.peerInitials,
        doj: '',
        experienceYears: '',
        experienceCategory: '',
        probationWeeks: 0,
        probationStatus: '',
        probationEndDate: '',
        profileCompletion: ProfileCompletion(
          percentage: 0,
          isAuthorized: false,
          photoVerified: false,
          addressVerified: false,
          kycVerified: false,
          sopRolesAcknowledged: false,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active',
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.magentaPrimary,
                child: Text(
                  widget.peerInitials,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.peerName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.peerRole,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Department: ${emp.dept}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    Text('Staff ID: ${emp.id}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    if (emp.email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Email: ${emp.email}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.magentaPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMentionSuggestionsBar() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email_rounded, size: 14, color: AppColors.magentaPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Mention Colleague',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.magentaPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(() => _showMentionSuggestions = false),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: _mentionMatches.length,
                itemBuilder: (context, idx) {
                  final emp = _mentionMatches[idx];
                  final initials = emp.name.isNotEmpty
                      ? emp.name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
                      : '??';

                  return InkWell(
                    onTap: () => _insertMention(emp),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.magentaPrimary.withOpacity(0.12),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.magentaPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              emp.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageText(String text, bool isMe, List<String> employeeNames) {
    if (!text.contains('@')) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isMe ? Colors.white : AppColors.textDark,
          height: 1.35,
        ),
      );
    }

    final spans = <TextSpan>[];
    final defaultStyle = TextStyle(
      fontSize: 13,
      color: isMe ? Colors.white : AppColors.textDark,
      height: 1.35,
    );
    final mentionStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: isMe ? const Color(0xFFFDE68A) : AppColors.magentaPrimary,
      backgroundColor: isMe ? Colors.white.withOpacity(0.18) : const Color(0xFFFDF2F8),
    );

    final names = employeeNames
        .where((n) => n.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final patternParts = <String>[];
    for (final name in names) {
      patternParts.add('@${RegExp.escape(name)}');
    }
    patternParts.add(r'@[A-Za-z0-9_]+');
    final regex = RegExp('(${patternParts.join('|')})');

    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: mentionStyle,
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  void _scrollToMessage(String messageId, List<ChatMessage> messages) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1 && _scrollController.hasClients) {
      final target = (index * 68.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildPinnedMessageBanner(
    BuildContext context,
    EcosystemProvider eco,
    ChatMessage pinnedMsg,
    List<ChatMessage> messages,
  ) {
    String remainingText = '';
    if (pinnedMsg.pinnedUntil != null) {
      final diff = pinnedMsg.pinnedUntil!.difference(DateTime.now());
      if (diff.inDays > 0) {
        remainingText = '${diff.inDays}d left';
      } else if (diff.inHours > 0) {
        remainingText = '${diff.inHours}h left';
      } else if (diff.inMinutes > 0) {
        remainingText = '${diff.inMinutes}m left';
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Icon(Icons.push_pin_rounded, size: 14, color: Color(0xFF059669)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _scrollToMessage(pinnedMsg.id, messages),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Pinned • ${pinnedMsg.senderName}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (remainingText.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            remainingText,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pinnedMsg.text,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _showUnpinDialog(context, eco, pinnedMsg),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageActionSheet(BuildContext context, EcosystemProvider eco, ChatMessage msg) {
    final isPinned = msg.isCurrentlyPinned;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.magentaPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        msg.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                    color: const Color(0xFF0D9488),
                  ),
                  title: Text(
                    isPinned ? 'Unpin Message' : 'Pin Message',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isPinned
                        ? 'Remove this message from the pinned banner'
                        : 'Keep this message easily accessible at the top',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isPinned) {
                      eco.unpinChatMessage(msg.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message unpinned')),
                      );
                    } else {
                      _showPinDurationDialog(context, eco, msg);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.reply_rounded, color: AppColors.magentaPrimary),
                  title: const Text('Reply', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _replyingTo = msg);
                    _focusNode.requestFocus();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Color(0xFF475569)),
                  title: const Text('Copy Text', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copied to clipboard')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    msg.isLikedBy(eco.activeEmpId) ? Icons.favorite : Icons.favorite_border,
                    color: const Color(0xFFEF4444),
                  ),
                  title: Text(
                    msg.isLikedBy(eco.activeEmpId) ? 'Unlike' : 'Like',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    eco.toggleChatMessageLike(msg.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPinDurationDialog(BuildContext context, EcosystemProvider eco, ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Icon(Icons.push_pin_rounded, color: Color(0xFF0D9488), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pin Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how long this pinned message will stay at the top of the chat:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                _buildPinOptionTile(
                  ctx,
                  title: '8 Hours',
                  subtitle: 'Pinned for 8 hours for quick shifts',
                  icon: Icons.timer_outlined,
                  onTap: () {
                    Navigator.pop(ctx);
                    eco.pinChatMessage(msg.id, duration: '8_hours');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message pinned for 8 hours 📌')),
                    );
                  },
                ),
                _buildPinOptionTile(
                  ctx,
                  title: '1 Week',
                  subtitle: 'Pinned for 7 days (standard notice)',
                  icon: Icons.calendar_view_week_rounded,
                  onTap: () {
                    Navigator.pop(ctx);
                    eco.pinChatMessage(msg.id, duration: '1_week');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message pinned for 1 week 📌')),
                    );
                  },
                ),
                _buildPinOptionTile(
                  ctx,
                  title: '1 Month',
                  subtitle: 'Pinned for 30 days (monthly goals & policies)',
                  icon: Icons.calendar_month_rounded,
                  onTap: () {
                    Navigator.pop(ctx);
                    eco.pinChatMessage(msg.id, duration: '1_month');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message pinned for 1 month 📌')),
                    );
                  },
                ),
                _buildPinOptionTile(
                  ctx,
                  title: 'Forever',
                  subtitle: 'Remains pinned until manually unpinned',
                  icon: Icons.all_inclusive_rounded,
                  onTap: () {
                    Navigator.pop(ctx);
                    eco.pinChatMessage(msg.id, duration: 'forever');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message pinned forever 📌')),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFFECFDF5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF059669)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
      ),
    );
  }

  void _showUnpinDialog(BuildContext context, EcosystemProvider eco, ChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpin Message?'),
        content: const Text('Do you want to remove this message from the pinned banner at the top?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            onPressed: () {
              Navigator.pop(ctx);
              eco.unpinChatMessage(msg.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message unpinned')),
              );
            },
            child: const Text('Unpin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final messages = eco.getConversation(widget.peerId);
    final activeEmpId = eco.activeEmpId;
    final peerEmp = eco.employees.firstWhere(
      (e) => e.id == widget.peerId || e.name.toLowerCase() == widget.peerName.toLowerCase(),
      orElse: () => Employee.simple(id: widget.peerId, name: widget.peerName, role: widget.peerRole, roleType: 'employee'),
    );
    final roleAcronym = widget.isGroup ? 'All Employees' : peerEmp.roleAcronym;
    final pinnedMsg = eco.getActivePinnedMessage(widget.peerId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0.8,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            if (widget.isGroup) {
              _showGroupRecipientsSheet(context, eco);
            } else {
              _showPeerInfoSheet(context, eco);
            }
          },
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: widget.isGroup
                      ? const LinearGradient(
                          colors: [Color(0xFFB45309), Color(0xFF831843)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.magentaPrimary,
                            const Color(0xFF4F46E5),
                          ],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isGroup
                      ? const Icon(Icons.groups_rounded, color: Colors.white, size: 20)
                      : Text(
                          widget.peerInitials,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.peerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            roleAcronym,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isGroup ? Icons.people_alt_outlined : Icons.info_outline_rounded,
              size: 20,
              color: const Color(0xFF64748B),
            ),
            tooltip: widget.isGroup ? 'Group Recipients' : 'Candidate Info',
            onPressed: () {
              if (widget.isGroup) {
                _showGroupRecipientsSheet(context, eco);
              } else {
                _showPeerInfoSheet(context, eco);
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Column(
        children: [
          // Banner for All-Hands group
          if (widget.isGroup)
            InkWell(
              onTap: () => _showGroupRecipientsSheet(context, eco),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: const Color(0xFFFEF3C7),
                child: Row(
                  children: const [
                    Icon(Icons.campaign_rounded, size: 16, color: Color(0xFFB45309)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MN Workforce All-Hands • Tap to view all group recipients & roles',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            ),

          // Pinned Message Top Banner (WhatsApp-style)
          if (pinnedMsg != null)
            _buildPinnedMessageBanner(context, eco, pinnedMsg, messages),

          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            Icons.waving_hand_rounded,
                            size: 32,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Say Hello to ${widget.peerName}!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Start collaborating on jewelry tasks, pillars, or daily work.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.isSentBy(activeEmpId);
                      final isLiked = msg.isLikedBy(activeEmpId);
                      final isMentioned = msg.mentionsUser(activeEmpId, eco.currentEmployee.name);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment:
                              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: const Color(0xFF475569),
                                child: Text(
                                  msg.senderName.isNotEmpty
                                      ? msg.senderName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: GestureDetector(
                                onLongPress: () => _showMessageActionSheet(context, eco, msg),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.74,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isMe
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF831843), // Rich festive plum
                                              Color(0xFF9D174D),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isMe ? null : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isMe
                                            ? const Color(0xFF831843).withOpacity(0.18)
                                            : const Color(0x0A000000),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: isMe
                                        ? null
                                        : Border.all(
                                            color: isMentioned
                                                ? AppColors.magentaPrimary.withOpacity(0.55)
                                                : const Color(0xFFE2E8F0),
                                            width: isMentioned ? 1.3 : 1.0,
                                          ),
                                  ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Quoted Reply Preview inside Bubble
                                    if (msg.replyToText != null && msg.replyToText!.isNotEmpty) ...[
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.white.withOpacity(0.18)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border(
                                            left: BorderSide(
                                              color: isMe ? const Color(0xFFFDE68A) : AppColors.magentaPrimary,
                                              width: 3.5,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg.replyToSenderName ?? 'Reply',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isMe ? const Color(0xFFFDE68A) : AppColors.magentaPrimary,
                                              ),
                                            ),
                                            Text(
                                              msg.replyToText!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: isMe ? Colors.white70 : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    if (!isMe && (widget.isGroup || msg.senderName.isNotEmpty)) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              msg.senderName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: widget.isGroup
                                                    ? AppColors.magentaPrimary
                                                    : const Color(0xFF0F172A),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              msg.senderRole,
                                              style: const TextStyle(
                                                fontSize: 8.5,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],

                                    _buildMessageText(
                                      msg.text,
                                      isMe,
                                      eco.allEmployees.map((e) => e.name).toList(),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatMsgTime(msg.timestamp),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: isMe
                                              ? Colors.white.withOpacity(0.7)
                                              : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        if (msg.isCurrentlyPinned) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.push_pin_rounded,
                                            size: 11,
                                            color: isMe ? const Color(0xFFFDE68A) : const Color(0xFF0D9488),
                                          ),
                                        ],
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            msg.readBy.length > 1
                                                ? Icons.done_all_rounded
                                                : Icons.done_rounded,
                                            size: 13,
                                            color: Colors.white.withOpacity(0.85),
                                          ),
                                        ],
                                        if (msg.likesCount > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isMe
                                                  ? Colors.white.withOpacity(0.2)
                                                  : const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.favorite,
                                                  size: 10,
                                                  color: Color(0xFFEF4444),
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${msg.likesCount}',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: isMe
                                                        ? Colors.white
                                                        : const Color(0xFFEF4444),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                            // Reply action button
                            InkWell(
                              onTap: () {
                                setState(() => _replyingTo = msg);
                                _focusNode.requestFocus();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.reply_rounded,
                                  size: 16,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            // Quick like button on peer message
                            if (!isMe) ...[
                              InkWell(
                                onTap: () => eco.toggleChatMessageLike(msg.id),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 14,
                                    color: isLiked
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ],
                            // Quick pin/unpin action button
                            InkWell(
                              onTap: () {
                                if (msg.isCurrentlyPinned) {
                                  _showUnpinDialog(context, eco, msg);
                                } else {
                                  _showPinDurationDialog(context, eco, msg);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  msg.isCurrentlyPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                  size: 15,
                                  color: msg.isCurrentlyPinned ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),


          // Quoted reply banner above input bar
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(left: BorderSide(color: AppColors.magentaPrimary, width: 4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 16, color: AppColors.magentaPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Replying to ${_replyingTo!.senderName}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.magentaPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _replyingTo!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                    onPressed: () => setState(() => _replyingTo = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Quick replies strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Quick @ Mention trigger button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        final cur = _textController.text;
                        _textController.text = '$cur@';
                        _textController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _textController.text.length),
                        );
                        _onTextChanged();
                        _focusNode.requestFocus();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFBCFE8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.alternate_email_rounded, size: 12, color: AppColors.magentaPrimary),
                            SizedBox(width: 4),
                            Text(
                              'Mention',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.magentaPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._quickReplies.map((r) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => _sendMessage(eco, r),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            r,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'Type message to ${widget.peerName}...',
                          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        ),
                        onChanged: _onTextChanged,
                        onSubmitted: (_) => _sendMessage(eco),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSending ? null : () => _sendMessage(eco),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF831843), Color(0xFFB45309)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33B45309),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isSending
                            ? const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.send_rounded, size: 19, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Mentions autocomplete popup floating safely above input bar
      if (_showMentionSuggestions && _mentionMatches.isNotEmpty)
        Positioned(
          left: 10,
          right: 10,
          bottom: 96 + (_replyingTo != null ? 48 : 0),
          child: _buildMentionSuggestionsBar(),
        ),
    ],
  ),
);
  }
}
