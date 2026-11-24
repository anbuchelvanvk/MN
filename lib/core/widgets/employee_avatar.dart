import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Profile picture shown everywhere an employee's face appears.
///
/// Uses the employee's uploaded photo (stored as a small data URI, or a web
/// URL) and falls back to their initials on a magenta gradient.
class EmployeeAvatar extends StatelessWidget {
  final String avatar;
  final String initials;
  final double size;

  /// Corner radius; defaults to a full circle.
  final double? radius;

  const EmployeeAvatar({
    super.key,
    required this.avatar,
    required this.initials,
    this.size = 40,
    this.radius,
  });

  static final Map<String, Uint8List> _decoded = {};

  /// Decodes `data:image/...;base64,...` once and caches it.
  static Uint8List? _bytesFor(String src) {
    if (!src.startsWith('data:image')) return null;
    final cached = _decoded[src];
    if (cached != null) return cached;
    final comma = src.indexOf(',');
    if (comma < 0) return null;
    try {
      final bytes = base64Decode(src.substring(comma + 1));
      if (_decoded.length > 64) _decoded.clear();
      _decoded[src] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final src = avatar.trim();
    final r = radius ?? size / 2;
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBE185D), Color(0xFF881337)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.trim().isNotEmpty ? initials.trim() : '?',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
          color: Colors.white,
        ),
      ),
    );

    Widget image = fallback;
    final bytes = _bytesFor(src);
    if (bytes != null) {
      image = Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback);
    } else if (src.startsWith('http')) {
      image = Image.network(src, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

/// Picks a photo and turns it into a 150x150 square PNG data URI.
class AvatarPicker {
  static const int outputSize = 150;

  /// Returns a `data:image/png;base64,...` string, or null if cancelled.
  static Future<String?> pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      // Downscale on the device first so large camera photos decode quickly.
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return null;
    final square = await cropToSquare(await picked.readAsBytes());
    return 'data:image/png;base64,${base64Encode(square)}';
  }

  /// Center-crops [input] to a square and resizes it to [size] x [size].
  static Future<Uint8List> cropToSquare(Uint8List input, {int size = outputSize}) async {
    final codec = await ui.instantiateImageCodec(input);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final side = math.min(img.width, img.height).toDouble();
    final src = Rect.fromLTWH(
      (img.width - side) / 2,
      (img.height - side) / 2,
      side,
      side,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      img,
      src,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final out = await recorder.endRecording().toImage(size, size);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    out.dispose();
    return data!.buffer.asUint8List();
  }
}
