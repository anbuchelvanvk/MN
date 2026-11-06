import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../../services/image_optimization_service.dart';

/// Unified To-Do Task Completion & Reversion Controller for All Roles
class TaskActionDialogs {
  /// Show completion modal with required comment box and optional image proof attachment
  static void showCompletionModal(
    BuildContext context,
    EcosystemProvider eco,
    TaskItem task,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TaskCompletionModal(eco: eco, task: task),
    );
  }

  /// Show uncheck / revert warning dialog for completed tasks
  static void showRevertDialog(
    BuildContext context,
    EcosystemProvider eco,
    TaskItem task,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.sandGold, width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mark Unfinished?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to revert this completed to-do back to unfinished work?',
              style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.35),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sandLight,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              eco.revertTask(task.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Marked unfinished: "${task.title}"'),
                  backgroundColor: AppColors.ragRed,
                ),
              );
            },
            child: const Text('Mark Unfinished', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Handle tap on any to-do task:
  /// - If not completed: show completion modal with optional image proof & submit button
  /// - If completed: show warning dialog to uncheck / mark as unfinished work
  static void handleTaskTap(
    BuildContext context,
    EcosystemProvider eco,
    TaskItem task,
  ) {
    if (task.isCompleted) {
      showRevertDialog(context, eco, task);
    } else {
      showCompletionModal(context, eco, task);
    }
  }
}

class _TaskCompletionModal extends StatefulWidget {
  final EcosystemProvider eco;
  final TaskItem task;

  const _TaskCompletionModal({
    required this.eco,
    required this.task,
  });

  @override
  State<_TaskCompletionModal> createState() => _TaskCompletionModalState();
}

class _TaskCompletionModalState extends State<_TaskCompletionModal> {
  CompressedImageResult? _attachedImage;
  late final TextEditingController _commentController;
  String? _commentError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit({required bool withProofImage}) {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      setState(() {
        _commentError = 'Completion comment is required. Please enter words describing your work.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completion comment is required before marking work complete.'),
          backgroundColor: AppColors.ragRed,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    widget.eco.completeTask(
      widget.task.id,
      proofText: commentText,
      photoUrl: (withProofImage && _attachedImage != null) ? _attachedImage!.dataUrl : null,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text((withProofImage && _attachedImage != null)
            ? 'Task completed with comment & photo proof!'
            : 'Task marked completed!'),
        backgroundColor: AppColors.ragGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.sandBorder, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.check,
                        color: AppColors.sandGold,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Complete Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Task Preview Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sandGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.task.category,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sandGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Due: ${widget.task.due} • ${widget.task.priority}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Comment Box Section (Required Field)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _commentError != null
                      ? AppColors.ragRed
                      : AppColors.sandGold.withOpacity(0.35),
                  width: _commentError != null ? 1.5 : 1.0,
                ),
                color: AppColors.burgundySurface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.commentDots,
                        size: 13,
                        color: AppColors.sandGold,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Completion Comment / Notes *',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFCA5A5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter remarks or explanation in words describing the work completed.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                    onChanged: (text) {
                      if (_commentError != null && text.trim().isNotEmpty) {
                        setState(() => _commentError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter completion details, work notes or deliverables (required)...',
                      hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      errorText: _commentError,
                      errorStyle: const TextStyle(fontSize: 10, color: AppColors.ragRed),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.sandBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _commentError != null ? AppColors.ragRed : AppColors.sandBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _commentError != null ? AppColors.ragRed : AppColors.sandGold,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Proof Attachment Section (Camera / Choose Photo - Optional)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _attachedImage != null
                      ? AppColors.ragGreen.withOpacity(0.5)
                      : AppColors.sandGold.withOpacity(0.3),
                ),
                color: AppColors.burgundySurface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      FaIcon(
                        FontAwesomeIcons.camera,
                        size: 13,
                        color: AppColors.sandGold,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Proof Attachment (Photo Optional)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attach photo or camera capture proof of work completion.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Camera / Gallery Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt_outlined, size: 15, color: AppColors.sandGold),
                          label: const Text(
                            'Take Photo',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.sandBorder),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final res = await ImageOptimizationService.pickAndCompressImage(source: ImageSource.camera);
                            if (res != null) {
                              setState(() => _attachedImage = res);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined, size: 15, color: AppColors.sandGold),
                          label: const Text(
                            'Choose Image',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.sandBorder),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final res = await ImageOptimizationService.pickAndCompressImage(source: ImageSource.gallery);
                            if (res != null) {
                              setState(() => _attachedImage = res);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  // If attached, show thumbnail preview and remove button
                  if (_attachedImage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.ragGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.ragGreen.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              _attachedImage!.bytes,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.check_circle, size: 13, color: AppColors.ragGreen),
                                    SizedBox(width: 4),
                                    Text(
                                      'Image Attached',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ragGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Size: ${_attachedImage!.sizeInKb.toStringAsFixed(1)} KB (Safe <= 150 KB)',
                                  style: const TextStyle(fontSize: 9.5, color: Color(0xFFCBD5E1)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                            onPressed: () => setState(() => _attachedImage = null),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Submit Buttons
            if (_attachedImage != null) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle, size: 18, color: Colors.white),
                label: const Text(
                  'Submit Proof',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : () => _submit(withProofImage: true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSubmitting ? null : () => _submit(withProofImage: false),
                child: const Text(
                  'Mark Without Proof',
                  style: TextStyle(fontSize: 11, color: AppColors.sandLight),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 18, color: Colors.black),
                label: const Text(
                  'Mark Completed',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sandGold,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : () => _submit(withProofImage: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

