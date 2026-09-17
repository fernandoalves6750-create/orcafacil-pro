import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/empresa_service.dart';
import '../../core/theme/app_colors.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

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
    _nomeController = TextEditingController();
    _cnpjController = TextEditingController();
    _wppController = TextEditingController();
    _assinaturaController = TextEditingController();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    await StorageService.carregarTudo();
    await EmpresaService.carregarEmpresa();
    setState(() {
      _nomeController.text = EmpresaService.dadosEmpresa['nome'] ?? '';
      _cnpjController.text = EmpresaService.dadosEmpresa['cnpj'] ?? '';
      _wppController.text = EmpresaService.dadosEmpresa['contato'] ?? '';
      _assinaturaController.text = EmpresaService.dadosEmpresa['assinatura'] ?? '';
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _wppController.dispose();
    _assinaturaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarLogotipo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        await StorageService.salvarLogo(bytes);
        setState(() {});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logotipo alterado e salvo com sucesso!'), backgroundColor: AppColors.surfaceDark),
        );
      }
    } catch (e) {
      debugPrint('Erro ao selecionar logo: $e');
    }
  }

  void _salvarDados() async {
    await EmpresaService.salvarEmpresa({
      'nome': _nomeController.text.trim(),
      'cnpj': _cnpjController.text.trim(),
      'contato': _wppController.text.trim(),
      'assinatura': _assinaturaController.text.trim(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados da empresa salvos com sucesso!'), backgroundColor: AppColors.surfaceDark),
    );
  }

  Future<void> _converterESalvarAssinatura(List<Offset?> pontos) async {
    if (pontos.isEmpty) return;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 200);

      final paintBg = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBg);

      final paintLine = Paint()
        ..color = Colors.black87
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;

      for (int i = 0; i < pontos.length - 1; i++) {
        if (pontos[i] != null && pontos[i + 1] != null) {
          canvas.drawLine(pontos[i]!, pontos[i + 1]!, paintLine);
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        await StorageService.salvarAssinatura(pngBytes);
      }
    } catch (e) {
      debugPrint('Erro ao converter assinatura: $e');
    }
  }

  void _abrirLousaDigital() {
    List<Offset?> pontosTemporarios = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text('Lousa Digital de Assinatura', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Faça sua assinatura manuscrita abaixo:', style: TextStyle(fontSize: 13, color: AppColors.textSub)),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textSub)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                  onPressed: () async {
                    await _converterESalvarAssinatura(pontosTemporarios);
                    setState(() {});

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assinatura manuscrita salva com sucesso!'), backgroundColor: AppColors.surfaceDark),
                    );
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
    bool temAssinaturaDesenhada = StorageService.assinaturaCacheGlobal != null;
    bool temLogoSalva = StorageService.logoCacheGlobal != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Configurar Dados da Empresa', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryBlue.withAlpha(80)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: AppColors.warningOrange, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dica: Insira o nome da sua empresa, CNPJ/CPF e contatos. Estes dados preencherão o cabeçalho dos seus orçamentos e recibos em PDF.',
                      style: TextStyle(color: AppColors.textSub, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.surfaceDark,
                    backgroundImage: temLogoSalva ? MemoryImage(StorageService.logoCacheGlobal!) : null,
                    child: !temLogoSalva ? const Icon(Icons.add_a_photo_rounded, size: 36, color: AppColors.primaryBlue) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryBlue,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        tooltip: 'Adicionar Logotipo',
                        onPressed: _selecionarLogotipo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Toque na câmera para adicionar o logotipo', style: TextStyle(color: AppColors.textSub, fontSize: 11)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nomeController,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa / Nome Fantasia',
                hintText: 'Digite o nome da sua empresa aqui',
                hintStyle: TextStyle(color: AppColors.textSub),
                labelStyle: TextStyle(color: AppColors.textSub),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cnpjController,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(
                labelText: 'CNPJ ou CPF',
                hintText: '00.000.000/0001-00',
                hintStyle: TextStyle(color: AppColors.textSub),
                labelStyle: TextStyle(color: AppColors.textSub),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _wppController,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(
                labelText: 'E-mail e WhatsApp de Contato',
                hintText: 'seu@email.com | (00) 00000-0000',
                hintStyle: TextStyle(color: AppColors.textSub),
                labelStyle: TextStyle(color: AppColors.textSub),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _assinaturaController,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(
                labelText: 'Cargo ou Nome para Assinatura',
                hintText: 'Ex: Técnico Responsável',
                hintStyle: TextStyle(color: AppColors.textSub),
                labelStyle: TextStyle(color: AppColors.textSub),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Assinatura Manuscrita (Lousa Digital)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSub)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  if (temAssinaturaDesenhada) ...[
                    Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          StorageService.assinaturaCacheGlobal!,
                          fit: BoxFit.contain,
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