import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/features/assignments/assignment_models.dart';
import 'package:studysync_syria/features/assignments/assignments_list_screen.dart';
import 'package:studysync_syria/features/assignments/take_assignment_screen.dart';
import 'package:studysync_syria/features/auth/auth_service.dart';
import 'package:studysync_syria/features/auth/login_screen.dart';
import 'package:studysync_syria/features/auth/signup_screen.dart';
import 'package:studysync_syria/features/curriculum/custom_lesson_models.dart';
import 'package:studysync_syria/features/curriculum/custom_topic_detail_screen.dart';
import 'package:studysync_syria/features/exams/exam_questions_screen.dart';
import 'package:studysync_syria/features/home/home_screen.dart';
import 'package:studysync_syria/features/profile/profile_screen.dart';
import 'package:studysync_syria/features/progress/progress_screen.dart';
import 'package:studysync_syria/features/quiz/quick_quiz_screen.dart';
import 'package:studysync_syria/features/subjects/topic_list_screen.dart';
import 'package:studysync_syria/features/topics/topic_detail_screen.dart';

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
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const SignupScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/subjects/:subjectId',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String subjectId = state.pathParameters['subjectId'] ?? '';
          return _slidePage(state, TopicListScreen(subjectId: subjectId));
        },
      ),
      GoRoute(
        path: '/topics/:topicId',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String topicId = state.pathParameters['topicId'] ?? '';
          return _slidePage(state, TopicDetailScreen(topicId: topicId));
        },
      ),
      GoRoute(
        path: '/quick-quiz',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const QuickQuizScreen()),
      ),
      GoRoute(
        path: '/exam-questions',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const ExamQuestionsScreen()),
      ),
      GoRoute(
        path: '/assignments',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const StudentAssignmentsScreen()),
      ),
      GoRoute(
        path: '/assignments/:assignmentId',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final StudentAssignment? a =
              state.extra is StudentAssignment
                  ? state.extra as StudentAssignment
                  : null;
          if (a == null) {
            // Direct deep-link without payload: bounce back to list.
            return _slidePage(
                state, const StudentAssignmentsScreen());
          }
          return _slidePage(
              state, TakeAssignmentScreen(assignment: a));
        },
      ),
      GoRoute(
        path: '/custom-lesson/:lessonId',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final StudentCustomLesson? lesson =
              state.extra is StudentCustomLesson
                  ? state.extra as StudentCustomLesson
                  : null;
          if (lesson == null) {
            return _slidePage(state, const CustomTopicDetailMissingScreen());
          }
          return _slidePage(
            state,
            CustomTopicDetailScreen(lesson: lesson),
          );
        },
      ),
      GoRoute(
        path: '/progress',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const ProgressScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const ProfileScreen()),
      ),
    ],
  );
}

/// Cross-fade with a tiny upward slide. Used for "tab" level routes
/// where there is no spatial relationship between source and target.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder:
        (BuildContext context, Animation<double> animation, _, Widget child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Right-to-left slide used for "drill-in" routes (subject → topics →
/// topic detail) where the user perceives forward motion.
CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder:
        (BuildContext context, Animation<double> animation, _, Widget child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
