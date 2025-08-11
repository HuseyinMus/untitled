import 'package:flutter/material.dart';
import 'package:untitled/data/repositories/stats_repository.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: StatsRepository.getSummary(),
        builder: (context, snap) {
          final summary = snap.data ?? {};
          final xp = (summary['xp'] as num?)?.toInt() ?? 0;
          final streak = (summary['streak'] as num?)?.toInt() ?? 0;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bolt_outlined),
                  title: const Text('XP'),
                  trailing: Text('$xp'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_fire_department_outlined),
                  title: const Text('Seri (gün)'),
                  trailing: Text('$streak'),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: StatsRepository.getDailyLast(14),
                builder: (context, days) {
                  final data = days.data ?? const [];
                  return DailyBarChart(data: data);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String date;
  final int correct;
  final int wrong;
  const _DayChip({required this.date, required this.correct, required this.wrong});

  @override
  Widget build(BuildContext context) {
    final total = correct + wrong;
    final percent = total == 0 ? 0.0 : correct / total;
    final label = date.length >= 8 ? '${date.substring(6, 8)}/${date.substring(4, 6)}' : date;
    return Chip(label: Text('$label  ${(percent * 100).round()}%'));
  }
}

class DailyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const DailyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight - 24;
              final barW = 14.0;
              final gap = 8.0;
              final items = data.take(14).toList().reversed.toList();
              final int Function(dynamic) asInt = (v) => (v as num?)?.toInt() ?? 0;
              final maxVal = items.fold<int>(1, (m, e) {
                final total = asInt(e['correct']) + asInt(e['wrong']);
                return total > m ? total : m;
              });
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Günlük Özet (son 14)'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final e in items) ...[
                            _Bar(
                              height: maxH * (((asInt(e['correct']) + asInt(e['wrong'])) == 0
                                  ? 0.0
                                  : (asInt(e['correct']) + asInt(e['wrong'])) / maxVal)),
                              correctRatio: ((asInt(e['correct']) + asInt(e['wrong'])) == 0)
                                  ? 0.0
                                  : (asInt(e['correct']) / (asInt(e['correct']) + asInt(e['wrong']))),
                              width: barW,
                            ),
                            SizedBox(width: gap),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// Geriye dönük: bazı eski referansları karşılamak için alias wrapper
class _DailyBarChart extends DailyBarChart {
  const _DailyBarChart({required List<Map<String, dynamic>> data}) : super(data: data);
}

class _Bar extends StatelessWidget {
  final double height;
  final double correctRatio;
  final double width;
  const _Bar({required this.height, required this.correctRatio, required this.width});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Yuvarlama kaynaklı taşmaları önlemek için güvenli yükseklik
    final double safeHeight = (height - 2).clamp(0.0, height);
    final double correctH = safeHeight * correctRatio;
    final double wrongH = safeHeight - correctH;
    return SizedBox(
      height: safeHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: width,
            height: wrongH,
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
          Container(
            width: width,
            height: correctH,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}


