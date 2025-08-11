import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/data/models/word_list.dart';

class UserListsRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  UserListsRepository(this.db, this.auth);

  String get _uid => auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _listsCol => db
      .collection('users')
      .doc(_uid)
      .collection('lists');

  Future<List<WordListMeta>> fetchLists() async {
    try {
      final snap = await _listsCol.orderBy('createdAt', descending: true).get();
      return snap.docs.map((d) {
        final m = d.data();
        return WordListMeta(
          id: d.id,
          name: m['name'] ?? 'Liste',
          description: m['description'],
          itemCount: (m['itemCount'] as num?)?.toInt() ?? 0,
          createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<String> createList(String name, {String? description}) async {
    try {
      final ref = await _listsCol.add({
        'name': name,
        'description': description,
        'itemCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Liste oluşturulamadı');
    } catch (_) {
      throw Exception('Liste oluşturulamadı');
    }
  }

  Future<void> renameList(String listId, String name) async {
    try {
      await _listsCol.doc(listId).update({'name': name});
    } catch (_) {}
  }

  Future<void> deleteList(String listId) async {
    try {
      // Basit silme (içerikleri ayrıca kaldırmak isteyebiliriz)
      await _listsCol.doc(listId).delete();
    } catch (_) {}
  }

  Future<void> addWord(String listId, String wordId) async {
    try {
      final ref = _listsCol.doc(listId).collection('items').doc(wordId);
      await ref.set({'addedAt': FieldValue.serverTimestamp()});
      await _listsCol.doc(listId).update({'itemCount': FieldValue.increment(1)});
    } catch (_) {}
  }

  Future<void> removeWord(String listId, String wordId) async {
    try {
      final ref = _listsCol.doc(listId).collection('items').doc(wordId);
      await ref.delete();
      await _listsCol.doc(listId).update({'itemCount': FieldValue.increment(-1)});
    } catch (_) {}
  }
}


