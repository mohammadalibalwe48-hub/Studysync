import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';

/// Full-screen search across topic titles, descriptions, key ideas, and
/// lesson body text. Returns matching topics ranked by where the
/// keyword landed (title > description > body).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<_Hit> hits = _runSearch(_query);
    return Scaffold(
      backgroundColor: scheme.surface,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'بحث',
                subtitle: 'ابحث في كل الدروس',
                onBack: () => context.pop(),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: (String v) =>
                      setState(() => _query = v.trim()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'مسح',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          ),
                    hintText: 'ابحث عن درس أو مفهوم...',
                  ),
                ),
              ),
              Expanded(
                child: _query.isEmpty
                    ? const _SearchHints()
                    : hits.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'لا توجد نتائج',
                            description:
                                'جرّب كلمات مختلفة أو اختر إحدى المواد من الصفحة الرئيسية.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              4,
                              20,
                              28,
                            ),
                            itemCount: hits.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (BuildContext c, int i) {
                              final _Hit h = hits[i];
                              return FadeSlideIn(
                                delay:
                                    Duration(milliseconds: 30 * i),
                                child: _HitRow(
                                  hit: h,
                                  query: _query,
                                  onTap: () => context.go(
                                    '/topics/${h.topic.id}',
                                  ),
                                ),
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

  List<_Hit> _runSearch(String raw) {
    if (raw.isEmpty) return const <_Hit>[];
    final String q = raw.toLowerCase();
    final List<_Hit> hits = <_Hit>[];
    for (final Topic t in Curriculum.topics) {
      final Subject s = Curriculum.subjects.firstWhere(
        (Subject sj) => sj.id == t.subjectId,
        orElse: () => const Subject(
          id: '',
          name: '',
          description: '',
          icon: Icons.menu_book_outlined,
          color: AppTheme.primary,
        ),
      );
      int score = 0;
      String matchedField = '';
      String snippet = '';
      if (t.title.toLowerCase().contains(q)) {
        score = 100;
        matchedField = 'title';
        snippet = t.description;
      } else if (t.description.toLowerCase().contains(q)) {
        score = 70;
        matchedField = 'description';
        snippet = t.description;
      } else if (t.keyIdeas
          .any((String k) => k.toLowerCase().contains(q))) {
        score = 60;
        matchedField = 'key_idea';
        snippet = t.keyIdeas.firstWhere(
          (String k) => k.toLowerCase().contains(q),
          orElse: () => '',
        );
      } else if (t.lessonContent.toLowerCase().contains(q)) {
        score = 40;
        matchedField = 'body';
        snippet = _extractSnippet(t.lessonContent, q);
      }
      if (score == 0) continue;
      hits.add(_Hit(
        topic: t,
        subject: s,
        score: score,
        matchedField: matchedField,
        snippet: snippet,
      ));
    }
    hits.sort((_Hit a, _Hit b) => b.score.compareTo(a.score));
    return hits;
  }

  String _extractSnippet(String body, String q) {
    final int idx = body.toLowerCase().indexOf(q);
    if (idx < 0) return '';
    final int start = (idx - 30).clamp(0, body.length);
    final int end = (idx + q.length + 80).clamp(0, body.length);
    return '...${body.substring(start, end).trim()}...';
  }
}

class _Hit {
  const _Hit({
    required this.topic,
    required this.subject,
    required this.score,
    required this.matchedField,
    required this.snippet,
  });

  final Topic topic;
  final Subject subject;
  final int score;
  final String matchedField;
  final String snippet;
}

class _SearchHints extends StatelessWidget {
  const _SearchHints();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: <Widget>[
        Text(
          'ابدأ بالكتابة للبحث في كل الدروس والمفاهيم.',
          style: TextStyle(
            fontSize: 13.5,
            color: palette.muted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'اقتراحات سريعة',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String s in const <String>[
              'قانون أوم',
              'الحركة',
              'التوازن الكيميائي',
              'الكهرومغناطيسية',
              'التفاعل',
            ])
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({
    required this.hit,
    required this.query,
    required this.onTap,
  });

  final _Hit hit;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final Color tone = hit.subject.color;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.outline, width: 1),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tone.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(hit.subject.icon, size: 18, color: tone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    hit.topic.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (hit.snippet.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      hit.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}
