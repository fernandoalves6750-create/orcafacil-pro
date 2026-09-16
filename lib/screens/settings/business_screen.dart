import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  // Variáveis globais estáticas para persistir no app inteiro
  static String empresaNome = '';
  static String empresaCnpj = '';
  static String empresaWhatsapp = '';
  static String empresaLogo = '';
  static String empresaAssinaturaTexto = '';
  static List<Offset?> assinaturaPontos = []; // Lousa digital manuscrita

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _wppController;
  late final TextEditingController _assinaturaController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: BusinessScreen.empresaNome);
    _cnpjController = TextEditingController(text: BusinessScreen.empresaCnpj);
    _wppController = TextEditingController(text: BusinessScreen.empresaWhatsapp);
    _assinaturaController = TextEditingController(text: BusinessScreen.empresaAssinaturaTexto);
  }

  void _salvarDados() {
    setState(() {
      BusinessScreen.empresaNome = _nomeController.text;
      BusinessScreen.empresaCnpj = _cnpjController.text;
      BusinessScreen.empresaWhatsapp = _wppController.text;
      BusinessScreen.empresaAssinaturaTexto = _assinaturaController.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados, Logo e Assinatura Digital salvos com sucesso!')),
    );
  }

  void _abrirLousaDigital() {
    List<Offset?> pontosTemporarios = List.from(BusinessScreen.assinaturaPontos);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text('Lousa Digital de Assinatura', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Faça sua assinatura manuscrita abaixo (use o mouse ou o dedo):', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setDialogState(() {
                              pontosTemporarios.add(details.localPosition);
                            });
                          },
                          onPanEnd: (details) {
                            setDialogState(() {
                              pontosTemporarios.add(null);
                            });
                          },
                          child: CustomPaint(
                            painter: AssinaturaPainter(pontosTemporarios),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            pontosTemporarios.clear();
                          });
                        },
                        icon: const Icon(Icons.clear, color: AppColors.errorRed, size: 18),
                        label: const Text('Limpar Assinatura', style: TextStyle(color: AppColors.errorRed)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                  onPressed: () {
                    setState(() {
                      BusinessScreen.assinaturaPontos = List.from(pontosTemporarios);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assinatura manuscrita salva com sucesso!')));
                  },
                  child: const Text('Salvar Assinatura'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool temAssinaturaDesenhada = BusinessScreen.assinaturaPontos.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Negócio, Logo & Assinatura')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: BusinessScreen.empresaLogo.isNotEmpty ? NetworkImage(BusinessScreen.empresaLogo) : null,
                    child: BusinessScreen.empresaLogo.isEmpty ? const Icon(Icons.business, size: 50, color: AppColors.primaryBlue) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryBlue,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            BusinessScreen.empresaLogo = 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logotipo padrão carregado!')));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome da Empresa', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _cnpjController, decoration: const InputDecoration(labelText: 'CNPJ / CPF', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _wppController, decoration: const InputDecoration(labelText: 'WhatsApp de Contato', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _assinaturaController, decoration: const InputDecoration(labelText: 'Texto da Assinatura Digital (Cargo/Nome)', border: OutlineInputBorder())),
            const SizedBox(height: 20),

            // Bloco elegante para a Lousa Digital na tela principal
            const Text('Assinatura Manuscrita (Lousa Digital)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMedium)),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  if (temAssinaturaDesenhada) ...[
                    Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomPaint(
                          painter: AssinaturaPainter(BusinessScreen.assinaturaPontos),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      side: const BorderSide(color: AppColors.primaryBlue),
                    ),
                    onPressed: _abrirLousaDigital,
                    icon: const Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
                    label: Text(
                      temAssinaturaDesenhada ? 'Alterar Assinatura Manuscrita' : 'Abrir Lousa Digital para Assinar',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: _salvarDados,
              child: const Text('Salvar Alterações', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class AssinaturaPainter extends CustomPainter {
  final List<Offset?> pontos;
  AssinaturaPainter(this.pontos);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < pontos.length - 1; i++) {
      if (pontos[i] != null && pontos[i + 1] != null) {
        canvas.drawLine(pontos[i]!, pontos[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}