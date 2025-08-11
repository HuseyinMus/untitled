import 'package:flutter/material.dart';
import 'package:untitled/data/repositories/in_memory_repository.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/state/app_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Repository repository = InMemoryRepository();
  String? selectedLevel;
  String? selectedPos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Home tarafında Firebase reposu kullanılıyorsa burası da güncellenebilir.
  }

  @override
  Widget build(BuildContext context) {
    final cats = repository.availableCategories();
    final levels = ['Tümü', ...repository.availableLevels()];
    final pos = ['Tümü', 'noun', 'verb', 'adjective', 'adverb'];
    return Scaffold(
      appBar: AppBar(title: const Text('Kategoriler')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedLevel ?? 'Tümü',
                        decoration: const InputDecoration(labelText: 'Seviye'),
                        items: levels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedLevel = v == 'Tümü' ? null : v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPos ?? 'Tümü',
                        decoration: const InputDecoration(labelText: 'Kelime Türü'),
                        items: pos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedPos = v == 'Tümü' ? null : v),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text('Sınav Listeleri', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final label = i < cats.length ? cats[i] : null;
                if (label == null) return const SizedBox.shrink();
                return _CategoryCard(
                  title: label,
                  subtitle: 'Seçili seviyeye uygun kelimeler',
                  count: 0,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onStart,
                    child: const Text('Başla'),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$count'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}


