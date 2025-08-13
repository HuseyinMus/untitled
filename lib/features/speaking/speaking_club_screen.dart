import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SpeakingClubScreen extends StatefulWidget {
  const SpeakingClubScreen({super.key});

  @override
  State<SpeakingClubScreen> createState() => _SpeakingClubScreenState();
}

class _SpeakingClubScreenState extends State<SpeakingClubScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ensureAuth();
  }

  Future<void> _ensureAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      setState(() => _ready = true);
    } catch (_) {
      setState(() => _ready = false);
    }
  }

  Future<void> _createRoom() async {
    final nameController = TextEditingController();
    String level = 'Genel';
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Oda Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Oda adı (örn. A2 Sohbet)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Seviye:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: level,
                  items: const [
                    DropdownMenuItem(value: 'Genel', child: Text('Genel')),
                    DropdownMenuItem(value: 'A1', child: Text('A1')),
                    DropdownMenuItem(value: 'A2', child: Text('A2')),
                    DropdownMenuItem(value: 'B1', child: Text('B1')),
                    DropdownMenuItem(value: 'B2', child: Text('B2')),
                    DropdownMenuItem(value: 'C1', child: Text('C1')),
                    DropdownMenuItem(value: 'C2', child: Text('C2')),
                  ],
                  onChanged: (v) {
                    level = v ?? 'Genel';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, nameController.text.trim()), child: const Text('Oluştur')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('speaking_rooms').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user?.uid,
        'level': level,
        'memberCount': 0,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oda oluşturulamadı.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Speaking Club')),
        body: const Center(child: Text('Oturum hazırlanıyor veya Firebase yok.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Speaking Club')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRoom,
        icon: const Icon(Icons.add),
        label: const Text('Oda Oluştur'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('speaking_rooms')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Hiç oda yok. Hemen bir tane oluştur!'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i];
              final m = d.data();
              final String title = (m['name'] ?? 'Oda').toString();
              final String level = (m['level'] ?? 'Genel').toString();
              final int count = (m['memberCount'] as num?)?.toInt() ?? 0;
              final String subtitle = 'Seviye: $level • Üye: $count';
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.group)),
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SpeakingRoomScreen(roomId: d.id, roomName: title),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SpeakingRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  const SpeakingRoomScreen({super.key, required this.roomId, required this.roomName});

  @override
  State<SpeakingRoomScreen> createState() => _SpeakingRoomScreenState();
}

class _SpeakingRoomScreenState extends State<SpeakingRoomScreen> {
  final TextEditingController controller = TextEditingController();
  bool sending = false;
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _typingCleanupTimer;
  Timer? _countdownTimer;
  String? _currentTopic;
  DateTime? _topicUntil;
  String _countdownLabel = '';

  static const List<String> _curatedTopicsGeneral = [
    'Introduce yourself and your hobbies',
    'Describe your last holiday',
    'Talk about your favorite movie and why',
    'Discuss pros and cons of social media',
    'Share a challenging experience and what you learned',
    'Debate: Remote work vs. office work',
    'Explain your daily routine in detail',
    'If you could live anywhere, where would it be and why?',
    'Describe a book that influenced you',
    'Talk about healthy lifestyle habits'
  ];

  @override
  void initState() {
    super.initState();
    _joinRoom();
    _typingCleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) => setState(() {}));
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickCountdown());
  }

  @override
  void dispose() {
    _typingCleanupTimer?.cancel();
    _countdownTimer?.cancel();
    _leaveRoom();
    super.dispose();
  }

  Future<void> _updateMemberCount(int delta) async {
    try {
      final ref = FirebaseFirestore.instance.collection('speaking_rooms').doc(widget.roomId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final int current = (snap.data()?['memberCount'] as num?)?.toInt() ?? 0;
        tx.update(ref, {'memberCount': (current + delta).clamp(0, 1000000)});
      });
    } catch (_) {}
  }

  Future<void> _joinRoom() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final memRef = FirebaseFirestore.instance
          .collection('speaking_rooms')
          .doc(widget.roomId)
          .collection('members')
          .doc(user.uid);
      await memRef.set({
        'uid': user.uid,
        'displayName': user.displayName ?? user.email ?? 'Kullanıcı',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _updateMemberCount(1);
    } catch (_) {}
  }

  Future<void> _leaveRoom() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final memRef = FirebaseFirestore.instance
          .collection('speaking_rooms')
          .doc(widget.roomId)
          .collection('members')
          .doc(user.uid);
      await memRef.delete();
      await _updateMemberCount(-1);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() => sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('speaking_rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
        'uid': user?.uid,
        'displayName': user?.displayName ?? user?.email ?? 'Kullanıcı',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesaj gönderilemedi.')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('speaking_rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true);
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('speaking_rooms')
              .doc(widget.roomId)
              .collection('members')
              .snapshots(),
          builder: (context, snap) {
            final count = snap.hasData ? snap.data!.docs.length : null;
            final suffix = count == null ? '' : ' • $count kişi';
            return Text('${widget.roomName}$suffix');
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Rastgele konu',
            onPressed: _setRandomTopic,
            icon: const Icon(Icons.lightbulb_outline),
          ),
          IconButton(
            tooltip: '3 dk başlat',
            onPressed: () => _startTopicTimer(const Duration(minutes: 3)),
            icon: const Icon(Icons.timer_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Oda meta: anlık konu ve geri sayım
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('speaking_rooms')
                .doc(widget.roomId)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasData) {
                final data = snap.data!.data() ?? {};
                final topic = (data['topic'] as String?)?.trim();
                final ts = data['topicUntil'] as Timestamp?;
                _currentTopic = (topic == null || topic.isEmpty) ? null : topic;
                _topicUntil = ts?.toDate();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentTopic ?? 'Konu seç: Lightbulb ile öneri al',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (_countdownLabel.isNotEmpty)
                            Text(_countdownLabel, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _openSuggestTopic,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Konu Öner'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          // Önerilen konular (son 10)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('speaking_rooms')
                .doc(widget.roomId)
                .collection('topics')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) {
                    final m = docs[i].data();
                    final text = (m['text'] ?? '').toString();
                    return ActionChip(
                      label: Text(text, overflow: TextOverflow.ellipsis),
                      avatar: const Icon(Icons.play_arrow, size: 16),
                      onPressed: () => _setTopic(text),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: docs.length,
                ),
              );
            },
          ),
          // Typing indicator
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('speaking_rooms')
                .doc(widget.roomId)
                .collection('typing')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final now = DateTime.now();
              final active = snap.data!.docs.where((d) {
                final ts = (d.data()['last'] as Timestamp?);
                if (ts == null) return false;
                return now.difference(ts.toDate()).inSeconds <= 5;
              }).length;
              if (active == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(active == 1 ? 'Bir kişi yazıyor...' : '$active kişi yazıyor...'),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: col.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Henüz mesaj yok. İlk mesajı sen yaz!'));
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m = docs[i].data();
                    final name = (m['displayName'] ?? 'User').toString();
                    final text = (m['text'] ?? '').toString();
                    final Timestamp? ts = m['createdAt'] as Timestamp?;
                    final timeStr = ts == null
                        ? ''
                        : TimeOfDay.fromDateTime(ts.toDate().toLocal()).format(context);
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text),
                          if (timeStr.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(timeStr, style: Theme.of(context).textTheme.bodySmall),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Mesaj yazın... (sesli sohbet için eklenti gerekir)'
                    ),
                    onSubmitted: (_) => _send(),
                    onChanged: (_) => _emitTyping(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _emitTyping() async {
    final now = DateTime.now();
    if (now.difference(_lastTypingSent).inMilliseconds < 1200) return; // throttling
    _lastTypingSent = now;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('speaking_rooms')
          .doc(widget.roomId)
          .collection('typing')
          .doc(user.uid)
          .set({'last': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  Future<void> _setRandomTopic() async {
    final topic = (_curatedTopicsGeneral.toList()..shuffle()).first;
    await _setTopic(topic);
  }

  Future<void> _setTopic(String text) async {
    try {
      await FirebaseFirestore.instance
          .collection('speaking_rooms')
          .doc(widget.roomId)
          .set({'topic': text}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _startTopicTimer(Duration duration) async {
    try {
      // Eğer konu yoksa rastgele belirle
      final snap = await FirebaseFirestore.instance.collection('speaking_rooms').doc(widget.roomId).get();
      final hasTopic = (snap.data() ?? {})['topic'] is String && ((snap.data()!['topic'] as String).trim().isNotEmpty);
      if (!hasTopic) {
        await _setRandomTopic();
      }
      final until = DateTime.now().add(duration);
      await FirebaseFirestore.instance
          .collection('speaking_rooms')
          .doc(widget.roomId)
          .set({'topicUntil': Timestamp.fromDate(until)}, SetOptions(merge: true));
    } catch (_) {}
  }

  void _tickCountdown() {
    if (_topicUntil == null) {
      if (_countdownLabel.isNotEmpty) setState(() => _countdownLabel = '');
      return;
    }
    final now = DateTime.now();
    final diff = _topicUntil!.difference(now);
    if (diff.isNegative) {
      if (_countdownLabel != '') setState(() => _countdownLabel = '');
      return;
    }
    final mm = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    final label = 'Süre: $mm:$ss';
    if (label != _countdownLabel) setState(() => _countdownLabel = label);
  }

  Future<void> _openSuggestTopic() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konu öner'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'Kısa bir konu başlığı yazın (EN)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Ekle')),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('speaking_rooms')
          .doc(widget.roomId)
          .collection('topics')
          .add({'text': text, 'createdAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }
}


