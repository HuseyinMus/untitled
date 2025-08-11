import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/features/profile/screens/my_lists_screen.dart';
import 'package:untitled/features/profile/screens/stats_screen.dart';
import 'package:untitled/features/profile/screens/settings_screen.dart';
import 'package:untitled/features/profile/screens/leaderboard_screen.dart';
import 'package:untitled/features/profile/widgets/avatar_picker.dart';
import 'package:untitled/core/firebase/admin_config.dart';
import 'package:untitled/features/profile/screens/admin_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? displayName;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    displayName = user?.displayName ?? user?.email ?? 'Misafir';
    photoUrl = user?.photoURL;
  }

  Future<_ProfileStats> _loadStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return const _ProfileStats();
      final col = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('words')
          .get();
      int learned = 0;
      int correct = 0;
      int wrong = 0;
      for (final d in col.docs) {
        final m = d.data();
        final int stage = (m['stage'] ?? 0) as int;
        final int c = (m['correctCount'] ?? 0) as int;
        final int w = (m['wrongCount'] ?? 0) as int;
        if (stage > 0 || c > 0) learned += 1;
        correct += c;
        wrong += w;
      }
      final int xp = correct * 10; // basit puanlama
      // seviye tahmini: her 100 XP bir seviye
      final int level = (xp / 100).floor() + 1;
      final double levelProgress = ((xp % 100) / 100).clamp(0, 1).toDouble();
      return _ProfileStats(
        learnedWords: learned,
        dailyGoalSuccessRate: 0.0, // ileride hesaplanacak
        streakDays: 0, // ileride hesaplanacak
        quizSuccessRate: correct + wrong == 0 ? 0 : correct / (correct + wrong),
        xp: xp,
        level: level,
        levelProgress: levelProgress,
      );
    } catch (_) {
      return const _ProfileStats();
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Avatar seç'),
              onTap: () async {
                Navigator.pop(context);
                final result = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => const AvatarPicker(),
                );
                if (result != null) {
                  setState(() {
                    photoUrl = null;
                    displayName = '${result} ${displayName ?? ''}'.trim();
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Kaldır'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await FirebaseAuth.instance.currentUser?.updatePhotoURL(null);
                  setState(() => photoUrl = null);
                } catch (_) {}
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeDisplayName() async {
    final controller = TextEditingController(text: displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('İsmi düzenle'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'İsim / kullanıcı adı')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(result);
        await FirebaseAuth.instance.currentUser?.reload();
        setState(() => displayName = result);
      } catch (_) {}
    }
  }

  Future<void> _resetPassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu hesap için e-posta bulunamadı.')));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi: $email')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre sıfırlama gönderilemedi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<_ProfileStats>(
        future: _loadStats(),
        builder: (context, snap) {
          final stats = snap.data ?? const _ProfileStats();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                          child: photoUrl == null ? Text((user?.email ?? 'M').substring(0, 1).toUpperCase()) : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: _showPhotoOptions,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(displayName ?? 'Misafir', style: Theme.of(context).textTheme.titleMedium)),
                              TextButton(onPressed: _changeDisplayName, child: const Text('Düzenle')),
                            ],
                          ),
                          Text('UID: ${user?.uid ?? '-'}', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Level ${stats.level} – Word Wizard'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: stats.levelProgress),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('XP: ${stats.xp}'),
                            Text('Öğrenilen: ${stats.learnedWords}')
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatTile(title: 'Toplam Öğrenilen', value: '${stats.learnedWords}'),
                    _StatTile(title: 'Günlük Hedef', value: '${(stats.dailyGoalSuccessRate * 100).round()}%'),
                    _StatTile(title: 'Seri (gün)', value: '${stats.streakDays}'),
                    _StatTile(title: 'Quiz Başarı', value: '${(stats.quizSuccessRate * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Hesap ve Ayarlar', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_outlined),
                        title: const Text('Admin Paneli'),
                        subtitle: const Text('Katalog kelimeleri ekle/sil'),
                        onTap: () async {
                          // Basit kontrol: e-mail varsa ve AdminConfig içinde ise izin verelim
                          final email = FirebaseAuth.instance.currentUser?.email ?? '';
                          final isAdmin = AdminConfig.adminEmails.contains(email);
                          if (!isAdmin) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin yetkisi gerekli.')));
                            }
                            return;
                          }
                          // Dinamik import yerine doğrudan navigasyon – dosya üstünde import gerekecek
                          if (context.mounted) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.folder_shared),
                        title: const Text('Kelime Listelerim'),
                        subtitle: const Text('Kendi listelerini oluştur ve yönet'),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyListsScreen())),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.stacked_line_chart),
                        title: const Text('İstatistikler'),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.emoji_events_outlined),
                        title: const Text('Liderlik Tablosu'),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Ayarlar'),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_reset),
                        title: const Text('Parola Değiştir'),
                        onTap: _resetPassword,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Çıkış Yap'),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  const _StatTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ProfileStats {
  final int learnedWords;
  final double dailyGoalSuccessRate;
  final int streakDays;
  final double quizSuccessRate;
  final int xp;
  final int level;
  final double levelProgress;

  const _ProfileStats({
    this.learnedWords = 0,
    this.dailyGoalSuccessRate = 0,
    this.streakDays = 0,
    this.quizSuccessRate = 0,
    this.xp = 0,
    this.level = 1,
    this.levelProgress = 0,
  });
}


