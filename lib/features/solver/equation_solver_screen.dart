import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';
import 'package:studysync_syria/features/solver/chem_balancer.dart';
import 'package:studysync_syria/features/solver/linear_solver.dart';
import 'package:studysync_syria/features/solver/physics_solver.dart';
import 'package:studysync_syria/features/solver/solver_models.dart';

/// One of the three problem categories the solver supports. Picking
/// the category up-front lets us tailor the input UI (e.g. the
/// physics tab adds a "solve for" picker) and avoid heuristic
/// dispatch errors for ambiguous inputs.
enum SolverMode { linear, physics, chemistry }

/// Local-only equation solver — no API key, no network calls.
///
/// Renders three modes (linear / physics / chemistry) and a
/// collapsible stepper that cites the rule applied at every step.
class EquationSolverScreen extends StatefulWidget {
  const EquationSolverScreen({super.key});

  @override
  State<EquationSolverScreen> createState() => _EquationSolverScreenState();
}

class _EquationSolverScreenState extends State<EquationSolverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: SolverMode.values.length, vsync: this);

  final TextEditingController _inputCtrl = TextEditingController();
  final TextEditingController _solveForCtrl =
      TextEditingController(text: 'I');

  Solution? _solution;
  String? _error;
  SolverMode _mode = SolverMode.linear;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      setState(() {
        _mode = SolverMode.values[_tabs.index];
        _solution = null;
        _error = null;
      });
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _inputCtrl.dispose();
    _solveForCtrl.dispose();
    super.dispose();
  }

  void _solve() {
    final String input = _inputCtrl.text.trim();
    if (input.isEmpty) {
      setState(() {
        _solution = null;
        _error = 'أدخل المعادلة أولًا.';
      });
      return;
    }
    try {
      final Solution s;
      switch (_mode) {
        case SolverMode.linear:
          s = LinearEquationSolver.solve(input);
          break;
        case SolverMode.physics:
          s = PhysicsFormulaSolver.solve(
            input,
            solveFor: _solveForCtrl.text.trim(),
          );
          break;
        case SolverMode.chemistry:
          s = ChemicalEquationBalancer.solve(input);
          break;
      }
      setState(() {
        _solution = s;
        _error = null;
      });
    } on SolverInputException catch (e) {
      setState(() {
        _solution = null;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _solution = null;
        _error = 'تعذّر الحلّ: $e';
      });
    }
  }

  void _loadExample(String exampleInput, {String? solveFor}) {
    setState(() {
      _inputCtrl.text = exampleInput;
      if (solveFor != null) _solveForCtrl.text = solveFor;
      _solution = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'حلّال المعادلات',
                subtitle: 'محلّي بالكامل — بدون اتصال بالإنترنت',
                onBack: () => context.pop(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: scheme.surface,
                child: TabBar(
                  controller: _tabs,
                  isScrollable: false,
                  labelColor: scheme.primary,
                  unselectedLabelColor: palette.muted,
                  indicatorColor: scheme.primary,
                  tabs: const <Tab>[
                    Tab(text: 'معادلة خطّية'),
                    Tab(text: 'فيزياء'),
                    Tab(text: 'كيمياء'),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  children: <Widget>[
                    FadeSlideIn(child: _buildInputCard(scheme, palette)),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: _ExampleStrip(
                        mode: _mode,
                        onTap: _loadExample,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_error != null)
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: _ErrorCard(message: _error!),
                      ),
                    if (_solution != null)
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 120),
                        child: _SolutionView(solution: _solution!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(ColorScheme scheme, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.outline),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _modeTitle(_mode),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _modeSubtitle(_mode),
            style: TextStyle(
              fontSize: 11.5,
              color: palette.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _inputCtrl,
            maxLines: 2,
            // Mathematical input is always LTR even in an RTL app.
            textDirection: TextDirection.ltr,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(200),
            ],
            decoration: InputDecoration(
              hintText: _modeHint(_mode),
              hintTextDirection: TextDirection.ltr,
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.primary, width: 1.5),
              ),
            ),
          ),
          if (_mode == SolverMode.physics) ...<Widget>[
            const SizedBox(height: 10),
            TextField(
              controller: _solveForCtrl,
              textDirection: TextDirection.ltr,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: InputDecoration(
                labelText: 'أوجد قيمة الرمز',
                hintText: 'I',
                hintTextDirection: TextDirection.ltr,
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: _solve,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('حلّ المعادلة'),
            ),
          ),
        ],
      ),
    );
  }

  static String _modeTitle(SolverMode m) {
    switch (m) {
      case SolverMode.linear:
        return 'معادلة خطّية في متغيّر واحد';
      case SolverMode.physics:
        return 'قانون فيزيائي';
      case SolverMode.chemistry:
        return 'موازنة معادلة كيميائية';
    }
  }

  static String _modeSubtitle(SolverMode m) {
    switch (m) {
      case SolverMode.linear:
        return 'مثال: 2x + 3 = 7. ندعم x, y, z, n, t.';
      case SolverMode.physics:
        return 'أدخل المعطيات بالشكل V=12, R=4 ثم حدّد الرمز المطلوب.';
      case SolverMode.chemistry:
        return 'أدخل المتفاعلات والنواتج بالصيغة H2 + O2 → H2O.';
    }
  }

  static String _modeHint(SolverMode m) {
    switch (m) {
      case SolverMode.linear:
        return '2x + 3 = 7';
      case SolverMode.physics:
        return 'V=12, R=4';
      case SolverMode.chemistry:
        return 'H2 + O2 -> H2O';
    }
  }
}

class _ExampleStrip extends StatelessWidget {
  const _ExampleStrip({required this.mode, required this.onTap});

  final SolverMode mode;
  final void Function(String input, {String? solveFor}) onTap;

  @override
  Widget build(BuildContext context) {
    final List<_Example> examples = _examplesFor(mode);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.lightbulb_outline_rounded, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final _Example e in examples)
                ActionChip(
                  label: Text(
                    e.label,
                    textDirection: TextDirection.ltr,
                  ),
                  onPressed: () => onTap(e.input, solveFor: e.solveFor),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static List<_Example> _examplesFor(SolverMode m) {
    switch (m) {
      case SolverMode.linear:
        return const <_Example>[
          _Example(label: '2x + 3 = 7', input: '2x + 3 = 7'),
          _Example(label: '3y - 5 = y + 1', input: '3y - 5 = y + 1'),
          _Example(label: '4n = 2n + 8', input: '4n = 2n + 8'),
        ];
      case SolverMode.physics:
        return const <_Example>[
          _Example(
              label: 'Ohm: V=12, R=4 → I',
              input: 'V=12, R=4',
              solveFor: 'I'),
          _Example(
              label: 'Newton: m=5, a=3 → F',
              input: 'm=5, a=3',
              solveFor: 'F'),
          _Example(
              label: 'KE: m=2, v=4 → KE',
              input: 'm=2, v=4',
              solveFor: 'KE'),
          _Example(
              label: 'PE: m=2, g=9.8, h=10 → PE',
              input: 'm=2, g=9.8, h=10',
              solveFor: 'PE'),
        ];
      case SolverMode.chemistry:
        return const <_Example>[
          _Example(label: 'H2 + O2 → H2O', input: 'H2 + O2 -> H2O'),
          _Example(
              label: 'CH4 + O2 → CO2 + H2O',
              input: 'CH4 + O2 -> CO2 + H2O'),
          _Example(
              label: 'Fe + O2 → Fe2O3',
              input: 'Fe + O2 -> Fe2O3'),
        ];
    }
  }
}

class _Example {
  const _Example({
    required this.label,
    required this.input,
    this.solveFor,
  });
  final String label;
  final String input;
  final String? solveFor;
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.error.withOpacity(0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionView extends StatelessWidget {
  const _SolutionView({required this.solution});

  final Solution solution;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.outline),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            solution.heading,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(solution.steps.length, (int i) {
            final SolutionStep step = solution.steps[i];
            return _StepTile(index: i + 1, step: step);
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: palette.goldGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.flag_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    solution.finalAnswer,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.step});

  final int index;
  final SolutionStep step;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Theme(
      // Strip default ExpansionTile divider lines so the card stays
      // clean inside the parent solution card.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsetsDirectional.symmetric(horizontal: 4, vertical: 4),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 12),
        title: Row(
          children: <Widget>[
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsetsDirectional.only(start: 34, top: 4),
          child: Text(
            step.expression,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: palette.warm.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                step.rule,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: palette.warm,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.explanation,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
