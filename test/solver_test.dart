import 'package:flutter_test/flutter_test.dart';
import 'package:studysync_syria/features/solver/chem_balancer.dart';
import 'package:studysync_syria/features/solver/linear_solver.dart';
import 'package:studysync_syria/features/solver/physics_solver.dart';
import 'package:studysync_syria/features/solver/solver_models.dart';

void main() {
  group('LinearEquationSolver', () {
    test('solves a basic single-variable equation', () {
      final Solution s = LinearEquationSolver.solve('2x + 3 = 7');
      expect(s.kind, SolutionKind.linearEquation);
      expect(s.finalAnswer, 'x = 2');
      expect(s.steps, isNotEmpty);
    });

    test('solves equation with variable on both sides', () {
      final Solution s = LinearEquationSolver.solve('3y - 5 = y + 1');
      expect(s.finalAnswer, 'y = 3');
    });

    test('detects no-solution', () {
      final Solution s = LinearEquationSolver.solve('2x + 1 = 2x + 5');
      expect(s.finalAnswer, contains('لا يوجد'));
    });

    test('detects identity (infinite solutions)', () {
      final Solution s = LinearEquationSolver.solve('2x + 4 = 2x + 4');
      expect(s.finalAnswer, contains('لا نهاية'));
    });

    test('rejects malformed input', () {
      expect(() => LinearEquationSolver.solve('hello'),
          throwsA(isA<SolverInputException>()));
    });
  });

  group('PhysicsFormulaSolver', () {
    test("solves Ohm's law for I", () {
      final Solution s = PhysicsFormulaSolver.solve('V=12, R=4', solveFor: 'I');
      expect(s.kind, SolutionKind.physicsFormula);
      expect(s.finalAnswer, 'I = 3 A');
    });

    test('solves Newton II for F', () {
      final Solution s = PhysicsFormulaSolver.solve('m=5, a=3', solveFor: 'F');
      expect(s.finalAnswer, 'F = 15 N');
    });

    test('solves KE forwards', () {
      final Solution s = PhysicsFormulaSolver.solve('m=2, v=4', solveFor: 'KE');
      expect(s.finalAnswer, 'KE = 16 J');
    });

    test('throws on unsupported variable set', () {
      expect(
        () => PhysicsFormulaSolver.solve('q=5', solveFor: 'p'),
        throwsA(isA<SolverInputException>()),
      );
    });
  });

  group('ChemicalEquationBalancer', () {
    test('balances H2 + O2 -> H2O', () {
      final Solution s =
          ChemicalEquationBalancer.solve('H2 + O2 -> H2O');
      expect(s.kind, SolutionKind.chemicalEquation);
      expect(s.finalAnswer, '2 H2 + O2 → 2 H2O');
    });

    test('balances combustion of methane', () {
      final Solution s =
          ChemicalEquationBalancer.solve('CH4 + O2 -> CO2 + H2O');
      expect(s.finalAnswer, 'CH4 + 2 O2 → CO2 + 2 H2O');
    });

    test('balances rusting iron', () {
      final Solution s =
          ChemicalEquationBalancer.solve('Fe + O2 -> Fe2O3');
      expect(s.finalAnswer, '4 Fe + 3 O2 → 2 Fe2O3');
    });

    test('rejects junk', () {
      expect(
        () => ChemicalEquationBalancer.solve('hello world'),
        throwsA(isA<SolverInputException>()),
      );
    });
  });
}
