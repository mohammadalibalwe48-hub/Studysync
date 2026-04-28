/// Lightweight progress snapshot used by the progress screen.
///
/// Values are placeholders for the frontend-only version; once the backend
/// is wired up this model will be populated from real study sessions.
class StudentProgress {
  const StudentProgress({
    required this.completionPercent,
    required this.correctAnswerRate,
    required this.streakDays,
    required this.physicsCompletionPercent,
    required this.chemistryCompletionPercent,
  });

  final double completionPercent;
  final double correctAnswerRate;
  final int streakDays;
  final double physicsCompletionPercent;
  final double chemistryCompletionPercent;

  static const StudentProgress placeholder = StudentProgress(
    completionPercent: 0.42,
    correctAnswerRate: 0.68,
    streakDays: 5,
    physicsCompletionPercent: 0.55,
    chemistryCompletionPercent: 0.30,
  );
}
