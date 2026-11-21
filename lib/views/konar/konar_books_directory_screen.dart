import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/konar_book_model.dart';
import '../../providers/ecosystem_provider.dart';
import 'konar_book_detail_screen.dart';

class KonarBooksDirectoryScreen extends StatefulWidget {
  const KonarBooksDirectoryScreen({super.key});

  @override
  State<KonarBooksDirectoryScreen> createState() => _KonarBooksDirectoryScreenState();
}

class _KonarBooksDirectoryScreenState extends State<KonarBooksDirectoryScreen> {
  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final isCeo = eco.isCeo || eco.activeRole == 'ceo' || eco.activeEmpId == 'MN-CEO01';
    final rawBooks = eco.konarBooks;

    // Filter books: If staff access toggle is OFF, non-CEO department staff cannot view the KONAR book.
    // Strictly deduplicate by department so duplicate/ghost Online Department entries are consolidated into 1 canonical book.
    final seenDepts = <String>{};
    final List<KonarBookModel> books = [];

    for (final b in rawBooks) {
      if (!isCeo && !b.isVisible) continue;
      final isOnline = b.id == 'online_department' ||
          b.id == 'online_dept' ||
          b.department.trim().toLowerCase().contains('online');
      final normDeptKey = isOnline ? 'online department' : b.department.trim().toLowerCase();

      if (!seenDepts.contains(normDeptKey)) {
        seenDepts.add(normDeptKey);
        if (isOnline) {
          if (b.sections.length != 5 || !b.sections.first.title.contains('01 PURPOSE')) {
            books.add(KonarBookModel.defaultOnlineDepartment());
            continue;
          }
        }
        books.add(b);
      }
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
              'KONAR Books',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Text(
              'Department Operational Manuals & SOPs',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCeo ? 'CEO Executive SOP Governance' : 'Department SOP Guidelines',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCeo
                              ? 'Manage department manuals, toggle staff visibility per department, or delete manuals & departments with staff reallocation.'
                              : 'Select your department to view, read, and acknowledge official KONAR Book and SOP guidelines.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Available Departments (${books.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),

            if (books.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 40, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 10),
                    Text(
                      'No KONAR Books Available',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'KONAR manuals for your department are either disabled or being updated by Executive Leadership.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

            // Live Department Cards fetched from Firebase
            ...books.map((book) => _buildDepartmentCard(context, book, isCeo, eco)),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(
    BuildContext context,
    KonarBookModel book,
    bool isCeo,
    EcosystemProvider eco,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KonarBookDetailScreen(department: book.department),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF831843), Color(0xFF9D174D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  book.department,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  book.version,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              if (isCeo && !book.isVisible) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'HIDDEN FOR STAFF',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            book.title,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      'Updated: ${DateFormat('dd MMM yyyy').format(book.lastUpdated)}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    Text(
                      '${book.sections.length} Chapters',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.magentaPrimary,
                      ),
                    ),
                  ],
                ),

                // CEO Management Panel: Staff Visibility Toggle, Delete KONAR Book & Delete Department
                if (isCeo) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        book.isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        size: 16,
                        color: book.isVisible ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        book.isVisible ? 'Staff Access: ON' : 'Staff Access: OFF',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: book.isVisible ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ),
                      const Spacer(),
                      Switch.adaptive(
                        value: book.isVisible,
                        activeColor: const Color(0xFF059669),
                        onChanged: (val) {
                          eco.toggleKonarBookVisibility(book.id, val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: val ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              content: Text(
                                val
                                    ? 'KONAR Book enabled: Staff of ${book.department} can now view this manual.'
                                    : 'KONAR Book disabled: Staff of ${book.department} can no longer see this manual.',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text(
                            'Delete Book',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _confirmDeleteKonarBook(context, eco, book),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF991B1B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.domain_disabled_rounded, size: 16),
                          label: const Text(
                            'Delete Dept',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _startDeleteDepartmentWorkflow(context, eco, book.department),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// CEO action: Delete KONAR Book alone
  void _confirmDeleteKonarBook(BuildContext context, EcosystemProvider eco, KonarBookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('Delete KONAR Book?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the official KONAR manual for "${book.department}"?\n\nStaff belonging to this department will no longer be able to view or download this book.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await eco.deleteKonarBook(book.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFDC2626),
                    content: Text('Deleted KONAR Book for ${book.department}.'),
                  ),
                );
              }
            },
            child: const Text('Delete Book'),
          ),
        ],
      ),
    );
  }

  /// CEO action: Delete department completely with prompt "Along with the employees?" and reallocation flow
  void _startDeleteDepartmentWorkflow(BuildContext context, EcosystemProvider eco, String deptName) {
    final lower = deptName.trim().toLowerCase();
    if (lower == 'administration' || lower == 'executive board') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('Core Executive / Administration department cannot be deleted.'),
        ),
      );
      return;
    }

    // Pop-up 1: Confirm deleting the department completely
    showDialog(
      context: context,
      builder: (ctx1) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
            SizedBox(width: 8),
            Text('Delete Department?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the department "$deptName" completely from MN Jewel Park?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx1),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx1);
              _promptAlongWithEmployees(context, eco, deptName);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  /// Pop-up 2: "Along with the employees?"
  void _promptAlongWithEmployees(BuildContext context, EcosystemProvider eco, String deptName) {
    final deptEmployees = eco.employees
        .where((e) => e.dept.trim().toLowerCase() == deptName.trim().toLowerCase())
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.people_outline_rounded, color: Color(0xFF9D174D), size: 24),
            SizedBox(width: 8),
            Flexible(child: Text('Staff Disposition')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Along with the employees?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Department "$deptName" currently has ${deptEmployees.length} staff member(s).\n\n• Select "Yes" to delete all employees along with the department.\n• Select "No" to reallocate the department members to another department.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx2),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9D174D),
              side: const BorderSide(color: Color(0xFF9D174D)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx2);
              _openReallocationScreen(context, eco, deptName, deptEmployees);
            },
            child: const Text('No (Reallocate)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx2);
              await _confirmAndDeleteWithEmployees(context, eco, deptName, deptEmployees.length);
            },
            child: const Text('Yes (Delete All)'),
          ),
        ],
      ),
    );
  }

  /// Final confirmation when CEO chooses "Yes (Delete with employees)"
  Future<void> _confirmAndDeleteWithEmployees(
    BuildContext context,
    EcosystemProvider eco,
    String deptName,
    int employeeCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Total Deletion'),
        content: Text(
          'Are you absolutely sure you want to permanently delete department "$deptName" along with all $employeeCount employee accounts and documents?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await eco.deleteDepartmentWithWorkflow(deptName: deptName, deleteEmployees: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Department "$deptName" and $employeeCount employee accounts were permanently deleted.'),
          ),
        );
      }
    }
  }

  /// Screen / Modal for reallocating department members to another department
  void _openReallocationScreen(
    BuildContext context,
    EcosystemProvider eco,
    String deptName,
    List<dynamic> deptEmployees,
  ) {
    final availableTargets = eco.availableDepartments
        .where((d) => d.trim().toLowerCase() != deptName.trim().toLowerCase())
        .toList();

    String selectedTarget = availableTargets.isNotEmpty ? availableTargets.first : 'Online Department';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctxSheet) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF9D174D), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reallocate Department Staff',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Reassigning ${deptEmployees.length} member(s) from "$deptName"',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Target Department Selector
                Text(
                  'SELECT TARGET DEPARTMENT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTarget,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F172A)),
                      items: availableTargets.map((d) {
                        return DropdownMenuItem<String>(
                          value: d,
                          child: Text(
                            d,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedTarget = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Employees to reallocate list
                Text(
                  'STAFF MEMBERS BEING TRANSFERRED (${deptEmployees.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: deptEmployees.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final emp = deptEmployees[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF831843),
                          child: Text(
                            emp.initials.toString().isNotEmpty ? emp.initials.toString() : 'MN',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          emp.name.toString(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${emp.role} • ID: ${emp.id}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                        trailing: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF9D174D)),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Confirmation Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF831843),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctxSheet);
                      await eco.deleteDepartmentWithWorkflow(
                        deptName: deptName,
                        deleteEmployees: false,
                        reallocateToDept: selectedTarget,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF059669),
                            content: Text(
                              'Successfully transferred ${deptEmployees.length} employee(s) to "$selectedTarget" and deleted "$deptName".',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Reallocate to $selectedTarget & Delete Department',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
