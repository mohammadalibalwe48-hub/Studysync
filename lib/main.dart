import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:studysync_syria/app/app.dart';
import 'package:studysync_syria/core/services/bookmarks_service.dart';
import 'package:studysync_syria/core/services/notifications_service.dart';
import 'package:studysync_syria/core/services/study_goal_service.dart';
import 'package:studysync_syria/core/services/study_pattern_service.dart';
import 'package:studysync_syria/core/services/theme_service.dart';
import 'package:studysync_syria/core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await SupabaseService.init();
  // Warm up local-only services so the first frame already has the
  // user's saved theme / bookmarks / daily-goal data.
  await Future.wait<void>(<Future<void>>[
    ThemeService.instance.load(),
    BookmarksService.instance.load(),
    StudyGoalService.instance.load(),
    StudyPatternService.instance.load(),
    NotificationsService.instance.init(),
  ]);
  // Refresh smart-notification schedules in the background; never
  // blocks first-frame paint.
  unawaited(NotificationsService.instance.refreshSchedules());
  runApp(const StudySyncApp());
}
