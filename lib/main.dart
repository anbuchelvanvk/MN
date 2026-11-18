import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/services/network_connectivity_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/widgets/internet_connection_banner.dart';
import 'core/widgets/app_notification_host.dart';
import 'providers/ecosystem_provider.dart';
import 'views/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization status: $e');
  }

  // Initialize Network Connectivity Monitoring
  NetworkConnectivityService().initialize();

  // Initialize Native Push Notifications & Request 24/7 Background Exemption Permissions
  await PushNotificationService().requestAllPriorPermissions();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.pureWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => EcosystemProvider(),
      child: const MnFamilyApp(),
    ),
  );
}

class MnFamilyApp extends StatelessWidget {
  const MnFamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MN Family',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.burgundySandTheme,
      home: const LoginScreen(),
      builder: (context, child) => AppNotificationHost(
        child: InternetConnectionBanner(child: child!),
      ),
    );
  }
}
