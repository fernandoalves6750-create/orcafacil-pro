import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../screens/settings/business_screen.dart';
import '../../screens/finance/finance_screen.dart';
import '../../screens/products/products_services_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  static final List<Map<String, dynamic>> listaOrcamentosGlobais = [];

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  void _abrirModalOrcamento([Map<String, dynamic>? itemExistente, int? index]) {
    final clienteController = TextEditingController(text: itemExistente?['cliente'] ?? '');
    String itemSelecionado = itemExistente?['item'] ?? (ProductsServicesScreen.itensGlobais.isNotEmpty ? ProductsServicesScreen.itensGlobais.first.name : 'Serviço Geral');
    final valorController = TextEditingController(text: itemExistente != null ? itemExistente['valor'].toString() : '0.00');
    String statusAtual = itemExistente?['status'] ?? 'Pendente';

    // Atualiza o valor automático se escolher da lista de produtos/serviços
    if (itemExistente == null && ProductsServicesScreen.itensGlobais.isNotEmpty) {
      valorController.text = ProductsServicesScreen.itensGlobais.first.price.toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(itemExistente == null ? 'Novo Orçamento' : 'Editar Orçamento', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: clienteController,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: const InputDecoration(labelText: 'Nome do Cliente', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  if (ProductsServicesScreen.itensGlobais.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      dropdownColor: AppColors.surfaceDark,
                      style: const TextStyle(color: AppColors.textLight),
                      value: itemSelecionado,
                      decoration: const InputDecoration(labelText: 'Produto / Serviço Cadastrado', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                      items: ProductsServicesScreen.itensGlobais.map((prod) {
                        return DropdownMenuItem(
                          value: prod.name,
                          child: Text('${prod.name} (R\$ ${prod.price.toStringAsFixed(2)})', style: const TextStyle(color: AppColors.textLight)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          itemSelecionado = val!;
                          final match = ProductsServicesScreen.itensGlobais.firstWhere((p) => p.name == val);
                          valorController.text = match.price.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: valorController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: const InputDecoration(labelText: 'Valor Total (R\$)', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.surfaceDark,
                    style: const TextStyle(color: AppColors.textLight),
                    value: statusAtual,
                    decoration: const InputDecoration(labelText: 'Status do Orçamento', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Pendente', child: Text('Pendente', style: TextStyle(color: AppColors.warningOrange))),
                      DropdownMenuItem(value: 'Aprovado', child: Text('Aprovado', style: TextStyle(color: AppColors.successGreen))),
                    ],
                    onChanged: (val) => setModalState(() => statusAtual = val!),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                    onPressed: () {
                      final valorDouble = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;
                      if (clienteController.text.isNotEmpty && valorDouble > 0) {
                        setState(() {
                          final novoOrcamento = {
                            'cliente': clienteController.text,
                            'item': itemSelecionado,
                            'valor': valorDouble,
                            'status': statusAtual,
                          };

                          if (itemExistente == null) {
                            BudgetsScreen.listaOrcamentosGlobais.add(novoOrcamento);
                            // Envio automático para o financeiro se estiver aprovado
                            if (statusAtual == 'Aprovado') {
                              FinanceScreen.listaFinanceiraGlobal.add({
                                'cliente': clienteController.text,
                                'descricao': itemSelecionado,
                                'valor': valorDouble,
                                'tipo': 'Receita',
                                'status': 'Pendente',
                              });
                            }
                          } else {
                            BudgetsScreen.listaOrcamentosGlobais[index!] = novoOrcamento;
                          }
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Salvar Orçamento'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarPreviaPdf(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Row(
          children: const [
            Icon(Icons.picture_as_pdf, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Orçamento Gerado (PDF)', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(BusinessScreen.empresaNome.isEmpty ? 'SUA EMPRESA' : BusinessScreen.empresaNome.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              Text('CNPJ: ${BusinessScreen.empresaCnpj.isEmpty ? '00.000.000/0001-00' : BusinessScreen.empresaCnpj}', style: const TextStyle(fontSize: 11, color: AppColors.textSub)),
              const Divider(color: AppColors.borderDark),
              Text('Cliente: ${item['cliente']}', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
              Text('Serviço: ${item['item']}', style: const TextStyle(color: AppColors.textLight)),
              const SizedBox(height: 10),
              Text('Valor Total: R\$ ${(item['valor'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
              Text('Status: ${item['status']}', style: const TextStyle(color: AppColors.textSub)),
              const SizedBox(height: 20),
              const Divider(color: AppColors.borderDark),
              Text('Responsável:\n${BusinessScreen.empresaAssinaturaTexto.isEmpty ? 'Técnico Responsável' : BusinessScreen.empresaAssinaturaTexto}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSub)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar', style: TextStyle(color: AppColors.textSub))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento PDF exportado com sucesso no dispositivo!')));
            },
            icon: const Icon(Icons.download),
            label: const Text('Salvar PDF'),
          ),
        ],
      ),
    );
  }

  void _enviarWhatsApp(Map<String, dynamic> item) async {
    final mensagem = "Olá *${item['cliente']}*! Segue o resumo do seu orçamento:\n\n*Serviço:* ${item['item']}\n*Valor:* R\$ ${(item['valor'] as double).toStringAsFixed(2)}\n*Status:* ${item['status']}\n\nGerado por ${BusinessScreen.empresaNome.isEmpty ? 'OrçaFácil Pro' : BusinessScreen.empresaNome}.";
    final telefone = BusinessScreen.empresaWhatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    
    final url = Uri.parse("https://wa.me/$telefone?text=${Uri.encodeComponent(mensagem)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse("https://api.whatsapp.com/send?text=${Uri.encodeComponent(mensagem)}"), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao abrir WhatsApp: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos')),
      body: BudgetsScreen.listaOrcamentosGlobais.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.description_outlined, size: 48, color: AppColors.textSub),
                  SizedBox(height: 12),
                  Text('Nenhum orçamento cadastrado.', style: TextStyle(color: AppColors.textSub, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Toque no botão + para criar um orçamento.', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: BudgetsScreen.listaOrcamentosGlobais.length,
              itemBuilder: (context, index) {
                final item = BudgetsScreen.listaOrcamentosGlobais[index];
                bool isAprovado = item['status'] == 'Aprovado';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['cliente'], style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isAprovado ? AppColors.successGreen : AppColors.warningOrange).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['status'],
                                style: TextStyle(
                                  color: isAprovado ? AppColors.successGreen : AppColors.warningOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${item['item']} • R\$ ${(item['valor'] as double).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
                        const Divider(color: AppColors.borderDark, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(
                              onPressed: () => _abrirModalOrcamento(item, index),
                              icon: const Icon(Icons.edit, size: 16, color: AppColors.primaryBlue),
                              label: const Text('Editar', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12)),
                            ),
                            TextButton.icon(
                              onPressed: () => _mostrarPreviaPdf(item),
                              icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.redAccent),
                              label: const Text('PDF', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ),
                            TextButton.icon(
                              onPressed: () => _enviarWhatsApp(item),
                              icon: const Icon(Icons.chat, size: 16, color: AppColors.successGreen),
                              label: const Text('WhatsApp', style: TextStyle(color: AppColors.successGreen, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _abrirModalOrcamento(),
        child: const Icon(Icons.add),
      ),
    );
  }
}