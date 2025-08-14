import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/data/repositories/profile_repository.dart';

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
        try {
          await ProfileRepository.upsertProfile(
            uid: user.uid,
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            username: usernameController.text.isEmpty ? null : usernameController.text,
          );
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'displayName': user.displayName,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } on Exception catch (e) {
          if (e.toString().contains('username_taken')) {
            setState(() { error = 'Bu kullanıcı adı alınmış. Lütfen başka bir kullanıcı adı deneyin.'; });
            return;
          }
        }
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


