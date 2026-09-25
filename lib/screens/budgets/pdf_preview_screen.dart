import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String nomeArquivo;
  final String titulo;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.nomeArquivo,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        iconTheme: const IconThemeData(color: AppColors.textLight),
        actions: [
          // BotÃ£o de compartilhamento direto (WhatsApp / Outros apps)
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primaryBlue),
            tooltip: 'Compartilhar / Enviar no WhatsApp',
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: nomeArquivo,
              );
            },
          ),
        ],
      ),
      // Exibe a prÃ©-visualizaÃ§Ã£o interativa na tela com ferramentas de impressÃ£o e compartilhamento
      body: PdfPreview(
        build: (format) async => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: nomeArquivo,
        actions: [
          // BotÃ£o personalizado na barra inferior do preview para WhatsApp/Compartilhar
          PdfPreviewAction(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: (context, build, pageFormat) async {
              await Printing.sharePdf(bytes: pdfBytes, filename: nomeArquivo);
            },
          ),
        ],
      ),
    );
  }
}
