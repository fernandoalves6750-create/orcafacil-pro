import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // Geração de PDF de Orçamento
  static Future<Uint8List> gerarPdfOrcamento({
    required Map<String, dynamic> orcamento,
    Map<String, dynamic>? dadosEmpresa,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final nomeEmpresa = dadosEmpresa?['nome'] ?? 'FS Manutenção e Suporte em Informática';
    final cnpjEmpresa = dadosEmpresa?['cnpj'] ?? 'CNPJ: 00.000.000/0001-00';
    final contatoEmpresa = dadosEmpresa?['contato'] ?? 'contato@fsmanutencao.com.br | (11) 90000-0000';

    final cliente = orcamento['cliente'] ?? 'Cliente não informado';
    final dataOrcamento = orcamento['data'] ?? DateTime.now().toString().substring(0, 10);
    final itens = (orcamento['itens'] as List<dynamic>?) ?? [
      {
        'descricao': orcamento['item'] ?? 'Serviço / Produto Geral',
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
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(nomeEmpresa, style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue800)),
                      pw.SizedBox(height: 4),
                      pw.Text(cnpjEmpresa, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
                      pw.Text(contatoEmpresa, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text('ORÇAMENTO', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800)),
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
              pw.Text('ITENS DO ORÇAMENTO', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue800)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(font: fontRegular, fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['Descrição / Serviço', 'Qtd', 'Preço Unit. (R\$)', 'Total (R\$)'],
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
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.Center(
                child: pw.Text('Orçamento válido por 10 dias.', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Geração de PDF de Recibo
  static Future<Uint8List> gerarPdfRecibo({
    required Map<String, dynamic> orcamento,
    Map<String, dynamic>? dadosEmpresa,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final nomeEmpresa = dadosEmpresa?['nome'] ?? 'FS Manutenção e Suporte em Informática';
    final cnpjEmpresa = dadosEmpresa?['cnpj'] ?? 'CNPJ: 00.000.000/0001-00';
    final contatoEmpresa = dadosEmpresa?['contato'] ?? 'contato@fsmanutencao.com.br | (11) 90000-0000';

    final cliente = orcamento['cliente'] ?? 'Cliente não informado';
    final dataRecibo = orcamento['data'] ?? DateTime.now().toString().substring(0, 10);
    final descricao = orcamento['item'] ?? orcamento['descricao'] ?? 'Serviço prestado';
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
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(nomeEmpresa, style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.green800)),
                      pw.SizedBox(height: 4),
                      pw.Text(cnpjEmpresa, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
                      pw.Text(contatoEmpresa, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green800, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text('RECIBO DE PAGAMENTO', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green800)),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1, height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Data: $dataRecibo', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 20),
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
                    pw.Text('R\$ ${valor.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColors.green900)),
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
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 30),
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