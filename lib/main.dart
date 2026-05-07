import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint("--- 🚀 Démarrage de l'application ---");

  try {
    debugPrint("Initialisation de la localisation (fr)...");
    await initializeDateFormatting('fr', null);
  } catch (e) {
    debugPrint("⚠️ Erreur localisation: $e");
  }

  try {
    debugPrint("Initialisation Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialisé");
  } catch (e) {
    debugPrint("ℹ️ Firebase initialization info (normal si sur Windows sans config): $e");
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: const QueueBuddyApp(),
    ),
  );
}

class QueueBuddyApp extends StatelessWidget {
  const QueueBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Queue Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
