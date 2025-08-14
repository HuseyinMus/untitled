import 'package:flutter/material.dart';
import 'package:untitled/features/home/home_screen.dart';
import 'package:untitled/features/profile/profile_screen.dart';
import 'package:untitled/data/repositories/in_memory_repository.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/features/categories/categories_screen.dart';
import 'package:untitled/features/study/study_hub_screen.dart';
import 'package:untitled/core/firebase/firebase_initializer.dart';
import 'package:untitled/data/repositories/firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/features/home/widgets/banner_ad_widget.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;
  Repository repository = InMemoryRepository();
  bool firebaseReady = false;

  @override
  void initState() {
    super.initState();
    _setupRepository();
  }

  Future<void> _setupRepository() async {
    final ok = await initializeFirebaseSafely();
    if (!mounted) return;
    if (ok) {
      try {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
        }
        final repo = FirebaseRepository(FirebaseFirestore.instance, auth);
        await repo.loadCatalogOnce();
        if (!mounted) return;
        setState(() {
          repository = repo;
          firebaseReady = true;
        });
        return;
      } catch (_) {
        // fallthrough
      }
    }
    if (!mounted) return;
    setState(() {
      repository = InMemoryRepository();
      firebaseReady = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(externalRepository: repository),
      CategoriesScreen(externalRepository: repository),
      StudyHubScreen(repository: repository),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              selectedIndex: index,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana'),
                NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Kategoriler'),
                NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Çalış'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
              ],
              onDestinationSelected: (i) => setState(() => index = i),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: BannerAdWidget(),
            ),
          ],
        ),
      ),
    );
  }
}


