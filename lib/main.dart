import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Mantengo tus imports
import 'firebase_options.dart';

// --- IMPORTANTE: Asegúrate de que esta ruta coincida con donde guardaste el archivo ---
import 'screens/splash_screen.dart'; 
import 'screens/home_screen.dart'; 
import 'screens/admin_panel.dart';

void main() async {
  // 1. Asegura que Flutter esté listo antes de iniciar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase usando las opciones específicas de tu proyecto
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduSmart', // Opcional: Cambié el título al nombre de tu app, puedes dejar 'App kahoot' si prefieres
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.blue
      ),
      // --- CAMBIO APLICADO: La aplicación ahora inicia en el SplashScreen ---
      home: const SplashScreen(), 
    );
  }
}