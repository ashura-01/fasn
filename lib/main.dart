import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await HiveService.init();
  await NotificationService.init();
  await HiveService.seedAffirmationsIfEmpty();

  runApp(const FasnApp());
}

class FasnApp extends StatelessWidget {
  const FasnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fasn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
