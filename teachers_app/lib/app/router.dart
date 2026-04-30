import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/features/assignments/assignment_builder_screen.dart';
import 'package:studysync_syria_teachers/features/assignments/assignment_submissions_screen.dart';
import 'package:studysync_syria_teachers/features/assignments/assignments_list_screen.dart';
import 'package:studysync_syria_teachers/features/auth/auth_service.dart';
import 'package:studysync_syria_teachers/features/auth/login_screen.dart';
import 'package:studysync_syria_teachers/features/auth/signup_screen.dart';
import 'package:studysync_syria_teachers/features/classes/classes_list_screen.dart';
import 'package:studysync_syria_teachers/features/classes/class_detail_screen.dart';
import 'package:studysync_syria_teachers/features/curriculum/curriculum_list_screen.dart';
import 'package:studysync_syria_teachers/features/curriculum/curriculum_models.dart';
import 'package:studysync_syria_teachers/features/curriculum/lesson_editor_screen.dart';
import 'package:studysync_syria_teachers/features/students/student_detail_screen.dart';
import 'package:studysync_syria_teachers/features/profile/profile_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/classes',
    refreshListenable: AuthService.instance,
    redirect: (BuildContext context, GoRouterState state) {
      final bool authed = AuthService.instance.isAuthenticated;
      final bool onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (!authed && !onAuth) return '/login';
      if (authed && onAuth) return '/classes';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const SignupScreen()),
      ),
      GoRoute(
        path: '/classes',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const ClassesListScreen()),
      ),
      GoRoute(
        path: '/classes/:classId',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String classId = state.pathParameters['classId']!;
          final String className =
              (state.extra as Map<String, dynamic>?)?['name'] as String? ??
                  'الصف';
          return _slidePage(
            state,
            ClassDetailScreen(classId: classId, className: className),
          );
        },
      ),
      GoRoute(
        path: '/students/:studentId',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String studentId = state.pathParameters['studentId']!;
          final String displayName =
              (state.extra as Map<String, dynamic>?)?['name'] as String? ??
                  'طالب';
          return _slidePage(
            state,
            StudentDetailScreen(
              studentId: studentId,
              displayName: displayName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/classes/:classId/assignments',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String classId = state.pathParameters['classId']!;
          final String className =
              (state.extra as Map<String, dynamic>?)?['name'] as String? ??
                  'الصف';
          return _slidePage(
            state,
            AssignmentsListScreen(
              classId: classId,
              className: className,
            ),
          );
        },
      ),
      GoRoute(
        path: '/classes/:classId/assignments/new',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String classId = state.pathParameters['classId']!;
          final String className = (state.extra
                  as Map<String, dynamic>?)?['className'] as String? ??
              'الصف';
          return _slidePage(
            state,
            AssignmentBuilderScreen(
              classId: classId,
              className: className,
            ),
          );
        },
      ),
      GoRoute(
        path: '/assignments/:assignmentId/submissions',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String aId = state.pathParameters['assignmentId']!;
          final String title =
              (state.extra as Map<String, dynamic>?)?['title'] as String? ??
                  'الواجب';
          return _slidePage(
            state,
            AssignmentSubmissionsScreen(
              assignmentId: aId,
              title: title,
            ),
          );
        },
      ),
      GoRoute(
        path: '/curriculum',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const CurriculumListScreen()),
      ),
      GoRoute(
        path: '/curriculum/new',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const LessonEditorScreen()),
      ),
      GoRoute(
        path: '/curriculum/:lessonId',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final CustomLesson? existing = state.extra is CustomLesson
              ? state.extra as CustomLesson
              : null;
          if (existing == null) {
            // Direct deep-link without payload: bounce back to list.
            return _slidePage(state, const CurriculumListScreen());
          }
          return _slidePage(
            state,
            LessonEditorScreen(existing: existing),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const ProfileScreen()),
      ),
    ],
  );
}

CustomTransitionPage<Object?> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<Object?>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (BuildContext _, Animation<double> animation,
            Animation<double> __, Widget child) =>
        FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    ),
  );
}
