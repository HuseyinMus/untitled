import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/core/firebase/admin_config.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController en = TextEditingController();
  final TextEditingController tr = TextEditingController();
  final TextEditingController pos = TextEditingController();
  final TextEditingController example = TextEditingController();
  final TextEditingController categories = TextEditingController();
  final TextEditingController level = TextEditingController();
  final TextEditingController mnemonic = TextEditingController();
  final TextEditingController search = TextEditingController();

  bool writing = false;
  String? error;
  bool exporting = false;

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    return AdminConfig.adminEmails.contains(email);
  }

  Future<void> _addWord() async {
    if (!_isAdmin) {
      setState(() => error = 'Admin yetkisi yok.');
      return;
    }
    final enV = en.text.trim();
    final trV = tr.text.trim();
    if (enV.isEmpty || trV.isEmpty) {
      setState(() => error = 'en ve tr zorunlu');
      return;
    }
    final List<String> cats = categories.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    try {
      setState(() { writing = true; error = null; });
      await FirebaseFirestore.instance.collection('catalog_words').add({
        'en': enV,
        'tr': trV,
        'pos': pos.text.trim(),
        'example': example.text.trim(),
        'categories': cats,
        'level': level.text.trim(),
        'mnemonic': mnemonic.text.trim().isEmpty ? null : mnemonic.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelime eklendi.')));
      en.clear(); tr.clear(); pos.clear(); example.clear(); categories.clear(); level.clear(); mnemonic.clear();
    } on FirebaseException catch (e) {
      setState(() => error = e.message ?? 'Kayıt başarısız');
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Future<void> _deleteWord(String docId) async {
    if (!_isAdmin) return;
    try {
      await FirebaseFirestore.instance.collection('catalog_words').doc(docId).delete();
    } catch (_) {}
  }

  Future<void> _openImportDialog() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin yetkisi gerekli.')));
      return;
    }
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('JSON İçe Aktar'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Aşağıya JSON array yapısını yapıştırın. Örnek:'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
                  child: const SelectableText('[\n  {\n    "en": "abandon",\n    "tr": "terk etmek",\n    "pos": "verb",\n    "example": "They had to abandon the car in the snow.",\n    "categories": ["TOEFL", "IELTS"],\n    "level": "B2",\n    "mnemonic": "a ban don"\n  }\n]'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 12,
                  decoration: const InputDecoration(hintText: 'JSON verisini buraya yapıştırın'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('İçe Aktar')),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    await _importFromJson(result);
  }

  Future<void> _importFromJson(String jsonText) async {
    if (!_isAdmin) return;
    try {
      setState(() { writing = true; error = null; });
      final dynamic decoded = jsonDecode(jsonText);
      if (decoded is! List) {
        setState(() => error = 'JSON bir dizi (array) olmalı.');
        return;
      }
      final List<Map<String, dynamic>> items = [];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          final enV = (e['en'] ?? e['english'] ?? '').toString().trim();
          final trV = (e['tr'] ?? e['turkish'] ?? '').toString().trim();
          final posV = (e['pos'] ?? e['partOfSpeech'] ?? '').toString().trim();
          final exV = (e['example'] ?? '').toString().trim();
          final lvlV = (e['level'] ?? '').toString().trim();
          final mnemV = (e['mnemonic'] ?? '').toString().trim();
          final catsV = e['categories'];
          final List<String> cats = catsV is List ? catsV.map((x) => x.toString()).toList() : <String>[];
          if (enV.isEmpty || trV.isEmpty) continue;
          items.add({
            'en': enV,
            'tr': trV,
            'pos': posV,
            'example': exV,
            'categories': cats,
            'level': lvlV,
            'mnemonic': mnemV.isEmpty ? null : mnemV,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      if (items.isEmpty) {
        setState(() => error = 'Uygun kayıt bulunamadı.');
        return;
      }
      // Partiler halinde yaz (limit 400 civarı tutalım)
      const int chunkSize = 400;
      for (int i = 0; i < items.length; i += chunkSize) {
        final batch = FirebaseFirestore.instance.batch();
        final end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
        final slice = items.sublist(i, end);
        for (final data in slice) {
          final doc = FirebaseFirestore.instance.collection('catalog_words').doc();
          batch.set(doc, data, SetOptions(merge: true));
        }
        await batch.commit();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${items.length} kayıt içe aktarıldı.')));
    } catch (e) {
      setState(() => error = 'JSON parse/yazma hatası: $e');
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Future<void> _openExportDialog() async {
    try {
      setState(() => exporting = true);
      final snap = await FirebaseFirestore.instance
          .collection('catalog_words')
          .orderBy('createdAt', descending: true)
          .limit(1000)
          .get();
      final list = snap.docs.map((d) {
        final m = d.data();
        return {
          'id': d.id,
          'en': m['en'],
          'tr': m['tr'],
          'pos': m['pos'],
          'example': m['example'],
          'categories': m['categories'],
          'level': m['level'],
          'mnemonic': m['mnemonic'],
        };
      }).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(list);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('JSON Dışa Aktar'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(child: SelectableText(jsonStr)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dışa aktarma hatası: $e')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Paneli – Katalog')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin notu (isteğe bağlı):
            // if (!_isAdmin)
            //   Padding(
            //     padding: const EdgeInsets.only(bottom: 8),
            //     child: Text(
            //       'Bu sayfayı kullanmak için admin e-postasıyla giriş yapmalısınız.',
            //       style: TextStyle(color: Theme.of(context).colorScheme.error),
            //     ),
            //   ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    const Text('Kelime Ekle'),
                    const SizedBox(height: 8),
                    TextField(controller: en, decoration: const InputDecoration(labelText: 'English (en)')),
                    const SizedBox(height: 8),
                    TextField(controller: tr, decoration: const InputDecoration(labelText: 'Türkçe (tr)')),
                    const SizedBox(height: 8),
                    TextField(controller: pos, decoration: const InputDecoration(labelText: 'Kelime türü (pos) – noun/verb/...')),
                    const SizedBox(height: 8),
                    TextField(controller: example, decoration: const InputDecoration(labelText: 'Örnek cümle (example)')),
                    const SizedBox(height: 8),
                    TextField(controller: categories, decoration: const InputDecoration(labelText: 'Kategoriler (virgülle)')),
                    const SizedBox(height: 8),
                    TextField(controller: level, decoration: const InputDecoration(labelText: 'Seviye (A1..C2 vb.)')),
                    const SizedBox(height: 8),
                    TextField(controller: mnemonic, decoration: const InputDecoration(labelText: 'Mnemonic (opsiyonel)')),
                    const SizedBox(height: 12),
                    if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (!_isAdmin || writing) ? null : _addWord,
                              child: Text(writing ? 'Kaydediliyor...' : 'Kaydet'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (!_isAdmin || writing) ? null : _openImportDialog,
                              icon: const Icon(Icons.file_upload),
                              label: const Text('JSON İçe Aktar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: exporting ? null : _openExportDialog,
                              icon: const Icon(Icons.file_download),
                              label: const Text('JSON Dışa Aktar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: search,
                  decoration: InputDecoration(
                    labelText: 'Ara (en/tr/pos/level)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () { search.clear(); setState(() {}); },
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('catalog_words')
                    .orderBy('createdAt', descending: true)
                    .limit(200)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('Katalog boş.'));
                  final q = search.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? docs
                      : docs.where((d) {
                          final m = d.data();
                          bool match(String? s) => (s ?? '').toLowerCase().contains(q);
                          final cats = (m['categories'] as List?)?.join(', ') ?? '';
                          return match(m['en']?.toString()) ||
                              match(m['tr']?.toString()) ||
                              match(m['pos']?.toString()) ||
                              match(m['level']?.toString()) ||
                              match(cats.toString());
                        }).toList(growable: false);
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = filtered[i];
                      final m = d.data();
                      final String enStr = (m['en'] ?? '').toString();
                      final String trStr = (m['tr'] ?? '').toString();
                      final String posStr = (m['pos'] ?? '').toString();
                      final String lvlStr = (m['level'] ?? '').toString();
                      final String catsStr = ((m['categories'] as List?)?.join(', ') ?? '').toString();
                      return ListTile(
                        title: Text('$enStr  →  $trStr'),
                        subtitle: Text('pos: $posStr • level: $lvlStr • cats: $catsStr'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _isAdmin ? () => _deleteWord(d.id) : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


