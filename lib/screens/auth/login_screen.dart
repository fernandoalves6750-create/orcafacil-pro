import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _lembrarDispositivo = true; // OpÃ§Ã£o de lembrar dispositivo ativada por padrÃ£o

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o e-mail e a senha.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? erro = await AuthService.fazerLogin(
      email: email,
      senha: senha,
      lembrarDispositivo: _lembrarDispositivo,
    );
    
    setState(() => _isLoading = false);

    if (erro == null && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro ?? 'E-mail ou senha incorretos. Verifique suas credenciais.')),
      );
    }
  }

  void _fazerLoginGoogle() async {
    setState(() => _isLoading = true);

    String? erro = await AuthService.fazerLoginComGoogle(
      lembrarDispositivo: _lembrarDispositivo,
    );

    setState(() => _isLoading = false);

    if (erro == null && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } else if (mounted && erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'OrÃ§aFÃ¡cil PRO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Acesse com suas credenciais',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSub, fontSize: 13),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    labelStyle: TextStyle(color: AppColors.textSub),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    labelStyle: TextStyle(color: AppColors.textSub),
                  ),
                ),
                const SizedBox(height: 12),
                // Checkbox para Lembrar este Dispositivo
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _lembrarDispositivo,
                        activeColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.textSub),
                        onChanged: (value) {
                          setState(() {
                            _lembrarDispositivo = value ?? true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lembrar este dispositivo',
                      style: TextStyle(color: AppColors.textSub, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _fazerLogin,
                            child: const Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 15)),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textLight,
                              side: const BorderSide(color: AppColors.textSub),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _fazerLoginGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                            label: const Text('Entrar com o Google', style: TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: const Text(
                    'NÃ£o tem conta? Cadastre-se aqui',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}