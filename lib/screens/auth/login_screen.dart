import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/empresa_service.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isCadastro = false;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _empresaController = TextEditingController();
  final _apelidoController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _empresaController.dispose();
    _apelidoController.dispose();
    super.dispose();
  }

  void _submeter() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final empresa = _empresaController.text.trim();
    final apelido = _apelidoController.text.trim();

    if (email.isEmpty || senha.isEmpty || (_isCadastro && (empresa.isEmpty || apelido.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_isCadastro) {
      bool cadastrado = await AuthService.cadastrarUsuario(email, senha, empresa);
      
      if (cadastrado) {
        await EmpresaService.salvarEmpresa({
          'nome': empresa,
          'responsavel': apelido,
          'cnpj': '',
          'contato': email,
          'assinatura': EmpresaService.dadosEmpresa['assinatura'],
          'logoPath': EmpresaService.dadosEmpresa['logoPath'] ?? '',
        });
      }

      setState(() => _isLoading = false);

      if (cadastrado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta cadastrada com sucesso! Faça login.')),
        );
        setState(() => _isCadastro = false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cadastrar conta.')),
        );
      }
    } else {
      bool valido = await AuthService.validarLogin(email, senha);
      setState(() => _isLoading = false);
      if (valido && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail ou senha incorretos. Verifique suas credenciais.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO DOS ASSETS (assets/logo.png)
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlue, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 40,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'OrçaFácil PRO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isCadastro ? 'Cadastre sua nova conta' : 'Acesse com suas credenciais',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSub, fontSize: 13),
                ),
                const SizedBox(height: 32),

                if (_isCadastro) ...[
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
                      labelText: 'Como você quer ser chamado?',
                      labelStyle: TextStyle(color: AppColors.textSub),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                            ),
                            onPressed: _submeter,
                            child: Text(
                              _isCadastro ? 'Cadastrar Conta' : 'Entrar',
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCadastro = !_isCadastro;
                    });
                  },
                  child: Text(
                    _isCadastro ? 'Já tem uma conta? Faça login' : 'Não tem conta? Cadastre-se aqui',
                    style: const TextStyle(color: AppColors.primaryBlue),
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