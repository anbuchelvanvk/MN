import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/services/network_connectivity_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/session_store.dart';
import 'core/widgets/internet_connection_banner.dart';
import 'core/widgets/app_notification_host.dart';
import 'providers/ecosystem_provider.dart';
import 'views/auth/login_screen.dart';
import 'views/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app font (Outfit) is bundled in assets/google_fonts, so text looks
  // right from the first launch, even offline.
  GoogleFonts.config.allowRuntimeFetching = false;
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization status: $e');
  }

  // Initialize Network Connectivity Monitoring
  NetworkConnectivityService().initialize();

  // Restore the signed-in session (stays logged in until the user taps Logout).
  String? initialEmpId;
  String? initialRole;
  try {
    final session = await SessionStore.restore();
    if (session != null) {
      initialEmpId = session.empId;
      initialRole = session.role;
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
    if (widget.initialEmpId == 'MN-CEO01') {
      return const MainShell(role: 'ceo');
    }
    return MainShell.forRole(widget.initialRole);
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
