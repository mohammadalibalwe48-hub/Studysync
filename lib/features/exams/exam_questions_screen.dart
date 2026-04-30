import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';

/// تصفية أسئلة الدورات بحسب المادة.
enum _ExamFilter { all, physics, chemistry }

/// نموذج سؤال دورة سابقة بنمط أسئلة البكالوريا السورية.
class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.subjectId,
    required this.year,
    required this.prompt,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  final String id;
  final String subjectId;
  final int year;
  final String prompt;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
}

/// قائمة بنماذج أسئلة دورات سابقة قابلة للتوسعة لاحقاً.
const List<ExamQuestion> _examQuestions = <ExamQuestion>[
  ExamQuestion(
    id: 'exam-phy-2024-1',
    subjectId: Curriculum.physicsId,
    year: 2024,
    prompt:
        'مقاومة أومية قيمتها R = 20 Ω طُبّق على طرفيها فرق كمون '
        'U = 60 V. ما شدة التيار المار فيها؟',
    options: <String>['0.33 A', '3 A', '40 A', '1200 A'],
    correctOptionIndex: 1,
    explanation:
        'بتطبيق قانون أوم: I = U / R = 60 / 20 = 3 A.',
  ),
  ExamQuestion(
    id: 'exam-phy-2024-2',
    subjectId: Curriculum.physicsId,
    year: 2024,
    prompt:
        'جسم كتلته m = 10 kg تؤثر عليه قوة محصلة F = 30 N. ما تسارعه؟',
    options: <String>['0.3 m/s²', '3 m/s²', '20 m/s²', '300 m/s²'],
    correctOptionIndex: 1,
    explanation:
        'بحسب القانون الثاني لنيوتن: a = F / m = 30 / 10 = 3 m/s².',
  ),
  ExamQuestion(
    id: 'exam-phy-2024-3',
    subjectId: Curriculum.physicsId,
    year: 2024,
    prompt:
        'يُرفع جسم كتلته m = 4 kg إلى ارتفاع h = 5 m '
        '(g ≈ 10 m/s²). ما الطاقة الكامنة الثقالية المكتسبة؟',
    options: <String>['20 J', '50 J', '100 J', '200 J'],
    correctOptionIndex: 3,
    explanation: 'Ep = m · g · h = 4 × 10 × 5 = 200 J.',
  ),
  ExamQuestion(
    id: 'exam-phy-2023-1',
    subjectId: Curriculum.physicsId,
    year: 2023,
    prompt:
        'مصباح يعمل تحت فرق كمون U = 220 V ويمر فيه تيار I = 0.5 A. '
        'الاستطاعة الكهربائية المستهلكة هي:',
    options: <String>['44 W', '110 W', '220 W', '440 W'],
    correctOptionIndex: 1,
    explanation: 'P = U · I = 220 × 0.5 = 110 W.',
  ),
  ExamQuestion(
    id: 'exam-chem-2024-1',
    subjectId: Curriculum.chemistryId,
    year: 2024,
    prompt:
        'أيّ من العوامل التالية يخفّض طاقة التنشيط لتفاعل ما؟',
    options: <String>[
      'تقليل تركيز المتفاعلات.',
      'تخفيض درجة الحرارة.',
      'إضافة حفّاز مناسب.',
      'تكبير قطعة المتفاعل الصلب.',
    ],
    correctOptionIndex: 2,
    explanation:
        'الحفّاز يسرّع التفاعل عبر مسار جديد بطاقة تنشيط أقل، دون أن '
        'يستهلك في التفاعل.',
  ),
  ExamQuestion(
    id: 'exam-chem-2024-2',
    subjectId: Curriculum.chemistryId,
    year: 2024,
    prompt:
        'في تفاعل: N₂(g) + 3H₂(g) ⇌ 2NH₃(g) (ناشر للحرارة)، رفع درجة '
        'الحرارة يؤدي إلى:',
    options: <String>[
      'إزاحة التوازن نحو NH₃.',
      'إزاحة التوازن نحو N₂ و H₂.',
      'لا يؤثّر على موقع التوازن.',
      'إيقاف التفاعل تماماً.',
    ],
    correctOptionIndex: 1,
    explanation:
        'في التفاعل الناشر للحرارة، الحرارة بمثابة ناتج. زيادتها تُزيح '
        'التوازن في اتجاه استهلاكها، أي نحو المتفاعلات.',
  ),
  ExamQuestion(
    id: 'exam-chem-2024-3',
    subjectId: Curriculum.chemistryId,
    year: 2024,
    prompt: 'الصيغة العامة للألكينات هي:',
    options: <String>['CnH2n+2', 'CnH2n', 'CnH2n-2', 'CnHn'],
    correctOptionIndex: 1,
    explanation:
        'الألكينات فحوم هيدروجينية تحوي رابطة مضاعفة، وصيغتها العامة '
        'CnH2n.',
  ),
  ExamQuestion(
    id: 'exam-chem-2023-1',
    subjectId: Curriculum.chemistryId,
    year: 2023,
    prompt:
        'المجموعة الوظيفية المميّزة لحمض الإيتانويك CH₃-COOH هي:',
    options: <String>[
      '-OH هيدروكسيلية',
      '-CHO ألدهيدية',
      '-COOH كربوكسيلية',
      '-CO- كيتونية',
    ],
    correctOptionIndex: 2,
    explanation:
        'حمض الإيتانويك يحوي مجموعة كربوكسيلية -COOH، وهي ما يميّز '
        'الأحماض الكربوكسيلية.',
  ),
];

class ExamQuestionsScreen extends StatefulWidget {
  const ExamQuestionsScreen({super.key});

  @override
  State<ExamQuestionsScreen> createState() => _ExamQuestionsScreenState();
}

class _ExamQuestionsScreenState extends State<ExamQuestionsScreen> {
  _ExamFilter _filter = _ExamFilter.all;

  List<ExamQuestion> get _filtered {
    return switch (_filter) {
      _ExamFilter.all => _examQuestions,
      _ExamFilter.physics => _examQuestions
          .where((ExamQuestion q) => q.subjectId == Curriculum.physicsId)
          .toList(growable: false),
      _ExamFilter.chemistry => _examQuestions
          .where(
              (ExamQuestion q) => q.subjectId == Curriculum.chemistryId)
          .toList(growable: false),
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<ExamQuestion> visible = _filtered;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _BackBar(
                title: 'أسئلة الدورات',
                onBack: () => context.go('/home'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: _FilterBar(
                  selected: _filter,
                  onChanged: (_ExamFilter f) =>
                      setState(() => _filter = f),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'لا توجد أسئلة',
                        description:
                            'لم يتم العثور على أسئلة وفق هذا الفلتر.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (BuildContext context, int i) {
                          final ExamQuestion q = visible[i];
                          return FadeSlideIn(
                            delay:
                                Duration(milliseconds: 60 + i * 50),
                            child: _ExamCard(question: q),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _ExamFilter selected;
  final ValueChanged<_ExamFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.outline, width: 0.6),
      ),
      child: Row(
        children: <Widget>[
          _FilterChip(
            label: 'الكل',
            selected: selected == _ExamFilter.all,
            onTap: () => onChanged(_ExamFilter.all),
          ),
          _FilterChip(
            label: 'فيزياء',
            selected: selected == _ExamFilter.physics,
            onTap: () => onChanged(_ExamFilter.physics),
          ),
          _FilterChip(
            label: 'كيمياء',
            selected: selected == _ExamFilter.chemistry,
            onTap: () => onChanged(_ExamFilter.chemistry),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? palette.goldGradient : null,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : palette.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamCard extends StatefulWidget {
  const _ExamCard({required this.question});

  final ExamQuestion question;

  @override
  State<_ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<_ExamCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ExamQuestion q = widget.question;
    final Subject? subject = Curriculum.subjectById(q.subjectId);
    final Color tone = subject?.color ?? palette.accent;
    final String subjectName = subject?.name ?? '—';
    final bool answered = _selected != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tone.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  subjectName,
                  style: TextStyle(
                    color: tone,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.champagne,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'دورة ${q.year}',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.prompt,
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(q.options.length, (int i) {
            final bool isCorrect = i == q.correctOptionIndex;
            final bool isSelected = _selected == i;
            Color border = palette.outline;
            Color bg = palette.card;
            Color iconColor = palette.muted;
            IconData icon = Icons.radio_button_off_rounded;
            if (answered) {
              if (isCorrect) {
                border = const Color(0xFF34A853);
                bg = const Color(0xFF34A853).withOpacity(0.06);
                iconColor = const Color(0xFF34A853);
                icon = Icons.check_circle_rounded;
              } else if (isSelected) {
                border = Theme.of(context).colorScheme.error;
                bg = Theme.of(context).colorScheme.error.withOpacity(0.06);
                iconColor = Theme.of(context).colorScheme.error;
                icon = Icons.cancel_rounded;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: answered ? null : () => setState(() => _selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: border,
                        width: answered ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(icon, color: iconColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q.options[i],
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (answered) ...<Widget>[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tone.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tone.withOpacity(0.20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.school_rounded, color: tone, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'الإجابة الصحيحة: ${q.options[q.correctOptionIndex]}',
                        style: TextStyle(
                          color: tone,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.explanation,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
