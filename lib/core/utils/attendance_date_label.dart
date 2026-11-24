/// Turns whatever HR typed for an attendance update ("22 Nov", "1-22",
/// "22/11/2026", "1 NOVEMBER, 2 NOVEMBER ... 15 NOVEMBER") into one clean
/// date such as "November 22nd" — the latest day covered by the update.
library;

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String ordinalDay(int d) {
  if (d >= 11 && d <= 13) return '${d}th';
  switch (d % 10) {
    case 1:
      return '${d}st';
    case 2:
      return '${d}nd';
    case 3:
      return '${d}rd';
    default:
      return '${d}th';
  }
}

String formatAttendanceDate(String rawInput, {String? defaultMonth}) {
  var clean = rawInput.trim();
  if (clean.isEmpty) return 'Today';

  String month = _normaliseMonth(defaultMonth) ?? _months[DateTime.now().month - 1];

  // Drop 4-digit years.
  clean = clean.replaceAll(RegExp(r'(?<!\d)(19|20)\d{2}(?!\d)'), ' ');

  final days = <int>{};

  // Numeric dates written day/month (Indian format): 22/11, 22-11-26, 22.11
  final numeric = RegExp(r'(?<!\d)(\d{1,2})\s*[/.\-]\s*(\d{1,2})(?:\s*[/.\-]\s*\d{2})?(?!\d)');
  final numericMatches = numeric.allMatches(clean).toList();
  final looksLikeDayMonth = numericMatches.isNotEmpty &&
      numericMatches.every((m) {
        final mo = int.parse(m.group(2)!);
        return mo >= 1 && mo <= 12 && int.parse(m.group(1)!) <= 31;
      }) &&
      // "1-22" is a day range, not day/month
      numericMatches.every((m) => int.parse(m.group(2)!) <= 12);
  if (looksLikeDayMonth) {
    for (final m in numericMatches) {
      days.add(int.parse(m.group(1)!));
      month = _months[int.parse(m.group(2)!) - 1];
    }
    clean = clean.replaceAll(numeric, ' ');
  }

  // Month names
  final monthMatch = RegExp(
    r'(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sept|sep|oct|nov|dec)',
    caseSensitive: false,
  ).firstMatch(clean);
  if (monthMatch != null) {
    month = _normaliseMonth(monthMatch.group(1)) ?? month;
  }

  // Remaining day numbers, with or without ordinal suffixes (22, 22nd).
  for (final m in RegExp(r'(?<!\d)(\d{1,2})(?:st|nd|rd|th)?(?![\d])', caseSensitive: false).allMatches(clean)) {
    final d = int.parse(m.group(1)!);
    if (d >= 1 && d <= 31) days.add(d);
  }

  if (days.isEmpty) return rawInput.trim();
  final latest = days.reduce((a, b) => a > b ? a : b);
  return '$month ${ordinalDay(latest)}';
}

String? _normaliseMonth(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final l = raw.trim().toLowerCase();
  for (final m in _months) {
    if (l.startsWith(m.substring(0, 3).toLowerCase())) return m;
  }
  return null;
}

/// Rewrites titles/bodies of attendance notifications saved by older builds
/// ("📋 November 1, 22 Attendance Update") to the clean date format.
(String, String) cleanLegacyAttendanceNotification(String title, String content) {
  final t = RegExp(r'^(📋\s*)?(.+?)\s+Attendance Update$').firstMatch(title.trim());
  if (t == null) return (title, content);
  final label = formatAttendanceDate(t.group(2)!);
  if (!RegExp(r'\d').hasMatch(label)) return (title, content);
  final newTitle = '📋 $label Attendance Update';
  final c = RegExp(r'^(.+?)\s+Attendance update has been made by HR\.(.*)$', dotAll: true)
      .firstMatch(content.trim());
  final newContent = c == null
      ? content
      : 'Attendance up to $label has been updated by HR.${c.group(2)}';
  return (newTitle, newContent);
}
