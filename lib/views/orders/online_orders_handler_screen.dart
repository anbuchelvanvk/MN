import '../../core/widgets/mn_app_bar.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../models/online_order_model.dart';
import '../../providers/ecosystem_provider.dart';

class OnlineOrdersHandlerScreen extends StatefulWidget {
  final String? initialOrderId;

  const OnlineOrdersHandlerScreen({super.key, this.initialOrderId});

  @override
  State<OnlineOrdersHandlerScreen> createState() => _OnlineOrdersHandlerScreenState();
}

class _OnlineOrdersHandlerScreenState extends State<OnlineOrdersHandlerScreen> {
  String? _selectedOrderId;
  final Map<String, bool> _stageExpanded = {
    'stage1': true,
    'stage2': false,
    'stage3': false,
    'stage4': false,
    'stage5': false,
  };

  @override
  void initState() {
    super.initState();
    _selectedOrderId = widget.initialOrderId;
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final orders = eco.onlineOrders;

    final effectiveOrderId = (_selectedOrderId != null && orders.any((o) => o.orderId == _selectedOrderId))
        ? _selectedOrderId
        : (orders.isNotEmpty ? orders.first.orderId : null);

    final currentOrder = orders.firstWhereOrNull((o) => o.orderId == effectiveOrderId);

    final isOS1Absent = eco.isEmployeeAbsent('65');
    final isOS2Absent = eco.isEmployeeAbsent('67');
    final isTLOrCeo = eco.activeEmpId == 'MN-TL1002' ||
        eco.activeEmpId == 'MN-CEO01' ||
        eco.activeRole == 'dept_head' ||
        eco.activeRole == 'ceo';

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: const MnAppBar(
        title: 'Online Orders',
        subtitle: 'Track, pack and dispatch',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overdue Master Escalation Banner (Visible to all involved roles)
            if (eco.overdueOnlineOrders.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.ragRed.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.ragRed, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_on, color: AppColors.ragRed, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SLA Overdue (${eco.overdueOnlineOrders.length})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Overdue Workflow Alert',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Absentee Staff Notice Banner
            if (isOS1Absent || isOS2Absent) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEA580C), width: 1.1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_off_outlined, color: Color(0xFFEA580C), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOS1Absent && isOS2Absent
                                ? 'OS1 & OS2 Absent'
                                : (isOS1Absent ? 'OS1 Absent Today' : 'OS2 Absent Today'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTLOrCeo
                                ? 'Reassign Staff Orders'
                                : 'Requires Lead Reallocation',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFEA580C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Screen Header & Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Online Orders',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Order Tracking Workflow',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.magentaPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _openCreateOrderDialog(context, eco),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('New Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (currentOrder == null) ...[
              _buildEmptyState(context, eco),
            ] else ...[
              // Order Selector Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: orders.map((ord) {
                    final isSelected = ord.orderId == currentOrder.orderId;
                    final isVadivam = ord.brand == 'Vadivam';
                    final brandColor = isVadivam ? const Color(0xFF38BDF8) : AppColors.sandGold;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedOrderId = ord.orderId),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? brandColor.withOpacity(0.15) : AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? brandColor : AppColors.sandBorder,
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ord.hasAnyOverdueStage ? AppColors.ragRed : brandColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ord.orderId,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? AppColors.textDark : AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${ord.brand} • ${ord.completedCount}/38',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? brandColor : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Active Order Summary Card (First 4 Questions + 5th Brand + 6th Delivery Date)
              LiquidGlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Reassignment Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: currentOrder.brand == 'Vadivam'
                                      ? const Color(0xFF38BDF8).withOpacity(0.2)
                                      : AppColors.sandGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  currentOrder.brand == 'Vadivam' ? Icons.diamond_outlined : Icons.auto_awesome,
                                  size: 18,
                                  color: currentOrder.brand == 'Vadivam' ? const Color(0xFF38BDF8) : AppColors.sandGold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${currentOrder.orderId}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      currentOrder.customerName,
                                      style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentOrder.brand == 'Vadivam'
                                ? const Color(0xFF38BDF8).withOpacity(0.18)
                                : AppColors.sandGold.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: currentOrder.brand == 'Vadivam' ? const Color(0xFF38BDF8) : AppColors.sandGold,
                            ),
                          ),
                          child: Text(
                            currentOrder.brand,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: currentOrder.brand == 'Vadivam' ? const Color(0xFF38BDF8) : AppColors.sandGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 6 Core Order Fields Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _metaField('Order ID', currentOrder.orderId, Icons.tag)),
                              const SizedBox(width: 10),
                              Expanded(child: _metaField('Customer Name', currentOrder.customerName, Icons.person_outline)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _metaField('Sales Channel', currentOrder.salesChannel, Icons.forum_outlined)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metaField(
                                  'Handled By',
                                  currentOrder.reallocatedToName != null
                                      ? '${currentOrder.reallocatedToName} (Reallocated)'
                                      : '${currentOrder.handledByName} (${currentOrder.primaryResponsibleRole})',
                                  Icons.badge_outlined,
                                  highlightColor: currentOrder.reallocatedToName != null
                                      ? const Color(0xFF38BDF8)
                                      : (currentOrder.brand == 'Vadivam' ? const Color(0xFF38BDF8) : AppColors.sandGold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _metaField(
                                  '5. Brand / Unit',
                                  currentOrder.brand,
                                  Icons.storefront_outlined,
                                  subtitle: currentOrder.brand == 'Vadivam' ? 'Responsible: OS2 Nisha' : 'Responsible: OS1 Kaaviya',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metaField(
                                  '6. Category',
                                  currentOrder.jewelleryCategory ?? 'Pendant',
                                  Icons.diamond_outlined,
                                  highlightColor: const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _metaField(
                                  '7. Expected Delivery',
                                  currentOrder.expectedDeliveryDate.isNotEmpty ? currentOrder.expectedDeliveryDate : 'Not specified',
                                  Icons.calendar_today_outlined,
                                  highlightColor: AppColors.sandGold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6. Dynamic Customer Jewellery Specifications Card
                    if (currentOrder.jewelleryCategory != null &&
                        currentOrder.jewelleryRequirements != null &&
                        currentOrder.jewelleryRequirements!.isNotEmpty) ...[
                      _buildJewellerySpecificationsCard(context, currentOrder),
                      const SizedBox(height: 14),
                    ],

                    // Overall Order Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Progress',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        Flexible(
                          child: Text(
                            '${currentOrder.completedCount}/38 (${(currentOrder.progressPercentage * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: currentOrder.progressPercentage,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          currentOrder.completedCount == 38 ? AppColors.ragGreen : AppColors.sandGold,
                        ),
                      ),
                    ),

                    // TL Reassign Button (If TL or CEO and primary handler is absent or reallocating)
                    if (isTLOrCeo) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.sandGold,
                          side: const BorderSide(color: AppColors.sandGold, width: 1.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                        onPressed: () => _openReassignDialog(context, eco, currentOrder),
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: Text(
                          currentOrder.reallocatedToName != null
                              ? 'Reassigned: ${currentOrder.reallocatedToName}'
                              : 'Reassign Order',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5 Subcategory Stages with Individual Due Dates
              ...['stage1', 'stage2', 'stage3', 'stage4', 'stage5'].map((stageId) {
                final stage = currentOrder.stages[stageId];
                if (stage == null) return const SizedBox.shrink();
                return _buildStageCard(context, eco, currentOrder, stage);
              }),
              const SizedBox(height: 16),

              // Bottom Utility Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.sandBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _confirmResetDialog(context, eco, currentOrder),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magentaPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () => _copyChecklistToClipboard(context, currentOrder),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _metaField(String label, String value, IconData icon, {Color? highlightColor, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: highlightColor ?? AppColors.textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildJewellerySpecificationsCard(BuildContext context, OnlineOrderModel order) {
    final cat = order.jewelleryCategory ?? 'Jewellery';
    final reqs = order.jewelleryRequirements ?? {};

    String footerTagline;
    if (cat == 'Pendant') {
      footerTagline = '* Required fields. Reference images can be shared separately through WhatsApp.';
    } else if (cat == 'Chain') {
      footerTagline = 'Our team will review your requirements and assist you with the design, estimated weight and quotation.';
    } else if (cat == 'Bracelet') {
      footerTagline = 'VADIVAM by MN Jewel Park | Your Idea. Your Design. Our Craftsmanship.';
    } else {
      footerTagline = 'Please share your design reference images along with the completed requirements, if available.';
    }

    void copyDetails() {
      final sb = StringBuffer();
      sb.writeln('--- $cat Requirements ---');
      sb.writeln('Order ID: ${order.orderId}');
      sb.writeln('Customer: ${order.customerName}');
      sb.writeln('Category: $cat');
      reqs.forEach((k, v) {
        if (v != null && v.toString().trim().isNotEmpty) {
          sb.writeln('$k: $v');
        }
      });
      sb.writeln(footerTagline);
      Clipboard.setData(ClipboardData(text: sb.toString()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('$cat requirements copied to clipboard!'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.diamond_outlined, size: 16, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '6. $cat Specifications',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Custom Client Order Requirements',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: copyDetails,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.magentaSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.magentaPrimary.withOpacity(0.3), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.copy, size: 12, color: AppColors.magentaPrimary),
                      SizedBox(width: 4),
                      Text(
                        'Copy Enquiry Details',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.magentaPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 20),
          ...reqs.entries.where((e) => e.value != null && e.value.toString().trim().isNotEmpty).map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      '${e.key}:',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: Text(
                      '${e.value}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    footerTagline,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    EcosystemProvider eco,
    OnlineOrderModel order,
    OrderStageInfo stage,
  ) {
    final stageItems = order.checklist.where((c) => c.stageId == stage.stageId).toList();
    final completedCount = stageItems.where((c) => c.isCompleted).length;
    final isCompleted = stageItems.isNotEmpty && completedCount == stageItems.length;
    final isOverdue = order.isStageOverdue(stage.stageId);
    final isExpanded = _stageExpanded[stage.stageId] ?? false;

    Color stageColor = isOverdue
        ? AppColors.ragRed
        : (isCompleted ? AppColors.ragGreen : AppColors.sandGold);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? AppColors.ragRed : (isCompleted ? AppColors.ragGreen.withOpacity(0.4) : Colors.white10),
          width: isOverdue ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Stage Header & SLA Due Date Row
          InkWell(
            onTap: () => setState(() => _stageExpanded[stage.stageId] = !isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: stageColor.withOpacity(0.18),
                                border: Border.all(color: stageColor, width: 1.2),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, size: 13, color: AppColors.ragGreen)
                                    : Text(
                                        '${stage.index}',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: stageColor),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${stage.index}. ${stage.stageName}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCompleted ? AppColors.ragGreen.withOpacity(0.12) : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCompleted ? AppColors.ragGreen.withOpacity(0.3) : AppColors.sandBorder,
                              ),
                            ),
                            child: Text(
                              '$completedCount/${stage.totalItems}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? AppColors.ragGreen : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stage Target Due Date & Overdue Alert
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectStageDueDate(context, eco, order, stage),
                          child: Row(
                            children: [
                              Icon(Icons.event, size: 13, color: isOverdue ? AppColors.ragRed : AppColors.sandGold),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Due: ${stage.dueDate.isNotEmpty ? stage.dueDate : "Set Due"}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isOverdue ? AppColors.ragRed : AppColors.sandLight,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.ragRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'OVERDUE',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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

          // Checklist Items (Expanded)
          if (isExpanded) ...[
            const Divider(color: AppColors.sandBorder, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: stageItems.map((item) {
                  return InkWell(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final actingEmpId = eco.activeEmpId;
                      final err = await eco.toggleOrderItemCompletion(
                        orderId: order.orderId,
                        itemId: item.id,
                        actingEmpId: actingEmpId,
                      );

                      if (err != null && mounted) {
                        // User requirement: Crisp red warning when handler is absent, advising TL approach
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.ragRed,
                            duration: const Duration(seconds: 4),
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    err,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            action: SnackBarAction(
                              label: 'Notify TL',
                              textColor: Colors.white,
                              onPressed: () {
                                eco.requestOrderReassignment(order);
                              },
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isCompleted ? AppColors.ragGreen : Colors.white.withOpacity(0.04),
                              border: Border.all(
                                color: item.isCompleted ? AppColors.ragGreen : Colors.white38,
                                width: 1.2,
                              ),
                            ),
                            child: item.isCompleted
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: item.isCompleted ? const Color(0xFF64748B) : Colors.white,
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectStageDueDate(
    BuildContext context,
    EcosystemProvider eco,
    OnlineOrderModel order,
    OrderStageInfo stage,
  ) async {
    final now = DateTime.now();
    DateTime initial = now;
    try {
      if (stage.dueDate.isNotEmpty) initial = DateTime.parse(stage.dueDate);
    } catch (_) {}
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now.add(const Duration(days: 365 * 5));
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.magentaPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      eco.updateOrderStageDueDate(order.orderId, stage.stageId, formatted);
    }
  }

  void _openCreateOrderDialog(BuildContext context, EcosystemProvider eco) {
    final orderIdCtrl = TextEditingController(text: 'ORD-MN-${DateFormat('yyMMdd-HHmmss').format(DateTime.now())}');
    String? formError;
    final customerCtrl = TextEditingController();
    String salesChannel = 'WhatsApp';
    String brand = 'MN Jewel Park'; // 'Vadivam' or 'MN Jewel Park'
    String selectedCategory = 'Pendant'; // 'Pendant', 'Chain', 'Bracelet', 'Earrings'

    // 1. Pendant state
    String pendantType = 'Name Pendant';
    String pendantPurity = '22K';
    final pendantWeightCtrl = TextEditingController();
    final pendantBudgetCtrl = TextEditingController();
    String pendantDesignPref = 'New customised design';
    String pendantPurchaseReq = 'Pendant only';
    String pendantPurpose = 'Personal use';
    String pendantRefImage = 'I have a reference image';
    final pendantAdditionalCtrl = TextEditingController();

    // 2. Chain state
    String chainType = 'Gold Chain';
    String chainPurity = '22K';
    final chainWeightCtrl = TextEditingController();
    String chainLength = '18 inches';
    String chainDesignRef = 'As per reference image';
    String chainPurpose = 'Regular wear';
    final chainBudgetCtrl = TextEditingController();
    final chainAdditionalCtrl = TextEditingController();

    // 3. Bracelet state
    String braceletType = 'Gold Bracelet';
    String braceletPurity = '22K';
    final braceletWeightCtrl = TextEditingController();
    final braceletSizeCtrl = TextEditingController();
    final braceletLengthCtrl = TextEditingController();
    String braceletDesignRef = 'I have a reference image';
    String braceletStonePref = 'Without stones';
    String braceletUsage = 'Regular use';
    final braceletBudgetCtrl = TextEditingController();
    String braceletUploadRef = 'I have a reference image';
    final braceletAdditionalCtrl = TextEditingController();

    // 4. Earrings state
    String earringType = 'Studs';
    String earringPurity = '22K';
    String earringPurchasePref = 'Pair';
    String earringStonePref = 'With Stones';
    String earringBackType = 'Push Back';
    String earringUsage = 'Regular Wear';
    final earringAdditionalCtrl = TextEditingController();

    final deliveryCtrl = TextEditingController(
      text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${(DateTime.now().day + 5).toString().padLeft(2, '0')}',
    );

    // Initial 5 subcategory due dates
    final now = DateTime.now();
    String fmt(DateTime dt) =>
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final stage1DueCtrl = TextEditingController(text: fmt(now.add(const Duration(days: 1))));
    final stage2DueCtrl = TextEditingController(text: fmt(now.add(const Duration(days: 2))));
    final stage3DueCtrl = TextEditingController(text: fmt(now.add(const Duration(days: 3))));
    final stage4DueCtrl = TextEditingController(text: fmt(now.add(const Duration(days: 4))));
    final stage5DueCtrl = TextEditingController(text: fmt(now.add(const Duration(days: 5))));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isVadivam = brand == 'Vadivam';
            final autoHandlerId = isVadivam ? '67' : '65';
            final autoHandlerName = isVadivam ? 'Nisha (OS2)' : 'Kaaviya (OS1)';

            Map<String, dynamic> buildCurrentCategoryData() {
              if (selectedCategory == 'Pendant') {
                return {
                  'Pendant Type': pendantType,
                  'Gold Purity': pendantPurity,
                  'Preferred Gold Weight': pendantWeightCtrl.text.trim(),
                  'Approximate Budget': pendantBudgetCtrl.text.trim(),
                  'Design Preference': pendantDesignPref,
                  'Purchase Requirement': pendantPurchaseReq,
                  'Purpose of Purchase': pendantPurpose,
                  'Reference Image Availability': pendantRefImage,
                  'Additional Requirements': pendantAdditionalCtrl.text.trim(),
                };
              } else if (selectedCategory == 'Chain') {
                return {
                  'Chain Type': chainType,
                  'Gold Purity': chainPurity,
                  'Expected Weight': chainWeightCtrl.text.trim(),
                  'Required Chain Length': chainLength,
                  'Design Reference': chainDesignRef,
                  'Purpose of Use': chainPurpose,
                  'Expected Budget': chainBudgetCtrl.text.trim(),
                  'Additional Requirements': chainAdditionalCtrl.text.trim(),
                };
              } else if (selectedCategory == 'Bracelet') {
                return {
                  'Bracelet Type': braceletType,
                  'Required Purity': braceletPurity,
                  'Approximate Weight Preference': braceletWeightCtrl.text.trim(),
                  'Bracelet Size': braceletSizeCtrl.text.trim(),
                  'Preferred Bracelet Length': braceletLengthCtrl.text.trim(),
                  'Design Reference': braceletDesignRef,
                  'Stone Preference': braceletStonePref,
                  'Usage': braceletUsage,
                  'Expected Budget': braceletBudgetCtrl.text.trim(),
                  'Upload / Share Reference': braceletUploadRef,
                  'Additional Requirements': braceletAdditionalCtrl.text.trim(),
                };
              } else {
                return {
                  'Type of Earrings': earringType,
                  'Preferred Gold Purity': earringPurity,
                  'Purchase Preference': earringPurchasePref,
                  'Stone Preference': earringStonePref,
                  'Earring Back Type': earringBackType,
                  'Intended Usage': earringUsage,
                  'Additional Requirements': earringAdditionalCtrl.text.trim(),
                };
              }
            }

            void copyEnquiryToClipboard() {
              final data = buildCurrentCategoryData();
              final sb = StringBuffer();
              sb.writeln('📋 *MN JEWEL PARK / VADIVAM - ONLINE ENQUIRY DETAILS*');
              sb.writeln('Customer: ${customerCtrl.text.trim().isNotEmpty ? customerCtrl.text.trim() : "Prospective Client"}');
              sb.writeln('Category: $selectedCategory');
              sb.writeln('----------------------------------------');
              data.forEach((k, v) {
                if (v != null && v.toString().trim().isNotEmpty) {
                  sb.writeln('• $k: $v');
                }
              });
              sb.writeln('----------------------------------------');
              if (selectedCategory == 'Pendant') {
                sb.writeln('* Required fields. Reference images can be shared separately through WhatsApp.');
              } else if (selectedCategory == 'Chain') {
                sb.writeln('Our team will review your requirements and assist you with the design, estimated weight and quotation.');
              } else if (selectedCategory == 'Bracelet') {
                sb.writeln('VADIVAM by MN Jewel Park | Your Idea. Your Design. Our Craftsmanship.');
              } else {
                sb.writeln('Please share your design reference images along with the completed requirements, if available.');
              }

              Clipboard.setData(ClipboardData(text: sb.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF10B981),
                  content: Text('Enquiry details copied to clipboard!'),
                ),
              );
            }

            return Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Create Online Order Workflow',
                            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 1. Order ID
                    const Text('1. Order ID / Number', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: orderIdCtrl,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Customer Name
                    const Text('2. Customer Name', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: customerCtrl,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'e.g. Mrs. Priya Sundaram',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Sales Channel
                    const Text('3. Sales Channel', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: salesChannel,
                      dropdownColor: AppColors.burgundySurface,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      ),
                      items: ['WhatsApp', 'Website', 'Instagram', 'Direct Call', 'Showroom'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => salesChannel = v);
                      },
                    ),
                    const SizedBox(height: 10),

                    // 4. Brand (Vadivam or MN Jewel Park)
                    const Text('4. Brand / Unit (Mandatory)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: brand,
                      dropdownColor: AppColors.burgundySurface,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MN Jewel Park', child: Text('MN Jewel Park (Handled by OS1 Kaaviya)')),
                        DropdownMenuItem(value: 'Vadivam', child: Text('Vadivam (Handled by OS2 Nisha)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => brand = v);
                      },
                    ),
                    const SizedBox(height: 10),

                    // 5. Handled By (Auto-locked to responsible role per rules)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.magentaSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.magentaBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge, size: 16, color: AppColors.magentaPrimary),
                          const SizedBox(width: 8),
                          Text(
                            '5. Handled by: $autoHandlerName (Auto-assigned)',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6. NEW 6TH SECTION: Jewellery Category Dropdown & Dynamic Requirements
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.magentaPrimary.withOpacity(0.35), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.diamond_outlined, size: 16, color: AppColors.magentaPrimary),
                                  SizedBox(width: 6),
                                  Text(
                                    '6. Jewellery Category',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.magentaSubtle,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 12, color: AppColors.magentaPrimary),
                                label: const Text('Copy Enquiry Details', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary)),
                                onPressed: copyEnquiryToClipboard,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Category Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppColors.textDark, fontSize: 12.5, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Select Jewellery Type',
                              labelStyle: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.magentaPrimary)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Pendant', child: Text('1. Pendant Requirements')),
                              DropdownMenuItem(value: 'Chain', child: Text('2. Chain Requirements')),
                              DropdownMenuItem(value: 'Bracelet', child: Text('3. Bracelet Requirements')),
                              DropdownMenuItem(value: 'Earrings', child: Text('4. Earring Requirements')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedCategory = v);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Dynamic Category Form
                          if (selectedCategory == 'Pendant') ...[
                            // Pendant Type *
                            _formDropdown(
                              label: 'Pendant Type *',
                              value: pendantType,
                              items: const ['Name Pendant', 'Initial Pendant', 'God / Divine Pendant', 'Photo / Face Pendant', 'Couple Pendant', 'Mugappu Pendant', 'Custom Design'],
                              onChanged: (v) => setModalState(() => pendantType = v!),
                            ),
                            const SizedBox(height: 14),
                            // Gold Purity Preference
                            _formDropdown(
                              label: 'Gold Purity Preference',
                              value: pendantPurity,
                              items: const ['22K', '18K', 'Not decided'],
                              onChanged: (v) => setModalState(() => pendantPurity = v!),
                            ),
                            const SizedBox(height: 14),
                            // Preferred Gold Weight & Budget
                            Row(
                              children: [
                                Expanded(
                                  child: _formTextField(
                                    label: 'Preferred Gold Weight',
                                    hint: 'e.g. 4.5 grams',
                                    controller: pendantWeightCtrl,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _formTextField(
                                    label: 'Approximate Budget',
                                    hint: 'e.g. ₹25,000',
                                    controller: pendantBudgetCtrl,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Design Preference
                            _formDropdown(
                              label: 'Design Preference',
                              value: pendantDesignPref,
                              items: const ['New customised design', 'Based on reference image', 'Modify an existing design'],
                              onChanged: (v) => setModalState(() => pendantDesignPref = v!),
                            ),
                            const SizedBox(height: 14),
                            // Purchase Requirement
                            _formDropdown(
                              label: 'Purchase Requirement',
                              value: pendantPurchaseReq,
                              items: const ['Pendant only', 'Pendant with chain', 'Not decided'],
                              onChanged: (v) => setModalState(() => pendantPurchaseReq = v!),
                            ),
                            const SizedBox(height: 14),
                            // Purpose of Purchase
                            _formDropdown(
                              label: 'Purpose of Purchase',
                              value: pendantPurpose,
                              items: const ['Personal use', 'Gift', 'Wedding / Special occasion', 'Other'],
                              onChanged: (v) => setModalState(() => pendantPurpose = v!),
                            ),
                            const SizedBox(height: 14),
                            // Reference Image Availability
                            _formDropdown(
                              label: 'Reference Image Availability',
                              value: pendantRefImage,
                              items: const ['I have a reference image', 'I will share later', 'I need design suggestions'],
                              onChanged: (v) => setModalState(() => pendantRefImage = v!),
                            ),
                            const SizedBox(height: 14),
                            // Additional Requirements
                            _formTextField(
                              label: 'Additional Requirements',
                              hint: 'Enter special instructions, font, dimensions...',
                              controller: pendantAdditionalCtrl,
                            ),
                            const SizedBox(height: 10),
                            const Text('* Required fields. Reference images can be shared separately through WhatsApp.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                          ] else if (selectedCategory == 'Chain') ...[
                            // Chain Type
                            _formDropdown(
                              label: 'Chain Type',
                              value: chainType,
                              items: const ['Gold Chain', 'Silver Chain', 'Chain with Pendant', 'Other'],
                              onChanged: (v) => setModalState(() => chainType = v!),
                            ),
                            const SizedBox(height: 14),
                            // Gold Purity
                            _formDropdown(
                              label: 'Gold Purity',
                              value: chainPurity,
                              items: const ['22K', '18K', 'Not decided'],
                              onChanged: (v) => setModalState(() => chainPurity = v!),
                            ),
                            const SizedBox(height: 14),
                            // Expected Weight & Length
                            Row(
                              children: [
                                Expanded(
                                  child: _formTextField(
                                    label: 'Expected Weight',
                                    hint: 'e.g. 12 grams',
                                    controller: chainWeightCtrl,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Required Chain Length',
                                    value: chainLength,
                                    items: const ['16 inches', '18 inches', '20 inches', '22 inches', 'Other / Not decided'],
                                    onChanged: (v) => setModalState(() => chainLength = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Design Reference
                            _formDropdown(
                              label: 'Design Reference',
                              value: chainDesignRef,
                              items: const ['As per reference image', 'Simple & Elegant', 'Traditional', 'Fancy / Trendy', 'Create a new design'],
                              onChanged: (v) => setModalState(() => chainDesignRef = v!),
                            ),
                            const SizedBox(height: 14),
                            // Purpose of Use & Budget
                            Row(
                              children: [
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Purpose of Use',
                                    value: chainPurpose,
                                    items: const ['Regular wear', 'Occasional wear', 'Special occasion / Gift'],
                                    onChanged: (v) => setModalState(() => chainPurpose = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _formTextField(
                                    label: 'Expected Budget (Optional)',
                                    hint: 'e.g. ₹60,000',
                                    controller: chainBudgetCtrl,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _formTextField(
                              label: 'Additional Requirements',
                              hint: 'Thickness, link pattern, clasp type...',
                              controller: chainAdditionalCtrl,
                            ),
                            const SizedBox(height: 10),
                            const Text('Our team will review your requirements and assist you with the design, estimated weight and quotation.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                          ] else if (selectedCategory == 'Bracelet') ...[
                            // Bracelet Type & Purity
                            Row(
                              children: [
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Bracelet Type',
                                    value: braceletType,
                                    items: const ['Gold Bracelet', 'Silver Bracelet', 'Other'],
                                    onChanged: (v) => setModalState(() => braceletType = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Required Purity',
                                    value: braceletPurity,
                                    items: const ['22K', '18K', '14K', 'Other'],
                                    onChanged: (v) => setModalState(() => braceletPurity = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Weight & Size & Length
                            Row(
                              children: [
                                Expanded(
                                  child: _formTextField(
                                    label: 'Weight Preference',
                                    hint: 'e.g. 15g',
                                    controller: braceletWeightCtrl,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _formTextField(
                                    label: 'Bracelet Size',
                                    hint: 'e.g. 2.4 / 2.6',
                                    controller: braceletSizeCtrl,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _formTextField(
                                    label: 'Length',
                                    hint: 'e.g. 7 inches',
                                    controller: braceletLengthCtrl,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Design Reference
                            _formDropdown(
                              label: 'Design Reference',
                              value: braceletDesignRef,
                              items: const ['I have a reference image', 'Modify an existing design', 'Create a new design', 'Need design suggestions'],
                              onChanged: (v) => setModalState(() => braceletDesignRef = v!),
                            ),
                            const SizedBox(height: 14),
                            // Stone Preference
                            _formDropdown(
                              label: 'Stone Preference',
                              value: braceletStonePref,
                              items: const ['Without stones', 'With natural stones', 'With diamonds', 'With CZ / American diamonds', 'Open to suggestions'],
                              onChanged: (v) => setModalState(() => braceletStonePref = v!),
                            ),
                            const SizedBox(height: 14),
                            // Usage & Budget
                            Row(
                              children: [
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Usage',
                                    value: braceletUsage,
                                    items: const ['Regular use', 'Occasional use', 'Special occasion'],
                                    onChanged: (v) => setModalState(() => braceletUsage = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _formTextField(
                                    label: 'Expected Budget',
                                    hint: 'e.g. ₹80,000',
                                    controller: braceletBudgetCtrl,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _formDropdown(
                              label: 'Upload / Share Design Reference',
                              value: braceletUploadRef,
                              items: const ['I have a reference image', 'Will share via WhatsApp', 'Need suggestions'],
                              onChanged: (v) => setModalState(() => braceletUploadRef = v!),
                            ),
                            const SizedBox(height: 14),
                            _formTextField(
                              label: 'Additional Requirements',
                              hint: 'Kada, flexible, lock type...',
                              controller: braceletAdditionalCtrl,
                            ),
                            const SizedBox(height: 10),
                            const Text('VADIVAM by MN Jewel Park | Your Idea. Your Design. Our Craftsmanship.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                          ] else ...[
                            // Earrings: Type & Purity
                            Row(
                              children: [
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Type of Earrings',
                                    value: earringType,
                                    items: const ['Studs', 'Drop Earrings', 'Hanging Earrings', 'Jhumkas', 'Hoop Earrings', 'Other'],
                                    onChanged: (v) => setModalState(() => earringType = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Preferred Gold Purity',
                                    value: earringPurity,
                                    items: const ['22K', '18K', '14K', 'Not Sure'],
                                    onChanged: (v) => setModalState(() => earringPurity = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Purchase Preference & Stone Preference
                            Row(
                              children: [
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Purchase Preference',
                                    value: earringPurchasePref,
                                    items: const ['Pair', 'Single Piece'],
                                    onChanged: (v) => setModalState(() => earringPurchasePref = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Stone Preference',
                                    value: earringStonePref,
                                    items: const ['With Stones', 'Without Stones', 'Natural Gemstones', 'Diamonds', 'Not Decided'],
                                    onChanged: (v) => setModalState(() => earringStonePref = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Earring Back Type & Intended Usage
                            Row(
                              children: [
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Earring Back Type',
                                    value: earringBackType,
                                    items: const ['Push Back', 'Screw Back', 'Clip-on', 'Not Sure'],
                                    onChanged: (v) => setModalState(() => earringBackType = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _formDropdown(
                                    label: 'Intended Usage',
                                    value: earringUsage,
                                    items: const ['Regular Wear', 'Occasional Wear', 'Party / Bridal Wear'],
                                    onChanged: (v) => setModalState(() => earringUsage = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _formTextField(
                              label: 'Additional Requirements',
                              hint: 'Special requests, design notes...',
                              controller: earringAdditionalCtrl,
                            ),
                            const SizedBox(height: 10),
                            const Text('Please share your design reference images along with the completed requirements, if available.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 7. MOVED TO 7TH POSITION: Expected Delivery Date
                    const Text('7. Expected Delivery Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: deliveryCtrl,
                      readOnly: true,
                      onTap: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 5)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (p != null) {
                          setModalState(() => deliveryCtrl.text = fmt(p));
                        }
                      },
                      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.magentaPrimary),
                          onPressed: () async {
                            final p = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 5)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (p != null) {
                              setModalState(() => deliveryCtrl.text = fmt(p));
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Subcategory Due Dates (Customer Verification, Product Verification, etc.)
                    const Text('SLA Target Due Dates for 5 Subcategories:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    _subDateInput('1. Customer Verification Due', stage1DueCtrl, fmt),
                    _subDateInput('2. Product Verification Due', stage2DueCtrl, fmt),
                    _subDateInput('3. Payment & Billing Due', stage3DueCtrl, fmt),
                    _subDateInput('4. Packing & Dispatch Due', stage4DueCtrl, fmt),
                    _subDateInput('5. Delivery & Customer Closure Due', stage5DueCtrl, fmt),
                    const SizedBox(height: 16),

                    if (formError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          formError!,
                          style: const TextStyle(color: AppColors.ragRed, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magentaPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        // Errors are shown inside the sheet (a SnackBar would be hidden behind it)
                        final newId = orderIdCtrl.text.trim();
                        if (newId.isEmpty) {
                          setModalState(() => formError = 'Please enter an order ID.');
                          return;
                        }
                        if (newId.contains('/')) {
                          setModalState(() => formError = 'Order ID cannot contain "/".');
                          return;
                        }
                        if (eco.onlineOrders.any((o) => o.orderId.toLowerCase() == newId.toLowerCase())) {
                          setModalState(() => formError = 'Order #$newId already exists. Use a different order ID.');
                          return;
                        }
                        if (customerCtrl.text.trim().isEmpty) {
                          setModalState(() => formError = 'Please enter customer name.');
                          return;
                        }

                        final stages = OnlineOrderModel.createDefaultStages();
                        stages['stage1']?.dueDate = stage1DueCtrl.text.trim();
                        stages['stage2']?.dueDate = stage2DueCtrl.text.trim();
                        stages['stage3']?.dueDate = stage3DueCtrl.text.trim();
                        stages['stage4']?.dueDate = stage4DueCtrl.text.trim();
                        stages['stage5']?.dueDate = stage5DueCtrl.text.trim();

                        final reqMap = buildCurrentCategoryData();

                        final newOrder = OnlineOrderModel(
                          orderId: newId,
                          customerName: customerCtrl.text.trim(),
                          salesChannel: salesChannel,
                          handledByEmpId: autoHandlerId,
                          handledByName: eco.employees.firstWhereOrNull((e) => e.id == autoHandlerId)?.name ??
                              (isVadivam ? 'Nisha' : 'Kaaviya'),
                          brand: brand,
                          jewelleryCategory: selectedCategory,
                          jewelleryRequirements: reqMap,
                          expectedDeliveryDate: deliveryCtrl.text.trim(),
                          createdAt: fmt(DateTime.now()),
                          stages: stages,
                          checklist: OnlineOrderModel.createDefaultChecklist(),
                        );

                        eco.createOnlineOrder(newOrder);
                        Navigator.pop(ctx);
                        setState(() => _selectedOrderId = newOrder.orderId);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.ragGreen,
                            content: Text('Order #${newOrder.orderId} ($selectedCategory) created for $brand!'),
                          ),
                        );
                      },
                      child: const Text('Create Order Workflow', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _formDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      dropdownColor: Colors.white,
      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.magentaPrimary)),
      ),
      items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _formTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.magentaPrimary)),
      ),
    );
  }

  Widget _subDateInput(String label, TextEditingController ctrl, String Function(DateTime) fmt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: ctrl,
                // Pick from a calendar so the value is always a parseable date
                readOnly: true,
                onTap: () async {
                  final now = DateTime.now();
                  final current = DateTime.tryParse(ctrl.text.trim());
                  final p = await showDatePicker(
                    context: context,
                    initialDate: current != null && !current.isBefore(DateTime(now.year, now.month, now.day))
                        ? current
                        : now,
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (p != null) ctrl.text = fmt(p);
                },
                style: const TextStyle(color: AppColors.textDark, fontSize: 11),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.sandBorder)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReassignDialog(BuildContext context, EcosystemProvider eco, OnlineOrderModel order) {
    final staffList = eco.employees.where((e) => e.roleType == 'employee' || e.roleType == 'team_lead').toList();
    String selectedEmp = staffList.isNotEmpty ? staffList.first.id : '67';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.sandGold, width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.swap_horiz, color: AppColors.sandGold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TL Reassign Order #${order.orderId}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Primary Handler for ${order.brand} is ${order.primaryResponsibleRole}. Use this if the staff is absent or overloaded to maintain SLA.',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 12),
              const Text('Reassign To Available Staff Member:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedEmp,
                dropdownColor: AppColors.burgundySurface,
                style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                ),
                items: staffList.map((e) {
                  final isAbsent = eco.isEmployeeAbsent(e.id);
                  return DropdownMenuItem(
                    value: e.id,
                    child: Text('${e.name} (${e.role}) ${isAbsent ? "[ABSENT]" : ""}'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedEmp = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                foregroundColor: AppColors.burgundyBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final newEmp = eco.employees.firstWhereOrNull((e) => e.id == selectedEmp);
                if (newEmp == null) return;
                final messenger = ScaffoldMessenger.of(context);
                eco.reassignOnlineOrder(
                  orderId: order.orderId,
                  newEmpId: newEmp.id,
                  newEmpName: newEmp.name,
                  authorizedBy: eco.currentEmployee.name,
                );
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.ragGreen,
                    content: Text('Order #${order.orderId} reallocated to ${newEmp.name}!'),
                  ),
                );
              },
              child: const Text('Confirm Reallocation', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetDialog(BuildContext context, EcosystemProvider eco, OnlineOrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.sandBorder)),
        title: const Text('Reset Checklist?', style: TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to clear all checked items for this order?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ragRed, foregroundColor: Colors.white),
            onPressed: () {
              eco.resetOrderChecklist(order.orderId);
              Navigator.pop(ctx);
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _copyChecklistToClipboard(BuildContext context, OnlineOrderModel order) {
    final buffer = StringBuffer();
    buffer.writeln('MN JEWEL PARK / VADIVAM ONLINE ORDER CHECKLIST');
    buffer.writeln('Order ID: ${order.orderId} | Brand: ${order.brand}');
    buffer.writeln('Customer: ${order.customerName} | Channel: ${order.salesChannel}');
    buffer.writeln('Delivery Date: ${order.expectedDeliveryDate}');
    buffer.writeln('Progress: ${order.completedCount}/38 completed\n');

    for (final stageId in ['stage1', 'stage2', 'stage3', 'stage4', 'stage5']) {
      final stage = order.stages[stageId];
      if (stage == null) continue;
      buffer.writeln('--- ${stage.index}. ${stage.stageName} (Target Due: ${stage.dueDate}) ---');
      final items = order.checklist.where((c) => c.stageId == stageId).toList();
      for (final item in items) {
        buffer.writeln('${item.isCompleted ? "[x]" : "[ ]"} ${item.title}');
      }
      buffer.writeln('');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order checklist copied to clipboard!'),
        backgroundColor: AppColors.ragGreen,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, EcosystemProvider eco) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: LiquidGlassCard(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sandGold.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: AppColors.sandGold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Online orders will appear here once booked or synced from store.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.sandLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.magentaPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => _openCreateOrderDialog(context, eco),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'Create Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
