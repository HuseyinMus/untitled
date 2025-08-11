import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/data/repositories/user_lists_repository.dart';
import 'package:untitled/features/profile/screens/word_picker_screen.dart';

class WordListDetailScreen extends StatefulWidget {
  final String listId;
  final String listName;
  const WordListDetailScreen({super.key, required this.listId, required this.listName});

  @override
  State<WordListDetailScreen> createState() => _WordListDetailScreenState();
}

class _WordListDetailScreenState extends State<WordListDetailScreen> {
  late final UserListsRepository repo;
  List<String> itemIds = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    repo = UserListsRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('items')
          .get();
      setState(() {
        itemIds = snap.docs.map((d) => d.id).toList(growable: false);
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  Future<void> _addWords() async {
    final ids = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => const WordPickerScreen()),
    );
    if (ids != null && ids.isNotEmpty) {
      for (final id in ids) {
        await repo.addWord(widget.listId, id);
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.listName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWords,
        icon: const Icon(Icons.add),
        label: const Text('Kelime Ekle'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : itemIds.isEmpty
              ? const Center(child: Text('Bu listede kelime yok.'))
              : ListView.separated(
                  itemCount: itemIds.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final id = itemIds[i];
                    return ListTile(
                      title: Text(id),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await repo.removeWord(widget.listId, id);
                          await _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}


