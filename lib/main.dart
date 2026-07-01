import 'package:ea_master_demo/auth/authService.dart';
import 'package:ea_master_demo/services/career_service.dart';
import 'package:ea_master_demo/auth/authWrapper.dart';
import 'package:ea_master_demo/screens/splashScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';


import 'package:ea_master_demo/services/train_service.dart';
import 'package:ea_master_demo/services/tts_service.dart';

// If you have a generated firebase_options.dart, import it:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // uncomment if using generated options
  );

  // Register Services as permanent singletons
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<CareerService>(CareerService(), permanent: true);
  Get.put<TrainService>(TrainService(), permanent: true);
  Get.put<TtsService>(TtsService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Short Master',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // add Inter to pubspec if desired
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF38BDF8),
          secondary: const Color(0xFF84CC16),
          surface: const Color(0xFF1E293B),
          background: const Color(0xFF0F172A),
        ),
      ),
      // Show splash first, then AuthWrapper takes over
      home: const _RootDecider(),
    );
  }
}

/// Shows [SplashScreen] for 3 s, then yields to [AuthWrapper].
class _RootDecider extends StatefulWidget {
  const _RootDecider();

  @override
  State<_RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<_RootDecider> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash ? SplashScreen() : AuthWrapper();
  }
}