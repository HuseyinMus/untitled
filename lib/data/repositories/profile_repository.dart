import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileRepository {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> getProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).collection('profile').doc('main').get();
      return doc.data() ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> upsertProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? username,
    String? avatar,
  }) async {
    final profileRef = _db.collection('users').doc(uid).collection('profile').doc('main');
    final String? usernameLower = username?.trim().toLowerCase();

    return _db.runTransaction((tx) async {
      // Username claim logic
      if (usernameLower != null && usernameLower.isNotEmpty) {
        final unameRef = _db.collection('usernames').doc(usernameLower);
        final unameSnap = await tx.get(unameRef);
        final existingUid = unameSnap.data()?['uid'] as String?;
        if (existingUid != null && existingUid != uid) {
          throw Exception('username_taken');
        }
        tx.set(unameRef, {'uid': uid}, SetOptions(merge: true));
      }

      final payload = <String, dynamic>{
        if (firstName != null) 'firstName': firstName.trim(),
        if (lastName != null) 'lastName': lastName.trim(),
        if (username != null) 'username': username.trim(),
        if (usernameLower != null) 'usernameLower': usernameLower,
        if (avatar != null) 'avatar': avatar,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      tx.set(profileRef, payload, SetOptions(merge: true));
    });
  }

  static Future<void> changeUsername({required String uid, required String newUsername}) async {
    final profileRef = _db.collection('users').doc(uid).collection('profile').doc('main');
    final newLower = newUsername.trim().toLowerCase();

    return _db.runTransaction((tx) async {
      final profileSnap = await tx.get(profileRef);
      final oldLower = (profileSnap.data()?['usernameLower'] as String?)?.toLowerCase();

      // Claim new username
      final newRef = _db.collection('usernames').doc(newLower);
      final newSnap = await tx.get(newRef);
      final existingUid = newSnap.data()?['uid'] as String?;
      if (existingUid != null && existingUid != uid) {
        throw Exception('username_taken');
      }
      tx.set(newRef, {'uid': uid}, SetOptions(merge: true));

      // Release old username if owned by same uid and different
      if (oldLower != null && oldLower != newLower) {
        final oldRef = _db.collection('usernames').doc(oldLower);
        final oldSnap = await tx.get(oldRef);
        if ((oldSnap.data()?['uid'] as String?) == uid) {
          tx.delete(oldRef);
        }
      }

      tx.set(profileRef, {
        'username': newUsername.trim(),
        'usernameLower': newLower,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}


