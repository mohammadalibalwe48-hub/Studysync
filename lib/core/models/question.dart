/// A multiple-choice practice question with a worked solution.
class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctOptionIndex,
    required this.workedSolution,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctOptionIndex;
  final String workedSolution;

  bool isCorrect(int selectedIndex) => selectedIndex == correctOptionIndex;
}
