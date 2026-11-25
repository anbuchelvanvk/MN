import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';
import 'employee_avatar.dart';

/// Finds the live employee record for an id (or, failing that, a name).
Employee? findPerson(EcosystemProvider eco, {String? empId, String? name}) {
  final id = (empId ?? '').trim().toLowerCase();
  final n = (name ?? '').trim().toLowerCase();
  for (final e in eco.allEmployees) {
    if (id.isNotEmpty && e.id.toLowerCase() == id) return e;
  }
  if (n.isEmpty) return null;
  for (final e in eco.allEmployees) {
    if (e.name.trim().toLowerCase() == n) return e;
  }
  return null;
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0]).join().toUpperCase();
}

/// A person's profile photo, looked up live by id so a new photo shows
/// everywhere at once. Falls back to their initials.
class PersonAvatar extends StatelessWidget {
  final String? empId;
  final String? name;
  final double size;
  final double? radius;

  const PersonAvatar({super.key, this.empId, this.name, this.size = 36, this.radius});

  @override
  Widget build(BuildContext context) {
    EcosystemProvider? eco;
    try {
      eco = Provider.of<EcosystemProvider>(context);
    } catch (_) {
      eco = null;
    }
    final emp = eco == null ? null : findPerson(eco, empId: empId, name: name);
    final label = emp?.name ?? name ?? '';
    return EmployeeAvatar(
      avatar: emp?.avatar ?? '',
      initials: label.isNotEmpty ? initialsOf(label) : (emp?.initials ?? '?'),
      size: size,
      radius: radius,
    );
  }
}

/// Overlapping photos of the people who liked or reacted, with a count.
/// Tap to see the full list.
class LikersRow extends StatelessWidget {
  final List<String> empIds;
  final double size;
  final int maxShown;
  final String title;

  const LikersRow({
    super.key,
    required this.empIds,
    this.size = 22,
    this.maxShown = 5,
    this.title = 'Liked by',
  });

  @override
  Widget build(BuildContext context) {
    final ids = empIds.toSet().where((s) => s.trim().isNotEmpty).toList();
    if (ids.isEmpty) return const SizedBox.shrink();
    final eco = context.watch<EcosystemProvider>();
    final shown = ids.take(maxShown).toList();
    final first = findPerson(eco, empId: ids.first);
    final firstName = first?.name.split(' ').first ?? 'Someone';
    final label = ids.length == 1 ? '$title $firstName' : '$title $firstName and ${ids.length - 1} other${ids.length == 2 ? '' : 's'}';
    final step = size * 0.68;

    return InkWell(
      key: const Key('likers_row'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => showLikersSheet(context, ids, title: title),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size + step * (shown.length - 1),
              height: size,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: step * i,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: PersonAvatar(empId: shown[i], size: size - 3),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLikersSheet(BuildContext context, List<String> empIds, {String title = 'Liked by'}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) {
      final eco = ctx.watch<EcosystemProvider>();
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text('$title (${empIds.length})',
                    style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    for (final id in empIds)
                      Builder(builder: (_) {
                        final e = findPerson(eco, empId: id);
                        return ListTile(
                          leading: PersonAvatar(empId: id, size: 38),
                          title: Text(e?.name ?? id, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                          subtitle: e == null ? null : Text(e.role, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
