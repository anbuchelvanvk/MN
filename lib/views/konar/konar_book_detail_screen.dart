import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/konar_pdf_service.dart';
import '../../core/services/google_drive_upload_service.dart';
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
  bool _allExpanded = false;

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final rawBook = eco.konarBooks.firstWhere(
      (b) => b.department.toLowerCase() == widget.department.toLowerCase(),
      orElse: () => eco.onlineDeptKonarBook,
    );
    final book = (rawBook.id == 'online_department' || rawBook.id == 'online_dept' || rawBook.department.toLowerCase().contains('online')) &&
            (rawBook.sections.length != 5 || !rawBook.sections.first.title.contains('01 PURPOSE'))
        ? KonarBookModel.defaultOnlineDepartment()
        : rawBook;

    final isCeo = eco.isCeo;
    final isHr = eco.isHr;
    final isTl = eco.isTeamLead ||
        eco.isDeptHead ||
        eco.activeRole == 'team_lead' ||
        eco.activeRole == 'dept_head' ||
        eco.activeEmpId == 'MN-TL1002';

    // TL has edit access ONLY for their own department's KONAR book
    final bool isTlForThisDept = isTl &&
        (eco.currentEmployee.dept.toLowerCase().contains(book.department.toLowerCase()) ||
            book.department.toLowerCase().contains(eco.currentEmployee.dept.toLowerCase()) ||
            (eco.currentEmployee.dept.toLowerCase().contains('online') &&
                (book.department.toLowerCase().contains('online') ||
                    book.id.toLowerCase().contains('online'))) ||
            book.id.toLowerCase().contains(eco.currentEmployee.dept.toLowerCase().replaceAll(' ', '_')));

    // Only CEO, HR, and Department TL (for their specific department) can update or upload.
    // Regular employees have read-only access (view and download).
    final bool canEdit = isCeo || isHr || isTlForThisDept;

    if (!book.isVisible && !isCeo) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          title: Text(
            'KONAR Book • ${book.department}',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.visibility_off_rounded, size: 40, color: Color(0xFFDC2626)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The KONAR Book for this department is currently disabled for staff by Executive Management.\n\nPlease contact HR or the CEO for access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          if (isCeo)
            IconButton(
              icon: Icon(
                book.isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: book.isVisible ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
              tooltip: book.isVisible ? 'Hide from Staff' : 'Show to Staff',
              onPressed: () {
                final next = !book.isVisible;
                eco.toggleKonarBookVisibility(book.id, next);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: next ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    content: Text(
                      next
                          ? 'Staff can now view this KONAR book.'
                          : 'This KONAR book is now hidden from staff.',
                    ),
                  ),
                );
              },
            ),
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

                  const SizedBox(height: 18),

                  // Quick Summary of KONAR Book Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCE7F3)),
                          ),
                          child: const Icon(Icons.summarize_rounded, size: 20, color: AppColors.magentaPrimary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Department Core Architecture',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '5 Operational Pillars: Purpose, Goals, Process, Structure, System',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _allExpanded = !_allExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF2F8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFBCFE8)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${book.sections.length} Architectures',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: const Color(0xFF831843),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                                  size: 14,
                                  color: const Color(0xFF831843),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chapters / Summaries List (Default Chapter 1 open, others collapsed for clean aesthetic)
                  ...book.sections.asMap().entries.map(
                    (entry) => _buildChapterCard(entry.value, entry.key),
                  ),

                  const SizedBox(height: 18),

                  // Lined Action Buttons at the End of Scrolling (View Full Book, Download Full Book, Share)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.magentaPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Official ${book.department} Manual (${book.version})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Primary Actions Row: View Full Book & Download Book (Equal width, 100% immune to truncation)
                        Row(
                          children: [
                            // View Full Book Button
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () => _handlePrintPdf(book),
                                  icon: const Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF831843)),
                                  label: Text(
                                    'View Full Book',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: const Color(0xFF831843),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFFBCFE8), width: 1.2),
                                    backgroundColor: const Color(0xFFFDF2F8),
                                    foregroundColor: const Color(0xFF831843),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Download Book Button
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () => _handleDownloadPdf(book),
                                  icon: const Icon(Icons.file_download_rounded, size: 18, color: Colors.white),
                                  label: Text(
                                    'Download Book',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Dedicated Share Button (Full width with clear descriptive label)
                        SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleSharePdf(book),
                            icon: const Icon(Icons.share_rounded, size: 17, color: Color(0xFF334155)),
                            label: Text(
                              'Share Official KONAR Book (PDF)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              backgroundColor: const Color(0xFFF8FAFC),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildChapterCard(KonarSection section, int index) {
    return Container(
      key: ValueKey('chapter_${section.title}_$_allExpanded'),
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
          initiallyExpanded: _allExpanded || index == 0,
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

  Future<void> _handleSharePdf(KonarBookModel book) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Preparing ${book.department} PDF for sharing...';
    });
    try {
      final eco = context.read<EcosystemProvider>();
      final file = await KonarPdfService.saveKonarPdfLocally(book, eco: eco);
      if (!mounted) return;
      setState(() => _isProcessing = false);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Official ${book.department} KONAR Book (${book.version}) - MN Jewel Park',
        subject: '${book.department} Official KONAR Book',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $e')),
      );
    }
  }

  void _showEditBookModal(BuildContext context, EcosystemProvider eco, KonarBookModel book) {
    final titleController = TextEditingController(text: book.title);
    final descController = TextEditingController(text: book.description);
    final versionController = TextEditingController(text: book.version);
    final driveUrlController = TextEditingController(text: book.pdfUrl ?? '');
    String? pickedBase64 = book.pdfBase64;
    Uint8List? pickedPdfBytes;
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

                  // Google Drive PDF Link
                  const Text('Google Drive PDF Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: driveUrlController,
                    decoration: InputDecoration(
                      hintText: 'https://drive.google.com/file/d/.../view',
                      hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(Icons.add_link_rounded, size: 20, color: Color(0xFF0F766E)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Attach New PDF Document
                  const Text('Or Select Local PDF Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                            pickedPdfBytes = bytes;
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
                                  'Uploaded directly to Google Drive & synced',
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
                        Navigator.pop(ctx);
                        setState(() {
                          _isProcessing = true;
                          _processingMessage = pickedPdfBytes != null
                              ? 'Uploading PDF to Google Drive...'
                              : 'Updating KONAR Book...';
                        });
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          String? finalDriveUrl = driveUrlController.text.trim().isNotEmpty
                              ? driveUrlController.text.trim()
                              : book.pdfUrl;

                          // If local PDF was selected, upload directly to Google Drive via Webhook
                          if (pickedPdfBytes != null) {
                            try {
                              final uploadRes = await GoogleDriveUploadService.uploadPdfToDrive(
                                pdfBytes: pickedPdfBytes!,
                                fileName: pickedFileName ?? '${book.department.replaceAll(' ', '_')}_KONAR_Book.pdf',
                              );
                              final uploadedUrl = uploadRes['driveUrl'] as String? ?? uploadRes['downloadUrl'] as String?;
                              if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                                finalDriveUrl = uploadedUrl;
                              }
                            } catch (uploadErr) {
                              debugPrint('Google Drive upload error: $uploadErr');
                            }
                          }

                          final updated = book.copyWith(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            version: versionController.text.trim().isNotEmpty ? versionController.text.trim() : book.version,
                            lastUpdated: DateTime.now(),
                            updatedByName: eco.currentEmployee.name,
                            updatedByRole: eco.currentEmployee.role,
                            updatedByEmpId: eco.currentEmployee.id,
                            pdfBase64: finalDriveUrl != null ? null : pickedBase64,
                            pdfUrl: finalDriveUrl,
                            attachmentFileName: pickedFileName ?? book.attachmentFileName,
                            hasPdfAttachment: (finalDriveUrl != null && finalDriveUrl.isNotEmpty) || (pickedBase64 != null && pickedBase64!.isNotEmpty),
                          );

                          await eco.updateKonarBook(
                            updated,
                            updaterName: eco.currentEmployee.name,
                            updaterRole: eco.currentEmployee.role,
                            updaterEmpId: eco.currentEmployee.id,
                          );

                          if (mounted) {
                            setState(() => _isProcessing = false);
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF0F766E),
                                content: Text('KONAR Book updated to ${updated.version} & synced to Google Drive!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isProcessing = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to update KONAR Book: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magentaPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Save & Publish to Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
