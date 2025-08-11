import 'package:flutter/material.dart';
import 'package:untitled/data/repositories/in_memory_repository.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/state/app_state.dart';
import 'package:untitled/core/firebase/firebase_initializer.dart';
import 'package:untitled/data/repositories/firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoriesScreen extends StatefulWidget {
  final Repository? externalRepository;
  const CategoriesScreen({super.key, this.externalRepository});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Repository repository = InMemoryRepository();
  String? selectedLevel;
  String? selectedPos;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _loading = true;
  bool _firebaseReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.externalRepository != null) {
      repository = widget.externalRepository!;
      _loading = false;
      _firebaseReady = repository is FirebaseRepository;
    } else {
      _setupRepository();
    }
  }

  Future<void> _setupRepository() async {
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
        if (!mounted) return;
        setState(() {
          repository = repo;
          _firebaseReady = true;
          _loading = false;
        });
        return;
      } catch (_) {
        // fallthrough to in-memory
      }
    }
    setState(() {
      repository = InMemoryRepository();
      _firebaseReady = false;
      _loading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Home tarafında Firebase reposu kullanılıyorsa burası da güncellenebilir.
  }

  @override
  Widget build(BuildContext context) {
    final levels = ['Tümü', ...repository.availableLevels()];
    final pos = ['Tümü', 'noun', 'verb', 'adjective', 'adverb'];
    final allCats = repository.availableCategories();
    final cats = allCats
        .where((c) => _query.isEmpty || c.toLowerCase().contains(_query.toLowerCase()))
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Kategoriler')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      if (!_firebaseReady)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Offline mod (Firebase bağlı değil) — in-memory katalog',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori ara',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: 12),
                  Text('Seviyeler', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...levels.map((e) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(e),
                                selected: (selectedLevel ?? 'Tümü') == e,
                                onSelected: (_) => setState(() => selectedLevel = e == 'Tümü' ? null : e),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Kelime Türleri', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...pos.map((e) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(e),
                                selected: (selectedPos ?? 'Tümü') == e,
                                onSelected: (_) => setState(() => selectedPos = e == 'Tümü' ? null : e),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Sınav Listeleri', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final label = i < cats.length ? cats[i] : null;
                if (label == null) return const SizedBox.shrink();
                final int count = _estimateCount(label);
                return _CategoryCard(
                  title: label,
                  subtitle: 'Seçili filtrelere uygun kelimeler',
                  count: count,
                  onStart: () {
                    selectedFilterNotifier.value = selectedFilterNotifier.value.copyWith(category: label, level: selectedLevel);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label seçildi')));
                  },
                );
              },
              childCount: cats.length,
            ),
          ),
        ],
      ),
    );
  }

  int _estimateCount(String category) {
    // Basit tahmin: kategoriye ait öğeleri alıp seçili seviye/pos ile filtrele
    List items = repository.byCategory(category);
    if (selectedLevel != null) {
      items = items.where((w) => (w.level ?? '') == selectedLevel).toList();
    }
    if (selectedPos != null) {
      items = items.where((w) => (w.partOfSpeech) == selectedPos).toList();
    }
    return items.length;
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onStart;
  const _CategoryCard({required this.title, required this.subtitle, required this.count, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = _iconFor(title);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onStart,
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(icon, size: 18),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, size: 12),
                        const SizedBox(width: 3),
                        Text('$count'),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onStart,
                  child: const Text('Başla'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String title) {
  final t = title.toLowerCase();
  if (t.contains('ielts')) return Icons.public;
  if (t.contains('toefl')) return Icons.school;
  if (t.contains('sat')) return Icons.auto_awesome;
  if (t.contains('phrasal')) return Icons.link;
  if (t.contains('academic')) return Icons.menu_book;
  return Icons.category;
}


