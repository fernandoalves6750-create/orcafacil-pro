import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  void _fazerLogin() {
    if (_emailController.text.isNotEmpty && _senhaController.text.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      // Login rápido de teste ou validação
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.request_quote_rounded, size: 72, color: AppColors.primaryBlue),
              const SizedBox(height: 16),
              const Text(
                'OrçaFácil Pro',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestão Profissional para Prestadores',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSub),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(
                  labelText: 'E-mail ou Usuário',
                  labelStyle: TextStyle(color: AppColors.textSub),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(
                  labelText: 'Senha de Acesso',
                  labelStyle: TextStyle(color: AppColors.textSub),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock, color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _fazerLogin,
                child: const Text('Entrar no Sistema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}