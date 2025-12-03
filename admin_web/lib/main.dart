import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/users/users_screen.dart';
import 'screens/users/user_detail_screen.dart';
import 'screens/destinations/destinations_screen.dart';
import 'screens/destinations/destination_form_screen.dart';
import 'screens/tours/tours_screen.dart';
import 'screens/tours/tour_form_screen.dart';
import 'screens/bookings/bookings_screen.dart';
import 'screens/bookings/booking_detail_screen.dart';
import 'services/admin_service.dart';
import 'widgets/admin_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const AdminWebApp());
}

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  // Router configuration
  static final GoRouter _router = GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isLoginRoute = state.matchedLocation == '/login';

      // Nếu chưa login và không phải login route
      if (user == null && !isLoginRoute) {
        return '/login';
      }

      // Nếu đã login, check admin
      if (user != null) {
        final isAdmin = await AdminService.isAdminUser(user.uid);
        if (!isAdmin && !isLoginRoute) {
          return '/login';
        }
        if (isAdmin && isLoginRoute) {
          return '/dashboard';
        }
      }

      return null; // No redirect
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Shell route - chỉ có 1 instance, sidebar không bị reload
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayout(
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/users/:userId',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return UserDetailScreen(userId: userId);
            },
          ),
          GoRoute(
            path: '/destinations',
            builder: (context, state) => const DestinationsScreen(),
          ),
          GoRoute(
            path: '/destinations/new',
            builder: (context, state) => const DestinationFormScreen(),
          ),
          GoRoute(
            path: '/destinations/:destinationId/edit',
            builder: (context, state) {
              final destinationId = state.pathParameters['destinationId']!;
              return DestinationFormScreen(destinationId: destinationId);
            },
          ),
          GoRoute(
            path: '/tours',
            builder: (context, state) => const ToursScreen(),
          ),
          GoRoute(
            path: '/tours/new',
            builder: (context, state) => const TourFormScreen(),
          ),
          GoRoute(
            path: '/tours/:tourId/edit',
            builder: (context, state) {
              final tourId = state.pathParameters['tourId']!;
              return TourFormScreen(tourId: tourId);
            },
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsScreen(),
          ),
          GoRoute(
            path: '/bookings/:bookingId',
            builder: (context, state) {
              final bookingId = state.pathParameters['bookingId']!;
              return BookingDetailScreen(bookingId: bookingId);
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Admin - Smart Travel App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      routerConfig: _router,
    );
  }
}

/// Wrapper để check authentication và admin status
/// Sử dụng GoRouter redirect để handle authentication
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // Check admin status
        return FutureBuilder<bool>(
          future: AdminService.isAdminUser(user.uid),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final isAdmin = adminSnapshot.data ?? false;
            if (!isAdmin) {
              return const LoginScreen();
            }

            // Admin authenticated, router will handle navigation
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
