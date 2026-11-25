import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ecosystem_provider.dart';
import '../theme/app_colors.dart';

/// Modal to request emergency step-out permission (15m, 30m, 1h, 2h, >2h)
/// with 2-hour quota tally and Orange Mark warning when exceeding 2 hours.
class EmergencyPermissionModal extends StatefulWidget {
  final String? empId;
  final String? empRole;

  const EmergencyPermissionModal({
    super.key,
    this.empId,
    this.empRole,
  });

  static Future<void> show(BuildContext context, {String? empId, String? empRole}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EmergencyPermissionModal(
        empId: empId,
        empRole: empRole,
      ),
    );
  }

  @override
  State<EmergencyPermissionModal> createState() => _EmergencyPermissionModalState();
}

class _EmergencyPermissionModalState extends State<EmergencyPermissionModal> {
  // Preset durations: 15m (0.25h), 30m (0.5h), 1hr (1.0h), 2hr (2.0h), 4hr (4.0h), custom
  double _selectedHours = 0.5; // Default 30m
  bool _isCustomDuration = false;
  final TextEditingController _customHoursController = TextEditingController(text: '4.5');
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _customHoursController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _onPresetSelected(double hours) {
    setState(() {
      _isCustomDuration = false;
      _selectedHours = hours;
    });
  }

  String _formatDuration(double hours) {
    if (hours <= 0) return '0hr';
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()}hr';
    }
    return '${hours.toStringAsFixed(1)}hr';
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final activeEmp = eco.currentEmployee;
    final empId = widget.empId ?? activeEmp.id;
    final role = widget.empRole ?? activeEmp.role;

    final effectiveHours = _isCustomDuration
        ? (double.tryParse(_customHoursController.text.trim()) ?? 4.5)
        : _selectedHours;

    // Check if this request exceeds standard 4.0 hr quota or cumulative monthly usage
    final currentUsed = eco.totalPermissionHoursUsed;
    final remainingQuota = eco.permissionHoursRemaining;
    final willExceedQuota = effectiveHours > 4.0 || (currentUsed + effectiveHours) > eco.monthlyPermissionHoursLimit;

    final excessHours = (effectiveHours > remainingQuota)
        ? (effectiveHours - remainingQuota)
        : (effectiveHours - 4.0);
    final positiveDiff = excessHours > 0 ? excessHours : (effectiveHours > 4.0 ? effectiveHours - 4.0 : 0.5);
    final timeGiven = _formatDuration(effectiveHours);
    final timeDifference = _formatDuration(positiveDiff);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.burgundyCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.sandGold, width: 1.5)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time_rounded, color: Color(0xFFD97706), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY PERMISSION',
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'Immediate step-out request • Approvals flow: TL/Staff → HR & CEO',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE2E8F0), height: 20),

              // Monthly Quota Tally (2.0 hrs standard)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '4-Hour Permission Quota',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${remainingQuota.toStringAsFixed(1)}h Remaining of 4.0h',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: willExceedQuota
                            ? AppColors.ragYellow.withOpacity(0.2)
                            : AppColors.ragGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: willExceedQuota ? AppColors.ragYellow : AppColors.ragGreen,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        willExceedQuota ? 'Orange Flag (Exceeds 4h)' : 'Within 4h Quota',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: willExceedQuota ? AppColors.ragYellow : AppColors.ragGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Duration selector (15m, 30m, 1hr, 2hr, 4hr, >4h custom)
              Text(
                'Select Step-Out Duration:',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _durationChip('15 Min', 0.25, isSelected: !_isCustomDuration && _selectedHours == 0.25),
                  _durationChip('30 Min', 0.5, isSelected: !_isCustomDuration && _selectedHours == 0.5),
                  _durationChip('1 Hour', 1.0, isSelected: !_isCustomDuration && _selectedHours == 1.0),
                  _durationChip('2 Hours', 2.0, isSelected: !_isCustomDuration && _selectedHours == 2.0),
                  _durationChip('4 Hours', 4.0, isSelected: !_isCustomDuration && _selectedHours == 4.0),
                  ChoiceChip(
                    label: const Text('> 4h Custom', style: TextStyle(fontSize: 11)),
                    selected: _isCustomDuration,
                    onSelected: (val) {
                      setState(() {
                        _isCustomDuration = true;
                      });
                    },
                    selectedColor: AppColors.magentaPrimary,
                    backgroundColor: AppColors.cardSurface,
                    labelStyle: TextStyle(
                      color: _isCustomDuration ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Custom hours input if selected
              if (_isCustomDuration) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customHoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Enter Custom Duration in Hours (e.g. 4.5, 5.0)',
                    labelStyle: const TextStyle(color: AppColors.magentaPrimary, fontSize: 11),
                    suffixText: 'Hours',
                    suffixStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.magentaPrimary),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Orange Mark Banner if exceeding 4.0 hrs
              if (willExceedQuota) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The time you gave [$timeGiven] exceeds your quota of 4hr window, by [$timeDifference]. Do you still want to proceed?',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Reason input field
              Text(
                'Reason for Emergency Permission:',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.magentaPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'e.g. Urgent banking errand, family emergency, doctor consultation...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.magentaPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: willExceedQuota ? const Color(0xFFD97706) : AppColors.magentaPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final reason = _reasonController.text.trim().isEmpty
                        ? 'Emergency Permission'
                        : _reasonController.text.trim();

                    eco.requestEmergencyPermission(
                      empId: empId,
                      hours: effectiveHours,
                      reason: reason,
                      requesterRole: role,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Emergency permission request ($timeGiven) sent! CEO & HR notified via instant push notification.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                  label: Text(
                    willExceedQuota
                        ? 'Yes, Proceed & Request ($timeGiven)'
                        : 'Submit Emergency Request ($timeGiven)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _durationChip(String label, double hours, {required bool isSelected}) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => _onPresetSelected(hours),
      selectedColor: AppColors.magentaPrimary,
      backgroundColor: AppColors.cardSurface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
