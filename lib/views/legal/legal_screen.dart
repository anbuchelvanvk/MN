import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/legal/legal_content.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../core/widgets/mn_brand_logo.dart';

/// Shows the built-in Privacy Policy or Terms & Conditions.
class LegalScreen extends StatefulWidget {
  final LegalDocument document;
  const LegalScreen({super.key, required this.document});

  static Future<void> open(BuildContext context, LegalDocument document) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LegalScreen(document: document)));

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late final List<GlobalKey> _sectionKeys =
      List.generate(widget.document.sections.length, (_) => GlobalKey());
  bool _contentsOpen = false;

  void _jumpTo(int i) {
    final ctx = _sectionKeys[i].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final other = identical(doc, privacyPolicy) ? termsAndConditions : privacyPolicy;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(title: doc.title, subtitle: 'MN Jewel Park • MN Family app'),
      body: SingleChildScrollView(
        key: const Key('legal_scroll'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MnBrandLogo(size: 56, onDark: false),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.title, style: _h(22)),
                      const SizedBox(height: 4),
                      Text('Effective ${doc.effective} • Updated ${doc.updated}', style: _body(12, muted: true)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(doc.lead, style: _body(14.5)),
            const SizedBox(height: 16),

            // Contents
            _card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  InkWell(
                    key: const Key('legal_contents_toggle'),
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _contentsOpen = !_contentsOpen),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Contents (${doc.sections.length})', style: _h(15))),
                          Icon(_contentsOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  if (_contentsOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                      // Own Material so the list tiles' tap ripple shows on the white card.
                      child: Material(
                        type: MaterialType.transparency,
                        child: Column(
                        children: [
                          for (var i = 0; i < doc.sections.length; i++)
                            ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: Text('${i + 1}.', style: _h(13).copyWith(color: AppColors.primary)),
                              minLeadingWidth: 22,
                              title: Text(doc.sections[i].title, style: _body(13.5)),
                              onTap: () => _jumpTo(i),
                            ),
                        ],
                      ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Sections
            for (var i = 0; i < doc.sections.length; i++)
              Padding(
                key: _sectionKeys[i],
                padding: const EdgeInsets.only(bottom: 12),
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: '${i + 1}.  ', style: _h(16).copyWith(color: AppColors.primary)),
                        TextSpan(text: doc.sections[i].title, style: _h(17)),
                      ])),
                      const SizedBox(height: 8),
                      for (final b in doc.sections[i].blocks) _block(b),
                    ],
                  ),
                ),
              ),

            // Link to the other document
            const SizedBox(height: 4),
            OutlinedButton.icon(
              key: const Key('legal_other_doc'),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LegalScreen(document: other)),
              ),
              icon: Icon(identical(other, privacyPolicy) ? Icons.privacy_tip_outlined : Icons.gavel_rounded, size: 18),
              label: Text('Read the ${other.title}'),
            ),
            const SizedBox(height: 14),
            Center(child: Text('© ${DateTime.now().year} MN Jewel Park', style: _body(12, muted: true))),
          ],
        ),
      ),
    );
  }

  Widget _block(LegalBlock b) {
    switch (b) {
      case LegalPara(:final text):
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: _body(14)));
      case LegalBullets(:final items, :final numbered):
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        child: numbered
                            ? Text('${i + 1}.', style: _h(13.5).copyWith(color: AppColors.primary))
                            : const Padding(
                                padding: EdgeInsets.only(top: 7),
                                child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                              ),
                      ),
                      Expanded(child: Text(items[i], style: _body(14))),
                    ],
                  ),
                ),
            ],
          ),
        );
      case LegalNote(:final text):
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: _body(13.5).copyWith(color: const Color(0xFF1E3A8A))),
              ),
            ],
          ),
        );
      case LegalRows(:final rows):
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              for (final r in rows)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1, style: _h(14)),
                      const SizedBox(height: 3),
                      Text(r.$2, style: _body(13.5)),
                    ],
                  ),
                ),
            ],
          ),
        );
      case LegalContact(:final heading, :final lines):
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: _h(14.5)),
              const SizedBox(height: 8),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${l.$1}: ', style: _body(13.5, muted: true)),
                    TextSpan(text: l.$2, style: _body(13.5).copyWith(fontWeight: FontWeight.w600)),
                  ])),
                ),
            ],
          ),
        );
    }
  }

  Widget _card({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 16, 16, 10)}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: AppColors.softShadow,
        ),
        child: child,
      );

  static TextStyle _h(double size) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 1.25);

  static TextStyle _body(double size, {bool muted = false}) => GoogleFonts.outfit(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: muted ? AppColors.textMuted : AppColors.textSecondary,
        height: 1.5,
      );
}
