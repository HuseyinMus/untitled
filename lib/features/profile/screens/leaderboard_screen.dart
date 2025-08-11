import 'package:flutter/material.dart';
import 'package:untitled/data/repositories/stats_repository.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liderlik Tablosu')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: StatsRepository.getLeaderboardTop(limit: 50),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          if (data.isEmpty) {
            return const Center(child: Text('Liderlik verisi yok veya erişim izni yok.'));
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = data[i];
              final rank = i + 1;
              final name = (e['displayName'] ?? 'User') as String;
              final xp = (e['xp'] ?? 0) as int;
              final photo = e['photoUrl'] as String?;
              return ListTile(
                leading: CircleAvatar(backgroundImage: photo != null ? NetworkImage(photo) : null, child: photo == null ? Text('$rank') : null),
                title: Text(name),
                trailing: Text('$xp XP'),
              );
            },
          );
        },
      ),
    );
  }
}


