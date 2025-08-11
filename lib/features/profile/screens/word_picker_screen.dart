import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WordPickerScreen extends StatefulWidget {
  const WordPickerScreen({super.key});
  @override
  State<WordPickerScreen> createState() => _WordPickerScreenState();
}

class _WordPickerScreenState extends State<WordPickerScreen> {
  final Set<String> selected = <String>{};
  String query = '';
  bool loading = true;
  List<_Item> items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('catalog_words').limit(1000).get();
      final list = snap.docs.map((d) {
        final m = d.data();
        return _Item(id: d.id, en: (m['en'] ?? '') as String, tr: (m['tr'] ?? '') as String);
      }).toList(growable: false);
      setState(() {
        items = list;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((w) {
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      return w.en.toLowerCase().contains(q) || w.tr.toLowerCase().contains(q);
    }).toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Kelime Seç')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: selected.isEmpty ? null : () => Navigator.pop(context, selected.toList()),
            icon: const Icon(Icons.check),
            label: Text('Ekle (${selected.length})'),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Ara'),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final w = filtered[i];
                        final checked = selected.contains(w.id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (_) {
                            setState(() {
                              if (checked) {
                                selected.remove(w.id);
                              } else {
                                selected.add(w.id);
                              }
                            });
                          },
                          title: Text(w.en),
                          subtitle: Text(w.tr),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Item {
  final String id;
  final String en;
  final String tr;
  _Item({required this.id, required this.en, required this.tr});
}


