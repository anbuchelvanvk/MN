import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for uploading and resolving KONAR Book PDFs in Google Drive.
/// Ensures documents remain viewable and downloadable 100% inside the app without navigating out.
class GoogleDriveUploadService {
  /// Secret token verified by Google Apps Script Webhook
  static const String secretToken = 'MN_JEWEL_PARK_INTERNAL_KEY_2026';

  /// Default Google Drive Folder ID provided for MN Jewel Park KONAR Books
  static const String targetFolderId = '125XQXutoTwVnedJBf03qenUXn88BniCx';

  /// Target Google Drive Folder ID for Creative Media Review Board & Video Drafts
  static const String mediaFolderId = '1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2';

  /// Official Deployed Google Apps Script Webhook URL for Creative Media Sharing & Review Board
  static const String mediaWebhookUrl =
      'https://script.google.com/macros/s/AKfycbzCv4GGti_wzFZy5vilJjiuh-FxDRNQY0c7ENpkV9JYwzaLjDBh65MDbNhvFJl43jYw/exec';

  /// Official Deployed Google Apps Script Webhook URL for MN Jewel Park KONAR Books
  static const String defaultWebhookUrl =
      'https://script.google.com/macros/s/AKfycbwoN_OHTZDTXK_Q97I5Kn3DxlGQyuQSvdSleZ_kjcGA82t53tdrFGDrXxCYW9axbiSvxQ/exec';

  /// Extracts the Google Drive alphanumeric File ID from any sharing or preview URL
  static String? extractFileId(String url) {
    if (url.trim().isEmpty) return null;
    final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)|id=([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1) ?? match?.group(2);
  }

  /// Returns the direct binary download endpoint for a Google Drive URL
  static String getDirectDownloadUrl(String url) {
    final fileId = extractFileId(url);
    if (fileId != null && fileId.isNotEmpty) {
      return 'https://drive.usercontent.google.com/download?id=$fileId&export=download';
    }
    return url;
  }

  /// Returns the clean preview URL for a Google Drive URL
  static String getPreviewUrl(String url) {
    final fileId = extractFileId(url);
    if (fileId != null && fileId.isNotEmpty) {
      return 'https://drive.google.com/file/d/$fileId/preview';
    }
    return url;
  }

  /// Uploads a PDF to the specified Google Apps Script Webhook and saves it in the Drive folder
  static Future<Map<String, dynamic>> uploadPdfToDrive({
    required Uint8List pdfBytes,
    required String fileName,
    String? webhookUrl,
    String? folderId,
  }) async {
    final client = http.Client();
    try {
      final base64String = base64Encode(pdfBytes);
      final targetUrl = (webhookUrl != null && webhookUrl.trim().isNotEmpty)
          ? webhookUrl.trim()
          : defaultWebhookUrl;

      final request = http.Request('POST', Uri.parse(targetUrl))
        ..followRedirects = true
        ..maxRedirects = 5
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'secretToken': secretToken,
          'folderId': folderId ?? targetFolderId,
          'filename': fileName,
          'base64': base64String,
        });

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 400) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['status'] == 'success') {
          return decoded;
        } else {
          throw Exception(decoded['message'] ?? 'Upload failed on Google Drive script');
        }
      } else {
        throw Exception('Google Drive webhook error (${response.statusCode}): ${response.body}');
      }
    } finally {
      client.close();
    }
  }

  /// Uploads video or photo files to Google Drive folder for media drafts review
  static Future<Map<String, dynamic>> uploadMediaToDrive({
    required Uint8List fileBytes,
    required String fileName,
    String? mimeType,
    String? webhookUrl,
    String? folderId,
  }) async {
    final client = http.Client();
    try {
      final base64String = base64Encode(fileBytes);
      final targetUrl = (webhookUrl != null && webhookUrl.trim().isNotEmpty)
          ? webhookUrl.trim()
          : mediaWebhookUrl;

      final request = http.Request('POST', Uri.parse(targetUrl))
        ..followRedirects = true
        ..maxRedirects = 5
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'secretToken': secretToken,
          'folderId': folderId ?? mediaFolderId,
          'filename': fileName,
          'mimeType': mimeType ?? 'application/octet-stream',
          'base64': base64String,
        });

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 400) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['status'] == 'success') {
          return decoded;
        } else {
          throw Exception(decoded['message'] ?? 'Upload failed on Google Drive script');
        }
      } else {
        throw Exception('Google Drive webhook error (${response.statusCode}): ${response.body}');
      }
    } finally {
      client.close();
    }
  }
}
