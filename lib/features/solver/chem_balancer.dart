import 'package:studysync_syria/features/solver/solver_models.dart';

/// Balancer for *simple* chemical equations using Gaussian elimination
/// over rationals. Supports formulas like `H2O`, `CO2`, `Ca(OH)2`,
/// `Fe2(SO4)3`. Multi-character elements (Cl, Na, Mg, …) and nested
/// parentheses with a multiplier are supported.
///
/// Limitations (kept tight on purpose):
///
///  • No charged species or hydrates — pure neutral compounds only.
///  • No more than 6 distinct elements / 6 species. Anything bigger
///    is rejected with a friendly Arabic message.
///  • Returns the smallest positive integer coefficients.
class ChemicalEquationBalancer {
  ChemicalEquationBalancer._();

  /// Recognises strings that look like a chemical equation. Cheap.
  static bool canSolve(String input) {
    final String s = input.trim();
    if (!s.contains('=') && !s.contains('->') && !s.contains('→')) return false;
    // Must contain at least one capital letter (chemical formula).
    return RegExp(r'[A-Z]').hasMatch(s);
  }

  /// Balances the equation. Throws [SolverInputException] on bad input.
  static Solution solve(String input) {
    final String raw = input.trim();
    final List<String> halves = _splitSides(raw);
    if (halves.length != 2) {
      throw const SolverInputException(
        'يجب فصل المتفاعلات والنواتج بسهم (→ أو ->).',
      );
    }
    final List<_Compound> reactants = _parseSide(halves[0]);
    final List<_Compound> products = _parseSide(halves[1]);
    if (reactants.isEmpty || products.isEmpty) {
      throw const SolverInputException('كلا الطرفين يجب أن يحتوي على مركّبات.');
    }
    final List<_Compound> all = <_Compound>[...reactants, ...products];
    if (all.length > 6) {
      throw const SolverInputException('عدد المركّبات أكبر من ٦.');
    }
    final List<String> elements =
        all.expand((_Compound c) => c.elementCounts.keys).toSet().toList()
          ..sort();
    if (elements.length > 6) {
      throw const SolverInputException('عدد العناصر أكبر من ٦.');
    }

    // Build a (#elements) × (#species) matrix M with reactants
    // positive and products negative; solve M·x = 0.
    final int rows = elements.length;
    final int cols = all.length;
    final List<List<Rational>> matrix = List<List<Rational>>.generate(
      rows,
      (int r) => List<Rational>.generate(cols, (int c) {
        final int count = all[c].elementCounts[elements[r]] ?? 0;
        final int signed = c < reactants.length ? count : -count;
        return Rational.fromInt(signed);
      }),
    );

    final List<Rational> nullSpace =
        _solveNullSpace(matrix, cols);
    if (nullSpace.isEmpty || nullSpace.every((Rational r) => r.isZero)) {
      throw const SolverInputException(
        'لا يمكن موازنة هذه المعادلة بمعاملات موجبة.',
      );
    }
    final List<int> coefs = _toSmallestIntegers(nullSpace);
    // Coefficients must all be positive.
    if (coefs.any((int c) => c <= 0)) {
      throw const SolverInputException(
        'لا توجد معاملات موجبة تحقّق التوازن.',
      );
    }

    // Build the worked-solution steps.
    final List<SolutionStep> steps = <SolutionStep>[];

    steps.add(SolutionStep(
      title: 'كتابة المعادلة الأولية',
      expression: _format(reactants, products),
      explanation: 'هذه هي المعادلة كما أدخلتها قبل الموازنة.',
      rule: 'Given',
    ));

    final StringBuffer atomsBuf = StringBuffer();
    for (final String el in elements) {
      final int leftCount =
          reactants.fold<int>(0, (int s, _Compound c) =>
              s + (c.elementCounts[el] ?? 0));
      final int rightCount =
          products.fold<int>(0, (int s, _Compound c) =>
              s + (c.elementCounts[el] ?? 0));
      atomsBuf.writeln('$el: متفاعلات=$leftCount, نواتج=$rightCount');
    }
    steps.add(SolutionStep(
      title: 'إحصاء الذرّات على كلا الطرفين',
      expression: atomsBuf.toString().trimRight(),
      explanation: 'نقارن عدد ذرّات كل عنصر قبل وبعد التفاعل.',
      rule: 'Conservation of Mass (Lavoisier)',
    ));

    steps.add(const SolutionStep(
      title: 'بناء نظام معادلات',
      expression: 'لكل عنصر: ∑ aᵢ·nᵢ(R) = ∑ bⱼ·mⱼ(P)',
      explanation:
          'لكل عنصر نكتب معادلة تساوي مجموع ذرّاته في المتفاعلات بمجموعها '
          'في النواتج، حيث المعاملات هي المجاهيل.',
      rule: 'Method of undetermined coefficients',
    ));

    steps.add(SolutionStep(
      title: 'حلّ النظام',
      expression: 'المعاملات: ${coefs.join(' : ')}',
      explanation:
          'حلّ النظام الخطّي يعطي نسبة المعاملات؛ نأخذ أصغر مجموعة أعداد '
          'صحيحة موجبة تحقّقها.',
      rule: 'Linear algebra (Gaussian elimination)',
    ));

    final String balanced = _formatWithCoefs(reactants, products, coefs);
    steps.add(SolutionStep(
      title: 'كتابة المعادلة الموزونة',
      expression: balanced,
      explanation: 'بهذه المعاملات تتساوى ذرّات كل عنصر في الطرفين.',
      rule: 'Balanced equation',
    ));

    return Solution(
      kind: SolutionKind.chemicalEquation,
      heading: 'موازنة المعادلة الكيميائية: ${_format(reactants, products)}',
      steps: steps,
      finalAnswer: balanced,
    );
  }

  // ──────────────────────────── parsing ─────────────────────────────

  static List<String> _splitSides(String raw) {
    String s = raw;
    if (s.contains('→')) return s.split('→');
    if (s.contains('->')) return s.split('->');
    if (s.contains('=')) return s.split('=');
    return <String>[];
  }

  static List<_Compound> _parseSide(String side) {
    final String trimmed = side.trim();
    if (trimmed.isEmpty) return const <_Compound>[];
    final List<String> parts = trimmed
        .split('+')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    return parts.map(_Compound.parse).toList();
  }

  static String _format(List<_Compound> r, List<_Compound> p) {
    return '${r.map((_Compound c) => c.raw).join(' + ')} → '
        '${p.map((_Compound c) => c.raw).join(' + ')}';
  }

  static String _formatWithCoefs(
    List<_Compound> r,
    List<_Compound> p,
    List<int> coefs,
  ) {
    String render(int coef, _Compound c) =>
        coef == 1 ? c.raw : '$coef ${c.raw}';
    final List<String> rs = <String>[
      for (int i = 0; i < r.length; i += 1) render(coefs[i], r[i]),
    ];
    final List<String> ps = <String>[
      for (int i = 0; i < p.length; i += 1)
        render(coefs[r.length + i], p[i]),
    ];
    return '${rs.join(' + ')} → ${ps.join(' + ')}';
  }

  // ─────────────────────── linear-algebra core ──────────────────────

  /// Returns one non-trivial vector in the null space of [m]
  /// (which has [cols] columns). Uses pivoted RREF over [Rational]s.
  static List<Rational> _solveNullSpace(List<List<Rational>> m, int cols) {
    final int rows = m.length;
    int row = 0;
    final List<int> pivotCols = <int>[];
    for (int col = 0; col < cols && row < rows; col += 1) {
      int pivotRow = -1;
      for (int r = row; r < rows; r += 1) {
        if (!m[r][col].isZero) {
          pivotRow = r;
          break;
        }
      }
      if (pivotRow < 0) continue;
      if (pivotRow != row) {
        final List<Rational> tmp = m[row];
        m[row] = m[pivotRow];
        m[pivotRow] = tmp;
      }
      // Normalise pivot row.
      final Rational pivot = m[row][col];
      for (int c = 0; c < cols; c += 1) {
        m[row][c] = m[row][c] / pivot;
      }
      // Eliminate every other row.
      for (int r = 0; r < rows; r += 1) {
        if (r == row) continue;
        final Rational factor = m[r][col];
        if (factor.isZero) continue;
        for (int c = 0; c < cols; c += 1) {
          m[r][c] = m[r][c] - factor * m[row][c];
        }
      }
      pivotCols.add(col);
      row += 1;
    }

    // The null space has dimension = cols - rank. We want one free
    // variable; pick the first non-pivot column. If rank == cols
    // we have only the trivial solution.
    final Set<int> pivotSet = pivotCols.toSet();
    int? freeCol;
    for (int c = 0; c < cols; c += 1) {
      if (!pivotSet.contains(c)) {
        freeCol = c;
        break;
      }
    }
    if (freeCol == null) return <Rational>[];

    // Set free variable to 1, back-substitute via the RREF.
    final List<Rational> x =
        List<Rational>.filled(cols, Rational.fromInt(0));
    x[freeCol] = Rational.fromInt(1);
    for (int i = 0; i < pivotCols.length; i += 1) {
      final int c = pivotCols[i];
      // Row `i` is m[i][c] = 1, m[i][freeCol] = ?
      x[c] = -m[i][freeCol];
    }
    return x;
  }

  /// Scales a rational vector so all entries are integers, then
  /// divides by the gcd, then flips signs so the leading entry is
  /// positive.
  static List<int> _toSmallestIntegers(List<Rational> v) {
    int lcm = 1;
    for (final Rational r in v) {
      lcm = _lcm(lcm, r.den);
    }
    final List<int> ints = <int>[
      for (final Rational r in v) (r.num * lcm) ~/ r.den,
    ];
    int g = 0;
    for (final int n in ints) {
      g = _gcd(g, n.abs());
    }
    if (g == 0) return ints;
    final List<int> reduced = <int>[for (final int n in ints) n ~/ g];
    // Flip sign so the first non-zero is positive.
    for (final int n in reduced) {
      if (n != 0) {
        if (n < 0) {
          return <int>[for (final int x in reduced) -x];
        }
        break;
      }
    }
    return reduced;
  }

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
  static int _lcm(int a, int b) =>
      a == 0 || b == 0 ? 0 : (a ~/ _gcd(a, b)) * b;
}

/// One species in a chemical equation, with element counts already
/// expanded out (parens, subscripts).
class _Compound {
  _Compound._({required this.raw, required this.elementCounts});

  factory _Compound.parse(String s) {
    final Map<String, int> counts = <String, int>{};
    _parseInto(s, 1, 0, counts);
    return _Compound._(raw: s, elementCounts: counts);
  }

  final String raw;
  final Map<String, int> elementCounts;

  /// Recursive descent parser for a compound formula.
  ///
  /// Returns the index after the parsed group.
  static int _parseInto(
    String s,
    int multiplier,
    int start,
    Map<String, int> out,
  ) {
    int i = start;
    while (i < s.length) {
      final String ch = s[i];
      if (ch == '(') {
        // Find matching close.
        int depth = 1;
        int j = i + 1;
        while (j < s.length && depth > 0) {
          if (s[j] == '(') depth += 1;
          if (s[j] == ')') depth -= 1;
          if (depth == 0) break;
          j += 1;
        }
        if (depth != 0) {
          throw const SolverInputException('قوس غير مغلق في الصيغة.');
        }
        // Multiplier after ')'.
        int k = j + 1;
        int sub = 0;
        while (k < s.length && _isDigit(s[k])) {
          sub = sub * 10 + (s.codeUnitAt(k) - 0x30);
          k += 1;
        }
        if (sub == 0) sub = 1;
        _parseInto(s.substring(i + 1, j), multiplier * sub, 0, out);
        i = k;
      } else if (ch == ')') {
        return i;
      } else if (_isUpper(ch)) {
        // Element: uppercase + (optional) lowercase.
        int k = i + 1;
        if (k < s.length && _isLower(s[k])) k += 1;
        final String element = s.substring(i, k);
        // Subscript.
        int sub = 0;
        while (k < s.length && _isDigit(s[k])) {
          sub = sub * 10 + (s.codeUnitAt(k) - 0x30);
          k += 1;
        }
        if (sub == 0) sub = 1;
        out[element] = (out[element] ?? 0) + sub * multiplier;
        i = k;
      } else if (ch == ' ') {
        i += 1;
      } else {
        throw SolverInputException('رمز غير متوقّع في الصيغة: "$ch".');
      }
    }
    return i;
  }

  static bool _isUpper(String c) =>
      c.length == 1 &&
      c.codeUnitAt(0) >= 0x41 &&
      c.codeUnitAt(0) <= 0x5A;
  static bool _isLower(String c) =>
      c.length == 1 &&
      c.codeUnitAt(0) >= 0x61 &&
      c.codeUnitAt(0) <= 0x7A;
  static bool _isDigit(String c) =>
      c.length == 1 &&
      c.codeUnitAt(0) >= 0x30 &&
      c.codeUnitAt(0) <= 0x39;
}

/// Tiny rational number type so the chemical balancer is exact.
class Rational {
  Rational._(this.num, this.den);

  factory Rational.fromInt(int n) => Rational._(n, 1);

  factory Rational.from(int num, int den) {
    if (den == 0) {
      throw const SolverInputException('قسمة على صفر.');
    }
    final int sign = den < 0 ? -1 : 1;
    final int n = num * sign;
    final int d = den * sign;
    final int g = _gcd(n.abs(), d);
    if (g == 0) return Rational._(0, 1);
    return Rational._(n ~/ g, d ~/ g);
  }

  final int num;
  final int den;

  bool get isZero => num == 0;

  Rational operator +(Rational o) =>
      Rational.from(num * o.den + o.num * den, den * o.den);
  Rational operator -(Rational o) =>
      Rational.from(num * o.den - o.num * den, den * o.den);
  Rational operator *(Rational o) =>
      Rational.from(num * o.num, den * o.den);
  Rational operator /(Rational o) =>
      Rational.from(num * o.den, den * o.num);
  Rational operator -() => Rational._(-num, den);

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  @override
  String toString() => den == 1 ? '$num' : '$num/$den';
}
