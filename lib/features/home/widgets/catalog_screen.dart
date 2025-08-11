import 'package:flutter/material.dart';
import 'package:untitled/data/models/word.dart';

class CatalogScreen extends StatelessWidget {
  final String title;
  final List<WordItem> items;
  const CatalogScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _SearchableList(items: items, scheme: scheme),
    );
  }
}

class _SearchableList extends StatefulWidget {
  final List<WordItem> items;
  final ColorScheme scheme;
  const _SearchableList({required this.items, required this.scheme});

  @override
  State<_SearchableList> createState() => _SearchableListState();
}

class _SearchableListState extends State<_SearchableList> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((w) {
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      return w.english.toLowerCase().contains(q) ||
          w.turkish.toLowerCase().contains(q) ||
          (w.level ?? '').toLowerCase().contains(q) ||
          w.categories.any((c) => c.toLowerCase().contains(q));
    }).toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Ara (EN/TR, kategori veya seviye)',
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final w = filtered[i];
              return Card(
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(w.english, style: const TextStyle(fontWeight: FontWeight.w600))),
                      if ((w.level ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(w.level!, style: TextStyle(color: widget.scheme.onSecondaryContainer)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${w.turkish} • ${w.partOfSpeech}'),
                      if ((w.level ?? '').isNotEmpty || w.categories.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: -8,
                            children: [
                              ...w.categories.map((c) => Chip(label: Text(c))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: filtered.length,
          ),
        ),
      ],
    );
  }
}


