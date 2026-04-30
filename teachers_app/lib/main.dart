import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:studysync_syria_teachers/app/app.dart';
import 'package:studysync_syria_teachers/core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await SupabaseService.init();
  runApp(const TeachersApp());
}
