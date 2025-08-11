import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/features/auth/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _login() async {
    setState(() { loading = true; error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
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
                  Text('Tekrarla & Öğren', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  
                  const SizedBox(height: 24),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-posta')), 
                  const SizedBox(height: 12),
                  TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre')),
                  const SizedBox(height: 12),
                  if (error != null) Text(error!, style: TextStyle(color: scheme.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: loading ? null : _login, child: Text(loading ? 'Bekleyin...' : 'Giriş Yap')),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Hesap Oluştur'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signInAnonymously();
                      } on FirebaseAuthException catch (e) {
                        final message = e.code == 'admin-restricted-operation'
                            ? 'Misafir girişi kapalı. Lütfen e-posta ile giriş yapın.'
                            : (e.message ?? 'Giriş başarısız.');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        }
                      }
                    },
                    child: const Text('Şimdilik Misafir Olarak Devam Et'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


