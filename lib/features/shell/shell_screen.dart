import 'package:flutter/material.dart';
import 'package:untitled/features/home/home_screen.dart';
import 'package:untitled/features/profile/profile_screen.dart';
import 'package:untitled/data/repositories/in_memory_repository.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/features/categories/categories_screen.dart';
import 'package:untitled/features/study/study_hub_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;
  final Repository quizRepo = InMemoryRepository();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const CategoriesScreen(),
      StudyHubScreen(repository: quizRepo),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana'),
          NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Kategoriler'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Çalış'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
        onDestinationSelected: (i) => setState(() => index = i),
      ),
    );
  }
}


