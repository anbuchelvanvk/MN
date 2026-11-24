import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/ecosystem_provider.dart';
import '../../services/image_optimization_service.dart';
import '../theme/app_colors.dart';

/// Modal to request Emergency Medical Leave with mandatory doctor prescription
/// compressed to <= 150 KB and instant Push Notification alerts to CEO & HR.
class EmergencyMedicalLeaveModal extends StatefulWidget {
  final String? empId;
  final String? empRole;

  const EmergencyMedicalLeaveModal({
    super.key,
    this.empId,
    this.empRole,
  });

  static Future<void> show(BuildContext context, {String? empId, String? empRole}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EmergencyMedicalLeaveModal(
        empId: empId,
        empRole: empRole,
      ),
    );
  }

  @override
  State<EmergencyMedicalLeaveModal> createState() => _EmergencyMedicalLeaveModalState();
}

class _EmergencyMedicalLeaveModalState extends State<EmergencyMedicalLeaveModal> {
  int _selectedDays = 1;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _customDaysController = TextEditingController(text: '4');
  bool _isCustomDays = false;

  Uint8List? _prescriptionBytes;
  String? _prescriptionBase64;
  int? _prescriptionSizeBytes;
  bool _isCompressing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickPrescription(ImageSource source) async {
    setState(() {
      _isCompressing = true;
      _errorMessage = null;
    });

    try {
      final result = await ImageOptimizationService.pickAndCompressImage(source: source);
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _prescriptionBytes = result.bytes;
          _prescriptionBase64 = base64Encode(result.bytes);
          _prescriptionSizeBytes = result.sizeBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to capture or compress prescription: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final activeEmp = eco.currentEmployee;
    final empId = widget.empId ?? activeEmp.id;
    final role = widget.empRole ?? activeEmp.role;

    final effectiveDays = _isCustomDays
        ? (int.tryParse(_customDaysController.text.trim()) ?? 1)
        : _selectedDays;

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
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medical_services_outlined, color: Color(0xFFE11D48), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY MEDICAL LEAVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'Prescription strictly required • Compressed to <= 150 KB',
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

              // Days Selector
              Text(
                'Leave Duration (Days):',
                style: GoogleFonts.plusJakartaSans(
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
                  _daysChip('1 Day', 1),
                  _daysChip('2 Days', 2),
                  _daysChip('3 Days', 3),
                  ChoiceChip(
                    label: const Text('Custom Days', style: TextStyle(fontSize: 11)),
                    selected: _isCustomDays,
                    onSelected: (val) {
                      setState(() {
                        _isCustomDays = true;
                      });
                    },
                    selectedColor: AppColors.magentaPrimary,
                    backgroundColor: AppColors.cardSurface,
                    labelStyle: TextStyle(
                      color: _isCustomDays ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              if (_isCustomDays) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customDaysController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Enter number of days',
                    labelStyle: const TextStyle(color: AppColors.magentaPrimary, fontSize: 11),
                    suffixText: 'Days',
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
              const SizedBox(height: 14),

              // Reason
              Text(
                'Diagnosis / Reason for Medical Leave:',
                style: GoogleFonts.plusJakartaSans(
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
                  hintText: 'e.g. Severe viral fever, eye infection, prescribed bed rest...',
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
              const SizedBox(height: 14),

              // Mandatory Doctor Prescription Section
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Doctor Prescription (Mandatory):',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandGold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.ragRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.ragRed, width: 0.8),
                    ),
                    child: const Text(
                      'REQUIRED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ragRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Image upload box & preview
              if (_isCompressing) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.sandGold),
                      SizedBox(height: 8),
                      Text('Compressing prescription to <= 150 KB...', style: TextStyle(color: AppColors.sandLight, fontSize: 11)),
                    ],
                  ),
                ),
              ] else if (_prescriptionBytes != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.ragGreen, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _prescriptionBytes!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.ragGreen, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Prescription Attached',
                                      style: TextStyle(color: AppColors.ragGreen, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Size: ${((_prescriptionSizeBytes ?? 0) / 1024).toStringAsFixed(1)} KB (<= 150 KB Verified)',
                                  style: const TextStyle(color: AppColors.sandGold, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.ragRed, size: 20),
                            onPressed: () {
                              setState(() {
                                _prescriptionBytes = null;
                                _prescriptionBase64 = null;
                                _prescriptionSizeBytes = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECDD3), width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Without doctor prescription, medical leave cannot be submitted or accepted.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFE11D48), fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.sandLight,
                                side: const BorderSide(color: AppColors.sandGold),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _pickPrescription(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.sandGold),
                              label: const Text('Camera', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.sandLight,
                                side: const BorderSide(color: AppColors.sandGold),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _pickPrescription(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined, size: 14, color: AppColors.sandGold),
                              label: const Text('Gallery', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.ragRed, fontSize: 11.5)),
              ],
              const SizedBox(height: 18),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _prescriptionBase64 != null ? AppColors.magentaPrimary : AppColors.sandBorder.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (_prescriptionBase64 == null) {
                      setState(() {
                        _errorMessage = 'Doctor prescription is strictly required. Please capture or upload a prescription.';
                      });
                      return;
                    }

                    final reason = _reasonController.text.trim().isEmpty
                        ? 'Medical Emergency'
                        : _reasonController.text.trim();

                    final success = await eco.requestEmergencyMedicalLeave(
                      empId: empId,
                      days: effectiveDays,
                      reason: reason,
                      prescriptionBase64: _prescriptionBase64!,
                      requesterRole: role,
                    );

                    if (success) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Emergency Medical Leave ($effectiveDays Days) submitted with prescription! '
                              'CEO & HR alerted immediately via Push Notification.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: Text(
                    _prescriptionBase64 != null
                        ? 'Submit Medical Leave ($effectiveDays Days)'
                        : 'Upload Prescription to Submit',
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

  Widget _daysChip(String label, int days) {
    final isSelected = !_isCustomDays && _selectedDays == days;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _isCustomDays = false;
          _selectedDays = days;
        });
      },
      selectedColor: AppColors.magentaPrimary,
      backgroundColor: AppColors.cardSurface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
