import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/konar_pdf_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/konar_book_model.dart';
import '../../providers/ecosystem_provider.dart';

class KonarBookDetailScreen extends StatefulWidget {
  final String department;

  const KonarBookDetailScreen({
    super.key,
    this.department = 'Online Department',
  });

  @override
  State<KonarBookDetailScreen> createState() => _KonarBookDetailScreenState();
}

class _KonarBookDetailScreenState extends State<KonarBookDetailScreen> {
  bool _isProcessing = false;
  String? _processingMessage;

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final book = eco.konarBooks.firstWhere(
      (b) => b.department.toLowerCase() == widget.department.toLowerCase(),
      orElse: () => eco.onlineDeptKonarBook,
    );

    final bool canEdit = eco.isCeo ||
        eco.isHr ||
        eco.isDeptHead ||
        eco.activeRole == 'dept_head' ||
        eco.activeEmpId == 'MN-TL1002';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KONAR Book',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              book.department,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.magentaPrimary, size: 24),
              tooltip: 'Update KONAR Book',
              onPressed: () => _showEditBookModal(context, eco, book),
            ),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF475569), size: 21),
            tooltip: 'View / Print PDF',
            onPressed: () => _handlePrintPdf(book),
          ),
        ],
      ),
      body: _isProcessing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.magentaPrimary),
                    const SizedBox(height: 16),
                    Text(
                      _processingMessage ?? 'Processing official KONAR Book...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.magentaPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Department Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF831843), Color(0xFF9D174D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF831843).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                book.version,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE68A).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                book.departmentCode,
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.verified_rounded, color: Color(0xFFFDE68A), size: 18),
                            const SizedBox(width: 4),
                            const Text(
                              'Live in Cloud',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          book.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.description,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFFFDE68A)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Authorized: ${book.updatedByName} (${book.updatedByRole})',
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(book.lastUpdated),
                              style: const TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick Action Buttons (Download PDF & Print/View)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleDownloadPdf(book),
                          icon: const Icon(Icons.file_download_rounded, size: 18),
                          label: const Text('Download PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handlePrintPdf(book),
                          icon: const Icon(Icons.visibility_rounded, size: 17, color: Color(0xFF831843)),
                          label: const Text('View / Print'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFBCFE8), width: 1.2),
                            backgroundColor: const Color(0xFFFDF2F8),
                            foregroundColor: const Color(0xFF831843),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Chapters Section Header
                  Row(
                    children: [
                      const Icon(Icons.auto_stories_rounded, size: 18, color: AppColors.magentaPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Standard Operating Chapters',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${book.sections.length} Chapters',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Chapters List
                  ...book.sections.map((section) => _buildChapterCard(section)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildChapterCard(KonarSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bookmark_rounded, size: 17, color: AppColors.magentaPrimary),
          ),
          title: Text(
            section.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          subtitle: section.subtitle.isNotEmpty
              ? Text(
                  section.subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F766E), fontWeight: FontWeight.w500),
                )
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 10),
                  Text(
                    section.content,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      height: 1.45,
                    ),
                  ),
                  if (section.keyRules.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.rule_rounded, size: 14, color: Color(0xFF831843)),
                              SizedBox(width: 6),
                              Text(
                                'MANDATORY PROCEDURES & SLAS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF831843),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...section.keyRules.map(
                            (rule) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: Color(0xFF831843), fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      rule,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDownloadPdf(KonarBookModel book) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Assembling & downloading ${book.department} PDF...';
    });
    try {
      final eco = context.read<EcosystemProvider>();
      final file = await KonarPdfService.saveKonarPdfLocally(book, eco: eco);
      if (!mounted) return;
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F766E),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saved to Downloads: ${file.path.split('/').last}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Share',
            textColor: const Color(0xFFFDE68A),
            onPressed: () => Share.shareXFiles([XFile(file.path)]),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download PDF: $e')),
      );
    }
  }

  Future<void> _handlePrintPdf(KonarBookModel book) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Loading official PDF preview...';
    });
    try {
      final eco = context.read<EcosystemProvider>();
      await KonarPdfService.viewOrPrintKonarPdf(book, eco: eco);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open PDF viewer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showEditBookModal(BuildContext context, EcosystemProvider eco, KonarBookModel book) {
    final titleController = TextEditingController(text: book.title);
    final descController = TextEditingController(text: book.description);
    final versionController = TextEditingController(text: book.version);
    String? pickedBase64 = book.pdfBase64;
    String? pickedFileName = book.attachmentFileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
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
                      const Icon(Icons.edit_note_rounded, color: AppColors.magentaPrimary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Update KONAR Book',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Changes will be saved to Cloud Firestore and notify Online Department team members.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  // Version
                  const Text('Version Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: versionController,
                    decoration: InputDecoration(
                      hintText: 'e.g. v2.5',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  const Text('Manual Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  const Text('Overview & Purpose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Attach New PDF Document
                  const Text('Official PDF Attachment (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final file = result.files.single;
                        final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
                        if (bytes != null) {
                          setModalState(() {
                            pickedBase64 = base64Encode(bytes);
                            pickedFileName = file.name;
                          });
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFBCFE8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pickedFileName ?? 'Tap to select new PDF document',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'PDF replaces auto-generated chapters',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.upload_file_rounded, color: AppColors.magentaPrimary, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        final updated = book.copyWith(
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          version: versionController.text.trim().isNotEmpty ? versionController.text.trim() : book.version,
                          lastUpdated: DateTime.now(),
                          updatedByName: eco.currentEmployee.name,
                          updatedByRole: eco.currentEmployee.role,
                          updatedByEmpId: eco.currentEmployee.id,
                          pdfBase64: pickedBase64,
                          attachmentFileName: pickedFileName,
                        );

                        Navigator.pop(ctx);
                        setState(() {
                          _isProcessing = true;
                          _processingMessage = pickedBase64 != null
                              ? 'Saving PDF to Cloud...'
                              : 'Updating KONAR Book...';
                        });
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await eco.updateKonarBook(
                            updated,
                            updaterName: eco.currentEmployee.name,
                            updaterRole: eco.currentEmployee.role,
                            onProgress: (progress) {
                              if (mounted) {
                                setState(() {
                                  _processingMessage = 'Uploading PDF in secure chunks (${(progress * 100).toInt()}%)...';
                                });
                              }
                            },
                          );

                          if (mounted) {
                            setState(() => _isProcessing = false);
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF0F766E),
                                content: Text('KONAR Book updated to ${updated.version} and Online Team notified!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isProcessing = false);
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red.shade700,
                                content: Text('Failed to update KONAR Book: $e'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magentaPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save & Publish to Online Team', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
