import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/supabase/supabase_client.dart';

/// Lets a signed-in student join a teacher-created class by entering its
/// 6-character join code. Looks up the class on Supabase, then inserts a
/// row into `class_members`.
///
/// Returns the joined class name on success, null on cancel.
class JoinClassDialog extends StatefulWidget {
  const JoinClassDialog({super.key});

  @override
  State<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<JoinClassDialog> {
  final TextEditingController _ctrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final String code = _ctrl.text.trim().toUpperCase();
    final SupabaseClient db = SupabaseService.client;
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) {
      setState(() {
        _busy = false;
        _error = 'يجب تسجيل الدخول أولاً.';
      });
      return;
    }

    try {
      // Look up the class via a SECURITY DEFINER RPC so students cannot
      // SELECT all rows in `public.classes` (which would leak every
      // join code). The function returns only (id, name) of the matching
      // class — see supabase/migrations/0003_classes_lookup_rpc.sql.
      final dynamic raw = await db.rpc<dynamic>(
        'lookup_class_by_code',
        params: <String, dynamic>{'code': code},
      );
      final List<dynamic> rows =
          raw is List ? raw : const <dynamic>[];
      if (rows.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'رمز الانضمام غير صحيح.';
        });
        return;
      }

      final Map<String, dynamic> row =
          Map<String, dynamic>.from(rows.first as Map);
      final String classId = row['id'] as String;
      final String className = row['name'] as String;

      // ignoreDuplicates: true → INSERT … ON CONFLICT DO NOTHING, which
      // does not require an UPDATE RLS policy. Without this, re-joining a
      // class the student is already in fails with an RLS denial.
      await db.from('class_members').upsert(<String, dynamic>{
        'class_id': classId,
        'student_id': user.id,
      }, onConflict: 'class_id,student_id', ignoreDuplicates: true);

      if (!mounted) return;
      Navigator.of(context).pop(className);
    } on PostgrestException catch (e) {
      setState(() {
        _busy = false;
        _error = 'تعذّر الانضمام: ${e.message}';
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'تعذّر الاتصال بالخادم.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return AlertDialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'الانضمام إلى صف',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'أدخل رمز الانضمام (6 أحرف) الذي زوّدك به معلّمك.',
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
              decoration: const InputDecoration(
                hintText: 'ABC123',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
              onFieldSubmitted: (_) => _submit(),
              validator: (String? v) {
                if (v == null || v.trim().length < 6) {
                  return 'الرمز يجب أن يكون من 6 أحرف.';
                }
                return null;
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('انضمام'),
        ),
      ],
    );
  }
}
