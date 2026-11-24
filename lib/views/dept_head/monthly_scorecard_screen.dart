import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/models/monthly_scorecard_model.dart';
import '../../core/services/monthly_scorecard_pdf_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/push_notification_service.dart';
import '../../services/firebase_employee_service.dart';
import '../../providers/ecosystem_provider.dart';

class MonthlyScorecardScreen extends StatefulWidget {
  const MonthlyScorecardScreen({super.key});

  @override
  State<MonthlyScorecardScreen> createState() => _MonthlyScorecardScreenState();
}

class _MonthlyScorecardScreenState extends State<MonthlyScorecardScreen> {
  int _selectedMonth = 10; // Default: October
  int _selectedYear = 2026; // Default: 2026
  late MonthlyScorecardModel _model;
  bool _isLoading = true;

  final NumberFormat _currFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);
  final NumberFormat _numFmt = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    _loadScorecard();
  }

  Future<void> _loadScorecard() async {
    setState(() => _isLoading = true);
    final key = 'monthly_scorecard_${_selectedYear}_$_selectedMonth';

    // 1. Try remote Firestore load first for cross-device sync
    if (FirebaseEmployeeService.isFirebaseAvailable) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('monthly_scorecards')
            .doc('${_selectedYear}_$_selectedMonth')
            .get();
        if (doc.exists && doc.data() != null) {
          _model = MonthlyScorecardModel.fromJson(doc.data()!);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(key, jsonEncode(_model.toJson()));
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      } catch (e) {
        debugPrint('Firestore load monthly scorecard: $e');
      }
    }

    // 2. Fallback to local SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);

    if (jsonStr != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        _model = MonthlyScorecardModel.fromJson(data);
      } catch (_) {
        _model = MonthlyScorecardModel(month: _selectedMonth, year: _selectedYear);
      }
    } else {
      _model = MonthlyScorecardModel(month: _selectedMonth, year: _selectedYear);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveScorecard() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'monthly_scorecard_${_selectedYear}_$_selectedMonth';
    await prefs.setString(key, jsonEncode(_model.toJson()));

    // 1. Save to Cloud Firestore for cross-device visibility (CEO & Team)
    if (FirebaseEmployeeService.isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('monthly_scorecards')
            .doc('${_selectedYear}_$_selectedMonth')
            .set(_model.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore save monthly scorecard: $e');
      }
    }

    // 2. Dispatch push notification to CEO & Online Team
    PushNotificationService().showNotification(
      id: 'scorecard_${DateTime.now().millisecondsSinceEpoch}',
      title: '📊 Monthly Scorecard Updated',
      body: 'Online Team TL updated the monthly scorecard for ${_model.monthName} ${_model.year}.',
    );

    try {
      if (mounted) {
        final eco = context.read<EcosystemProvider>();
        eco.postBroadcastNotification(
          title: '📊 Monthly Scorecard Updated',
          content: 'Online Team TL updated the monthly performance scorecard for ${_model.monthName} ${_model.year}. Available on CEO Portal & Online Team direct access.',
          senderName: eco.currentEmployee.name,
          senderRole: 'Online Team Lead',
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  String _formatCurrency(double val) => _currFmt.format(val).replaceAll('Rs.', 'Rs. ');
  String _formatNum(num val) => _numFmt.format(val);

  void _changeMonth(int delta) {
    int newMonth = _selectedMonth + delta;
    int newYear = _selectedYear;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    setState(() {
      _selectedMonth = newMonth;
      _selectedYear = newYear;
    });
    _loadScorecard();
  }

  void _previewPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              'PDF Preview • ${_model.monthName} ${_model.year}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: AppColors.pureWhite,
            foregroundColor: AppColors.textDark,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PdfPreview(
            build: (format) => MonthlyScorecardPdfService.generatePdf(_model),
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName: 'Monthly_Scorecard_${_model.monthName}_${_model.year}.pdf',
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    try {
      final bytes = await MonthlyScorecardPdfService.generatePdf(_model);
      final fileName = 'Monthly_Scorecard_${_model.monthName}_${_model.year}.pdf';

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF059669),
              content: Text('Scorecard PDF prepared for download ($fileName)'),
            ),
          );
        }
        return;
      }

      Directory? dir;
      try {
        if (!kIsWeb && Platform.isAndroid) {
          dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Offer standard share/save flow so user can download to device folder
      await Printing.sharePdf(bytes: bytes, filename: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Scorecard PDF saved locally:\n${file.path}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Failed to download PDF: $e'),
          ),
        );
      }
    }
  }

  void _openEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditScorecardSheet(
        model: _model,
        onSave: (updated) {
          setState(() {
            _model = updated;
          });
          _saveScorecard();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Scorecard for ${_model.monthName} updated successfully!',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('Monthly Scorecard', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.pureWhite,
          foregroundColor: AppColors.textDark,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Scorecard',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
            ),
            Text(
              'Online Department TL (OTM)',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Scorecard Values',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFDC2626)),
            ),
            onPressed: _openEditModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Picker Banner
            _buildMonthPickerBanner(),
            const SizedBox(height: 14),

            // Top 4 Summary Cards (2x2 Grid)
            _buildTopSummaryCards(),
            const SizedBox(height: 14),

            // Category Breakdown Section
            _buildCategorySection(
              title: 'Instagram',
              percentage: '${_model.instaPercentage}%',
              iconAsset: 'assets/scorecard_icons/icon_instagram.png',
              subtitle: 'Target/day: Content, Product, Stories, Carousel, Influencer, Campaign',
              metrics: [
                _buildCircularMetric(
                  label: 'Content Reel',
                  actual: _model.instaContentReelActual,
                  target: _model.instaContentReelTarget,
                  roleTag: 'VPE / OTM',
                ),
                _buildCircularMetric(
                  label: 'Product Reel',
                  actual: _model.instaProductReelActual,
                  target: _model.instaProductReelTarget,
                  roleTag: 'Ass.VPE / OTM',
                ),
                _buildCircularMetric(
                  label: 'Stories',
                  actual: _model.instaStoriesActual,
                  target: _model.instaStoriesTarget,
                  roleTag: 'OTM',
                ),
                _buildCircularMetric(
                  label: 'Carousel Post',
                  actual: _model.instaCarouselActual,
                  target: _model.instaCarouselTarget,
                  roleTag: 'OTM',
                ),
                _buildCircularMetric(
                  label: 'Active Campaign',
                  actual: _model.instaCampaignActual,
                  target: _model.instaCampaignTarget,
                  roleTag: 'OTM / AC',
                ),
                _buildCircularMetric(
                  label: 'Influencer',
                  actual: _model.instaInfluencerActual,
                  target: _model.instaInfluencerTarget,
                  roleTag: 'OTM / VPE',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildCategorySection(
              title: 'Website',
              percentage: '${_model.webPercentage}%',
              iconAsset: 'assets/scorecard_icons/icon_website.png',
              subtitle: 'Target/day: Listing, Orders, Campaign, Retargeting',
              metrics: [
                _buildCircularMetric(
                  label: 'MN Listing',
                  actual: _model.webMnListingActual,
                  target: _model.webMnListingTarget,
                  roleTag: 'OTM / ECE',
                ),
                _buildCircularMetric(
                  label: 'Vadivam Listing',
                  actual: _model.webVadivamListingActual,
                  target: _model.webVadivamListingTarget,
                  roleTag: 'OTM / ECE',
                ),
                _buildCircularMetric(
                  label: 'Campaign',
                  actual: _model.webCampaignActual,
                  target: _model.webCampaignTarget,
                  roleTag: 'OTM / AC',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildCategorySection(
              title: 'WhatsApp',
              percentage: '${_model.waPercentage}%',
              iconAsset: 'assets/scorecard_icons/icon_whatsapp.png',
              subtitle: 'Target/day: Stories, Broadcast, Channels, Campaign',
              metrics: [
                _buildCircularMetric(
                  label: 'Stories / Status',
                  actual: _model.waStoriesActual,
                  target: _model.waStoriesTarget,
                  roleTag: 'OTM / OSH',
                ),
                _buildCircularMetric(
                  label: 'Channels',
                  actual: _model.waChannelsActual,
                  target: _model.waChannelsTarget,
                  roleTag: 'OTM / OS1',
                ),
                _buildCircularMetric(
                  label: 'Campaign',
                  actual: _model.waCampaignActual,
                  target: _model.waCampaignTarget,
                  roleTag: 'OTM / AC',
                ),
                _buildCircularMetric(
                  label: 'WhatsApp Broadcast',
                  actual: _model.waBroadcastActual,
                  target: _model.waBroadcastTarget,
                  roleTag: 'OTM',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildCategorySection(
              title: 'Mobile App',
              percentage: '${_model.appPercentage}%',
              iconAsset: 'assets/scorecard_icons/icon_mobile_app.png',
              subtitle: 'Target/day: Downloads, Listing, Notification, Review',
              metrics: [
                _buildCircularMetric(
                  label: 'MN Listing',
                  actual: _model.appMnListingActual,
                  target: _model.appMnListingTarget,
                  roleTag: 'OTM / ECE',
                ),
                _buildCircularMetric(
                  label: 'Vadivam Listing',
                  actual: _model.appVadivamListingActual,
                  target: _model.appVadivamListingTarget,
                  roleTag: 'OTM / ECE',
                ),
                _buildCircularMetric(
                  label: 'Campaign',
                  actual: _model.appCampaignActual,
                  target: _model.appCampaignTarget,
                  roleTag: 'OTM / AC',
                ),
                _buildCircularMetric(
                  label: 'Notification',
                  actual: _model.appNotificationActual,
                  target: _model.appNotificationTarget,
                  roleTag: 'OTM / ECE',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildCategorySection(
              title: 'Google',
              percentage: '${_model.googlePercentage}%',
              iconAsset: 'assets/scorecard_icons/icon_google.png',
              subtitle: 'Target/day: Listing, Campaign',
              metrics: [
                _buildCircularMetric(
                  label: 'Blogs',
                  actual: _model.googleBlogsActual,
                  target: _model.googleBlogsTarget,
                  roleTag: 'OTM / OSH',
                  isSpecialAmber: true,
                ),
                _buildCircularMetric(
                  label: 'Listing',
                  actual: _model.googleListingActual,
                  target: _model.googleListingTarget,
                  roleTag: 'Ass.VPE / OTM / AC',
                ),
                _buildCircularMetric(
                  label: 'Campaign',
                  actual: _model.googleCampaignActual,
                  target: _model.googleCampaignTarget,
                  roleTag: 'OTM / AC',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildCategorySection(
              title: 'Other Social Media',
              percentage: '${_model.osmPercentage}%',
              iconAsset: 'assets/scorecard_icons/icon_other_social.png',
              subtitle: 'Target/day: Snapchat, Blogs, Pinterest, Shorts, LinkedIn, X Post',
              metrics: [
                _buildCircularMetric(
                  label: 'Snapchat',
                  actual: _model.osmSnapchatActual,
                  target: _model.osmSnapchatTarget,
                  roleTag: 'OSH',
                ),
                _buildCircularMetric(
                  label: 'Pinterest',
                  actual: _model.osmPinterestActual,
                  target: _model.osmPinterestTarget,
                  roleTag: 'OTM',
                ),
                _buildCircularMetric(
                  label: 'Shorts',
                  actual: _model.osmShortsActual,
                  target: _model.osmShortsTarget,
                  roleTag: 'OTM / VPE',
                ),
                _buildCircularMetric(
                  label: 'LinkedIn',
                  actual: _model.osmLinkedinActual,
                  target: _model.osmLinkedinTarget,
                  roleTag: 'OTM',
                ),
                _buildCircularMetric(
                  label: 'X Post',
                  actual: _model.osmXPostActual,
                  target: _model.osmXPostTarget,
                  roleTag: 'OTM',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Designing Section
            _buildDesigningCard(),
            const SizedBox(height: 12),

            // Other Targets
            _buildOtherTargetsCard(),
            const SizedBox(height: 12),

            // Performance Section
            _buildPerformanceCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildMonthPickerBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22, color: Color(0xFF0F172A)),
            onPressed: () => _changeMonth(-1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_model.monthName} ${_model.year}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _model.dateRangeTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22, color: Color(0xFF0F172A)),
            onPressed: () => _changeMonth(1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTopMetricCard(
                title: 'Total Sales and Order',
                value: _formatNum(_model.totalSalesActual),
                target: '${_formatCurrency(_model.totalSalesTarget)}\n(${_formatCurrency(_model.totalSalesTarget / _model.daysInMonth)} Per Day)',
                isAchieved: _model.totalSalesActual >= _model.totalSalesTarget,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTopMetricCard(
                title: 'Sales Order',
                value: '${_model.salesOrdersActual}',
                target: '${_model.salesOrdersTarget} Conversion\n(${(_model.salesOrdersTarget / _model.daysInMonth).toStringAsFixed(0)} Per Day)',
                isAchieved: _model.salesOrdersActual >= _model.salesOrdersTarget,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTopMetricCard(
                title: 'Scheme Conversions',
                value: '${_model.schemeConversionsActual.toStringAsFixed(3)}G',
                target: '${_model.schemeConversionsTarget.toStringAsFixed(3)}G Target\n(${(_model.schemeConversionsTarget / _model.daysInMonth).toStringAsFixed(3)}G Per Day)',
                isAchieved: _model.schemeConversionsActual >= _model.schemeConversionsTarget,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTopMetricCard(
                title: 'Monthly Scheme',
                value: _formatCurrency(_model.monthlySchemeActual),
                target: '${_formatCurrency(_model.monthlySchemeTarget)} Target\n(${_formatCurrency(_model.monthlySchemeTarget / _model.daysInMonth)} Per Day)',
                isAchieved: _model.monthlySchemeActual >= _model.monthlySchemeTarget,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopMetricCard({
    required String title,
    required String value,
    required String target,
    required bool isAchieved,
  }) {
    final statusColor = isAchieved ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final statusBg = isAchieved ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAchieved ? 'ACHIEVED' : 'PENDING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            target,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required String percentage,
    required String iconAsset,
    required String subtitle,
    required List<Widget> metrics,
  }) {
    final int pctVal = int.tryParse(percentage.replaceAll('%', '')) ?? 0;
    // Sector percentage colors: >= 95% Green, 50% to < 95% Orange, < 50% Red
    final Color badgeColor = pctVal >= 95
        ? const Color(0xFF047857)
        : (pctVal >= 50 ? const Color(0xFFEA580C) : const Color(0xFFDC2626));
    final Color badgeBg = pctVal >= 95
        ? const Color(0xFFECFDF5)
        : (pctVal >= 50 ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  iconAsset,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.apps, size: 26, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor, width: 1.2),
                ),
                child: Text(
                  percentage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics,
          ),
        ],
      ),
    );
  }

  Widget _buildCircularMetric({
    required String label,
    required num actual,
    required num target,
    String? roleTag,
    bool isSpecialAmber = false,
  }) {
    Color circleBorderColor;
    Color circleBg;

    if (isSpecialAmber) {
      circleBorderColor = const Color(0xFFD97706);
      circleBg = const Color(0xFFFFFBEB);
    } else if (actual < target) {
      circleBorderColor = const Color(0xFFDC2626);
      circleBg = const Color(0xFFFEF2F2);
    } else if (actual == target) {
      circleBorderColor = const Color(0xFF047857);
      circleBg = const Color(0xFFECFDF5);
    } else {
      circleBorderColor = const Color(0xFF1D4ED8);
      circleBg = const Color(0xFFEFF6FF);
    }

    return SizedBox(
      width: 86,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleBg,
              border: Border.all(color: circleBorderColor, width: 2.4),
              boxShadow: [
                BoxShadow(
                  color: circleBorderColor.withOpacity(0.14),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatCompact(actual, padZero: true),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: circleBorderColor,
                  ),
                ),
                Container(
                  width: 28,
                  height: 1.2,
                  color: circleBorderColor.withOpacity(0.6),
                  margin: const EdgeInsets.symmetric(vertical: 1.5),
                ),
                Text(
                  _formatCompact(target, padZero: true),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.15,
            ),
          ),
          if (roleTag != null && roleTag.isNotEmpty) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                roleTag,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCompact(num val, {bool padZero = true}) {
    if (val >= 10000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    } else if (val >= 1000) {
      if (val % 1000 == 0) return '${(val / 1000).toStringAsFixed(0)}k';
      return '${(val / 1000).toStringAsFixed(1)}k';
    } else if (padZero && val >= 0 && val < 10 && val == val.roundToDouble()) {
      return '0${val.toInt()}';
    }
    return val.toString();
  }

  Widget _buildDesigningCard() {
    final int dPct = _model.designFeedbackRating;
    final Color dBadgeColor = dPct >= 95
        ? const Color(0xFF047857)
        : (dPct >= 50 ? const Color(0xFFEA580C) : const Color(0xFFDC2626));
    final Color dBadgeBg = dPct >= 95
        ? const Color(0xFFECFDF5)
        : (dPct >= 50 ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/scorecard_icons/icon_designing.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.palette, size: 26, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Designing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Get 100% Feedback Rating',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dBadgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: dBadgeColor, width: 1.2),
                ),
                child: Text(
                  '$dPct%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: dBadgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF047857),
                ),
                child: FittedBox(fit: BoxFit.scaleDown, child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_model.designResponse}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Response',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In Design we need to get the customer or Concern team',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildPill('On Time', const Color(0xFF059669)),
                        _buildPill('Quality Design', const Color(0xFF059669)),
                        _buildPill('Design Perfection', const Color(0xFF059669)),
                        _buildPill('${_model.designFeedbackRating}% Feedback', const Color(0xFF1D4ED8)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOtherTargetsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Other Targets',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildCircularMetric(
                label: 'MN App Downloads',
                actual: _model.downloadsMnActual,
                target: _model.downloadsMnTarget,
              ),
              _buildCircularMetric(
                label: 'Vadivam App Downloads',
                actual: _model.downloadsVadivamActual,
                target: _model.downloadsVadivamTarget,
              ),
              _buildCircularMetric(
                label: 'MN Followers',
                actual: _model.followersMnActual,
                target: _model.followersMnTarget,
              ),
              _buildCircularMetric(
                label: 'Vadivam Followers',
                actual: _model.followersVadivamActual,
                target: _model.followersVadivamTarget,
              ),
              _buildCircularMetric(
                label: 'Google Reviews',
                actual: _model.googleReviewsActual,
                target: _model.googleReviewsTarget,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _buildPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMemberStat('Gokul', _model.gokulSales, _model.gokulSchemes, _model.gokulGold),
                      const SizedBox(width: 14),
                      _buildMemberStat('Kaaviya', _model.kaaviyaSales, _model.kaaviyaSchemes, _model.kaaviyaGold),
                      const SizedBox(width: 14),
                      _buildMemberStat('Nisha', _model.nishaSales, _model.nishaSchemes, _model.nishaGold),
                      const SizedBox(width: 14),
                      _buildMemberStat('Asha', _model.ashaSales, _model.ashaSchemes, _model.ashaGold),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Large Green Circle for Top Performer
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF047857),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33047857),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(height: 3),
                Text(
                  _capitalizeFirst(_model.topPerformer),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Performance is\nhigh',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStat(String name, double sales, double schemes, double gold) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(width: 4, height: 16, color: const Color(0xFF047857)),
            const SizedBox(width: 2),
            Container(width: 4, height: 10, color: const Color(0xFF10B981)),
            const SizedBox(width: 2),
            Container(width: 4, height: 14, color: const Color(0xFF059669)),
            const SizedBox(width: 2),
            Container(width: 4, height: 8, color: const Color(0xFF34D399)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(sales),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF047857),
          ),
        ),
        Text(
          _formatCurrency(schemes),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          gold > 0 ? '${gold.toStringAsFixed(3)}g' : '0g',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(
                  'Preview PDF',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _previewPdf,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  'Download PDF',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _downloadPdf,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Comprehensive BottomSheet Modal that lets Praveen Kumar (TL)
/// customize any actual number, target number, or top performer
class _EditScorecardSheet extends StatefulWidget {
  final MonthlyScorecardModel model;
  final ValueChanged<MonthlyScorecardModel> onSave;

  const _EditScorecardSheet({
    required this.model,
    required this.onSave,
  });

  @override
  State<_EditScorecardSheet> createState() => _EditScorecardSheetState();
}

class _EditScorecardSheetState extends State<_EditScorecardSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MonthlyScorecardModel _m;

  // Controllers
  late TextEditingController _totalSalesActual;
  late TextEditingController _totalSalesTarget;
  late TextEditingController _salesOrdersActual;
  late TextEditingController _salesOrdersTarget;
  late TextEditingController _schemeConversionsActual;
  late TextEditingController _schemeConversionsTarget;
  late TextEditingController _monthlySchemeActual;
  late TextEditingController _monthlySchemeTarget;

  // Instagram
  late TextEditingController _instaContentReelActual;
  late TextEditingController _instaContentReelTarget;
  late TextEditingController _instaProductReelActual;
  late TextEditingController _instaProductReelTarget;
  late TextEditingController _instaStoriesActual;
  late TextEditingController _instaStoriesTarget;
  late TextEditingController _instaCarouselActual;
  late TextEditingController _instaCarouselTarget;
  late TextEditingController _instaCampaignActual;
  late TextEditingController _instaCampaignTarget;
  late TextEditingController _instaInfluencerActual;
  late TextEditingController _instaInfluencerTarget;

  // Website
  late TextEditingController _webMnListingActual;
  late TextEditingController _webMnListingTarget;
  late TextEditingController _webVadivamListingActual;
  late TextEditingController _webVadivamListingTarget;
  late TextEditingController _webCampaignActual;
  late TextEditingController _webCampaignTarget;

  // WhatsApp
  late TextEditingController _waStoriesActual;
  late TextEditingController _waStoriesTarget;
  late TextEditingController _waChannelsActual;
  late TextEditingController _waChannelsTarget;
  late TextEditingController _waCampaignActual;
  late TextEditingController _waCampaignTarget;
  late TextEditingController _waBroadcastActual;
  late TextEditingController _waBroadcastTarget;

  // Mobile App
  late TextEditingController _appMnListingActual;
  late TextEditingController _appMnListingTarget;
  late TextEditingController _appVadivamListingActual;
  late TextEditingController _appVadivamListingTarget;
  late TextEditingController _appCampaignActual;
  late TextEditingController _appCampaignTarget;
  late TextEditingController _appNotificationActual;
  late TextEditingController _appNotificationTarget;

  // Google
  late TextEditingController _googleBlogsActual;
  late TextEditingController _googleBlogsTarget;
  late TextEditingController _googleListingActual;
  late TextEditingController _googleListingTarget;
  late TextEditingController _googleCampaignActual;
  late TextEditingController _googleCampaignTarget;

  // Other Social Media
  late TextEditingController _osmSnapchatActual;
  late TextEditingController _osmSnapchatTarget;
  late TextEditingController _osmPinterestActual;
  late TextEditingController _osmPinterestTarget;
  late TextEditingController _osmShortsActual;
  late TextEditingController _osmShortsTarget;
  late TextEditingController _osmLinkedinActual;
  late TextEditingController _osmLinkedinTarget;
  late TextEditingController _osmXPostActual;
  late TextEditingController _osmXPostTarget;

  // Designing & Other Targets
  late TextEditingController _designResponse;
  late TextEditingController _designFeedbackRating;
  late TextEditingController _downloadsMnActual;
  late TextEditingController _downloadsMnTarget;
  late TextEditingController _downloadsVadivamActual;
  late TextEditingController _downloadsVadivamTarget;
  late TextEditingController _followersMnActual;
  late TextEditingController _followersMnTarget;
  late TextEditingController _followersVadivamActual;
  late TextEditingController _followersVadivamTarget;
  late TextEditingController _googleReviewsActual;
  late TextEditingController _googleReviewsTarget;

  // Team
  late TextEditingController _gokulSales;
  late TextEditingController _gokulSchemes;
  late TextEditingController _gokulGold;
  late TextEditingController _kaaviyaSales;
  late TextEditingController _kaaviyaSchemes;
  late TextEditingController _kaaviyaGold;
  late TextEditingController _nishaSales;
  late TextEditingController _nishaSchemes;
  late TextEditingController _nishaGold;
  late TextEditingController _ashaSales;
  late TextEditingController _ashaSchemes;
  late TextEditingController _ashaGold;
  late String _topPerformer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _m = widget.model;

    _totalSalesActual = TextEditingController(text: _m.totalSalesActual.toStringAsFixed(0));
    _totalSalesTarget = TextEditingController(text: _m.totalSalesTarget.toStringAsFixed(0));
    _salesOrdersActual = TextEditingController(text: _m.salesOrdersActual.toString());
    _salesOrdersTarget = TextEditingController(text: _m.salesOrdersTarget.toString());
    _schemeConversionsActual = TextEditingController(text: _m.schemeConversionsActual.toString());
    _schemeConversionsTarget = TextEditingController(text: _m.schemeConversionsTarget.toString());
    _monthlySchemeActual = TextEditingController(text: _m.monthlySchemeActual.toStringAsFixed(0));
    _monthlySchemeTarget = TextEditingController(text: _m.monthlySchemeTarget.toStringAsFixed(0));

    _instaContentReelActual = TextEditingController(text: _m.instaContentReelActual.toString());
    _instaContentReelTarget = TextEditingController(text: _m.instaContentReelTarget.toString());
    _instaProductReelActual = TextEditingController(text: _m.instaProductReelActual.toString());
    _instaProductReelTarget = TextEditingController(text: _m.instaProductReelTarget.toString());
    _instaStoriesActual = TextEditingController(text: _m.instaStoriesActual.toString());
    _instaStoriesTarget = TextEditingController(text: _m.instaStoriesTarget.toString());
    _instaCarouselActual = TextEditingController(text: _m.instaCarouselActual.toString());
    _instaCarouselTarget = TextEditingController(text: _m.instaCarouselTarget.toString());
    _instaCampaignActual = TextEditingController(text: _m.instaCampaignActual.toString());
    _instaCampaignTarget = TextEditingController(text: _m.instaCampaignTarget.toString());
    _instaInfluencerActual = TextEditingController(text: _m.instaInfluencerActual.toString());
    _instaInfluencerTarget = TextEditingController(text: _m.instaInfluencerTarget.toString());

    _webMnListingActual = TextEditingController(text: _m.webMnListingActual.toString());
    _webMnListingTarget = TextEditingController(text: _m.webMnListingTarget.toString());
    _webVadivamListingActual = TextEditingController(text: _m.webVadivamListingActual.toString());
    _webVadivamListingTarget = TextEditingController(text: _m.webVadivamListingTarget.toString());
    _webCampaignActual = TextEditingController(text: _m.webCampaignActual.toString());
    _webCampaignTarget = TextEditingController(text: _m.webCampaignTarget.toString());

    _waStoriesActual = TextEditingController(text: _m.waStoriesActual.toString());
    _waStoriesTarget = TextEditingController(text: _m.waStoriesTarget.toString());
    _waChannelsActual = TextEditingController(text: _m.waChannelsActual.toString());
    _waChannelsTarget = TextEditingController(text: _m.waChannelsTarget.toString());
    _waCampaignActual = TextEditingController(text: _m.waCampaignActual.toString());
    _waCampaignTarget = TextEditingController(text: _m.waCampaignTarget.toString());
    _waBroadcastActual = TextEditingController(text: _m.waBroadcastActual.toString());
    _waBroadcastTarget = TextEditingController(text: _m.waBroadcastTarget.toString());

    _appMnListingActual = TextEditingController(text: _m.appMnListingActual.toString());
    _appMnListingTarget = TextEditingController(text: _m.appMnListingTarget.toString());
    _appVadivamListingActual = TextEditingController(text: _m.appVadivamListingActual.toString());
    _appVadivamListingTarget = TextEditingController(text: _m.appVadivamListingTarget.toString());
    _appCampaignActual = TextEditingController(text: _m.appCampaignActual.toString());
    _appCampaignTarget = TextEditingController(text: _m.appCampaignTarget.toString());
    _appNotificationActual = TextEditingController(text: _m.appNotificationActual.toString());
    _appNotificationTarget = TextEditingController(text: _m.appNotificationTarget.toString());

    _googleBlogsActual = TextEditingController(text: _m.googleBlogsActual.toString());
    _googleBlogsTarget = TextEditingController(text: _m.googleBlogsTarget.toString());
    _googleListingActual = TextEditingController(text: _m.googleListingActual.toString());
    _googleListingTarget = TextEditingController(text: _m.googleListingTarget.toString());
    _googleCampaignActual = TextEditingController(text: _m.googleCampaignActual.toString());
    _googleCampaignTarget = TextEditingController(text: _m.googleCampaignTarget.toString());

    _osmSnapchatActual = TextEditingController(text: _m.osmSnapchatActual.toString());
    _osmSnapchatTarget = TextEditingController(text: _m.osmSnapchatTarget.toString());
    _osmPinterestActual = TextEditingController(text: _m.osmPinterestActual.toString());
    _osmPinterestTarget = TextEditingController(text: _m.osmPinterestTarget.toString());
    _osmShortsActual = TextEditingController(text: _m.osmShortsActual.toString());
    _osmShortsTarget = TextEditingController(text: _m.osmShortsTarget.toString());
    _osmLinkedinActual = TextEditingController(text: _m.osmLinkedinActual.toString());
    _osmLinkedinTarget = TextEditingController(text: _m.osmLinkedinTarget.toString());
    _osmXPostActual = TextEditingController(text: _m.osmXPostActual.toString());
    _osmXPostTarget = TextEditingController(text: _m.osmXPostTarget.toString());

    _designResponse = TextEditingController(text: _m.designResponse.toString());
    _designFeedbackRating = TextEditingController(text: _m.designFeedbackRating.toString());

    _downloadsMnActual = TextEditingController(text: _m.downloadsMnActual.toString());
    _downloadsMnTarget = TextEditingController(text: _m.downloadsMnTarget.toString());
    _downloadsVadivamActual = TextEditingController(text: _m.downloadsVadivamActual.toString());
    _downloadsVadivamTarget = TextEditingController(text: _m.downloadsVadivamTarget.toString());
    _followersMnActual = TextEditingController(text: _m.followersMnActual.toString());
    _followersMnTarget = TextEditingController(text: _m.followersMnTarget.toString());
    _followersVadivamActual = TextEditingController(text: _m.followersVadivamActual.toString());
    _followersVadivamTarget = TextEditingController(text: _m.followersVadivamTarget.toString());
    _googleReviewsActual = TextEditingController(text: _m.googleReviewsActual.toString());
    _googleReviewsTarget = TextEditingController(text: _m.googleReviewsTarget.toString());

    _gokulSales = TextEditingController(text: _m.gokulSales.toStringAsFixed(0));
    _gokulSchemes = TextEditingController(text: _m.gokulSchemes.toStringAsFixed(0));
    _gokulGold = TextEditingController(text: _m.gokulGold.toString());
    _kaaviyaSales = TextEditingController(text: _m.kaaviyaSales.toStringAsFixed(0));
    _kaaviyaSchemes = TextEditingController(text: _m.kaaviyaSchemes.toStringAsFixed(0));
    _kaaviyaGold = TextEditingController(text: _m.kaaviyaGold.toString());
    _nishaSales = TextEditingController(text: _m.nishaSales.toStringAsFixed(0));
    _nishaSchemes = TextEditingController(text: _m.nishaSchemes.toStringAsFixed(0));
    _nishaGold = TextEditingController(text: _m.nishaGold.toString());
    _ashaSales = TextEditingController(text: _m.ashaSales.toStringAsFixed(0));
    _ashaSchemes = TextEditingController(text: _m.ashaSchemes.toStringAsFixed(0));
    _ashaGold = TextEditingController(text: _m.ashaGold.toString());
    _topPerformer = _m.topPerformer;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _totalSalesActual.dispose();
    _totalSalesTarget.dispose();
    _salesOrdersActual.dispose();
    _salesOrdersTarget.dispose();
    _schemeConversionsActual.dispose();
    _schemeConversionsTarget.dispose();
    _monthlySchemeActual.dispose();
    _monthlySchemeTarget.dispose();
    _instaContentReelActual.dispose();
    _instaContentReelTarget.dispose();
    _instaProductReelActual.dispose();
    _instaProductReelTarget.dispose();
    _instaStoriesActual.dispose();
    _instaStoriesTarget.dispose();
    _instaCarouselActual.dispose();
    _instaCarouselTarget.dispose();
    _instaCampaignActual.dispose();
    _instaCampaignTarget.dispose();
    _instaInfluencerActual.dispose();
    _instaInfluencerTarget.dispose();
    _webMnListingActual.dispose();
    _webMnListingTarget.dispose();
    _webVadivamListingActual.dispose();
    _webVadivamListingTarget.dispose();
    _webCampaignActual.dispose();
    _webCampaignTarget.dispose();
    _waStoriesActual.dispose();
    _waStoriesTarget.dispose();
    _waChannelsActual.dispose();
    _waChannelsTarget.dispose();
    _waCampaignActual.dispose();
    _waCampaignTarget.dispose();
    _waBroadcastActual.dispose();
    _waBroadcastTarget.dispose();
    _appMnListingActual.dispose();
    _appMnListingTarget.dispose();
    _appVadivamListingActual.dispose();
    _appVadivamListingTarget.dispose();
    _appCampaignActual.dispose();
    _appCampaignTarget.dispose();
    _appNotificationActual.dispose();
    _appNotificationTarget.dispose();
    _googleBlogsActual.dispose();
    _googleBlogsTarget.dispose();
    _googleListingActual.dispose();
    _googleListingTarget.dispose();
    _googleCampaignActual.dispose();
    _googleCampaignTarget.dispose();
    _osmSnapchatActual.dispose();
    _osmSnapchatTarget.dispose();
    _osmPinterestActual.dispose();
    _osmPinterestTarget.dispose();
    _osmShortsActual.dispose();
    _osmShortsTarget.dispose();
    _osmLinkedinActual.dispose();
    _osmLinkedinTarget.dispose();
    _osmXPostActual.dispose();
    _osmXPostTarget.dispose();
    _designResponse.dispose();
    _designFeedbackRating.dispose();
    _downloadsMnActual.dispose();
    _downloadsMnTarget.dispose();
    _downloadsVadivamActual.dispose();
    _downloadsVadivamTarget.dispose();
    _followersMnActual.dispose();
    _followersMnTarget.dispose();
    _followersVadivamActual.dispose();
    _followersVadivamTarget.dispose();
    _googleReviewsActual.dispose();
    _googleReviewsTarget.dispose();
    _gokulSales.dispose();
    _gokulSchemes.dispose();
    _gokulGold.dispose();
    _kaaviyaSales.dispose();
    _kaaviyaSchemes.dispose();
    _kaaviyaGold.dispose();
    _nishaSales.dispose();
    _nishaSchemes.dispose();
    _nishaGold.dispose();
    _ashaSales.dispose();
    _ashaSchemes.dispose();
    _ashaGold.dispose();
    super.dispose();
  }

  void _submit() {
    final updated = MonthlyScorecardModel(
      month: _m.month,
      year: _m.year,
      totalSalesActual: double.tryParse(_totalSalesActual.text) ?? _m.totalSalesActual,
      totalSalesTarget: double.tryParse(_totalSalesTarget.text) ?? _m.totalSalesTarget,
      salesOrdersActual: int.tryParse(_salesOrdersActual.text) ?? _m.salesOrdersActual,
      salesOrdersTarget: int.tryParse(_salesOrdersTarget.text) ?? _m.salesOrdersTarget,
      schemeConversionsActual: double.tryParse(_schemeConversionsActual.text) ?? _m.schemeConversionsActual,
      schemeConversionsTarget: double.tryParse(_schemeConversionsTarget.text) ?? _m.schemeConversionsTarget,
      monthlySchemeActual: double.tryParse(_monthlySchemeActual.text) ?? _m.monthlySchemeActual,
      monthlySchemeTarget: double.tryParse(_monthlySchemeTarget.text) ?? _m.monthlySchemeTarget,
      instaContentReelActual: int.tryParse(_instaContentReelActual.text) ?? _m.instaContentReelActual,
      instaContentReelTarget: int.tryParse(_instaContentReelTarget.text) ?? _m.instaContentReelTarget,
      instaProductReelActual: int.tryParse(_instaProductReelActual.text) ?? _m.instaProductReelActual,
      instaProductReelTarget: int.tryParse(_instaProductReelTarget.text) ?? _m.instaProductReelTarget,
      instaStoriesActual: int.tryParse(_instaStoriesActual.text) ?? _m.instaStoriesActual,
      instaStoriesTarget: int.tryParse(_instaStoriesTarget.text) ?? _m.instaStoriesTarget,
      instaCarouselActual: int.tryParse(_instaCarouselActual.text) ?? _m.instaCarouselActual,
      instaCarouselTarget: int.tryParse(_instaCarouselTarget.text) ?? _m.instaCarouselTarget,
      instaCampaignActual: int.tryParse(_instaCampaignActual.text) ?? _m.instaCampaignActual,
      instaCampaignTarget: int.tryParse(_instaCampaignTarget.text) ?? _m.instaCampaignTarget,
      instaInfluencerActual: int.tryParse(_instaInfluencerActual.text) ?? _m.instaInfluencerActual,
      instaInfluencerTarget: int.tryParse(_instaInfluencerTarget.text) ?? _m.instaInfluencerTarget,
      webMnListingActual: int.tryParse(_webMnListingActual.text) ?? _m.webMnListingActual,
      webMnListingTarget: int.tryParse(_webMnListingTarget.text) ?? _m.webMnListingTarget,
      webVadivamListingActual: int.tryParse(_webVadivamListingActual.text) ?? _m.webVadivamListingActual,
      webVadivamListingTarget: int.tryParse(_webVadivamListingTarget.text) ?? _m.webVadivamListingTarget,
      webCampaignActual: int.tryParse(_webCampaignActual.text) ?? _m.webCampaignActual,
      webCampaignTarget: int.tryParse(_webCampaignTarget.text) ?? _m.webCampaignTarget,
      waStoriesActual: int.tryParse(_waStoriesActual.text) ?? _m.waStoriesActual,
      waStoriesTarget: int.tryParse(_waStoriesTarget.text) ?? _m.waStoriesTarget,
      waChannelsActual: int.tryParse(_waChannelsActual.text) ?? _m.waChannelsActual,
      waChannelsTarget: int.tryParse(_waChannelsTarget.text) ?? _m.waChannelsTarget,
      waCampaignActual: int.tryParse(_waCampaignActual.text) ?? _m.waCampaignActual,
      waCampaignTarget: int.tryParse(_waCampaignTarget.text) ?? _m.waCampaignTarget,
      waBroadcastActual: int.tryParse(_waBroadcastActual.text) ?? _m.waBroadcastActual,
      waBroadcastTarget: int.tryParse(_waBroadcastTarget.text) ?? _m.waBroadcastTarget,
      appMnListingActual: int.tryParse(_appMnListingActual.text) ?? _m.appMnListingActual,
      appMnListingTarget: int.tryParse(_appMnListingTarget.text) ?? _m.appMnListingTarget,
      appVadivamListingActual: int.tryParse(_appVadivamListingActual.text) ?? _m.appVadivamListingActual,
      appVadivamListingTarget: int.tryParse(_appVadivamListingTarget.text) ?? _m.appVadivamListingTarget,
      appCampaignActual: int.tryParse(_appCampaignActual.text) ?? _m.appCampaignActual,
      appCampaignTarget: int.tryParse(_appCampaignTarget.text) ?? _m.appCampaignTarget,
      appNotificationActual: int.tryParse(_appNotificationActual.text) ?? _m.appNotificationActual,
      appNotificationTarget: int.tryParse(_appNotificationTarget.text) ?? _m.appNotificationTarget,
      googleBlogsActual: int.tryParse(_googleBlogsActual.text) ?? _m.googleBlogsActual,
      googleBlogsTarget: int.tryParse(_googleBlogsTarget.text) ?? _m.googleBlogsTarget,
      googleListingActual: int.tryParse(_googleListingActual.text) ?? _m.googleListingActual,
      googleListingTarget: int.tryParse(_googleListingTarget.text) ?? _m.googleListingTarget,
      googleCampaignActual: int.tryParse(_googleCampaignActual.text) ?? _m.googleCampaignActual,
      googleCampaignTarget: int.tryParse(_googleCampaignTarget.text) ?? _m.googleCampaignTarget,
      osmSnapchatActual: int.tryParse(_osmSnapchatActual.text) ?? _m.osmSnapchatActual,
      osmSnapchatTarget: int.tryParse(_osmSnapchatTarget.text) ?? _m.osmSnapchatTarget,
      osmPinterestActual: int.tryParse(_osmPinterestActual.text) ?? _m.osmPinterestActual,
      osmPinterestTarget: int.tryParse(_osmPinterestTarget.text) ?? _m.osmPinterestTarget,
      osmShortsActual: int.tryParse(_osmShortsActual.text) ?? _m.osmShortsActual,
      osmShortsTarget: int.tryParse(_osmShortsTarget.text) ?? _m.osmShortsTarget,
      osmLinkedinActual: int.tryParse(_osmLinkedinActual.text) ?? _m.osmLinkedinActual,
      osmLinkedinTarget: int.tryParse(_osmLinkedinTarget.text) ?? _m.osmLinkedinTarget,
      osmXPostActual: int.tryParse(_osmXPostActual.text) ?? _m.osmXPostActual,
      osmXPostTarget: int.tryParse(_osmXPostTarget.text) ?? _m.osmXPostTarget,
      designResponse: int.tryParse(_designResponse.text) ?? _m.designResponse,
      designFeedbackRating: int.tryParse(_designFeedbackRating.text) ?? _m.designFeedbackRating,
      downloadsMnActual: int.tryParse(_downloadsMnActual.text) ?? _m.downloadsMnActual,
      downloadsMnTarget: int.tryParse(_downloadsMnTarget.text) ?? _m.downloadsMnTarget,
      downloadsVadivamActual: int.tryParse(_downloadsVadivamActual.text) ?? _m.downloadsVadivamActual,
      downloadsVadivamTarget: int.tryParse(_downloadsVadivamTarget.text) ?? _m.downloadsVadivamTarget,
      followersMnActual: int.tryParse(_followersMnActual.text) ?? _m.followersMnActual,
      followersMnTarget: int.tryParse(_followersMnTarget.text) ?? _m.followersMnTarget,
      followersVadivamActual: int.tryParse(_followersVadivamActual.text) ?? _m.followersVadivamActual,
      followersVadivamTarget: int.tryParse(_followersVadivamTarget.text) ?? _m.followersVadivamTarget,
      googleReviewsActual: int.tryParse(_googleReviewsActual.text) ?? _m.googleReviewsActual,
      googleReviewsTarget: int.tryParse(_googleReviewsTarget.text) ?? _m.googleReviewsTarget,
      gokulSales: double.tryParse(_gokulSales.text) ?? _m.gokulSales,
      gokulSchemes: double.tryParse(_gokulSchemes.text) ?? _m.gokulSchemes,
      gokulGold: double.tryParse(_gokulGold.text) ?? _m.gokulGold,
      kaaviyaSales: double.tryParse(_kaaviyaSales.text) ?? _m.kaaviyaSales,
      kaaviyaSchemes: double.tryParse(_kaaviyaSchemes.text) ?? _m.kaaviyaSchemes,
      kaaviyaGold: double.tryParse(_kaaviyaGold.text) ?? _m.kaaviyaGold,
      nishaSales: double.tryParse(_nishaSales.text) ?? _m.nishaSales,
      nishaSchemes: double.tryParse(_nishaSchemes.text) ?? _m.nishaSchemes,
      nishaGold: double.tryParse(_nishaGold.text) ?? _m.nishaGold,
      ashaSales: double.tryParse(_ashaSales.text) ?? _m.ashaSales,
      ashaSchemes: double.tryParse(_ashaSchemes.text) ?? _m.ashaSchemes,
      ashaGold: double.tryParse(_ashaGold.text) ?? _m.ashaGold,
      topPerformer: _topPerformer,
    );

    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Scorecard Data',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFFDC2626),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFFDC2626),
                  tabs: const [
                    Tab(text: 'Summary (4)'),
                    Tab(text: 'Social Media'),
                    Tab(text: 'Web & WA & App'),
                    Tab(text: 'Other Targets'),
                    Tab(text: 'Team Performance'),
                  ],
                ),
                const SizedBox(height: 8),
                // Visual Legend Header to distinguish Actual vs Target
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('ACTUAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 5),
                      Text('Blue = Achieved', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF))),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('TARGET', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 5),
                      Text('Amber = Goal', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Top 4 Summary
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDualInput(
                        title: 'Total Sales and Order',
                        actualLabel: 'Actual (Rs)',
                        actualCtrl: _totalSalesActual,
                        targetLabel: 'Target (Rs)',
                        targetCtrl: _totalSalesTarget,
                      ),
                      _buildDualInput(
                        title: 'Sales Orders',
                        actualLabel: 'Actual Orders',
                        actualCtrl: _salesOrdersActual,
                        targetLabel: 'Target Orders',
                        targetCtrl: _salesOrdersTarget,
                      ),
                      _buildDualInput(
                        title: 'Scheme Conversions',
                        actualLabel: 'Actual (G)',
                        actualCtrl: _schemeConversionsActual,
                        targetLabel: 'Target (G)',
                        targetCtrl: _schemeConversionsTarget,
                      ),
                      _buildDualInput(
                        title: 'Monthly Scheme',
                        actualLabel: 'Actual (Rs)',
                        actualCtrl: _monthlySchemeActual,
                        targetLabel: 'Target (Rs)',
                        targetCtrl: _monthlySchemeTarget,
                      ),
                    ],
                  ),
                ),

                // Tab 2: Social Media (Instagram & Other Social Media)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instagram', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 10),
                      _buildDualInput(
                        title: 'Content Reel',
                        actualLabel: 'Actual Reels',
                        actualCtrl: _instaContentReelActual,
                        targetLabel: 'Target Reels (Days)',
                        targetCtrl: _instaContentReelTarget,
                        roleTag: 'VPE / OTM',
                      ),
                      _buildDualInput(
                        title: 'Product Reel',
                        actualLabel: 'Actual Reels',
                        actualCtrl: _instaProductReelActual,
                        targetLabel: 'Target Reels (Days)',
                        targetCtrl: _instaProductReelTarget,
                        roleTag: 'Ass.VPE / OTM',
                      ),
                      _buildDualInput(
                        title: 'Stories',
                        actualLabel: 'Actual Stories',
                        actualCtrl: _instaStoriesActual,
                        targetLabel: 'Target Stories',
                        targetCtrl: _instaStoriesTarget,
                        roleTag: 'OTM',
                      ),
                      _buildDualInput(
                        title: 'Carousel Post',
                        actualLabel: 'Actual Posts',
                        actualCtrl: _instaCarouselActual,
                        targetLabel: 'Target Posts',
                        targetCtrl: _instaCarouselTarget,
                        roleTag: 'OTM',
                      ),
                      _buildDualInput(
                        title: 'Active Campaign',
                        actualLabel: 'Actual Campaigns',
                        actualCtrl: _instaCampaignActual,
                        targetLabel: 'Target Campaigns',
                        targetCtrl: _instaCampaignTarget,
                        roleTag: 'OTM / AC',
                      ),
                      _buildDualInput(
                        title: 'Influencer',
                        actualLabel: 'Actual Collabs',
                        actualCtrl: _instaInfluencerActual,
                        targetLabel: 'Target Collabs',
                        targetCtrl: _instaInfluencerTarget,
                        roleTag: 'OTM / VPE',
                      ),
                      const Divider(height: 28),
                      Text('Other Social Media', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 10),
                      _buildDualInput(
                        title: 'Snapchat',
                        actualLabel: 'Actual Snaps',
                        actualCtrl: _osmSnapchatActual,
                        targetLabel: 'Target Snaps',
                        targetCtrl: _osmSnapchatTarget,
                        roleTag: 'OSH',
                      ),
                      _buildDualInput(
                        title: 'Pinterest',
                        actualLabel: 'Actual Pins',
                        actualCtrl: _osmPinterestActual,
                        targetLabel: 'Target Pins',
                        targetCtrl: _osmPinterestTarget,
                        roleTag: 'OTM',
                      ),
                      _buildDualInput(
                        title: 'Shorts',
                        actualLabel: 'Actual Shorts',
                        actualCtrl: _osmShortsActual,
                        targetLabel: 'Target Shorts',
                        targetCtrl: _osmShortsTarget,
                        roleTag: 'OTM / VPE',
                      ),
                      _buildDualInput(
                        title: 'LinkedIn',
                        actualLabel: 'Actual Posts',
                        actualCtrl: _osmLinkedinActual,
                        targetLabel: 'Target Posts',
                        targetCtrl: _osmLinkedinTarget,
                        roleTag: 'OTM',
                      ),
                      _buildDualInput(
                        title: 'X Post',
                        actualLabel: 'Actual Posts',
                        actualCtrl: _osmXPostActual,
                        targetLabel: 'Target Posts',
                        targetCtrl: _osmXPostTarget,
                        roleTag: 'OTM',
                      ),
                    ],
                  ),
                ),

                // Tab 3: Web, WhatsApp, App, Google
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Website', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 10),
                      _buildDualInput(
                        title: 'MN Listing',
                        actualLabel: 'Actual Listings',
                        actualCtrl: _webMnListingActual,
                        targetLabel: 'Target Listings',
                        targetCtrl: _webMnListingTarget,
                        roleTag: 'OTM / ECE',
                      ),
                      _buildDualInput(
                        title: 'Vadivam Listing',
                        actualLabel: 'Actual Listings',
                        actualCtrl: _webVadivamListingActual,
                        targetLabel: 'Target Listings',
                        targetCtrl: _webVadivamListingTarget,
                        roleTag: 'OTM / ECE',
                      ),
                      _buildDualInput(
                        title: 'Campaign',
                        actualLabel: 'Actual Campaigns',
                        actualCtrl: _webCampaignActual,
                        targetLabel: 'Target Campaigns',
                        targetCtrl: _webCampaignTarget,
                        roleTag: 'OTM / AC',
                      ),
                      const Divider(height: 28),
                      Text('WhatsApp', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 10),
                      _buildDualInput(
                        title: 'Stories / Status',
                        actualLabel: 'Actual Stories',
                        actualCtrl: _waStoriesActual,
                        targetLabel: 'Target Stories',
                        targetCtrl: _waStoriesTarget,
                        roleTag: 'OTM / OSH',
                      ),
                      _buildDualInput(
                        title: 'Channels',
                        actualLabel: 'Actual Channels',
                        actualCtrl: _waChannelsActual,
                        targetLabel: 'Target Channels',
                        targetCtrl: _waChannelsTarget,
                        roleTag: 'OTM / OS1',
                      ),
                      _buildDualInput(
                        title: 'Campaign',
                        actualLabel: 'Actual Campaigns',
                        actualCtrl: _waCampaignActual,
                        targetLabel: 'Target Campaigns',
                        targetCtrl: _waCampaignTarget,
                        roleTag: 'OTM / AC',
                      ),
                      _buildDualInput(
                        title: 'WhatsApp Broadcast',
                        actualLabel: 'Actual Reached',
                        actualCtrl: _waBroadcastActual,
                        targetLabel: 'Target Reached',
                        targetCtrl: _waBroadcastTarget,
                        roleTag: 'OTM',
                      ),
                      const Divider(height: 28),
                      Text('Mobile App', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 10),
                      _buildDualInput(
                        title: 'MN Listing',
                        actualLabel: 'Actual Listings',
                        actualCtrl: _appMnListingActual,
                        targetLabel: 'Target Listings',
                        targetCtrl: _appMnListingTarget,
                        roleTag: 'OTM / ECE',
                      ),
                      _buildDualInput(
                        title: 'Vadivam Listing',
                        actualLabel: 'Actual Listings',
                        actualCtrl: _appVadivamListingActual,
                        targetLabel: 'Target Listings',
                        targetCtrl: _appVadivamListingTarget,
                        roleTag: 'OTM / ECE',
                      ),
                      _buildDualInput(
                        title: 'Campaign',
                        actualLabel: 'Actual Campaigns',
                        actualCtrl: _appCampaignActual,
                        targetLabel: 'Target Campaigns',
                        targetCtrl: _appCampaignTarget,
                        roleTag: 'OTM / AC',
                      ),
                      _buildDualInput(
                        title: 'Notification',
                        actualLabel: 'Actual Sent',
                        actualCtrl: _appNotificationActual,
                        targetLabel: 'Target Sent',
                        targetCtrl: _appNotificationTarget,
                        roleTag: 'OTM / ECE',
                      ),
                      const Divider(height: 28),
                      Text('Google', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 10),
                      _buildDualInput(
                        title: 'Blogs',
                        actualLabel: 'Actual Blogs',
                        actualCtrl: _googleBlogsActual,
                        targetLabel: 'Target Blogs',
                        targetCtrl: _googleBlogsTarget,
                        roleTag: 'OTM / OSH',
                      ),
                      _buildDualInput(
                        title: 'Listing',
                        actualLabel: 'Actual Listings',
                        actualCtrl: _googleListingActual,
                        targetLabel: 'Target Listings',
                        targetCtrl: _googleListingTarget,
                        roleTag: 'Ass.VPE / OTM / AC',
                      ),
                      _buildDualInput(
                        title: 'Campaign',
                        actualLabel: 'Actual Campaigns',
                        actualCtrl: _googleCampaignActual,
                        targetLabel: 'Target Campaigns',
                        targetCtrl: _googleCampaignTarget,
                        roleTag: 'OTM / AC',
                      ),
                    ],
                  ),
                ),

                // Tab 4: Designing & Other Targets
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Designing', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 10),
                      _buildDualInput(
                        title: 'Design Responses & Feedback',
                        actualLabel: 'Total Responses',
                        actualCtrl: _designResponse,
                        targetLabel: 'Feedback Rating %',
                        targetCtrl: _designFeedbackRating,
                      ),
                      const Divider(height: 28),
                      Text('Other Targets', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 10),
                      _buildDualInput(
                        title: 'MN App Downloads',
                        actualLabel: 'Actual Downloads',
                        actualCtrl: _downloadsMnActual,
                        targetLabel: 'Target Downloads',
                        targetCtrl: _downloadsMnTarget,
                      ),
                      _buildDualInput(
                        title: 'Vadivam App Downloads',
                        actualLabel: 'Actual Downloads',
                        actualCtrl: _downloadsVadivamActual,
                        targetLabel: 'Target Downloads',
                        targetCtrl: _downloadsVadivamTarget,
                      ),
                      _buildDualInput(
                        title: 'MN Followers',
                        actualLabel: 'Actual Followers',
                        actualCtrl: _followersMnActual,
                        targetLabel: 'Target Followers',
                        targetCtrl: _followersMnTarget,
                      ),
                      _buildDualInput(
                        title: 'Vadivam Followers',
                        actualLabel: 'Actual Followers',
                        actualCtrl: _followersVadivamActual,
                        targetLabel: 'Target Followers',
                        targetCtrl: _followersVadivamTarget,
                      ),
                      _buildDualInput(
                        title: 'Google Reviews',
                        actualLabel: 'Actual Reviews',
                        actualCtrl: _googleReviewsActual,
                        targetLabel: 'Target Reviews',
                        targetCtrl: _googleReviewsTarget,
                      ),
                    ],
                  ),
                ),

                // Tab 5: Team Performance
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Performer Dropdown
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF047857), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Best Performer (Placed inside Green Circle)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF047857)),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _topPerformer,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Gokul', child: Text('Gokul')),
                                DropdownMenuItem(value: 'Kaaviya', child: Text('Kaaviya')),
                                DropdownMenuItem(value: 'Nisha', child: Text('Nisha')),
                                DropdownMenuItem(value: 'Asha', child: Text('Asha')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _topPerformer = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Gokul', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      _buildTripleInput('Sales (Rs)', _gokulSales, 'Schemes (Rs)', _gokulSchemes, 'Gold (g)', _gokulGold),
                      const SizedBox(height: 12),
                      Text('Kaaviya', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      _buildTripleInput('Sales (Rs)', _kaaviyaSales, 'Schemes (Rs)', _kaaviyaSchemes, 'Gold (g)', _kaaviyaGold),
                      const SizedBox(height: 12),
                      Text('Nisha', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      _buildTripleInput('Sales (Rs)', _nishaSales, 'Schemes (Rs)', _nishaSchemes, 'Gold (g)', _nishaGold),
                      const SizedBox(height: 12),
                      Text('Asha', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      _buildTripleInput('Sales (Rs)', _ashaSales, 'Schemes (Rs)', _ashaSchemes, 'Gold (g)', _ashaGold),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submit,
                child: Text('Save & Update Scorecard', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualInput({
    required String title,
    required String actualLabel,
    required TextEditingController actualCtrl,
    required String targetLabel,
    required TextEditingController targetCtrl,
    String? roleTag,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (roleTag != null && roleTag.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    roleTag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // ACTUAL (High Contrast Soft Blue Theme)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Soft Blue
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF93C5FD), width: 1.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 12, color: Color(0xFF1D4ED8)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'ACTUAL',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              actualLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E40AF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: actualCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A8A),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // TARGET (High Contrast Soft Amber Theme)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), // Soft Amber
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCD34D), width: 1.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag, size: 12, color: Color(0xFFB45309)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB45309),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'TARGET',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              targetLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF92400E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: targetCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF78350F),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: Color(0xFFFCD34D)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: Color(0xFFFCD34D)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: Color(0xFFB45309), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripleInput(
    String label1, TextEditingController ctrl1,
    String label2, TextEditingController ctrl2,
    String label3, TextEditingController ctrl3,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label1, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF047857))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: ctrl1,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF047857)),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFA7F3D0))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label2, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: ctrl2,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFBAE6FD))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label3, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: ctrl3,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFFDE68A))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

