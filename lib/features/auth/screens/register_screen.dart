import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _register() async {
    setState(() { loading = true; error = null; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName('${firstNameController.text.trim()} ${lastNameController.text.trim()}'.trim());
        // Basit profil başlangıcı
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() { error = e.message; });
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'Ad')), 
                  const SizedBox(height: 12),
                  TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Soyad')), 
                  const SizedBox(height: 12),
                  TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Kullanıcı adı (opsiyonel)')), 
                  const SizedBox(height: 12),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-posta')), 
                  const SizedBox(height: 12),
                  TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre')),
                  const SizedBox(height: 12),
                  if (error != null) Text(error!, style: TextStyle(color: scheme.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: loading ? null : _register, child: Text(loading ? 'Bekleyin...' : 'Kayıt Ol')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


