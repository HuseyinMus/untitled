import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/data/repositories/user_lists_repository.dart';
import 'package:untitled/data/models/word_list.dart';
import 'package:untitled/features/profile/screens/word_list_detail_screen.dart';

class MyListsScreen extends StatefulWidget {
  const MyListsScreen({super.key});

  @override
  State<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen> {
  late final UserListsRepository repo;
  List<WordListMeta> lists = const [];
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
      final data = await repo.fetchLists();
      setState(() {
        lists = data;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yeni liste'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'İsim')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Oluştur')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        await repo.createList(name);
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Liste oluşturulamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelime Listelerim')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        label: const Text('Yeni Liste'),
        icon: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : lists.isEmpty
              ? const Center(child: Text('Henüz listen yok. Yeni bir liste oluştur.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: lists.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = lists[i];
                      return ListTile(
                        title: Text(m.name),
                        subtitle: Text('${m.itemCount} kelime'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'rename') {
                              final c = TextEditingController(text: m.name);
                              final newName = await showDialog<String>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Liste adını değiştir'),
                                  content: TextField(controller: c),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Kaydet')),
                                  ],
                                ),
                              );
                              if (newName != null && newName.isNotEmpty) {
                                await repo.renameList(m.id, newName);
                                await _load();
                              }
                            } else if (v == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Silinsin mi?'),
                                  content: Text('"${m.name}" listesi silinecek.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await repo.deleteList(m.id);
                                await _load();
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'rename', child: Text('Yeniden adlandır')),
                            PopupMenuItem(value: 'delete', child: Text('Sil')),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WordListDetailScreen(listId: m.id, listName: m.name),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


