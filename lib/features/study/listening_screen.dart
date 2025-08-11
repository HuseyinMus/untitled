import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:untitled/data/repositories/repository.dart';

class ListeningScreen extends StatefulWidget {
  final Repository repository;
  final String? selectedCategory;
  final String? selectedLevel;
  const ListeningScreen({super.key, required this.repository, this.selectedCategory, this.selectedLevel});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final FlutterTts tts = FlutterTts();
  int current = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await tts.setSpeechRate(0.45);
    await tts.setPitch(1.0);
  }

  @override
  void dispose() {
    try {
      tts.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.repository.catalog.where((w) {
      if (widget.selectedCategory != null && !w.categories.contains(widget.selectedCategory)) return false;
      if (widget.selectedLevel != null && (w.level ?? '') != widget.selectedLevel) return false;
      return true;
    }).toList(growable: false);
    final word = items.isEmpty ? null : items[current % items.length];
    return Scaffold(
      appBar: AppBar(title: const Text('Dinleme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (word == null) ...[
              const SizedBox(height: 32),
              const Center(child: Text('Katalog boş.')),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(word.english, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(word.turkish, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await tts.setLanguage('en-US');
                      await tts.speak(word.english);
                    },
                    icon: const Icon(Icons.volume_up),
                    label: const Text('İngilizce'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await tts.setLanguage('tr-TR');
                      await tts.speak(word.turkish);
                    },
                    icon: const Icon(Icons.record_voice_over),
                    label: const Text('Türkçe'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: items.isEmpty
                        ? null
                        : () => setState(() => current = (current - 1 + items.length) % items.length),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Önceki'),
                  ),
                  OutlinedButton.icon(
                    onPressed: items.isEmpty
                        ? null
                        : () => setState(() => current = (current + 1) % items.length),
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Sonraki'),
                  ),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }
}


