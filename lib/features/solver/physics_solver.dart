import 'package:studysync_syria/features/solver/solver_models.dart';

/// Local physics formula solver.
///
/// The student enters a comma-separated list of `name=value` pairs
/// (e.g. `V=12, R=4`) along with the symbol they want to solve for.
/// We pattern-match the *set of supplied symbols* against a small
/// hand-curated rules table and apply the matching formula step by
/// step, citing the underlying law (Ohm, Newton II, etc.).
class PhysicsFormulaSolver {
  PhysicsFormulaSolver._();

  /// One rule = one formula + which sets of given variables it can
  /// solve. Adding a new physics relation is a one-line append.
  static final List<_Rule> _rules = <_Rule>[
    // Ohm's law: V = IR
    _Rule(
      lawArabic: 'قانون أوم',
      lawCitation: "Ohm's Law: V = I × R",
      solutions: <Set<String>, _RuleSolver>{
        <String>{'V', 'I', 'R'}.toSet(): (Map<String, double> g) =>
            _solveOhm(g),
      },
      summary: 'يربط الجهد (V) مع التيار (I) والمقاومة (R) في دارة كهربائية.',
    ),
    // Newton's second law: F = m·a
    _Rule(
      lawArabic: 'قانون نيوتن الثاني',
      lawCitation: "Newton's Second Law: F = m × a",
      solutions: <Set<String>, _RuleSolver>{
        <String>{'F', 'm', 'a'}.toSet(): (Map<String, double> g) =>
            _solveNewtonII(g),
      },
      summary:
          'يحدّد القوة (F) كحاصل ضرب الكتلة (m) في تسارعها (a).',
    ),
    // Kinetic energy: KE = 0.5·m·v²
    _Rule(
      lawArabic: 'الطاقة الحركية',
      lawCitation: 'Kinetic Energy: KE = ½ × m × v²',
      solutions: <Set<String>, _RuleSolver>{
        <String>{'KE', 'm', 'v'}.toSet(): (Map<String, double> g) =>
            _solveKE(g),
      },
      summary: 'الطاقة الحركية لجسم كتلته m وسرعته v.',
    ),
    // Gravitational potential energy: PE = m·g·h
    _Rule(
      lawArabic: 'طاقة الوضع الجاذبية',
      lawCitation: 'Gravitational PE: PE = m × g × h',
      solutions: <Set<String>, _RuleSolver>{
        <String>{'PE', 'm', 'g', 'h'}.toSet(): (Map<String, double> g) =>
            _solvePE(g),
      },
      summary: 'طاقة الوضع لجسم على ارتفاع h ضمن تسارع جاذبي g.',
    ),
    // Conservation of energy: KE_i + PE_i = KE_f + PE_f
    _Rule(
      lawArabic: 'حفظ الطاقة الميكانيكية',
      lawCitation: 'Conservation of Energy: KE_i + PE_i = KE_f + PE_f',
      solutions: <Set<String>, _RuleSolver>{
        <String>{'KE_i', 'PE_i', 'KE_f', 'PE_f'}.toSet():
            (Map<String, double> g) => _solveConservation(g),
      },
      summary:
          'مجموع الطاقة الحركية والكامنة في نظام معزول يبقى ثابتًا.',
    ),
  ];

  /// Top-level dispatch: parse the input, find a matching rule, and
  /// run it.
  static Solution solve(String input, {required String solveFor}) {
    final Map<String, double> givens = _parseGivens(input);
    if (givens.isEmpty) {
      throw const SolverInputException(
        'أدخل القيم بالصيغة: V=12, R=4',
      );
    }
    if (solveFor.isEmpty) {
      throw const SolverInputException('حدّد الرمز الذي تريد إيجاد قيمته.');
    }
    if (givens.containsKey(solveFor)) {
      throw SolverInputException(
        'الرمز "$solveFor" موجود ضمن المعطيات؛ احذفه ثم اطلب الحلّ.',
      );
    }

    // Collect "what we know plus what we want" — the rule signature.
    final Set<String> signature = <String>{...givens.keys, solveFor};
    for (final _Rule rule in _rules) {
      for (final MapEntry<Set<String>, _RuleSolver> entry
          in rule.solutions.entries) {
        if (_setEquals(entry.key, signature)) {
          return entry.value(<String, double>{...givens, '__solveFor': 0})
              ._intoSolution(rule, solveFor, givens);
        }
      }
    }

    throw SolverInputException(
      'لا توجد قاعدة فيزيائية مدعومة تطابق المعطيات: '
      '${signature.join(', ')}.',
    );
  }

  /// Recognises `Symbol=Number` pairs separated by commas, semicolons
  /// or spaces. Symbols may contain letters, underscores or digits
  /// (so `KE_i` works).
  static Map<String, double> _parseGivens(String input) {
    final Map<String, double> out = <String, double>{};
    final List<String> chunks =
        input.split(RegExp('[,;\n]')).where((String s) => s.trim().isNotEmpty).toList();
    for (final String chunk in chunks) {
      final int eq = chunk.indexOf('=');
      if (eq <= 0) {
        throw SolverInputException('قيمة غير صالحة: "${chunk.trim()}"');
      }
      final String name = chunk.substring(0, eq).trim();
      final String raw = chunk.substring(eq + 1).trim();
      final double? n = double.tryParse(raw);
      if (n == null) {
        throw SolverInputException('لا يمكن قراءة الرقم: "$raw".');
      }
      out[name] = n;
    }
    return out;
  }

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final String x in a) {
      if (!b.contains(x)) return false;
    }
    return true;
  }

  // ─────────────────────────── rule bodies ──────────────────────────

  static _PhysicsResult _solveOhm(Map<String, double> g) {
    if (g.containsKey('V') && g.containsKey('I')) {
      // Solve for R
      final double v = g['V']!;
      final double i = g['I']!;
      if (i == 0) {
        throw const SolverInputException('قسمة على صفر: التيار I = 0.');
      }
      final double r = v / i;
      return _PhysicsResult(
        steps: <SolutionStep>[
          SolutionStep(
            title: 'كتابة قانون أوم',
            expression: 'V = I × R',
            explanation: 'الجهد يساوي حاصل ضرب التيار في المقاومة.',
            rule: "Ohm's Law",
          ),
          SolutionStep(
            title: 'عزل المقاومة',
            expression: 'R = V ÷ I',
            explanation: 'اقسم طرفَي المعادلة على I.',
            rule: 'Equality property of division',
          ),
          SolutionStep(
            title: 'استبدال القيم',
            expression: 'R = ${_fmt(v)} ÷ ${_fmt(i)}',
            explanation: 'عوّض الجهد والتيار من المعطيات.',
            rule: 'Substitution',
          ),
          SolutionStep(
            title: 'حساب القيمة',
            expression: 'R = ${_fmt(r)} Ω',
            explanation: 'ناتج القسمة هو قيمة المقاومة بالأوم.',
            rule: 'Arithmetic',
          ),
        ],
        finalAnswer: 'R = ${_fmt(r)} Ω',
      );
    }
    if (g.containsKey('V') && g.containsKey('R')) {
      final double v = g['V']!;
      final double r = g['R']!;
      if (r == 0) {
        throw const SolverInputException('قسمة على صفر: المقاومة R = 0.');
      }
      final double i = v / r;
      return _PhysicsResult(
        steps: <SolutionStep>[
          const SolutionStep(
            title: 'كتابة قانون أوم',
            expression: 'V = I × R',
            explanation: 'الجهد يساوي حاصل ضرب التيار في المقاومة.',
            rule: "Ohm's Law",
          ),
          const SolutionStep(
            title: 'عزل التيار',
            expression: 'I = V ÷ R',
            explanation: 'اقسم طرفَي المعادلة على R.',
            rule: 'Equality property of division',
          ),
          SolutionStep(
            title: 'استبدال القيم',
            expression: 'I = ${_fmt(v)} ÷ ${_fmt(r)}',
            explanation: 'عوّض الجهد والمقاومة من المعطيات.',
            rule: 'Substitution',
          ),
          SolutionStep(
            title: 'حساب القيمة',
            expression: 'I = ${_fmt(i)} A',
            explanation: 'ناتج القسمة هو شدّة التيار بالأمبير.',
            rule: 'Arithmetic',
          ),
        ],
        finalAnswer: 'I = ${_fmt(i)} A',
      );
    }
    // Solve for V given I, R.
    final double i = g['I']!;
    final double r = g['R']!;
    final double v = i * r;
    return _PhysicsResult(
      steps: <SolutionStep>[
        const SolutionStep(
          title: 'كتابة قانون أوم',
          expression: 'V = I × R',
          explanation: 'الجهد يساوي حاصل ضرب التيار في المقاومة.',
          rule: "Ohm's Law",
        ),
        SolutionStep(
          title: 'استبدال القيم',
          expression: 'V = ${_fmt(i)} × ${_fmt(r)}',
          explanation: 'عوّض التيار والمقاومة من المعطيات.',
          rule: 'Substitution',
        ),
        SolutionStep(
          title: 'حساب القيمة',
          expression: 'V = ${_fmt(v)} V',
          explanation: 'حاصل الضرب هو قيمة الجهد بالفولت.',
          rule: 'Arithmetic',
        ),
      ],
      finalAnswer: 'V = ${_fmt(v)} V',
    );
  }

  static _PhysicsResult _solveNewtonII(Map<String, double> g) {
    if (g.containsKey('m') && g.containsKey('a')) {
      final double m = g['m']!;
      final double a = g['a']!;
      final double f = m * a;
      return _PhysicsResult(
        steps: <SolutionStep>[
          const SolutionStep(
            title: 'كتابة قانون نيوتن الثاني',
            expression: 'F = m × a',
            explanation: 'القوّة المحصّلة تساوي الكتلة في التسارع.',
            rule: "Newton's Second Law",
          ),
          SolutionStep(
            title: 'استبدال القيم',
            expression: 'F = ${_fmt(m)} × ${_fmt(a)}',
            explanation: 'عوّض الكتلة والتسارع من المعطيات.',
            rule: 'Substitution',
          ),
          SolutionStep(
            title: 'حساب القيمة',
            expression: 'F = ${_fmt(f)} N',
            explanation: 'حاصل الضرب هو القوّة بالنيوتن.',
            rule: 'Arithmetic',
          ),
        ],
        finalAnswer: 'F = ${_fmt(f)} N',
      );
    }
    if (g.containsKey('F') && g.containsKey('m')) {
      final double f = g['F']!;
      final double m = g['m']!;
      if (m == 0) {
        throw const SolverInputException('قسمة على صفر: الكتلة m = 0.');
      }
      final double a = f / m;
      return _PhysicsResult(
        steps: <SolutionStep>[
          const SolutionStep(
            title: 'كتابة قانون نيوتن الثاني',
            expression: 'F = m × a',
            explanation: 'القوّة المحصّلة تساوي الكتلة في التسارع.',
            rule: "Newton's Second Law",
          ),
          const SolutionStep(
            title: 'عزل التسارع',
            expression: 'a = F ÷ m',
            explanation: 'اقسم طرفَي المعادلة على الكتلة.',
            rule: 'Equality property of division',
          ),
          SolutionStep(
            title: 'استبدال القيم',
            expression: 'a = ${_fmt(f)} ÷ ${_fmt(m)}',
            explanation: 'عوّض القوة والكتلة من المعطيات.',
            rule: 'Substitution',
          ),
          SolutionStep(
            title: 'حساب القيمة',
            expression: 'a = ${_fmt(a)} m/s²',
            explanation: 'ناتج القسمة هو التسارع.',
            rule: 'Arithmetic',
          ),
        ],
        finalAnswer: 'a = ${_fmt(a)} m/s²',
      );
    }
    // F, a known → m
    final double f = g['F']!;
    final double a = g['a']!;
    if (a == 0) {
      throw const SolverInputException('قسمة على صفر: التسارع a = 0.');
    }
    final double m = f / a;
    return _PhysicsResult(
      steps: <SolutionStep>[
        const SolutionStep(
          title: 'كتابة قانون نيوتن الثاني',
          expression: 'F = m × a',
          explanation: 'القوّة المحصّلة تساوي الكتلة في التسارع.',
          rule: "Newton's Second Law",
        ),
        const SolutionStep(
          title: 'عزل الكتلة',
          expression: 'm = F ÷ a',
          explanation: 'اقسم طرفَي المعادلة على التسارع.',
          rule: 'Equality property of division',
        ),
        SolutionStep(
          title: 'استبدال القيم',
          expression: 'm = ${_fmt(f)} ÷ ${_fmt(a)}',
          explanation: 'عوّض القوة والتسارع من المعطيات.',
          rule: 'Substitution',
        ),
        SolutionStep(
          title: 'حساب القيمة',
          expression: 'm = ${_fmt(m)} kg',
          explanation: 'ناتج القسمة هو الكتلة بالكيلوغرام.',
          rule: 'Arithmetic',
        ),
      ],
      finalAnswer: 'm = ${_fmt(m)} kg',
    );
  }

  static _PhysicsResult _solveKE(Map<String, double> g) {
    if (g.containsKey('m') && g.containsKey('v')) {
      final double m = g['m']!;
      final double v = g['v']!;
      final double ke = 0.5 * m * v * v;
      return _PhysicsResult(
        steps: <SolutionStep>[
          const SolutionStep(
            title: 'كتابة معادلة الطاقة الحركية',
            expression: 'KE = ½ × m × v²',
            explanation: 'تعريف الطاقة الحركية لجسم متحرّك.',
            rule: 'Kinetic Energy formula',
          ),
          SolutionStep(
            title: 'استبدال القيم',
            expression: 'KE = ½ × ${_fmt(m)} × (${_fmt(v)})²',
            explanation: 'عوّض الكتلة والسرعة من المعطيات.',
            rule: 'Substitution',
          ),
          SolutionStep(
            title: 'حساب القيمة',
            expression: 'KE = ${_fmt(ke)} J',
            explanation: 'ناتج العملية هو الطاقة الحركية بالجول.',
            rule: 'Arithmetic',
          ),
        ],
        finalAnswer: 'KE = ${_fmt(ke)} J',
      );
    }
    if (g.containsKey('KE') && g.containsKey('m')) {
      final double ke = g['KE']!;
      final double m = g['m']!;
      if (m <= 0) {
        throw const SolverInputException('الكتلة يجب أن تكون موجبة.');
      }
      final double v = (2 * ke / m).abs();
      final double sqrtV = _sqrt(v);
      return _PhysicsResult(
        steps: <SolutionStep>[
          const SolutionStep(
            title: 'كتابة معادلة الطاقة الحركية',
            expression: 'KE = ½ × m × v²',
            explanation: 'تعريف الطاقة الحركية لجسم متحرّك.',
            rule: 'Kinetic Energy formula',
          ),
          const SolutionStep(
            title: 'عزل v²',
            expression: 'v² = (2 × KE) ÷ m',
            explanation: 'اضرب طرفَي المعادلة في 2 ثم اقسم على m.',
            rule: 'Equality property of multiplication and division',
          ),
          SolutionStep(
            title: 'استبدال القيم',
            expression: 'v² = (2 × ${_fmt(ke)}) ÷ ${_fmt(m)} = ${_fmt(v)}',
            explanation: 'احسب قيمة مربّع السرعة.',
            rule: 'Substitution',
          ),
          SolutionStep(
            title: 'الجذر التربيعي',
            expression: 'v = √${_fmt(v)} ≈ ${_fmt(sqrtV)} m/s',
            explanation: 'خذ الجذر التربيعي للحصول على السرعة.',
            rule: 'Square root',
          ),
        ],
        finalAnswer: 'v ≈ ${_fmt(sqrtV)} m/s',
      );
    }
    // KE, v known → m
    final double ke = g['KE']!;
    final double v = g['v']!;
    if (v == 0) {
      throw const SolverInputException('قسمة على صفر: السرعة v = 0.');
    }
    final double m = (2 * ke) / (v * v);
    return _PhysicsResult(
      steps: <SolutionStep>[
        const SolutionStep(
          title: 'كتابة معادلة الطاقة الحركية',
          expression: 'KE = ½ × m × v²',
          explanation: 'تعريف الطاقة الحركية لجسم متحرّك.',
          rule: 'Kinetic Energy formula',
        ),
        const SolutionStep(
          title: 'عزل الكتلة',
          expression: 'm = (2 × KE) ÷ v²',
          explanation: 'اضرب طرفَي المعادلة في 2 ثم اقسم على v².',
          rule: 'Equality property of multiplication and division',
        ),
        SolutionStep(
          title: 'استبدال القيم',
          expression:
              'm = (2 × ${_fmt(ke)}) ÷ (${_fmt(v)})² = ${_fmt(m)} kg',
          explanation: 'عوّض الطاقة والسرعة من المعطيات.',
          rule: 'Substitution',
        ),
      ],
      finalAnswer: 'm = ${_fmt(m)} kg',
    );
  }

  static _PhysicsResult _solvePE(Map<String, double> g) {
    if (g.containsKey('m') && g.containsKey('g') && g.containsKey('h')) {
      final double m = g['m']!;
      final double gv = g['g']!;
      final double h = g['h']!;
      final double pe = m * gv * h;
      return _PhysicsResult(
        steps: <SolutionStep>[
          const SolutionStep(
            title: 'كتابة معادلة طاقة الوضع الجاذبية',
            expression: 'PE = m × g × h',
            explanation: 'تعريف طاقة الوضع لجسم على ارتفاع h.',
            rule: 'Gravitational PE formula',
          ),
          SolutionStep(
            title: 'استبدال القيم',
            expression: 'PE = ${_fmt(m)} × ${_fmt(gv)} × ${_fmt(h)}',
            explanation: 'عوّض الكتلة وتسارع الجاذبية والارتفاع.',
            rule: 'Substitution',
          ),
          SolutionStep(
            title: 'حساب القيمة',
            expression: 'PE = ${_fmt(pe)} J',
            explanation: 'حاصل الضرب هو طاقة الوضع بالجول.',
            rule: 'Arithmetic',
          ),
        ],
        finalAnswer: 'PE = ${_fmt(pe)} J',
      );
    }
    // Otherwise, isolate the missing variable.
    final double pe = g['PE']!;
    final Map<String, double> known = <String, double>{
      for (final MapEntry<String, double> e in g.entries)
        if (e.key != 'PE' && e.key != '__solveFor') e.key: e.value,
    };
    final List<String> missing =
        <String>['m', 'g', 'h'].where((String k) => !known.containsKey(k)).toList();
    if (missing.length != 1) {
      throw const SolverInputException(
        'يجب توفير ثلاث متغيرات بالضبط من الأربعة: PE, m, g, h.',
      );
    }
    final String target = missing.first;
    final double prod =
        known.values.fold<double>(1, (double acc, double x) => acc * x);
    if (prod == 0) {
      throw const SolverInputException('قسمة على صفر بين المعطيات.');
    }
    final double value = pe / prod;
    return _PhysicsResult(
      steps: <SolutionStep>[
        const SolutionStep(
          title: 'كتابة معادلة طاقة الوضع الجاذبية',
          expression: 'PE = m × g × h',
          explanation: 'تعريف طاقة الوضع لجسم على ارتفاع h.',
          rule: 'Gravitational PE formula',
        ),
        SolutionStep(
          title: 'عزل $target',
          expression: '$target = PE ÷ (${known.keys.join(' × ')})',
          explanation: 'اقسم طرفَي المعادلة على حاصل ضرب المتغيّرات الأخرى.',
          rule: 'Equality property of division',
        ),
        SolutionStep(
          title: 'استبدال القيم',
          expression: '$target = ${_fmt(pe)} ÷ ${_fmt(prod)} = ${_fmt(value)}',
          explanation: 'عوّض المعطيات لحساب القيمة.',
          rule: 'Substitution',
        ),
      ],
      finalAnswer: '$target = ${_fmt(value)}',
    );
  }

  static _PhysicsResult _solveConservation(Map<String, double> g) {
    final Map<String, double> known = <String, double>{
      for (final MapEntry<String, double> e in g.entries)
        if (e.key != '__solveFor') e.key: e.value,
    };
    final List<String> all = <String>['KE_i', 'PE_i', 'KE_f', 'PE_f'];
    final List<String> missing =
        all.where((String k) => !known.containsKey(k)).toList();
    if (missing.length != 1) {
      throw const SolverInputException(
        'يجب توفير ثلاث قيم من: KE_i, PE_i, KE_f, PE_f.',
      );
    }
    final String target = missing.first;
    final double left = (known['KE_i'] ?? 0) + (known['PE_i'] ?? 0);
    final double right = (known['KE_f'] ?? 0) + (known['PE_f'] ?? 0);
    final double value;
    final String formula;
    switch (target) {
      case 'KE_i':
        value = right - (known['PE_i'] ?? 0);
        formula = 'KE_i = (KE_f + PE_f) − PE_i';
        break;
      case 'PE_i':
        value = right - (known['KE_i'] ?? 0);
        formula = 'PE_i = (KE_f + PE_f) − KE_i';
        break;
      case 'KE_f':
        value = left - (known['PE_f'] ?? 0);
        formula = 'KE_f = (KE_i + PE_i) − PE_f';
        break;
      case 'PE_f':
        value = left - (known['KE_f'] ?? 0);
        formula = 'PE_f = (KE_i + PE_i) − KE_f';
        break;
      default:
        throw SolverInputException('متغيّر غير معروف: $target');
    }
    return _PhysicsResult(
      steps: <SolutionStep>[
        const SolutionStep(
          title: 'كتابة قانون حفظ الطاقة',
          expression: 'KE_i + PE_i = KE_f + PE_f',
          explanation: 'مجموع الطاقة الميكانيكية ثابت في الأنظمة المعزولة.',
          rule: 'Conservation of Mechanical Energy',
        ),
        SolutionStep(
          title: 'إعادة ترتيب لعزل $target',
          expression: formula,
          explanation: 'حلّ المعادلة جبريًا للحصول على المتغيّر المطلوب.',
          rule: 'Algebraic manipulation',
        ),
        SolutionStep(
          title: 'استبدال القيم',
          expression: '$target = ${_fmt(value)}',
          explanation: 'عوّض المعطيات لحساب الطاقة المتبقّية.',
          rule: 'Substitution',
        ),
      ],
      finalAnswer: '$target = ${_fmt(value)} J',
    );
  }

  static double _sqrt(double x) {
    if (x < 0) return double.nan;
    // Newton's method, no dart:math import to keep this file
    // dependency-free for tests.
    double guess = x / 2 + 1;
    for (int i = 0; i < 30; i += 1) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static String _fmt(double n) {
    if (n.isNaN || n.isInfinite) return n.toString();
    if (n == n.roundToDouble()) return n.toInt().toString();
    String s = n.toStringAsFixed(4);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}

typedef _RuleSolver = _PhysicsResult Function(Map<String, double>);

class _Rule {
  _Rule({
    required this.lawArabic,
    required this.lawCitation,
    required this.solutions,
    required this.summary,
  });

  final String lawArabic;
  final String lawCitation;
  final Map<Set<String>, _RuleSolver> solutions;
  final String summary;
}

class _PhysicsResult {
  const _PhysicsResult({required this.steps, required this.finalAnswer});

  final List<SolutionStep> steps;
  final String finalAnswer;

  Solution _intoSolution(
    _Rule rule,
    String solveFor,
    Map<String, double> givens,
  ) {
    final String givensSummary = givens.entries
        .map((MapEntry<String, double> e) =>
            '${e.key}=${PhysicsFormulaSolver._fmt(e.value)}')
        .join(', ');
    return Solution(
      kind: SolutionKind.physicsFormula,
      heading: '${rule.lawArabic} — أوجد $solveFor من ($givensSummary)',
      steps: steps,
      finalAnswer: finalAnswer,
    );
  }
}
