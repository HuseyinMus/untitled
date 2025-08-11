import 'package:flutter/material.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/data/repositories/firebase_repository.dart';
import 'package:untitled/data/models/word.dart';
import 'package:untitled/features/study/flashcard_screen.dart';

class DueWordsScreen extends StatefulWidget {
  final Repository repository;
  const DueWordsScreen({super.key, required this.repository});

  @override
  State<DueWordsScreen> createState() => _DueWordsScreenState();
}

class _DueWordsScreenState extends State<DueWordsScreen> {
  List<WordItem> items = const <WordItem>[];
  bool loading = true;
  final Map<String, DateTime> _nextAtById = <String, DateTime>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final repo = widget.repository;
    try {
      if (repo is FirebaseRepository) {
        final list = await repo.dueWordsAsync(limit: 200);
        // nextReviewAt bilgilerini eşle
        final futures = list.map((w) => repo.getUserWordStateAsync(w.id));
        final states = await Future.wait(futures);
        for (final s in states) {
          _nextAtById[s.wordId] = s.nextReviewAt;
        }
        setState(() {
          items = list;
          loading = false;
        });
      } else {
        final list = repo.dueWords(limit: 200);
        _nextAtById.clear();
        for (final w in list) {
          try {
            final s = repo.getOrCreateState(w.id);
            _nextAtById[w.id] = s.nextReviewAt;
          } catch (_) {}
        }
        setState(() {
          items = list;
          loading = false;
        });
      }
    } catch (_) {
      setState(() {
        items = const <WordItem>[];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugüne due kelimeler'),
        actions: [
          IconButton(
            onPressed: loading || items.isEmpty
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FlashcardScreen(
                          repository: widget.repository,
                          initialQueue: List<WordItem>.from(items),
                        ),
                      ),
                    );
                    await _load();
                  },
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: 'Flashcard ile başla',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Center(child: Text('Bugün due kelime yok.')),
                    ],
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final w = items[i];
                      final dt = _nextAtById[w.id];
                      final nextStr = dt == null ? '' : _formatDateTime(dt);
                      return ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(w.english),
                        subtitle: Text('${w.turkish} • ${w.partOfSpeech}${nextStr.isEmpty ? '' : ' • ${nextStr}'}'),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: items.isEmpty
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FlashcardScreen(
                          repository: widget.repository,
                          initialQueue: List<WordItem>.from(items),
                        ),
                      ),
                    );
                    await _load();
                  },
            icon: const Icon(Icons.school),
            label: Text('Flashcard ile çalış (${items.length})'),
          ),
        ),
      ),
    );
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    // Yerel saat
    final d = dt.toLocal();
    final now = DateTime.now();
    final diff = d.difference(now);
    final y = d.year;
    final m = _two(d.month);
    final day = _two(d.day);
    final hh = _two(d.hour);
    final mm = _two(d.minute);
    final base = '$day.$m.$y $hh:$mm';
    if (diff.inMinutes.abs() < 1) return '$base (şimdi)';
    if (diff.isNegative) {
      final mins = diff.inMinutes.abs();
      if (mins < 60) return '$base (${mins}dk gecikmiş)';
      final hrs = diff.inHours.abs();
      return '$base (${hrs}saat gecikmiş)';
    } else {
      final mins = diff.inMinutes;
      if (mins < 60) return '$base (${mins}dk sonra)';
      final hrs = diff.inHours;
      return '$base (${hrs}saat sonra)';
    }
  }
}


