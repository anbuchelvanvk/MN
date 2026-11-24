import '../../core/widgets/mn_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';

class WorkPillarScreen extends StatefulWidget {
  const WorkPillarScreen({super.key});

  @override
  State<WorkPillarScreen> createState() => _WorkPillarScreenState();
}

class _WorkPillarScreenState extends State<WorkPillarScreen> {
  final _stationController = TextEditingController();
  final _targetController = TextEditingController();
  final _hoursController = TextEditingController();
  final _notesController = TextEditingController();
  String _department = 'Operations';
  bool _scaleCalibrated = false;
  bool _sopAcknowledged = false;

  @override
  void dispose() {
    _stationController.dispose();
    _targetController.dispose();
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: const MnAppBar(
        title: 'Work',
        subtitle: 'Tasks and daily routines',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.magentaBorder, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.magentaPrimary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operations & Craftsmanship Gate',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SOP discipline, hallmarking precision, and master craftsmanship records.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form Inputs
            LiquidGlassCard(
              padding: const EdgeInsets.all(18),
              backgroundColor: AppColors.burgundyGlass,
              borderColor: AppColors.sandBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Operational Inputs',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Department Unit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sandLight,
                    ),
                  ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _department,
                    dropdownColor: AppColors.burgundySurface,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12.5),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.sandPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.burgundySurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sandBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sandBorder),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Operations', child: Text('Operations')),
                      DropdownMenuItem(value: 'Online', child: Text('Online Orders')),
                      DropdownMenuItem(value: 'Sales', child: Text('Luxury Sales')),
                      DropdownMenuItem(value: 'Housekeeping', child: Text('Housekeeping')),
                      DropdownMenuItem(value: 'Vault', child: Text('Vault Security')),
                      DropdownMenuItem(value: 'Finance', child: Text('Finance Accounts')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _department = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _inputBox(
                          label: 'Work Station ID',
                          controller: _stationController,
                          hint: 'e.g. Bench #4',
                          icon: Icons.store_mall_directory_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _inputBox(
                          label: 'Shift Duration',
                          controller: _hoursController,
                          hint: 'e.g. 8.5 hrs',
                          icon: Icons.timer_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _inputBox(
                    label: 'Target Deliverable Today',
                    controller: _targetController,
                    hint: 'e.g. 14 Velvet Trays Reconciled',
                    icon: Icons.task_alt,
                  ),
                  const SizedBox(height: 14),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.burgundySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sandBorder),
                    ),
                    child: Material(type: MaterialType.transparency, child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      activeColor: AppColors.magentaPrimary,
                      checkColor: Colors.white,
                      title: Text(
                        '0.001g Bullion Balance Calibrated',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        'Certified electronic scale zeroed with official weights',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      value: _scaleCalibrated,
                      onChanged: (v) => setState(() => _scaleCalibrated = v ?? false),
                    )),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.burgundySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sandBorder),
                    ),
                    child: Material(type: MaterialType.transparency, child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      activeColor: AppColors.magentaPrimary,
                      checkColor: Colors.white,
                      title: Text(
                        'Daily Shift SOP Checklist Signed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        'Shift opening checklist physically and digitally verified',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      value: _sopAcknowledged,
                      onChanged: (v) => setState(() => _sopAcknowledged = v ?? false),
                    )),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Operational Observations & Notes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sandLight,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Enter scale readings, tray numbers, or tool maintenance logs...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5),
                      filled: true,
                      fillColor: AppColors.burgundySurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sandBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sandBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  LiquidGlassButton(
                    label: 'Save & Submit Work Log',
                    icon: Icons.check_circle_outline,
                    height: 46,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.burgundyPrimary,
                          content: Text('Operational log saved successfully!'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBox({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.sandLight,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12.5),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: AppColors.sandGold),
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11),
            filled: true,
            fillColor: AppColors.burgundySurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.sandBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.sandBorder),
            ),
          ),
        ),
      ],
    );
  }
}
