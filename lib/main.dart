import 'package:firebase_auth/firebase_auth.dart';
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

  // S-08: Only restore session if Firebase Auth has an authentic active user session
  String? initialEmpId;
  String? initialRole;
  try {
    // On web the persisted user is restored asynchronously, so wait briefly
    // for the first auth state instead of reading currentUser immediately.
    final restoredUser = FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
    if (restoredUser != null) {
      final prefs = await SharedPreferences.getInstance();
      initialEmpId = prefs.getString('saved_emp_id');
      initialRole = prefs.getString('saved_role');
    }
  } catch (_) {}

  // Initialize Native Push Notifications & Request 24/7 Background Exemption Permissions
  try {
    await PushNotificationService()
        .requestAllPriorPermissions(empId: initialEmpId)
        .timeout(const Duration(seconds: 3));
  } catch (_) {}

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
    // setActiveEmpId already loads the pillars; keep the saved role if the
    // staff directory has not streamed in yet.
    ecoProvider.setActiveEmpId(initialEmpId, fallbackRole: initialRole);
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

class MnFamilyApp extends StatefulWidget {
  final String? initialEmpId;
  final String? initialRole;

  const MnFamilyApp({
    super.key,
    this.initialEmpId,
    this.initialRole,
  });

  @override
  State<MnFamilyApp> createState() => _MnFamilyAppState();
}

class _MnFamilyAppState extends State<MnFamilyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Process a deep-link notification payload once, after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.processPendingPayloadIfAny();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final eco = Provider.of<EcosystemProvider>(context, listen: false);
      if (!eco.isLoggedIn) return;
      eco.checkAndResetDailySops();
      eco.checkAndDispatchCelebrations();
    }
  }

  Widget _resolveHomeScreen() {
    if (widget.initialEmpId == null || widget.initialEmpId!.isEmpty) {
      return const LoginScreen();
    }
    if (widget.initialEmpId == 'MN-CEO01' || widget.initialRole == 'ceo') {
      return const CeoSuiteScreen();
    }
    switch (widget.initialRole) {
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
