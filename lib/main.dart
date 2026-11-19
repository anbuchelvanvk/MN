import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'views/employee/employee_portal_screen.dart';
import 'views/dept_head/dept_head_portal_screen.dart';
import 'views/hr/hr_portal_screen.dart';
import 'views/ceo/ceo_suite_screen.dart';

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

  // Read saved session to keep user permanently logged in across app closes
  String? initialEmpId;
  String? initialRole;
  try {
    final prefs = await SharedPreferences.getInstance();
    initialEmpId = prefs.getString('saved_emp_id');
    initialRole = prefs.getString('saved_role');
  } catch (_) {}

  // Initialize Native Push Notifications & Request 24/7 Background Exemption Permissions
  await PushNotificationService().requestAllPriorPermissions(empId: initialEmpId);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.pureWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final ecoProvider = EcosystemProvider();
  if (initialEmpId != null && initialEmpId.isNotEmpty) {
    ecoProvider.setLoggedIn(true);
    ecoProvider.setActiveEmpId(initialEmpId);
    ecoProvider.loadEmployeeFourPillars(initialEmpId);
  } else {
    ecoProvider.setLoggedIn(false);
  }

  runApp(
    ChangeNotifierProvider<EcosystemProvider>.value(
      value: ecoProvider,
      child: MnFamilyApp(
        initialEmpId: initialEmpId,
        initialRole: initialRole,
      ),
    ),
  );
}

class MnFamilyApp extends StatelessWidget {
  final String? initialEmpId;
  final String? initialRole;

  const MnFamilyApp({
    super.key,
    this.initialEmpId,
    this.initialRole,
  });

  Widget _resolveHomeScreen() {
    if (initialEmpId == null || initialEmpId!.isEmpty) {
      return const LoginScreen();
    }
    if (initialEmpId == 'MN-CEO01' || initialRole == 'ceo') {
      return const CeoSuiteScreen();
    }
    switch (initialRole) {
      case 'hr':
        return const HrPortalScreen();
      case 'dept_head':
      case 'team_lead':
        return const DeptHeadPortalScreen();
      case 'ceo':
        return const CeoSuiteScreen();
      case 'employee':
      default:
        return const EmployeePortalScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Process direct deep-link notification payload on post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.processPendingPayloadIfAny();
    });

    return MaterialApp(
      title: 'MN Family',
      navigatorKey: PushNotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.burgundySandTheme,
      home: _resolveHomeScreen(),
      builder: (context, child) => AppNotificationHost(
        child: InternetConnectionBanner(child: child!),
      ),
    );
  }
}
