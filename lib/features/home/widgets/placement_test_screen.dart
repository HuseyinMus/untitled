import 'dart:math';

import 'package:flutter/material.dart';
import 'package:untitled/data/models/word.dart';

class PlacementTestScreen extends StatefulWidget {
  final List<WordItem> pool;
  const PlacementTestScreen({super.key, required this.pool});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  static const int total = 10;
  late final List<WordItem> questions;
  int index = 0;
  int score = 0;
  List<WordItem> options = [];
  WordItem? current;

  @override
  void initState() {
    super.initState();
    final pool = List<WordItem>.from(widget.pool);
    pool.shuffle();
    questions = pool.take(min(total, pool.length)).toList();
    _next();
  }

  void _next() {
    if (index >= questions.length) {
      final double ratio = questions.isEmpty ? 0 : score / questions.length;
      final String level = ratio >= 0.85
          ? 'C1'
          : ratio >= 0.7
              ? 'B2'
              : ratio >= 0.5
                  ? 'B1'
                  : 'A2';
      Navigator.of(context).pop({'score': score, 'suggestedLevel': level});
      return;
    }
    current = questions[index++];
    final rnd = Random();
    final set = <WordItem>{current!};
    while (set.length < 4 && set.length < widget.pool.length) {
      set.add(widget.pool[rnd.nextInt(widget.pool.length)]);
    }
    options = set.toList()..shuffle();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Seviye Tespit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Soru ${index}/${questions.length}', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(current!.english, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((o) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ElevatedButton(
                    onPressed: () {
                      if (o.id == current!.id) score += 1;
                      _next();
                    },
                    child: Text(o.turkish),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}


