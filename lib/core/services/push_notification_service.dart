import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../views/chat/chat_conversation_screen.dart';
import '../widgets/company_notification_sheet.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('Background message received: ${message.messageId}');
    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ?? data['title'] ?? 'MN Family Alert';
    final body = notification?.body ?? data['body'] ?? '';
    final isChat = data['type'] == 'chat' || title.contains('💬');
    if (body.isNotEmpty) {
      await PushNotificationService().showNotification(
        id: message.messageId ?? 'BG-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        isChat: isChat,
      );
    }
  } catch (e) {
    debugPrint('Background message error: $e');
  }
}

/// PushNotificationService manages native device push notifications,
/// ensuring alerts appear in the status bar and on the phone lock screen
/// with high importance and public visibility.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String? _pendingPayload;

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

  /// Deep-link direct navigation handler for tapped notifications
  static void handleNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    final cleanPayload = payload.trim();
    debugPrint('Executing direct deep-link navigation for payload: $cleanPayload');

    final navState = navigatorKey.currentState;
    if (navState == null || navState.context.mounted != true) {
      _pendingPayload = cleanPayload;
      return;
    }

    final context = navState.context;

    if (cleanPayload.startsWith('chat:')) {
      // payload format: "chat:PEER_ID|PEER_NAME|PEER_ROLE|IS_GROUP"
      final raw = cleanPayload.substring(5);
      final parts = raw.split('|');
      final peerId = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'ALL_HANDS';
      final peerName = parts.length > 1 && parts[1].isNotEmpty
          ? parts[1]
          : (peerId == 'ALL_HANDS' ? 'MN All-Hands Workforce' : 'Colleague');
      final peerRole = parts.length > 2 && parts[2].isNotEmpty
          ? parts[2]
          : (peerId == 'ALL_HANDS' ? 'All Employees' : 'Staff');
      final isGroup = parts.length > 3 ? parts[3] == 'true' : peerId == 'ALL_HANDS';
      final initials = peerName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

      navState.push(
        MaterialPageRoute(
          builder: (_) => ChatConversationScreen(
            peerId: peerId,
            peerName: peerName,
            peerRole: peerRole,
            peerInitials: initials.isNotEmpty ? initials : '??',
            isGroup: isGroup,
          ),
        ),
      );
    } else if (cleanPayload.startsWith('company_notif:') ||
        cleanPayload.startsWith('notif:') ||
        cleanPayload.startsWith('alert:') ||
        cleanPayload.startsWith('birthday:')) {
      CompanyNotificationSheet.show(context);
    }
  }

  static void processPendingPayloadIfAny() {
    if (_pendingPayload != null) {
      final payload = _pendingPayload;
      _pendingPayload = null;
      Future.delayed(const Duration(milliseconds: 350), () {
        handleNotificationPayload(payload);
      });
    }
  }

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
          handleNotificationPayload(response.payload);
        },
      );

      // Listen to native Android notification click events
      if (!kIsWeb && Platform.isAndroid) {
        const MethodChannel clickChannel =
            MethodChannel('com.mnjewelpark.mn_family_app/notification_clicks');
        clickChannel.setMethodCallHandler((call) async {
          if (call.method == 'onNotificationClicked') {
            final payload = call.arguments?.toString();
            handleNotificationPayload(payload);
          }
        });

        try {
          final initialNativePayload =
              await clickChannel.invokeMethod<String>('getInitialNotificationPayload');
          if (initialNativePayload != null && initialNativePayload.isNotEmpty) {
            handleNotificationPayload(initialNativePayload);
          }
        } catch (_) {}

        try {
          final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
          if (launchDetails?.didNotificationLaunchApp == true &&
              launchDetails?.notificationResponse?.payload != null) {
            handleNotificationPayload(launchDetails!.notificationResponse!.payload);
          }
        } catch (_) {}
      }

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

      // Configure Firebase Cloud Messaging for Background & Closed App notifications
      if (!kIsWeb) {
        try {
          if (Firebase.apps.isNotEmpty) {
            FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
            final messaging = FirebaseMessaging.instance;
            await messaging.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            );
            await messaging.setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
            FirebaseMessaging.onMessage.listen((RemoteMessage message) {
              final notification = message.notification;
              final data = message.data;
              final title = notification?.title ?? data['title'] ?? 'MN Family Alert';
              final body = notification?.body ?? data['body'] ?? '';
              final isChat = data['type'] == 'chat' || title.contains('💬');
              if (body.isNotEmpty) {
                showNotification(
                  id: message.messageId ?? 'FG-${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  body: body,
                  isChat: isChat,
                );
              }
            });
            // Subscribe to workforce broadcast topic
            await messaging.subscribeToTopic('mn_workforce');
          }
        } catch (fcmError) {
          debugPrint('FirebaseMessaging initialization note: $fcmError');
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

  static const MethodChannel _backgroundChannel =
      MethodChannel('com.mnjewelpark.mn_family_app/background_permissions');

  /// Check whether battery optimization is ignored (unrestricted background)
  Future<bool> isBatteryOptimizationIgnored() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final res = await _backgroundChannel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request exemption from battery optimizations (pops Android system dialog)
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final res = await _backgroundChannel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return res ?? false;
    } catch (e) {
      debugPrint('Battery optimization request note: $e');
      return false;
    }
  }

  /// Sync active logged-in employee ID to Android native preferences
  Future<void> syncActiveUserToNative(String empId, String empName) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _backgroundChannel.invokeMethod('syncActiveUser', {
        'empId': empId,
        'empName': empName,
      });
    } catch (e) {
      debugPrint('Sync active user to native note: $e');
    }
  }

  /// Start 24/7 background keep-alive sync
  Future<void> startBackgroundSync() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _backgroundChannel.invokeMethod('startBackgroundSync');
    } catch (e) {
      debugPrint('Start background sync note: $e');
    }
  }

  /// Request all prior permissions (Notifications + Battery Exemption + Native Sync)
  Future<void> requestAllPriorPermissions({String? empId, String? empName}) async {
    await initialize();
    if (!kIsWeb && Platform.isAndroid) {
      final isIgnored = await isBatteryOptimizationIgnored();
      if (!isIgnored) {
        await requestIgnoreBatteryOptimizations();
      }
      if (empId != null && empId.isNotEmpty) {
        await syncActiveUserToNative(empId, empName ?? empId);
      }
      await startBackgroundSync();
    }
  }
}
