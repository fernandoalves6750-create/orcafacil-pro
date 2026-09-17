import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  // Controlador da lousa de assinatura
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.textLight,
    exportBackgroundColor: AppColors.surfaceDark,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Desenhar Assinatura', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.errorRed),
            tooltip: 'Limpar',
            onPressed: () => _controller.clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Desenhe sua assinatura no espaço abaixo:',
              style: TextStyle(color: AppColors.textSub, fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderDark),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surfaceDark,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _controller,
                  backgroundColor: AppColors.surfaceDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textSub)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (_controller.isNotEmpty) {
                        // Converte o desenho para bytes de imagem (PNG)
                        Uint8List? signatureBytes = await _controller.toPngBytes();
                        if (signatureBytes != null) {
                          // Salva de forma permanente no StorageService para nunca mais sumir
                          await StorageService.salvarAssinatura(signatureBytes);
                        }

                        if (!context.mounted) return;
                        Navigator.pop(context, signatureBytes);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Assinatura salva com sucesso!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor, desenhe a assinatura antes de salvar.')),
                        );
                      }
                    },
                    child: const Text('Salvar Assinatura', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}