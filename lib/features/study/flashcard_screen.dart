import 'package:flutter/material.dart';
import 'package:untitled/core/srs/srs.dart';
import 'package:untitled/data/models/word.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/data/repositories/firebase_repository.dart';
import 'package:untitled/data/repositories/stats_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FlashcardScreen extends StatefulWidget {
  final Repository repository;
  final List<WordItem> initialQueue;

  const FlashcardScreen({super.key, required this.repository, required this.initialQueue});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late List<WordItem> queue;
  bool showBack = false;

  @override
  void initState() {
    super.initState();
    queue = List<WordItem>.from(widget.initialQueue);
  }

  Future<void> _answer(ReviewGrade grade) async {
    if (queue.isEmpty) return;
    final current = queue.first;
    final repo = widget.repository;
    try {
      if (repo is FirebaseRepository) {
        await repo.applyReviewAsync(current.id, grade);
      } else {
        repo.applyReview(current.id, grade);
      }
    } catch (_) {}
    await StatsRepository.recordStudyReview(isCorrect: grade != ReviewGrade.again);
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'flashcard_answer', parameters: {
        'grade': grade.toString(),
      });
    } catch (_) {}
    setState(() {
      showBack = false;
      queue.removeAt(0);
    });
    if (queue.isEmpty) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final WordItem? current = queue.isNotEmpty ? queue.first : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: current == null
          ? const Center(child: Text('Tebrikler! Bugünlük bitti.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${queue.length} kaldı'),
                      IconButton(
                        onPressed: () => setState(() => showBack = !showBack),
                        icon: Icon(showBack ? Icons.visibility_off : Icons.visibility),
                        tooltip: 'Ön/arka',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showBack = !showBack),
                      child: _GlassCard(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: showBack
                                  ? Column(
                                      key: const ValueKey('back'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(current.turkish, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                                        const SizedBox(height: 12),
                                        Text(current.example, textAlign: TextAlign.center),
                                        if (current.mnemonic != null) ...[
                                          const SizedBox(height: 12),
                                          Text('Mnemonic: ${current.mnemonic!}', textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
                                        ],
                                      ],
                                    )
                                  : Text(current.english, key: const ValueKey('front'), style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (showBack)
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => _answer(ReviewGrade.again), child: const Text('Again'))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(onPressed: () => _answer(ReviewGrade.hard), child: const Text('Hard'))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton(onPressed: () => _answer(ReviewGrade.good), child: const Text('Good'))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton(onPressed: () => _answer(ReviewGrade.easy), child: const Text('Easy'))),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () => setState(() => showBack = true),
                      child: const Text('Cevabı Göster'),
                    ),
                ],
              ),
            ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            scheme.surfaceVariant.withOpacity(0.7),
            scheme.surfaceVariant.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}


