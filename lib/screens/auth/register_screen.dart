import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/empresa_service.dart';
import '../../core/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  bool _lembrarDispositivo = true; // Ativado por padrÃ£o

  final _empresaController = TextEditingController();
  final _apelidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    _empresaController.dispose();
    _apelidoController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _cadastrar() async {
    final empresa = _empresaController.text.trim();
    final apelido = _apelidoController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (empresa.isEmpty || apelido.isEmpty || email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatÃ³rios.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // IntegraÃ§Ã£o real com o AuthService do Firebase com a opÃ§Ã£o de lembrar dispositivo
    String? erro = await AuthService.cadastrarUsuario(
      email: email,
      senha: senha,
      nomeEmpresa: empresa,
      lembrarDispositivo: _lembrarDispositivo,
    );

    if (erro == null) {
      await EmpresaService.salvarEmpresa({
        'nome': empresa,
        'responsavel': apelido,
        'cnpj': '',
        'contato': email,
        'assinatura': EmpresaService.dadosEmpresa['assinatura'] ?? '',
        'logoPath': EmpresaService.dadosEmpresa['logoPath'] ?? '',
      });
    }

    setState(() => _isLoading = false);

    if (erro == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta cadastrada com sucesso!')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro ?? 'Erro ao cadastrar conta. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Criar Nova Conta', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.surfaceDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: _empresaController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(
                  labelText: 'Nome da Empresa',
                  labelStyle: TextStyle(color: AppColors.textSub),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apelidoController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(
                  labelText: 'Como vocÃª quer ser chamado?',
                  labelStyle: TextStyle(color: AppColors.textSub),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _cadastrar,
                      child: const Text('Cadastrar Conta', style: TextStyle(color: Colors.white, fontSize: 15)),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'JÃ¡ tem uma conta? FaÃ§a login',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
