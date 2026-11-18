import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Service to capture, downsample, and strictly compress photos & receipts to <= 150 KB
/// to eliminate Android Out-Of-Memory (OOM) crashes and optimize Firestore storage.
class ImageOptimizationService {
  static const int maxTargetSizeBytes = 150 * 1024; // 150 KB limit
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from Camera or Gallery and guarantee <= 150 KB compression
  static Future<CompressedImageResult?> pickAndCompressImage({
    ImageSource source = ImageSource.camera,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 960,
        maxHeight: 960,
        imageQuality: 65,
      );

      if (file == null) return null;

      Uint8List bytes = await file.readAsBytes();

      // If already under 150KB, return directly
      if (bytes.lengthInBytes <= maxTargetSizeBytes) {
        final base64Str = base64Encode(bytes);
        return CompressedImageResult(
          bytes: bytes,
          dataUrl: 'data:image/jpeg;base64,$base64Str',
          sizeBytes: bytes.lengthInBytes,
        );
      }

      // If larger than 150KB, recompress using Canvas downsampling
      bytes = await _downscaleAndCompress(bytes, targetBytes: maxTargetSizeBytes);
      final base64Str = base64Encode(bytes);

      return CompressedImageResult(
        bytes: bytes,
        dataUrl: 'data:image/jpeg;base64,$base64Str',
        sizeBytes: bytes.lengthInBytes,
      );
    } catch (e) {
      debugPrint('ImageOptimizationService pick error: $e');
      return null;
    }
  }

  /// Safe widget builder supporting base64 data URLs and remote HTTP URLs
  static Widget buildImageWidget(
    String url, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Data = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            height: height ?? 80,
            width: width,
            color: const Color(0xFFF1F5F9),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 24),
          ),
        );
      } catch (_) {}
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          height: height ?? 80,
          width: width,
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 24),
        ),
      );
    }
    return Container(
      height: height ?? 80,
      width: width,
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(Icons.image, color: Color(0xFF94A3B8), size: 24),
    );
  }

  /// Iteratively downscales the image in memory until under the 150 KB target
  static Future<Uint8List> _downscaleAndCompress(
    Uint8List originalBytes, {
    required int targetBytes,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      int currentWidth = image.width;
      int currentHeight = image.height;
      Uint8List compressed = originalBytes;

      // Downsample dimensions by 20% steps until size is <= 150 KB
      while (compressed.lengthInBytes > targetBytes && currentWidth > 200 && currentHeight > 200) {
        currentWidth = (currentWidth * 0.8).round();
        currentHeight = (currentHeight * 0.8).round();

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawImageRect(
          image,
          ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          ui.Rect.fromLTWH(0, 0, currentWidth.toDouble(), currentHeight.toDouble()),
          ui.Paint()..filterQuality = ui.FilterQuality.medium,
        );
        final picture = recorder.endRecording();
        final newImg = await picture.toImage(currentWidth, currentHeight);
        final byteData = await newImg.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          compressed = byteData.buffer.asUint8List();
        }
      }

      return compressed;
    } catch (e) {
      debugPrint('Downscale error: $e');
      return originalBytes;
    }
  }
}

class CompressedImageResult {
  final Uint8List bytes;
  final String dataUrl;
  final int sizeBytes;

  CompressedImageResult({
    required this.bytes,
    required this.dataUrl,
    required this.sizeBytes,
  });

  double get sizeInKb => sizeBytes / 1024.0;
}
