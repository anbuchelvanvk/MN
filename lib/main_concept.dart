import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/ecosystem_provider.dart';
import 'views/client_concept/concept_home_welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF620013),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => EcosystemProvider(),
      child: const MnFamilyConceptApp(),
    ),
  );
}

class MnFamilyConceptApp extends StatelessWidget {
  const MnFamilyConceptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MN Family • Client Concept',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFF620013),
        primaryColor: const Color(0xFF620013),
      ),
      home: const ConceptHomeWelcomeScreen(),
    );
  }
}
