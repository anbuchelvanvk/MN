import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/role_app_bar.dart';
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

    if (_selectedOrderId == null && orders.isNotEmpty) {
      _selectedOrderId = orders.first.orderId;
    } else if (orders.isNotEmpty && !orders.any((o) => o.orderId == _selectedOrderId)) {
      _selectedOrderId = orders.first.orderId;
    }

    final currentOrder = orders.isNotEmpty
        ? orders.firstWhere(
            (o) => o.orderId == _selectedOrderId,
            orElse: () => orders.first,
          )
        : null;

    final isOS1Absent = eco.isEmployeeAbsent('MN-1007');
    final isOS2Absent = eco.isEmployeeAbsent('MN-1008');
    final isTLOrCeo = eco.activeEmpId == 'MN-TL1002' ||
        eco.activeEmpId == 'MN-CEO01' ||
        eco.activeRole == 'dept_head' ||
        eco.activeRole == 'ceo';

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: RoleAppBar(
        roleName: 'Orders',
        userName: '${eco.currentEmployee.name} • Online Orders',
        roleColor: const Color(0xFFF59E0B),
        roleIcon: Icons.shopping_bag_outlined,
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
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Overdue Workflow Alert',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFFFCA5A5)),
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
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTLOrCeo
                                ? 'Reassign Staff Orders'
                                : 'Requires Lead Reallocation',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFFFED7AA)),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Order Tracking Workflow',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sandGold,
                    foregroundColor: AppColors.burgundyBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _openCreateOrderDialog(context, eco),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.burgundyBg),
                  label: const Text('New Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.burgundyBg)),
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
                            color: isSelected ? brandColor.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? brandColor : Colors.white.withOpacity(0.08),
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
                                      color: isSelected ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    '${ord.brand} • ${ord.completedCount}/38',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isSelected ? brandColor : const Color(0xFF94A3B8),
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
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
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
                                  '6. Expected Delivery',
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
                    const SizedBox(height: 14),

                    // Overall Order Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Progress',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
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
                        backgroundColor: Colors.white12,
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
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
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
                        backgroundColor: Colors.white.withOpacity(0.08),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
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
            color: highlightColor ?? Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFFCBD5E1)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
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
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stageColor),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${stage.index}. ${stage.stageName}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
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
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$completedCount/${stage.totalItems}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? AppColors.ragGreen : Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.white70,
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
                                    fontSize: 10.5,
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
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
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
            const Divider(color: Colors.white10, height: 1),
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
                                eco.postBroadcastNotification(
                                  title: 'Reassignment Request: Order #${order.orderId}',
                                  content: '${eco.currentEmployee.name} requested TL Praveenkumar to reassign ${order.brand} Order #${order.orderId} due to staff absence.',
                                  senderName: eco.currentEmployee.name,
                                  senderRole: eco.currentEmployee.role,
                                );
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
    DateTime initial = DateTime.now();
    try {
      if (stage.dueDate.isNotEmpty) initial = DateTime.parse(stage.dueDate);
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.sandGold,
              onPrimary: Colors.black,
              surface: AppColors.burgundySurface,
              onSurface: AppColors.sandLight,
            ),
            dialogBackgroundColor: AppColors.burgundyCard,
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
    final orderIdCtrl = TextEditingController(text: 'ORD-MN-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final customerCtrl = TextEditingController();
    String salesChannel = 'WhatsApp';
    String brand = 'MN Jewel Park'; // 'Vadivam' or 'MN Jewel Park'
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
            final autoHandlerId = isVadivam ? 'MN-1008' : 'MN-1007';
            final autoHandlerName = isVadivam ? 'Nisha (OS2)' : 'Kaaviya (OS1)';

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Create Online Order Workflow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 1. Order ID
                    const Text('1. Order ID / Number', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: orderIdCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Customer Name
                    const Text('2. Customer Name', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: customerCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'e.g. Mrs. Priya Sundaram',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Sales Channel
                    const Text('3. Sales Channel', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: salesChannel,
                      dropdownColor: AppColors.burgundySurface,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: ['WhatsApp', 'Website', 'Instagram', 'Direct Call', 'Showroom'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => salesChannel = v);
                      },
                    ),
                    const SizedBox(height: 10),

                    // 5. 5th Dropdown: Brand (Vadivam or MN Jewel Park)
                    const Text('5. Brand / Unit (Mandatory)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: brand,
                      dropdownColor: AppColors.burgundySurface,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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

                    // 4. Handled By (Auto-locked to responsible role per rules)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge, size: 16, color: AppColors.sandGold),
                          const SizedBox(width: 8),
                          Text(
                            '4. Handled by: $autoHandlerName',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 6. 6th Field: Expected Delivery Date
                    const Text('6. Expected Delivery Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: deliveryCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.sandGold),
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
                    const Text('SLA Target Due Dates for 5 Subcategories:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    _subDateInput('1. Customer Verification Due', stage1DueCtrl, fmt),
                    _subDateInput('2. Product Verification Due', stage2DueCtrl, fmt),
                    _subDateInput('3. Payment & Billing Due', stage3DueCtrl, fmt),
                    _subDateInput('4. Packing & Dispatch Due', stage4DueCtrl, fmt),
                    _subDateInput('5. Delivery & Customer Closure Due', stage5DueCtrl, fmt),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sandGold,
                        foregroundColor: AppColors.burgundyBg,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (customerCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter customer name.')),
                          );
                          return;
                        }

                        final stages = OnlineOrderModel.createDefaultStages();
                        stages['stage1']?.dueDate = stage1DueCtrl.text.trim();
                        stages['stage2']?.dueDate = stage2DueCtrl.text.trim();
                        stages['stage3']?.dueDate = stage3DueCtrl.text.trim();
                        stages['stage4']?.dueDate = stage4DueCtrl.text.trim();
                        stages['stage5']?.dueDate = stage5DueCtrl.text.trim();

                        final newOrder = OnlineOrderModel(
                          orderId: orderIdCtrl.text.trim(),
                          customerName: customerCtrl.text.trim(),
                          salesChannel: salesChannel,
                          handledByEmpId: autoHandlerId,
                          handledByName: isVadivam ? 'Nisha' : 'Kaaviya',
                          brand: brand,
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
                            content: Text('Order #${newOrder.orderId} created for $brand!'),
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

  Widget _subDateInput(String label, TextEditingController ctrl, String Function(DateTime) fmt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFFCBD5E1))),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
    String selectedEmp = staffList.isNotEmpty ? staffList.first.id : 'MN-1008';

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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
                style: const TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1), height: 1.3),
              ),
              const SizedBox(height: 12),
              const Text('Reassign To Available Staff Member:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedEmp,
                dropdownColor: AppColors.burgundySurface,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
                final newEmp = eco.employees.firstWhere((e) => e.id == selectedEmp, orElse: () => eco.employees.first);
                eco.reassignOnlineOrder(
                  orderId: order.orderId,
                  newEmpId: newEmp.id,
                  newEmpName: newEmp.name,
                  authorizedBy: eco.currentEmployee.name,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white24)),
        title: const Text('Reset Checklist?', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to clear all checked items for this order?', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
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
                backgroundColor: AppColors.sandGold,
                foregroundColor: AppColors.burgundyBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => _openCreateOrderDialog(context, eco),
              icon: const Icon(Icons.add, size: 16, color: AppColors.burgundyBg),
              label: const Text(
                'Create Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.burgundyBg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
