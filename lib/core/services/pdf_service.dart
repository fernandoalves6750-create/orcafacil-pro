import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/services/storage_service.dart';

class PdfService {
  static pw.Font? _fontRegularCache;
  static pw.Font? _fontBoldCache;

  static Future<void> _initFonts() async {
    _fontRegularCache ??= await PdfGoogleFonts.robotoRegular();
    _fontBoldCache ??= await PdfGoogleFonts.robotoBold();
  }

  // FunÃ§Ã£o auxiliar para converter a data do formato AAAA-MM-DD para DD/MM/AAAA
  static String _formatarDataBr(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) {
      final agora = DateTime.now();
      return "${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year}";
    }

    try {
      final partes = dataStr.split(' ')[0].split('-');
      if (partes.length == 3) {
        final ano = partes[0];
        final mes = partes[1];
        final dia = partes[2];
        return "$dia/$mes/$ano";
      }
    } catch (_) {}

    return dataStr; // Retorna original caso nÃ£o consiga converter
  }

  // GeraÃ§Ã£o de PDF de OrÃ§amento
  static Future<Uint8List> gerarPdfOrcamento({
    required Map<String, dynamic> orcamento,
    Map<String, dynamic>? dadosEmpresa,
  }) async {
    await _initFonts();
    final pdf = pw.Document();

    final fontRegular = _fontRegularCache!;
    final fontBold = _fontBoldCache!;

    final nomeEmpresa = dadosEmpresa?['nome'] ?? '';
    final cnpjEmpresa = dadosEmpresa?['cnpj'] ?? '';
    final contatoEmpresa = dadosEmpresa?['contato'] ?? '';
    
    Uint8List? logoBytes = dadosEmpresa?['logoBytes'] ?? StorageService.logoCacheGlobal;

    final numeroOrcamento = orcamento['numero'] ?? orcamento['id'] ?? '#001';
    final cliente = orcamento['cliente'] ?? 'Cliente nÃ£o informado';
    
    // Data formatada para DD/MM/AAAA
    final dataOrcamento = _formatarDataBr(orcamento['data']);
    
    final itens = (orcamento['itens'] as List<dynamic>?) ?? [
      {
        'descricao': orcamento['item'] ?? 'ServiÃ§o / Produto Geral',
        'quantidade': 1,
        'valorUnitario': orcamento['valor'] ?? 0.0,
      }
    ];
    final valorTotal = (orcamento['valor'] as num?)?.toDouble() ?? 0.0;
    final formaPagamento = orcamento['formaPagamento'] ?? 'A combinar';
    final entrada = (orcamento['entrada'] as num?)?.toDouble() ?? 0.0;
    final valorRestante = valorTotal - entrada;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoBytes != null) ...[
                          pw.Image(
                            pw.MemoryImage(logoBytes),
                            width: 45,
                            height: 45,
                            fit: pw.BoxFit.contain,
                          ),
                          pw.SizedBox(width: 12),
                        ],
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (nomeEmpresa.isNotEmpty)
                                pw.Text(nomeEmpresa, style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800)),
                              if (nomeEmpresa.isNotEmpty) pw.SizedBox(height: 2),
                              if (cnpjEmpresa.isNotEmpty)
                                pw.Text(cnpjEmpresa, style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700)),
                              if (contatoEmpresa.isNotEmpty)
                                pw.Text(contatoEmpresa, style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('ORÃ‡AMENTO', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue800)),
                        pw.SizedBox(height: 2),
                        pw.Text('$numeroOrcamento', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1, height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLIENTE:', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(cliente, style: pw.TextStyle(font: fontBold, fontSize: 13)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('DATA:', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(dataOrcamento, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('ITENS DO ORÃ‡AMENTO', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue800)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(font: fontRegular, fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['DescriÃ§Ã£o / ServiÃ§o', 'Qtd', 'PreÃ§o Unit. (R\$)', 'Total (R\$)'],
                data: itens.map((item) {
                  final qtd = (item['quantidade'] as num?)?.toInt() ?? 1;
                  final unit = (item['valorUnitario'] as num?)?.toDouble() ?? 0.0;
                  return [
                    item['descricao']?.toString() ?? '',
                    qtd.toString(),
                    unit.toStringAsFixed(2),
                    (qtd * unit).toStringAsFixed(2),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildLinhaResumo('Valor Total:', 'R\$ ${valorTotal.toStringAsFixed(2)}', fontBold, true),
                        pw.SizedBox(height: 4),
                        _buildLinhaResumo('Pagamento:', formaPagamento, fontRegular, false),
                        pw.SizedBox(height: 2),
                        _buildLinhaResumo('Entrada:', 'R\$ ${entrada.toStringAsFixed(2)}', fontRegular, false),
                        pw.SizedBox(height: 2),
                        _buildLinhaResumo('Restante:', 'R\$ ${valorRestante.toStringAsFixed(2)}', fontBold, false),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              if (StorageService.assinaturaCacheGlobal != null) ...[
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Image(
                        pw.MemoryImage(StorageService.assinaturaCacheGlobal!),
                        width: 140,
                        height: 50,
                        fit: pw.BoxFit.contain,
                      ),
                      pw.SizedBox(height: 2),
                      pw.SizedBox(
                        width: 180,
                        child: pw.Divider(color: PdfColors.grey700, thickness: 1),
                      ),
                      pw.Text('Assinatura do Profissional', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
              ],

              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.Center(
                child: pw.Text('OrÃ§amento vÃ¡lido por 10 dias.', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // GeraÃ§Ã£o de PDF de Recibo
  static Future<Uint8List> gerarPdfRecibo({
    required Map<String, dynamic> orcamento,
    Map<String, dynamic>? dadosEmpresa,
  }) async {
    await _initFonts();
    final pdf = pw.Document();

    final fontRegular = _fontRegularCache!;
    final fontBold = _fontBoldCache!;

    final nomeEmpresa = dadosEmpresa?['nome'] ?? '';
    final cnpjEmpresa = dadosEmpresa?['cnpj'] ?? '';
    final contatoEmpresa = dadosEmpresa?['contato'] ?? '';
    
    Uint8List? logoBytes = dadosEmpresa?['logoBytes'] ?? StorageService.logoCacheGlobal;

    final cliente = orcamento['cliente'] ?? 'Cliente nÃ£o informado';
    
    // Data formatada para DD/MM/AAAA
    final dataRecibo = _formatarDataBr(orcamento['data']);
    
    final descricao = orcamento['item'] ?? orcamento['descricao'] ?? 'ServiÃ§o prestado';
    final valor = (orcamento['valor'] as num?)?.toDouble() ?? 0.0;
    final formaPagamento = orcamento['formaPagamento'] ?? 'Pix';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoBytes != null) ...[
                          pw.Image(
                            pw.MemoryImage(logoBytes),
                            width: 45,
                            height: 45,
                            fit: pw.BoxFit.contain,
                          ),
                          pw.SizedBox(width: 12),
                        ],
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (nomeEmpresa.isNotEmpty)
                                pw.Text(nomeEmpresa, style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue800)),
                              if (nomeEmpresa.isNotEmpty) pw.SizedBox(height: 2),
                              if (cnpjEmpresa.isNotEmpty)
                                pw.Text(cnpjEmpresa, style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700)),
                              if (contatoEmpresa.isNotEmpty)
                                pw.Text(contatoEmpresa, style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'RECIBO DE PAGAMENTO',
                      style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.blue800),
                    ),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1, height: 25),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Data: $dataRecibo', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('VALOR RECEBIDO:', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey600)),
                    pw.SizedBox(height: 4),
                    pw.Text('R\$ ${valor.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColors.blue900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('Recebemos de:', style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(cliente, style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.SizedBox(height: 16),
              pw.Text('Referente a:', style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(descricao, style: pw.TextStyle(font: fontBold, fontSize: 13)),
              pw.SizedBox(height: 16),
              pw.Text('Forma de Pagamento: $formaPagamento', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.grey800)),
              pw.Spacer(),

              if (StorageService.assinaturaCacheGlobal != null) ...[
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Image(
                        pw.MemoryImage(StorageService.assinaturaCacheGlobal!),
                        width: 140,
                        height: 50,
                        fit: pw.BoxFit.contain,
                      ),
                      pw.SizedBox(height: 2),
                      pw.SizedBox(
                        width: 180,
                        child: pw.Divider(color: PdfColors.grey700, thickness: 1),
                      ),
                      if (nomeEmpresa.isNotEmpty)
                        pw.Text(nomeEmpresa, style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
              ] else if (nomeEmpresa.isNotEmpty) ...[
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.SizedBox(width: 250, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                      pw.SizedBox(height: 4),
                      pw.Text(nomeEmpresa, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    ],
                  ),
                ),
              ],

              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildLinhaResumo(String titulo, String valor, pw.Font fonte, bool destaque) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(titulo, style: pw.TextStyle(font: fonte, fontSize: destaque ? 10 : 8, color: destaque ? PdfColors.blue900 : PdfColors.grey800)),
        pw.Text(valor, style: pw.TextStyle(font: fonte, fontSize: destaque ? 10 : 8, color: destaque ? PdfColors.blue900 : PdfColors.grey800)),
      ],
    );
  }
}
