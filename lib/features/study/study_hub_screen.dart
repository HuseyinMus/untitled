import 'package:flutter/material.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/features/quiz/quiz_screen.dart';
import 'package:untitled/features/study/flashcard_screen.dart';
import 'package:untitled/features/study/listening_screen.dart';
import 'package:untitled/state/app_state.dart';

class StudyHubScreen extends StatelessWidget {
  final Repository repository;
  const StudyHubScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    final filter = selectedFilterNotifier.value;
    final selCategory = filter.category;
    final selLevel = filter.level;
    final title = selCategory ?? 'Tüm Katalog';

    final items = repository.catalog.where((w) {
      if (selCategory != null && !w.categories.contains(selCategory)) return false;
      if (selLevel != null && (w.level ?? '') != selLevel) return false;
      return true;
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text('Çalış • $title')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selCategory == null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Kategori seçilmedi'),
                  subtitle: const Text('Kategoriler sekmesinden seçim yapın.'),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.1,
                children: [
                  _ModeTile(
                    icon: Icons.style,
                    label: 'Flashcard',
                    onTap: items.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FlashcardScreen(repository: repository, initialQueue: items),
                              ),
                            ),
                  ),
                  _ModeTile(
                    icon: Icons.quiz,
                    label: 'Quiz',
                    onTap: items.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QuizScreen(repository: repository),
                              ),
                            ),
                  ),
                  _ModeTile(
                    icon: Icons.hearing,
                    label: 'Dinleme',
                    onTap: items.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ListeningScreen(repository: repository),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ModeTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [scheme.secondaryContainer, scheme.tertiaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 36),
                const SizedBox(height: 8),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


