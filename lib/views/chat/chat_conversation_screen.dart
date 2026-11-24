import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../models/chat_message_model.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../../core/utils/file_saver.dart';

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

  /// Called by the back button when this is the first page of a floating chat window.
  final VoidCallback? onClose;

  /// Open the emoji picker / attachment options right away (chat dock shortcuts).
  final bool autoOpenEmoji;
  final bool autoOpenAttachments;

  const ChatConversationScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.peerRole,
    required this.peerInitials,
    this.isGroup = false,
    this.initialText,
    this.onClose,
    this.autoOpenEmoji = false,
    this.autoOpenAttachments = false,
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
      if (widget.autoOpenEmoji) {
        _showEmojiPicker(context);
      } else if (widget.autoOpenAttachments) {
        _showAttachmentOptionsSheet(context, eco);
      }
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
          _scrollController.position.maxScrollExtent,
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

    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _showAttachmentOptionsSheet(BuildContext context, EcosystemProvider eco) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share Attachment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Send photos, capture a picture, or attach PDF documents.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentChoice(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    gradient: const [Color(0xFFE11D48), Color(0xFFBE123C)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(eco, ImageSource.camera);
                    },
                  ),
                  _buildAttachmentChoice(
                    icon: Icons.photo_library_rounded,
                    label: 'Photos',
                    gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(eco, ImageSource.gallery);
                    },
                  ),
                  _buildAttachmentChoice(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF Document',
                    gradient: const [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendPdf(eco);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentChoice({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage(EcosystemProvider eco, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70, // Fully compressed image
      );
      if (picked == null) return;

      setState(() => _isSending = true);
      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';
      final currentText = _textController.text.trim();
      final reply = _replyingTo;

      await eco.sendChatMessage(
        receiverId: widget.peerId,
        text: currentText.isNotEmpty ? currentText : '📷 Photo',
        replyToId: reply?.id,
        replyToSenderName: reply?.senderName,
        replyToText: reply?.text,
        attachmentUrl: dataUri,
        attachmentType: 'image',
      );

      if (mounted) {
        _textController.clear();
        setState(() {
          _replyingTo = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendPdf(EcosystemProvider eco) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) return;

      if (bytes.lengthInBytes > 750 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF size must be under 750 KB for instant sync.')),
          );
        }
        return;
      }

      setState(() => _isSending = true);
      final base64Str = base64Encode(bytes);
      final cleanName = file.name.replaceAll(';', '_').replaceAll(',', '_');
      final dataUri = 'data:application/pdf;name=$cleanName;base64,$base64Str';
      final currentText = _textController.text.trim();
      final reply = _replyingTo;

      await eco.sendChatMessage(
        receiverId: widget.peerId,
        text: currentText.isNotEmpty ? currentText : '📄 $cleanName',
        replyToId: reply?.id,
        replyToSenderName: reply?.senderName,
        replyToText: reply?.text,
        attachmentUrl: dataUri,
        attachmentType: 'pdf',
      );

      _textController.clear();
      setState(() {
        _replyingTo = null;
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send PDF: $e')),
        );
      }
    }
  }

  Widget _buildAttachmentWidget(BuildContext context, ChatMessage msg, bool isMe) {
    final url = msg.attachmentUrl ?? '';
    final isPdf = msg.attachmentType == 'pdf' || url.contains('application/pdf');

    if (isPdf) {
      String fileName = 'Document.pdf';
      if (url.contains('name=')) {
        final match = RegExp(r'name=([^;]+)').firstMatch(url);
        if (match != null && match.group(1) != null) {
          fileName = match.group(1)!;
        }
      } else if (msg.text.startsWith('📄 ')) {
        fileName = msg.text.substring(2).trim();
      }

      return GestureDetector(
        onTap: () => _handlePdfClick(context, msg, fileName),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withOpacity(0.18) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMe ? Colors.white24 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF Document • Tap to view/save',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isMe ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.download_rounded,
                size: 18,
                color: isMe ? Colors.white70 : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImageViewer(context, msg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 220,
            maxWidth: 240,
          ),
          color: Colors.black12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildImageContent(url),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'View & Save',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(String url) {
    try {
      if (url.startsWith('data:image')) {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Part = url.substring(commaIdx + 1);
          final bytes = base64Decode(base64Part);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.broken_image_rounded, color: Colors.grey),
            ),
          );
        }
      } else if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        );
      }
    } catch (_) {}
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Icon(Icons.broken_image_rounded, color: Colors.grey),
    );
  }

  Uint8List? _extractBytesFromUrl(String url) {
    try {
      if (url.startsWith('data:')) {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Part = url.substring(commaIdx + 1);
          return base64Decode(base64Part);
        }
      }
    } catch (_) {}
    return null;
  }

  void _showFullImageViewer(BuildContext context, ChatMessage msg) {
    final url = msg.attachmentUrl ?? '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              msg.senderName.isNotEmpty ? msg.senderName : 'Photo Attachment',
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_rounded, color: Colors.white, size: 24),
                tooltip: 'Save to Downloads',
                onPressed: () => _saveImageLocally(ctx, msg),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                tooltip: 'Share Image',
                onPressed: () => _shareImage(ctx, msg),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.8,
              maxScale: 4.0,
              child: _buildImageContent(url),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _saveImageLocally(ctx, msg),
            backgroundColor: AppColors.magentaPrimary,
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            label: const Text(
              'Save to Phone',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveImageLocally(BuildContext context, ChatMessage msg) async {
    try {
      final url = msg.attachmentUrl ?? '';
      Uint8List? bytes = _extractBytesFromUrl(url);

      if (bytes == null && url.startsWith('http')) {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          bytes = resp.bodyBytes;
        }
      }

      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not decode photo data.')),
          );
        }
        return;
      }

      final fileName = 'MN_Photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await saveBytesWithPicker(
        bytes: bytes,
        fileName: fileName,
        extensions: const ['jpg', 'jpeg', 'png'],
        dialogTitle: 'Save photo',
      );
      if (saved != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F766E),
            content: const Text('Photo saved.'),
            action: SnackBarAction(
              label: 'Share',
              textColor: const Color(0xFFFDE68A),
              onPressed: () => _shareImage(context, msg),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save photo: $e')),
        );
      }
    }
  }

  Future<void> _shareImage(BuildContext context, ChatMessage msg) async {
    try {
      final url = msg.attachmentUrl ?? '';
      final bytes = _extractBytesFromUrl(url);
      if (bytes == null) return;
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/MN_Share_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(tempFile.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _handlePdfClick(BuildContext context, ChatMessage msg, String fileName) async {
    try {
      final url = msg.attachmentUrl ?? '';
      Uint8List? bytes = _extractBytesFromUrl(url);

      if (bytes == null && url.startsWith('http')) {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          bytes = resp.bodyBytes;
        }
      }

      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read PDF document data.')),
          );
        }
        return;
      }

      final nonNullBytes = bytes;
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Material(type: MaterialType.transparency, child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.visibility_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('View / Print Document', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Preview and print with device PDF viewer', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Printing.layoutPdf(onLayout: (_) async => nonNullBytes, name: fileName);
                  },
                )),
                Material(type: MaterialType.transparency, child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.file_download_rounded, color: Color(0xFF16A34A)),
                  ),
                  title: const Text('Save to Downloads', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Save document directly to phone storage', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _savePdfLocally(context, nonNullBytes, fileName);
                  },
                )),
                Material(type: MaterialType.transparency, child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.share_rounded, color: AppColors.magentaPrimary),
                  ),
                  title: const Text('Share Document', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Send document via WhatsApp, Mail, etc.', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final tempDir = await getTemporaryDirectory();
                    final tempFile = File('${tempDir.path}/$fileName');
                    await tempFile.writeAsBytes(nonNullBytes);
                    await Share.shareXFiles([XFile(tempFile.path)]);
                  },
                )),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process PDF: $e')),
        );
      }
    }
  }

  Future<void> _savePdfLocally(BuildContext context, Uint8List bytes, String fileName) async {
    try {
      final saved = await saveBytesWithPicker(
        bytes: bytes,
        fileName: fileName,
        extensions: const ['pdf'],
        dialogTitle: 'Save document',
      );
      if (saved != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F766E),
            content: Text('Document saved.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save document: $e')),
        );
      }
    }
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
                        ? emp.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase()
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
                                        style: TextStyle(fontSize: 11.5, color: AppColors.magentaPrimary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${emp.straightCutRole} • ${emp.dept}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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
                      ? emp.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase()
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
                                fontSize: 11.5,
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
                              fontSize: 11,
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

  /// Emoji reaction chips under a message; tap one to add/remove yours.
  Widget _reactionChips(EcosystemProvider eco, ChatMessage msg, bool isMe) {
    final counts = msg.reactionCounts;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final e in counts.entries)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => eco.toggleChatReaction(msg.id, e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: msg.hasReacted(eco.activeEmpId, e.key)
                    ? (isMe ? Colors.white.withOpacity(0.32) : AppColors.magentaSubtle)
                    : (isMe ? Colors.white.withOpacity(0.16) : const Color(0xFFF4EEF2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${e.key} ${e.value}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const List<String> _composerEmojis = [
    '😀', '😂', '😊', '😍', '🥰', '😎', '🤔', '😮', '😢', '😡',
    '👍', '👎', '👏', '🙏', '💪', '🤝', '👌', '✌️', '🙌', '👀',
    '❤️', '💖', '🔥', '✨', '🎉', '🎂', '💍', '💎', '🌸', '⭐',
    '✅', '❌', '⏰', '📦', '📸', '🎥', '📍', '💯', '🙂', '😅',
  ];

  /// Emoji picker for the message box; inserts at the cursor.
  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: GridView.count(
            crossAxisCount: 8,
            shrinkWrap: true,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final e in _composerEmojis)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final value = _textController.value;
                    final sel = value.selection.isValid
                        ? value.selection
                        : TextSelection.collapsed(offset: value.text.length);
                    final text = value.text.replaceRange(sel.start, sel.end, e);
                    _textController.value = TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: sel.start + e.length),
                    );
                    _onTextChanged();
                  },
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                ),
            ],
          ),
        ),
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
                const SizedBox(height: 10),
                // Quick emoji reactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final emoji in ChatMessage.reactionChoices)
                      InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          Navigator.pop(ctx);
                          eco.toggleChatReaction(msg.id, emoji);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: msg.hasReacted(eco.activeEmpId, emoji)
                                ? AppColors.magentaSubtle
                                : const Color(0xFFF8F4F7),
                            border: Border.all(
                              color: msg.hasReacted(eco.activeEmpId, emoji)
                                  ? AppColors.magentaPrimary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Material(type: MaterialType.transparency, child: ListTile(
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
                )),
                Material(type: MaterialType.transparency, child: ListTile(
                  leading: const Icon(Icons.reply_rounded, color: AppColors.magentaPrimary),
                  title: const Text('Reply', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final wasNearBottom = _scrollController.hasClients &&
                        (_scrollController.position.maxScrollExtent - _scrollController.offset) < 100;
                    final prevOffset = _scrollController.hasClients ? _scrollController.offset : null;
                    setState(() => _replyingTo = msg);
                    _focusNode.requestFocus();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        if (wasNearBottom) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        } else if (prevOffset != null) {
                          _scrollController.jumpTo((prevOffset + 48.0).clamp(0.0, _scrollController.position.maxScrollExtent));
                        }
                      }
                    });
                  },
                )),
                Material(type: MaterialType.transparency, child: ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Color(0xFF475569)),
                  title: const Text('Copy Text', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copied to clipboard')),
                    );
                  },
                )),
                Material(type: MaterialType.transparency, child: ListTile(
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
                    final currentOffset = _scrollController.hasClients ? _scrollController.offset : null;
                    eco.toggleChatMessageLike(msg.id);
                    if (currentOffset != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients &&
                            (_scrollController.offset - currentOffset).abs() > 2) {
                          _scrollController.jumpTo(
                            currentOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
                          );
                        }
                      });
                    }
                  },
                )),
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
      child: Material(type: MaterialType.transparency, child: ListTile(
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
      )),
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            } else {
              widget.onClose?.call();
            }
          },
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
                              fontSize: 11.5,
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
                    findChildIndexCallback: (Key key) {
                      if (key is ValueKey<String>) {
                        final id = key.value;
                        final idx = messages.indexWhere((m) => m.id == id);
                        return idx != -1 ? idx : null;
                      }
                      return null;
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.isSentBy(activeEmpId);
                      final isLiked = msg.isLikedBy(activeEmpId);
                      final isMentioned = msg.mentionsUser(activeEmpId, eco.currentEmployee.name);

                      return Padding(
                        key: ValueKey(msg.id),
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
                                    fontSize: 11.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            // Sent message actions on the LEFT of bubble
                            if (isMe) ...[
                              // Quick pin/unpin action button
                              InkWell(
                                onTap: () {
                                  final wasNearBottom = _scrollController.hasClients &&
                                      (_scrollController.position.maxScrollExtent - _scrollController.offset) < 100;
                                  if (msg.isCurrentlyPinned) {
                                    _showUnpinDialog(context, eco, msg);
                                  } else {
                                    _showPinDurationDialog(context, eco, msg);
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (_scrollController.hasClients && wasNearBottom) {
                                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                                    }
                                  });
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
                              // Reply action button
                              InkWell(
                                onTap: () {
                                  final wasNearBottom = _scrollController.hasClients &&
                                      (_scrollController.position.maxScrollExtent - _scrollController.offset) < 100;
                                  final prevOffset = _scrollController.hasClients ? _scrollController.offset : null;
                                  setState(() => _replyingTo = msg);
                                  _focusNode.requestFocus();
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (_scrollController.hasClients) {
                                      if (wasNearBottom) {
                                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                                      } else if (prevOffset != null) {
                                        _scrollController.jumpTo((prevOffset + 48.0).clamp(0.0, _scrollController.position.maxScrollExtent));
                                      }
                                    }
                                  });
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
                              const SizedBox(width: 4),
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
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isMe ? const Color(0xFFFDE68A) : AppColors.magentaPrimary,
                                                ),
                                              ),
                                              Text(
                                                msg.replyToText!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
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
                                                  fontSize: 10,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                      ],

                                      // Attachment Preview Widget (Photo / PDF)
                                      if (msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty) ...[
                                        _buildAttachmentWidget(context, msg, isMe),
                                        if (msg.text.isNotEmpty && msg.text != '📷 Photo' && !msg.text.startsWith('📄 '))
                                          const SizedBox(height: 6),
                                      ],

                                      if (msg.text.isNotEmpty && (msg.attachmentUrl == null || (msg.text != '📷 Photo' && !msg.text.startsWith('📄 '))))
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
                                              fontSize: 11,
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
                                                      fontSize: 11,
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
                                      if (msg.reactions.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        _reactionChips(eco, msg, isMe),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Received message actions on the RIGHT of bubble
                            if (!isMe) ...[
                              const SizedBox(width: 4),
                              // Reply action button
                              InkWell(
                                onTap: () {
                                  final wasNearBottom = _scrollController.hasClients &&
                                      (_scrollController.position.maxScrollExtent - _scrollController.offset) < 100;
                                  final prevOffset = _scrollController.hasClients ? _scrollController.offset : null;
                                  setState(() => _replyingTo = msg);
                                  _focusNode.requestFocus();
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (_scrollController.hasClients) {
                                      if (wasNearBottom) {
                                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                                      } else if (prevOffset != null) {
                                        _scrollController.jumpTo((prevOffset + 48.0).clamp(0.0, _scrollController.position.maxScrollExtent));
                                      }
                                    }
                                  });
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
                              InkWell(
                                onTap: () {
                                  final currentOffset = _scrollController.hasClients ? _scrollController.offset : null;
                                  eco.toggleChatMessageLike(msg.id);
                                  if (currentOffset != null) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (_scrollController.hasClients &&
                                          (_scrollController.offset - currentOffset).abs() > 2) {
                                        _scrollController.jumpTo(
                                          currentOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
                                        );
                                      }
                                    });
                                  }
                                },
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
                              // Quick pin/unpin action button
                              InkWell(
                                onTap: () {
                                  final wasNearBottom = _scrollController.hasClients &&
                                      (_scrollController.position.maxScrollExtent - _scrollController.offset) < 100;
                                  if (msg.isCurrentlyPinned) {
                                    _showUnpinDialog(context, eco, msg);
                                  } else {
                                    _showPinDurationDialog(context, eco, msg);
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (_scrollController.hasClients && wasNearBottom) {
                                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                                    }
                                  });
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
                  // Attachment button (Photos, Camera, PDF)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSending ? null : () => _showAttachmentOptionsSheet(context, eco),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.attach_file_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
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
                          hintText: 'Message',
                          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          prefixIcon: IconButton(
                            tooltip: 'Emoji',
                            icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.magentaPrimary),
                            onPressed: () => _showEmojiPicker(context),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
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
                            colors: [Color(0xFFE11D48), Color(0xFF881337)],
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
