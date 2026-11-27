import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/services/data_vault_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_saver.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../providers/ecosystem_provider.dart';

// ------------------------------------------------------------------ helpers
const _friendly = <String, (String, IconData)>{
  'social_causes': ('Social causes', Icons.volunteer_activism_rounded),
  'company_notifications': ('Notifications', Icons.notifications_rounded),
  'mn_team_chats': ('Team chat messages', Icons.chat_bubble_rounded),
  'personal_todos': ('To-dos', Icons.task_alt_rounded),
  'personal_notes': ('Personal notes', Icons.sticky_note_2_rounded),
  'tasks': ('Tasks', Icons.assignment_rounded),
  'leave_prescriptions': ('Leave & medical notes', Icons.medical_services_rounded),
  'attendance_punches': ('Attendance punches', Icons.fingerprint_rounded),
  'monthly_scorecards': ('Monthly scorecards', Icons.assessment_rounded),
  'online_orders': ('Online orders', Icons.shopping_bag_rounded),
  'konar_books': ('Konar books', Icons.menu_book_rounded),
  'departments': ('Departments', Icons.apartment_rounded),
  'users': ('Staff logins (no passwords)', Icons.key_rounded),
  'password_reset_queue': ('Password requests', Icons.lock_reset_rounded),
  'system_metadata': ('App settings', Icons.settings_rounded),
};

String collectionLabel(String id) {
  final f = _friendly[id];
  if (f != null) return f.$1;
  if (id.endsWith('_employees')) {
    final dept = id.replaceAll('_employees', '').replaceAll('_', ' ');
    return 'Staff – ${dept[0].toUpperCase()}${dept.substring(1)}';
  }
  final words = id.replaceAll('_', ' ');
  return words.isEmpty ? id : '${words[0].toUpperCase()}${words.substring(1)}';
}

IconData collectionIcon(String id) =>
    _friendly[id]?.$2 ?? (id.endsWith('_employees') ? Icons.badge_rounded : Icons.folder_rounded);

/// Turns stored values (incl. {__type: timestamp}) into readable text.
String readableValue(dynamic v) {
  if (v == null) return '—';
  if (v is Map && v['__type'] == 'timestamp') {
    final d = DateTime.tryParse('${v['value']}')?.toLocal();
    return d == null ? '${v['value']}' : _fmtDate(d);
  }
  if (v is Map || v is List) return const JsonEncoder.withIndent('  ').convert(v);
  final s = v.toString();
  final d = (s.length >= 10 && s.length <= 32) ? DateTime.tryParse(s) : null;
  return d != null ? _fmtDate(d.toLocal()) : s;
}

String _fmtDate(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${d.day} ${m[d.month - 1]} ${d.year}, $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

String _docTitle(Map<String, dynamic> doc) {
  final data = (doc['data'] as Map?) ?? const {};
  for (final k in ['title', 'name', 'text', 'content', 'foodName', 'customerName', 'email', 'label']) {
    final v = data[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return '${doc['id']}';
}

String? _docSubtitle(Map<String, dynamic> doc) {
  final data = (doc['data'] as Map?) ?? const {};
  final parts = <String>[];
  for (final k in ['senderName', 'empName', 'employeeName', 'status', 'dept', 'category']) {
    final v = data[k];
    if (v is String && v.trim().isNotEmpty) parts.add(v.trim());
    if (parts.length == 2) break;
  }
  for (final k in ['timestamp', 'date', 'createdAt', 'updatedAt']) {
    if (data[k] != null) {
      parts.add(readableValue(data[k]));
      break;
    }
  }
  return parts.isEmpty ? null : parts.join(' • ');
}

// ============================================================ main screen
/// CEO: download a full backup, open a backup file, or delete activity data.
class DataVaultScreen extends StatefulWidget {
  const DataVaultScreen({super.key});

  @override
  State<DataVaultScreen> createState() => _DataVaultScreenState();
}

class _DataVaultScreenState extends State<DataVaultScreen> {
  bool _busy = false;
  String? _busyLabel;
  DateTime? _lastBackupAt;

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _busyLabel = 'Preparing backup…';
    });
    try {
      final backup = await DataVaultService.exportBackup();
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));
      final now = DateTime.now();
      final name = 'MN-Family-backup-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      final saved = await saveBytesWithPicker(
        bytes: bytes,
        fileName: name,
        extensions: const ['json'],
        dialogTitle: 'Save backup',
      );
      if (!mounted) return;
      if (saved == null) {
        _snack('Backup not saved.');
      } else {
        setState(() => _lastBackupAt = DateTime.now());
        _snack('Backup saved: ${DataVaultService.totalDocs(backup)} records.', color: AppColors.ragGreen);
      }
    } on DataVaultException catch (e) {
      if (mounted) _snack(e.message, color: AppColors.ragRed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openFile() async {
    try {
      final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['json'], withData: true);
      if (picked == null || picked.files.isEmpty) return;
      final f = picked.files.first;
      var bytes = f.bytes;
      if (bytes == null && f.path != null) bytes = await File(f.path!).readAsBytes();
      if (bytes == null) throw DataVaultException('This file could not be read.');
      final backup = DataVaultService.parseFile(bytes);
      if (!mounted) return;
      final eco = context.read<EcosystemProvider>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: eco,
            child: BackupViewerScreen(backup: backup, fileName: f.name),
          ),
        ),
      );
    } on DataVaultException catch (e) {
      _snack(e.message, color: AppColors.ragRed);
    } catch (e) {
      _snack('Could not open the file: $e', color: AppColors.ragRed);
    }
  }

  Future<void> _deleteEverything() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(hasRecentBackup: _lastBackupAt != null, onBackupFirst: _download),
    );
    if (res == null || !mounted) return;
    setState(() {
      _busy = true;
      _busyLabel = 'Deleting…';
    });
    try {
      final r = await DataVaultService.wipe(includeActivity: res);
      if (!mounted) return;
      await context.read<EcosystemProvider>().clearLocalActivityAfterWipe();
      final deleted = (r['deleted'] as Map?) ?? {};
      final total = deleted.values.fold<int>(0, (s, v) => s + ((v as num?)?.toInt() ?? 0));
      final profiles = (r['profilesCleared'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.ragGreen, size: 40),
          title: const Text('Data deleted'),
          content: Text(
            '$total records removed from ${deleted.length} sections'
            '${profiles > 0 ? ', and activity cleared from $profiles staff profiles' : ''}.\n\n'
            'Staff details and logins were kept.',
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    } on DataVaultException catch (e) {
      if (mounted) _snack(e.message, color: AppColors.ragRed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MnAppBar(title: 'Data Vault', subtitle: 'Backup, restore & reset'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _ActionCard(
                icon: Icons.cloud_download_rounded,
                color: AppColors.primary,
                title: 'Download full backup',
                body: 'Saves everything in the app — social services, attendance, notifications, chats, tasks, '
                    'pillar commitment activity and staff details — as one file. Passwords are never included.',
                button: 'Download backup',
                onTap: _busy ? null : _download,
                footnote: _lastBackupAt == null ? null : 'Last backup saved ${_fmtDate(_lastBackupAt!)}',
              ),
              const SizedBox(height: 14),
              _ActionCard(
                icon: Icons.folder_open_rounded,
                color: const Color(0xFF2563EB),
                title: 'Open a backup file',
                body: 'See everything inside a backup, section by section. You can put the data back into the app from there.',
                button: 'Choose backup file',
                onTap: _busy ? null : _openFile,
              ),
              const SizedBox(height: 26),
              Text('DANGER ZONE',
                  style: GoogleFonts.outfit(
                      fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.ragRed)),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.delete_forever_rounded,
                color: AppColors.ragRed,
                title: 'Delete everything',
                body: 'Permanently deletes social services, attendance, notifications, chats, tasks, notes, orders, '
                    'scorecards and pillar commitment activity from Firebase. Staff details, logins, departments and Konar books are kept.',
                button: 'Delete everything…',
                danger: true,
                onTap: _busy ? null : _deleteEverything,
              ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x66000000),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 14),
                          Text(_busyLabel ?? 'Working…', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String button;
  final VoidCallback? onTap;
  final bool danger;
  final String? footnote;
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.button,
    required this.onTap,
    this.danger = false,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: danger ? const Color(0xFFFECACA) : AppColors.line),
        boxShadow: danger ? null : AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: GoogleFonts.outfit(fontSize: 13.5, color: AppColors.textSecondary, height: 1.45)),
          const SizedBox(height: 14),
          danger
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ragRed,
                    side: const BorderSide(color: AppColors.ragRed),
                  ),
                  onPressed: onTap,
                  icon: Icon(icon, size: 18),
                  label: Text(button),
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: onTap,
                  icon: Icon(icon, size: 18),
                  label: Text(button),
                ),
          if (footnote != null) ...[
            const SizedBox(height: 8),
            Text(footnote!, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.ragGreen)),
          ],
        ],
      ),
    );
  }
}

/// Returns null if cancelled, otherwise whether to clear pillar activity too.
class _DeleteDialog extends StatefulWidget {
  final bool hasRecentBackup;
  final Future<void> Function() onBackupFirst;
  const _DeleteDialog({required this.hasRecentBackup, required this.onBackupFirst});

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _ctrl = TextEditingController();
  bool _activity = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ctrl.text.trim() == 'DELETE';
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.ragRed, size: 40),
      title: const Text('Delete everything?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This permanently removes social services, attendance, notifications, team chats, tasks, to-dos, notes, '
              'orders, scorecards and password requests for everyone. It cannot be undone except from a backup file.',
              style: GoogleFonts.outfit(fontSize: 13.5, height: 1.45, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Text('Kept: staff details, logins, departments, Konar books.',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ragGreen)),
            if (!widget.hasRecentBackup) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('You have not downloaded a backup yet.',
                          style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF92400E))),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onBackupFirst();
                      },
                      child: const Text('Backup first'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _activity,
              onChanged: (v) => setState(() => _activity = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('Also clear pillar commitment activity on staff profiles',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
              subtitle: Text('Health logs, family time, work documents, grooming',
                  style: GoogleFonts.outfit(fontSize: 12)),
            ),
            const SizedBox(height: 6),
            Text('Type DELETE to confirm', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'DELETE'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.ragRed),
          onPressed: ready ? () => Navigator.pop(context, _activity) : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

// ============================================================ backup viewer
/// "Special window" that shows everything inside a backup file.
class BackupViewerScreen extends StatefulWidget {
  final Map<String, dynamic> backup;
  final String fileName;
  const BackupViewerScreen({super.key, required this.backup, required this.fileName});

  @override
  State<BackupViewerScreen> createState() => _BackupViewerScreenState();
}

class _BackupViewerScreenState extends State<BackupViewerScreen> {
  bool _restoring = false;

  Map<String, dynamic> get _collections => Map<String, dynamic>.from(widget.backup['collections'] as Map);

  /// "Made 3 days ago (22 Nov 2026, 10:00 AM)" for the restore check.
  static String backupAgeText(DateTime? created, {DateTime? now}) {
    if (created == null) return 'Backup date unknown';
    final n = now ?? DateTime.now();
    final diff = n.difference(created);
    final ago = diff.inMinutes < 60
        ? (diff.inMinutes < 1 ? 'just now' : '${diff.inMinutes} min ago')
        : diff.inHours < 24
            ? '${diff.inHours} h ago'
            : '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = created.hour % 12 == 0 ? 12 : created.hour % 12;
    final when = '${created.day} ${m[created.month - 1]} ${created.year}, '
        '$h:${created.minute.toString().padLeft(2, '0')} ${created.hour >= 12 ? 'PM' : 'AM'}';
    return 'Made $ago ($when)';
  }

  Future<void> _restore() async {
    bool activity = true;
    final created = DateTime.tryParse('${widget.backup['createdAt']}')?.toLocal();
    final records = _collections.values.fold<int>(0, (s, v) => s + ((v as List?)?.length ?? 0));
    final old = created != null && DateTime.now().difference(created).inDays > 30;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          icon: const Icon(Icons.settings_backup_restore_rounded, color: AppColors.primary, size: 40),
          title: const Text('Restore?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const Key('restore_summary'),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: old ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: old ? const Color(0xFFFDBA74) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(backupAgeText(created),
                        style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('$records record${records == 1 ? '' : 's'} will be put back',
                        style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    if (old) ...[
                      const SizedBox(height: 6),
                      Text('This backup is more than a month old. Newer changes made since then stay, '
                          'but older versions of the same records will replace them.',
                          style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF9A3412))),
                    ],
                  ],
                ),
              ),
              Text(
                'Social causes, notifications, chats, tasks and the rest of this backup will be written back to Firebase. '
                'Records that exist now are updated, nothing is deleted, and current staff details are never overwritten.',
                style: GoogleFonts.outfit(fontSize: 13.5, height: 1.45, color: AppColors.textSecondary),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: activity,
                onChanged: (v) => setD(() => activity = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('Also restore pillar commitment activity on staff profiles',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
          ],
        ),
      ),
    );
    if (go != true || !mounted) return;
    setState(() => _restoring = true);
    try {
      final r = await DataVaultService.restore(widget.backup, includeActivity: activity);
      if (!mounted) return;
      final restored = (r['restored'] as Map?) ?? {};
      final total = restored.values.fold<int>(0, (s, v) => s + ((v as num?)?.toInt() ?? 0));
      await context.read<EcosystemProvider>().refreshAllData();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.ragGreen, size: 40),
          title: const Text('Data restored'),
          content: Text('$total records put back'
              '${(r['profilesRestored'] as num? ?? 0) > 0 ? ', plus activity on ${r['profilesRestored']} staff profiles' : ''}.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    } on DataVaultException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.ragRed));
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _collections.entries.toList()
      ..sort((a, b) => collectionLabel(a.key).compareTo(collectionLabel(b.key)));
    final created = DateTime.tryParse('${widget.backup['createdAt']}')?.toLocal();
    final total = cols.fold<int>(0, (s, e) => s + ((e.value as List?)?.length ?? 0));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(title: 'Backup file', subtitle: widget.fileName),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _restoring ? null : _restore,
            icon: _restoring
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.settings_backup_restore_rounded),
            label: Text(_restoring ? 'Restoring…' : 'Restore this backup'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(22)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$total records',
                    style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('in ${cols.length} sections',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFFFFE4EF))),
                const SizedBox(height: 10),
                Text(
                  [
                    if (created != null) 'Saved ${_fmtDate(created)}',
                    if ((widget.backup['createdBy'] ?? '').toString().isNotEmpty) 'by ${widget.backup['createdBy']}',
                  ].join(' '),
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final e in cols)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RowTile(
                icon: collectionIcon(e.key),
                title: collectionLabel(e.key),
                subtitle: '${(e.value as List?)?.length ?? 0} records',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _CollectionScreen(
                      title: collectionLabel(e.key),
                      docs: ((e.value as List?) ?? const []).map((d) => Map<String, dynamic>.from(d as Map)).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _RowTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    if (subtitle != null)
                      Text(subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBB8C4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> docs;
  const _CollectionScreen({required this.title, required this.docs});

  @override
  State<_CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<_CollectionScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final docs = q.isEmpty ? widget.docs : widget.docs.where((d) => jsonEncode(d).toLowerCase().contains(q)).toList();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(title: widget.title, subtitle: '${widget.docs.length} records'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            onChanged: (v) => setState(() => _q = v.trim()),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search in this section'),
          ),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Text('Nothing here', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppColors.textMuted)),
            ),
          for (final d in docs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RowTile(
                icon: Icons.description_outlined,
                title: _docTitle(d),
                subtitle: _docSubtitle(d),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _RecordScreen(doc: d, sectionTitle: widget.title)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordScreen extends StatelessWidget {
  final Map<String, dynamic> doc;
  final String sectionTitle;
  const _RecordScreen({required this.doc, required this.sectionTitle});

  @override
  Widget build(BuildContext context) {
    final data = Map<String, dynamic>.from((doc['data'] as Map?) ?? const {});
    final keys = data.keys.toList()..sort();
    final subs = Map<String, dynamic>.from((doc['subcollections'] as Map?) ?? const {});
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(
        title: _docTitle(doc),
        subtitle: sectionTitle,
        actions: [
          MnGlassIconButton(
            icon: Icons.copy_rounded,
            tooltip: 'Copy all',
            onTap: () {
              Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(doc)));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                _field('Record ID', '${doc['id']}'),
                for (final k in keys) _field(k, readableValue(data[k])),
              ],
            ),
          ),
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const MnSectionTitle('Inside this record'),
            const SizedBox(height: 8),
            for (final e in subs.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RowTile(
                  icon: Icons.folder_rounded,
                  title: collectionLabel(e.key),
                  subtitle: '${(e.value as List?)?.length ?? 0} records',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _CollectionScreen(
                        title: collectionLabel(e.key),
                        docs: ((e.value as List?) ?? const []).map((d) => Map<String, dynamic>.from(d as Map)).toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _field(String k, String v) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            const SizedBox(height: 3),
            SelectableText(v, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textDark, height: 1.35)),
          ],
        ),
      );
}

/// "Made 3 days ago (22 Nov 2026, 10:00 AM)" — shown before a restore.
String backupAgeText(DateTime? created, {DateTime? now}) =>
    _BackupViewerScreenState.backupAgeText(created, now: now);
