import 'package:flutter/material.dart';

class PlacementResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final String suggestedLevel;

  const PlacementResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.suggestedLevel,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = total == 0 ? 0 : score / total;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Seviye Tespit Sonucu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Önerilen Seviye', style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text(
                        suggestedLevel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Skor: $score / $total (${(ratio * 100).round()}%)', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Öneriler', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('• Bu seviyedeki kelimelere odaklanarak başlayın.'),
                    const SizedBox(height: 4),
                    const Text('• Günlük hedefinizi gerçekçi tutun (10-15 kelime).'),
                    const SizedBox(height: 4),
                    const Text('• Quiz ve Flashcard modlarını dönüşümlü kullanın.'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop({
                  'score': score,
                  'suggestedLevel': suggestedLevel,
                });
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }
}


