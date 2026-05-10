import 'package:studysync_syria/features/solver/solver_models.dart';

/// Pure-Dart solver for **single-variable linear equations** of the
/// form `aX + b = cX + d` where `X` is one of the standard variable
/// letters (`x`, `y`, `z`, `n`, `t`).
///
/// It tokenises both sides into a stream of (sign, coefficient, var?)
/// terms, simplifies, isolates X, and returns a [Solution] with the
/// per-step cited rules so the UI can render a worked example.
class LinearEquationSolver {
  LinearEquationSolver._();

  /// Variable letters we'll recognise in a problem. Keeps the parser
  /// trivial — we only handle one variable per equation.
  static const String _varChars = 'xyznt';

  /// Returns `true` if [input] looks like a single-variable linear
  /// equation we can solve. Cheap: just checks for `=` and a
  /// recognised variable character.
  static bool canSolve(String input) {
    final String s = input.trim();
    if (!s.contains('=')) return false;
    for (int i = 0; i < s.length; i += 1) {
      if (_varChars.contains(s[i])) return true;
    }
    return false;
  }

  /// Solves [input] symbolically. Throws [SolverInputException] if
  /// the input is malformed.
  static Solution solve(String input) {
    final String raw = input.trim();
    final int eqIdx = raw.indexOf('=');
    if (eqIdx < 0) {
      throw const SolverInputException('المعادلة يجب أن تحتوي على علامة "=".');
    }
    final String left = raw.substring(0, eqIdx);
    final String right = raw.substring(eqIdx + 1);

    // Find the (single) variable character used.
    final String? variable = _detectVariable('$left$right');
    if (variable == null) {
      throw const SolverInputException(
        'لم نجد متغيّرًا (مثل x). جرّب: 2x + 3 = 7',
      );
    }

    final _LinearForm leftForm = _parseSide(left, variable);
    final _LinearForm rightForm = _parseSide(right, variable);

    final List<SolutionStep> steps = <SolutionStep>[];

    steps.add(SolutionStep(
      title: 'كتابة المعادلة',
      expression: '$left = $right',
      explanation: 'هذه المعادلة الأصلية كما أدخلتها.',
      rule: 'Given',
    ));

    // Move the variable terms to the left, constants to the right.
    final num combinedCoef = leftForm.coef - rightForm.coef;
    final num combinedConst = rightForm.constant - leftForm.constant;

    final String afterMove =
        '${_fmtCoef(combinedCoef, variable)} = ${_fmtNum(combinedConst)}';
    steps.add(SolutionStep(
      title: 'جمع الحدود المتشابهة',
      expression: afterMove,
      explanation: 'انقل كل الحدود التي تحتوي على $variable إلى الطرف الأيسر '
          'والحدود الثابتة إلى الطرف الأيمن، ثم اجمع كلًا منها.',
      rule: 'Like terms (الجمع الجبري)',
    ));

    if (combinedCoef == 0) {
      if (combinedConst == 0) {
        steps.add(const SolutionStep(
          title: 'حلول لانهائية',
          expression: '0 = 0',
          explanation: 'الطرفان متطابقان لأي قيمة لـ المتغير.',
          rule: 'Identity',
        ));
        return Solution(
          kind: SolutionKind.linearEquation,
          heading: 'حلّ المعادلة الخطية: $raw',
          steps: steps,
          finalAnswer: 'لا نهاية من الحلول',
        );
      } else {
        steps.add(SolutionStep(
          title: 'لا حلّ',
          expression: '0 = ${_fmtNum(combinedConst)}',
          explanation: 'بعد التبسيط أصبحت المعادلة عبارة كاذبة، '
              'إذًا لا توجد قيمة لـ $variable تحقّق المعادلة.',
          rule: 'Contradiction',
        ));
        return Solution(
          kind: SolutionKind.linearEquation,
          heading: 'حلّ المعادلة الخطية: $raw',
          steps: steps,
          finalAnswer: 'لا يوجد حلّ',
        );
      }
    }

    final num value = combinedConst / combinedCoef;
    steps.add(SolutionStep(
      title: 'القسمة لعزل $variable',
      expression:
          '$variable = ${_fmtNum(combinedConst)} ÷ ${_fmtNum(combinedCoef)}',
      explanation:
          'اقسم طرفَي المعادلة على معامل $variable للحصول على قيمة المتغير.',
      rule: 'Equality property of division',
    ));

    steps.add(SolutionStep(
      title: 'النتيجة',
      expression: '$variable = ${_fmtNum(value)}',
      explanation: 'هذه هي قيمة $variable التي تحقّق المعادلة.',
      rule: 'Final answer',
    ));

    return Solution(
      kind: SolutionKind.linearEquation,
      heading: 'حلّ المعادلة الخطية: $raw',
      steps: steps,
      finalAnswer: '$variable = ${_fmtNum(value)}',
    );
  }

  // ──────────────────────────── helpers ─────────────────────────────

  static String? _detectVariable(String s) {
    for (int i = 0; i < s.length; i += 1) {
      if (_varChars.contains(s[i])) return s[i];
    }
    return null;
  }

  /// Parses one side of an equation (e.g. "2x + 3 - 5x") into
  /// `coef * x + constant` form. Variable other than [variable] is
  /// rejected.
  static _LinearForm _parseSide(String side, String variable) {
    String s = side.replaceAll(' ', '');
    if (s.isEmpty) return const _LinearForm(coef: 0, constant: 0);

    // Make sure the first term has an explicit sign so the splitter
    // can tokenise uniformly.
    if (s[0] != '+' && s[0] != '-') {
      s = '+$s';
    }

    num coef = 0;
    num constant = 0;
    int i = 0;
    while (i < s.length) {
      // Each term starts with + or -.
      final String sign = s[i];
      if (sign != '+' && sign != '-') {
        throw SolverInputException('رمز غير متوقّع: "$sign".');
      }
      i += 1;
      // Read until the next + / - (this is the body of the term).
      int j = i;
      while (j < s.length && s[j] != '+' && s[j] != '-') {
        j += 1;
      }
      final String body = s.substring(i, j);
      i = j;
      if (body.isEmpty) {
        throw const SolverInputException('حدّ فارغ في المعادلة.');
      }
      // Split body into coef + (optional) variable.
      final int varIdx = body.indexOf(variable);
      if (varIdx < 0) {
        // pure constant
        final num? n = num.tryParse(body);
        if (n == null) {
          throw SolverInputException('لا يمكن قراءة الرقم: "$body".');
        }
        constant += sign == '+' ? n : -n;
      } else {
        // body looks like "<num>?<variable><rest>"
        final String head = body.substring(0, varIdx);
        final String tail = body.substring(varIdx + 1);
        if (tail.isNotEmpty) {
          throw SolverInputException(
              'لا يمكن قراءة الجزء بعد $variable في "$body".');
        }
        num c;
        if (head.isEmpty || head == '*') {
          c = 1;
        } else if (head == '-') {
          c = -1;
        } else {
          // Strip optional trailing '*' (e.g. "2*x").
          final String h = head.endsWith('*')
              ? head.substring(0, head.length - 1)
              : head;
          final num? n = num.tryParse(h);
          if (n == null) {
            throw SolverInputException('لا يمكن قراءة معامل $variable: "$h".');
          }
          c = n;
        }
        coef += sign == '+' ? c : -c;
      }
    }

    return _LinearForm(coef: coef, constant: constant);
  }

  static String _fmtCoef(num coef, String variable) {
    if (coef == 0) return '0';
    if (coef == 1) return variable;
    if (coef == -1) return '-$variable';
    return '${_fmtNum(coef)}$variable';
  }

  static String _fmtNum(num n) {
    if (n is int) return n.toString();
    final double d = n.toDouble();
    if (d == d.roundToDouble()) return d.toInt().toString();
    // Trim trailing zeros, max 4 decimals.
    String s = d.toStringAsFixed(4);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}

class _LinearForm {
  const _LinearForm({required this.coef, required this.constant});
  final num coef;
  final num constant;
}
