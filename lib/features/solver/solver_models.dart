/// Shared types for the local equation solver.
///
/// One [Solution] is a tree of [SolutionStep]s, each citing the
/// underlying physical/mathematical rule that was applied. The UI
/// renders these as a collapsible stepper.

/// A single step in a worked solution.
class SolutionStep {
  const SolutionStep({
    required this.title,
    required this.expression,
    required this.explanation,
    required this.rule,
  });

  /// One-line summary, shown collapsed (e.g. "Combine like terms").
  final String title;

  /// The mathematical expression / equation after this step (e.g.
  /// "5x = 15"). Plain text — the UI uses a monospaced font for it.
  final String expression;

  /// Free-form prose explaining *why* this step is valid. Shown when
  /// the step is expanded.
  final String explanation;

  /// Citation of the underlying rule or law (e.g. "Ohm's Law: V = IR").
  /// Surfaced as a small chip beside the title.
  final String rule;
}

/// One complete worked solution returned by the solver.
class Solution {
  const Solution({
    required this.kind,
    required this.heading,
    required this.steps,
    required this.finalAnswer,
  });

  /// Which kind of problem the solver detected and handled. Keeps the
  /// UI from having to special-case rendering, and helps tests assert
  /// dispatch.
  final SolutionKind kind;

  /// One-line restatement of the problem (e.g. "Solve 2x + 3 = 7 for
  /// x"). Always shown above the steps.
  final String heading;

  final List<SolutionStep> steps;

  /// Plain-text final answer (e.g. "x = 2", "I = 3 A",
  /// "2 H2 + O2 → 2 H2O").
  final String finalAnswer;
}

enum SolutionKind {
  linearEquation,
  physicsFormula,
  chemicalEquation,
}

/// Thrown when the solver can't recognise the user's input. Carries
/// a human-readable, Arabic message so the UI just renders it.
class SolverInputException implements Exception {
  const SolverInputException(this.message);

  final String message;

  @override
  String toString() => 'SolverInputException: $message';
}
