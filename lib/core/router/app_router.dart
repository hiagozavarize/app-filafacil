import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/queue/presentation/screens/add_to_queue_screen.dart';
import '../../features/queue/presentation/screens/consult_queue_screen.dart';
import '../../features/queue/presentation/screens/patient_call_screen.dart';
import '../../features/queue/presentation/screens/ticket_receipt_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';

/// Roteador declarativo (`GoRouter`) mapeando todas as 11 telas do fluxo completo no Figma.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/add-to-queue',
        name: 'add-to-queue',
        builder: (context, state) => const AddToQueueScreen(),
      ),
      GoRoute(
        path: '/ticket-receipt',
        name: 'ticket-receipt',
        builder: (context, state) => const TicketReceiptScreen(),
      ),
      GoRoute(
        path: '/consult-queue',
        name: 'consult-queue',
        builder: (context, state) => const ConsultQueueScreen(),
      ),
      GoRoute(
        path: '/patient-call',
        name: 'patient-call',
        builder: (context, state) => const PatientCallScreen(),
      ),
      GoRoute(
        path: '/stats',
        name: 'stats',
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );
});

