import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/features/auth/auth_service.dart';
import 'package:studysync_syria/features/auth/login_screen.dart';
import 'package:studysync_syria/features/auth/signup_screen.dart';
import 'package:studysync_syria/features/home/home_screen.dart';
import 'package:studysync_syria/features/profile/profile_screen.dart';

/// Builds the [GoRouter] used by the app.
///
/// Auth state comes from [AuthService.instance] which is a [ChangeNotifier];
/// the router refreshes whenever auth changes so signed-out users get
/// redirected to /login automatically.
GoRouter buildRouter() {
  final AuthService auth = AuthService.instance;

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (BuildContext context, GoRouterState state) {
      final bool isAuthed = auth.isAuthenticated;
      final String location = state.matchedLocation;
      final bool onAuthScreen =
          location == '/login' || location == '/signup';

      if (!isAuthed && !onAuthScreen) return '/login';
      if (isAuthed && onAuthScreen) return '/home';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (BuildContext context, GoRouterState state) =>
            const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileScreen(),
      ),
    ],
  );
}
