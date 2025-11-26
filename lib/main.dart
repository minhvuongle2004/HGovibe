import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/trip_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/map_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/account_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/auth/auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Khởi tạo locale data cho intl (tiếng Việt)
  await initializeDateFormatting('vi', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Travel App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/sign-up': (context) => const SignUpScreen(),
        '/home': (context) => const AuthGuard(child: HomeScreen()),
        '/favorites': (context) => const AuthGuard(child: FavoritesScreen()),
        '/map': (context) => const AuthGuard(child: MapScreen()),
        '/trips': (context) => const AuthGuard(child: TripsScreen()),
        '/account': (context) => const AuthGuard(child: AccountScreen()),
      },
    );
  }
}