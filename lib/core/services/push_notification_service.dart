import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// PushNotificationService manages native device push notifications,
/// ensuring alerts appear in the status bar and on the phone lock screen
/// with high importance and public visibility.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final Set<String> _dispatchedNotificationIds = {};

  // Testing hooks
  static List<Map<String, String>> testNotificationLog = [];

  static const String _channelId = 'mn_family_channel_high';
  static const String _channelName = 'MN Family Official Notifications';
  static const String _channelDescription = 'Official corporate alerts, directives, and reminders';

  static const String _chatChannelId = 'mn_family_channel_chat';
  static const String _chatChannelName = 'MN Family Chat & Messages';
  static const String _chatChannelDescription = 'Instant direct messages, group chat alerts and @mentions';

  /// Initialize notification plugin with high-importance lock screen channel
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Push notification tapped with payload: ${response.payload}');
        },
      );

      // Create Android High Importance Notification Channel for Lockscreen display
      if (!kIsWeb && Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // Request POST_NOTIFICATIONS permission on Android 13+
          await androidPlugin.requestNotificationsPermission();

          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );
          await androidPlugin.createNotificationChannel(channel);

          const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
            _chatChannelId,
            _chatChannelName,
            description: _chatChannelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );
          await androidPlugin.createNotificationChannel(chatChannel);
        }
      }

      _isInitialized = true;
      debugPrint('PushNotificationService initialized with lockscreen visibility.');
    } catch (e) {
      debugPrint('PushNotificationService initialization note: $e');
    }
  }

  /// Dispatch a push notification to the device.
  /// Uses NotificationVisibility.public to ensure it is displayed on the lock screen.
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
    bool isChat = false,
  }) async {
    // Record for testing verification
    testNotificationLog.add({
      'id': id,
      'title': title,
      'body': body,
    });

    // Avoid duplicate pushes for the exact same notification ID
    if (_dispatchedNotificationIds.contains(id)) return;
    _dispatchedNotificationIds.add(id);

    if (!_isInitialized) {
      await initialize();
    }
    if (!_isInitialized) {
      // In test or non-supported platform environments, testNotificationLog is preserved
      return;
    }

    try {
      final bigTextStyleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: isChat ? 'MN Team Chat' : 'MN Family Alert',
        htmlFormatSummaryText: true,
      );

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        isChat ? _chatChannelId : _channelId,
        isChat ? _chatChannelName : _channelName,
        channelDescription: isChat ? _chatChannelDescription : _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: bigTextStyleInformation,
        // NotificationVisibility.public displays the full notification on the lock screen even when locked
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        ticker: isChat ? 'New Chat Message' : 'MN Family Alert',
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final int notificationId = id.hashCode & 0x7FFFFFFF;

      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: payload ?? id,
      );
    } catch (e) {
      debugPrint('PushNotificationService showNotification note: $e');
    }
  }

  /// Specialized instant push notification for chat messages & mentions
  Future<void> showChatNotification({
    required String id,
    required String senderName,
    required String message,
    required bool isGroup,
    String? payload,
  }) async {
    final title = isGroup ? '💬 $senderName (MN All-Hands)' : '💬 $senderName';
    await showNotification(
      id: id,
      title: title,
      body: message,
      payload: payload,
      isChat: true,
    );
  }

  /// Reset testing logs
  static void clearTestLogs() {
    testNotificationLog.clear();
  }
}
