import 'package:flutter/material.dart';
import 'package:untitled/data/repositories/in_memory_repository.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/core/firebase/firebase_initializer.dart';
import 'package:untitled/data/repositories/firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/data/models/word.dart';
import 'package:untitled/features/study/flashcard_screen.dart';
import 'package:untitled/features/quiz/quiz_screen.dart';
import 'package:untitled/features/study/listening_screen.dart';
import 'package:untitled/features/home/widgets/catalog_screen.dart';
import 'package:untitled/features/home/widgets/placement_test_screen.dart';
import 'package:untitled/features/study/due_words_screen.dart';

class HomeScreen extends StatefulWidget {
  final Repository? externalRepository;
  const HomeScreen({super.key, this.externalRepository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Repository repository = InMemoryRepository();
  bool firebaseReady = false;
  bool loadingDue = false;
  List dueCache = [];
  int dailyGoal = 10;
  String? selectedCategory;
  String? selectedLevel;
  int featuredIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.externalRepository != null) {
      repository = widget.externalRepository!;
      firebaseReady = repository is FirebaseRepository;
      _refreshDue();
    } else {
      _setupFirebase();
    }
  }

  Future<void> _setupFirebase() async {
    final ok = await initializeFirebaseSafely();
    if (!mounted) return;
    if (ok) {
      try {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
        }
        final repo = FirebaseRepository(FirebaseFirestore.instance, auth);
        await repo.loadCatalogOnce();
        setState(() {
          repository = repo;
          firebaseReady = true;
        });
      } on FirebaseAuthException {
        setState(() {
          repository = InMemoryRepository();
          firebaseReady = false;
        });
      } catch (_) {
        setState(() {
          repository = InMemoryRepository();
          firebaseReady = false;
        });
      }
      await _refreshDue();
    } else {
      setState(() {
        firebaseReady = false;
      });
      await _refreshDue();
    }
  }

  Future<void> _refreshDue() async {
    if (!mounted) return;
    setState(() {
      loadingDue = true;
    });
    if (repository is FirebaseRepository) {
      try {
        final repo = repository as FirebaseRepository;
        final list = await repo.dueWordsAsync(limit: dailyGoal);
        if (!mounted) return;
        setState(() {
          dueCache = list;
          loadingDue = false;
        });
      } on FirebaseException {
        // İzin hatalarında çevrimdışı moda düşmeyelim; sadece listeyi boşaltalım
        if (!mounted) return;
        setState(() {
          dueCache = const [];
          loadingDue = false;
        });
      }
    } else {
      final list = repository.dueWords(limit: dailyGoal);
      if (!mounted) return;
      setState(() {
        dueCache = list;
        loadingDue = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Öğren - SRS'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!firebaseReady)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Offline mod (Firebase bağlı değil) — in-memory katalog kullanılıyor',
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _setupFirebase,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Yeniden Bağlan'),
                          ),
                        ],
                      ),
                    ),
                  _HeaderCard(
                    dueCount: dueCache.length,
                    onStart: () async {
                      final List<WordItem> listToStudy = dueCache.isNotEmpty
                          ? List<WordItem>.from(dueCache)
                          : repository.catalog.take(dailyGoal).toList();
                      if (listToStudy.isEmpty) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FlashcardScreen(
                            repository: repository,
                            initialQueue: listToStudy,
                          ),
                        ),
                      );
                      await _refreshDue();
                    },
                    onViewDue: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DueWordsScreen(repository: repository),
                        ),
                      );
                      await _refreshDue();
                    },
                  ),
                  const SizedBox(height: 12),
                  _FeaturedCategories(
                    repository: repository,
                    initialIndex: featuredIndex,
                    onChanged: (i, label) {
                      setState(() {
                        featuredIndex = i;
                        selectedCategory = label == 'Tümü' ? null : label;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _GoalCard(
                    goal: dailyGoal,
                    onChanged: (v) async {
                      setState(() => dailyGoal = v);
                      await _refreshDue();
                    },
                  ),
                  const SizedBox(height: 12),
                  _PlacementCard(
                    onStart: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlacementTestScreen(pool: repository.catalog),
                        ),
                      );
                      if (result is Map && result['suggestedLevel'] is String) {
                        setState(() => selectedLevel = result['suggestedLevel'] as String);
                      }
                    },
                    selectedLevel: selectedLevel,
                  ),
                  const SizedBox(height: 12),
                  _CategoryFilter(
                    repository: repository,
                    selectedCategory: selectedCategory,
                    selectedLevel: selectedLevel,
                    onChanged: (cat, lvl) {
                      setState(() {
                        selectedCategory = cat;
                        selectedLevel = lvl;
                      });
                    },
                    onOpenCatalog: (title, items) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CatalogScreen(title: title, items: items),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Modlar', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _ModesRow(onOpenQuiz: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          repository: repository,
                          selectedCategory: selectedCategory,
                          selectedLevel: selectedLevel,
                        ),
                      ),
                    );
                  }, onOpenListening: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListeningScreen(
                          repository: repository,
                          selectedCategory: selectedCategory,
                          selectedLevel: selectedLevel,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Text('Katalog (örnek)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverList.separated(
            itemCount: repository.catalog.length,
            itemBuilder: (_, i) {
              final w = repository.catalog[i];
              return ListTile(
                title: Text(w.english),
                subtitle: Text('${w.turkish} • ${w.partOfSpeech}'),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int dueCount;
  final VoidCallback? onStart;
  final VoidCallback? onViewDue;
  const _HeaderCard({required this.dueCount, required this.onStart, this.onViewDue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bugün hazır', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('$dueCount', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('kelime'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: ElevatedButton(onPressed: onStart, child: const Text('Çalışmaya Başla'))),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onViewDue,
                      icon: const Icon(Icons.list),
                      label: const Text('Detay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.auto_awesome, size: 56, color: scheme.onSurface.withOpacity(0.9)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final int goal;
  final ValueChanged<int> onChanged;
  const _GoalCard({required this.goal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Günlük hedef'),
                Text('$goal kelime'),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              min: 5,
              max: 20,
              divisions: 3,
              value: goal.toDouble(),
              label: '$goal',
              onChanged: (v) => onChanged(v.round()),
            )
          ],
        ),
      ),
    );
  }
}

class _ModesRow extends StatelessWidget {
  final VoidCallback? onOpenQuiz;
  final VoidCallback? onOpenListening;
  const _ModesRow({this.onOpenQuiz, this.onOpenListening});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _ModeChip(icon: Icons.style, label: 'Flashcard'),
        const SizedBox(width: 8),
        _ModeChip(icon: Icons.quiz, label: 'Quiz', onTap: onOpenQuiz),
        const SizedBox(width: 8),
        _ModeChip(icon: Icons.hearing, label: 'Dinleme', onTap: onOpenListening),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback? onTap;
  const _ModeChip({required this.icon, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [scheme.secondaryContainer, scheme.tertiaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: scheme.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _PlacementCard extends StatelessWidget {
  final VoidCallback onStart;
  final String? selectedLevel;
  const _PlacementCard({required this.onStart, required this.selectedLevel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.school_outlined, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seviye Tespit', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(selectedLevel == null ? 'Kısa test ile seviyeni belirle.' : 'Önerilen seviye: $selectedLevel'),
                ],
              ),
            ),
            ElevatedButton(onPressed: onStart, child: const Text('Teste Başla')),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final Repository repository;
  final String? selectedCategory;
  final String? selectedLevel;
  final void Function(String? category, String? level) onChanged;
  final void Function(String title, List<WordItem> items) onOpenCatalog;

  const _CategoryFilter({
    required this.repository,
    required this.selectedCategory,
    required this.selectedLevel,
    required this.onChanged,
    required this.onOpenCatalog,
  });

  @override
  Widget build(BuildContext context) {
    final cats = ['Tümü', ...repository.availableCategories()];
    final lvls = ['Tümü', ...repository.availableLevels()];
    final currentCat = selectedCategory ?? 'Tümü';
    final currentLvl = selectedLevel ?? 'Tümü';
    final List<WordItem> filtered = () {
      List<WordItem> items = repository.catalog;
      if (currentCat != 'Tümü') {
        items = repository.byCategory(currentCat);
      }
      if (currentLvl != 'Tümü') {
        items = items.where((w) => (w.level ?? '') == currentLvl).toList();
      }
      return items;
    }();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategoriler', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...cats.map((e) {
                    final bool selected = e == currentCat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(e),
                        selected: selected,
                        onSelected: (_) => onChanged(e == 'Tümü' ? null : e, currentLvl == 'Tümü' ? null : currentLvl),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Seviyeler', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...lvls.map((e) {
                    final bool selected = e == currentLvl;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(e),
                        selected: selected,
                        onSelected: (_) => onChanged(currentCat == 'Tümü' ? null : currentCat, e == 'Tümü' ? null : e),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: filtered.isEmpty ? null : () => onOpenCatalog('Katalog – ${currentCat}${currentLvl == 'Tümü' ? '' : ' / $currentLvl'}', filtered),
                icon: const Icon(Icons.menu_book),
                label: Text('Listele (${filtered.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCategories extends StatefulWidget {
  final Repository repository;
  final int initialIndex;
  final void Function(int index, String label) onChanged;
  const _FeaturedCategories({required this.repository, required this.initialIndex, required this.onChanged});

  @override
  State<_FeaturedCategories> createState() => _FeaturedCategoriesState();
}

class _FeaturedCategoriesState extends State<_FeaturedCategories> {
  late final PageController controller;
  late final List<String> items;

  @override
  void initState() {
    super.initState();
    items = ['Tümü', ...widget.repository.availableCategories()];
    controller = PageController(viewportFraction: 0.9, initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: controller,
        itemCount: items.length,
        onPageChanged: (i) => widget.onChanged(i, items[i]),
        itemBuilder: (_, i) {
          final label = items[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [scheme.secondaryContainer, scheme.tertiaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Öne Çıkan', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 8),
                          Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => widget.onChanged(i, label),
                      child: const Text('Seç'),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

