import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/theme/app_colors.dart';
import '../products/products_services_screen.dart';
import 'pdf_preview_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  static List<Map<String, dynamic>> listaOrcamentosGlobais = [];

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await StorageService.carregarTudo();
    if (mounted) setState(() {});
  }

  void _adicionarOuEditarOrcamento({Map<String, dynamic>? orcamentoExistente, int? index}) async {
    // Garante sincronização imediata dos produtos cadastrados ao abrir o modal
    await StorageService.carregarTudo();

    final clienteController = TextEditingController(text: orcamentoExistente?['cliente'] ?? '');
    
    List<Map<String, dynamic>> itensOrcamento = [];
    if (orcamentoExistente != null && orcamentoExistente['itens'] != null) {
      itensOrcamento = List<Map<String, dynamic>>.from(
        (orcamentoExistente['itens'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } else if (orcamentoExistente != null && orcamentoExistente['item'] != null) {
      itensOrcamento.add({
        'descricao': orcamentoExistente['item'],
        'quantidade': 1,
        'valorUnitario': orcamentoExistente['valor'] ?? 0.0,
      });
    } else {
      itensOrcamento.add({'descricao': '', 'quantidade': 1, 'valorUnitario': 0.0});
    }

    final entradaController = TextEditingController(text: orcamentoExistente != null ? orcamentoExistente['entrada'].toString() : '0.0');
    String statusSelecionado = orcamentoExistente?['status'] ?? 'Pendente';
    String formaPagamentoSelecionada = orcamentoExistente?['formaPagamento'] ?? 'Pix';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double calcularTotal() {
              double total = 0;
              for (var item in itensOrcamento) {
                double qtd = (item['quantidade'] as num?)?.toDouble() ?? 1.0;
                double val = (item['valorUnitario'] as num?)?.toDouble() ?? 0.0;
                total += qtd * val;
              }
              return total;
            }

            // Lista unificada e sem duplicatas puxando de ambas as fontes de cache
            final List<Map<String, dynamic>> listaProdutos = [
              ...StorageService.produtosCacheGlobal,
              ...ProductsServicesScreen.listaProdutosGlobais,
            ].fold<Map<String, Map<String, dynamic>>>({}, (map, item) {
              final nome = item['name'] ?? item['nome'] ?? '';
              if (nome.isNotEmpty) map[nome] = item;
              return map;
            }).values.toList();

            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Text(
                orcamentoExistente == null ? 'Novo Orçamento' : 'Editar Orçamento',
                style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: clienteController,
                        style: const TextStyle(color: AppColors.textLight),
                        decoration: const InputDecoration(labelText: 'Nome do Cliente', labelStyle: TextStyle(color: AppColors.textSub)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Itens / Produtos / Serviços', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),

                      ...itensOrcamento.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var item = entry.value;

                        final precoController = TextEditingController(text: item['valorUnitario'].toString());
                        final descController = TextEditingController(text: item['descricao']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('Item ${idx + 1}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  if (itensOrcamento.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.close, color: AppColors.errorRed, size: 18),
                                      onPressed: () {
                                        setDialogState(() {
                                          itensOrcamento.removeAt(idx);
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: listaProdutos.any((p) => (p['name'] ?? p['nome'] ?? '') == item['descricao']) ? item['descricao'] : null,
                                dropdownColor: AppColors.surfaceDark,
                                style: const TextStyle(color: AppColors.textLight),
                                decoration: const InputDecoration(
                                  labelText: 'Puxar Produto/Serviço Cadastrado (Opcional)',
                                  labelStyle: TextStyle(color: AppColors.textSub, fontSize: 12),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Digitação Extra / Manual', style: TextStyle(color: AppColors.textSub)),
                                  ),
                                  ...listaProdutos.map((prod) {
                                    final nomeProd = prod['name'] ?? prod['nome'] ?? '';
                                    final precoProd = (prod['price'] ?? prod['preco'] ?? prod['valor'] ?? 0.0) as num;
                                    return DropdownMenuItem<String>(
                                      value: nomeProd.toString(),
                                      child: Text("$nomeProd (R\$ ${precoProd.toStringAsFixed(2)})"),
                                    );
                                  }),
                                ],
                                onChanged: (selectedName) {
                                  setDialogState(() {
                                    if (selectedName != null) {
                                      final prod = listaProdutos.firstWhere(
                                        (p) => (p['name'] ?? p['nome'] ?? '') == selectedName,
                                        orElse: () => {},
                                      );
                                      final nomeEncontrado = prod['name'] ?? prod['nome'] ?? '';
                                      final precoEncontrado = (prod['price'] ?? prod['preco'] ?? prod['valor'] ?? 0.0) as double;
                                      
                                      item['descricao'] = nomeEncontrado;
                                      item['valorUnitario'] = precoEncontrado;
                                      descController.text = nomeEncontrado;
                                      precoController.text = precoEncontrado.toString();
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descController,
                                onChanged: (val) => item['descricao'] = val,
                                style: const TextStyle(color: AppColors.textLight),
                                decoration: const InputDecoration(labelText: 'Descrição / Extra', labelStyle: TextStyle(color: AppColors.textSub, fontSize: 12)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: TextEditingController(text: item['quantidade'].toString()),
                                      onChanged: (val) => item['quantidade'] = int.tryParse(val) ?? 1,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: AppColors.textLight),
                                      decoration: const InputDecoration(labelText: 'Qtd', labelStyle: TextStyle(color: AppColors.textSub, fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: precoController,
                                      onChanged: (val) => item['valorUnitario'] = double.tryParse(val.replaceAll(',', '.')) ?? 0.0,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: AppColors.textLight),
                                      decoration: const InputDecoration(labelText: 'Preço Unit. (R\$)', labelStyle: TextStyle(color: AppColors.textSub, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            itensOrcamento.add({'descricao': '', 'quantidade': 1, 'valorUnitario': 0.0});
                          });
                        },
                        icon: const Icon(Icons.add, color: AppColors.primaryBlue),
                        label: const Text('Adicionar Item / Extra', style: TextStyle(color: AppColors.primaryBlue)),
                      ),
                      const Divider(color: AppColors.borderDark),
                      const SizedBox(height: 8),
                      Text(
                        'Valor Total Calculado: R\$ ${calcularTotal().toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: entradaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppColors.textLight),
                        decoration: const InputDecoration(labelText: 'Valor de Entrada / Sinal (R\$)', labelStyle: TextStyle(color: AppColors.textSub)),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: formaPagamentoSelecionada,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: AppColors.textLight),
                        decoration: const InputDecoration(labelText: 'Forma de Pagamento', labelStyle: TextStyle(color: AppColors.textSub)),
                        items: ['Pix', 'Cartão de Crédito', 'Dinheiro', 'Boleto', 'A combinar'].map((fp) {
                          return DropdownMenuItem(value: fp, child: Text(fp));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => formaPagamentoSelecionada = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: statusSelecionado,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: AppColors.textLight),
                        decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: AppColors.textSub)),
                        items: ['Pendente', 'Aprovado', 'Concluído', 'Cancelado'].map((status) {
                          return DropdownMenuItem(value: status, child: Text(status));
                        }).toList(),
                        onChanged: (novoValor) {
                          if (novoValor != null) {
                            setDialogState(() => statusSelecionado = novoValor);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textSub)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  onPressed: () async {
                    final cliente = clienteController.text.trim();
                    final valorTotal = calcularTotal();
                    final entrada = double.tryParse(entradaController.text.replaceAll(',', '.')) ?? 0.0;

                    if (cliente.isNotEmpty && itensOrcamento.isNotEmpty && valorTotal > 0) {
                      final dataAtual = DateTime.now().toString().substring(0, 10);
                      final novoRegistro = {
                        'cliente': cliente,
                        'item': itensOrcamentoResumo(itensOrcamento),
                        'itens': itensOrcamento,
                        'valor': valorTotal,
                        'entrada': entrada,
                        'formaPagamento': formaPagamentoSelecionada,
                        'status': statusSelecionado,
                        'data': orcamentoExistente?['data'] ?? dataAtual,
                      };

                      setState(() {
                        if (index == null) {
                          BudgetsScreen.listaOrcamentosGlobais.add(novoRegistro);
                        } else {
                          BudgetsScreen.listaOrcamentosGlobais[index] = novoRegistro;
                        }
                      });

                      await StorageService.salvarBudgets();

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Orçamento salvo com sucesso!')),
                      );
                    }
                  },
                  child: const Text('Salvar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String itensOrcamentoResumo(List<Map<String, dynamic>> itens) {
    if (itens.isEmpty) return 'Orçamento Geral';
    return itens.map((i) => "${i['quantidade']}x ${i['descricao']}").join(', ');
  }

  void _deletarOrcamento(int index) async {
    setState(() {
      BudgetsScreen.listaOrcamentosGlobais.removeAt(index);
    });
    await StorageService.salvarBudgets();
  }

  Color _obterCorStatus(String status) {
    switch (status) {
      case 'Aprovado':
        return AppColors.successGreen;
      case 'Concluído':
        return AppColors.primaryBlue;
      case 'Cancelado':
        return AppColors.errorRed;
      default:
        return AppColors.warningOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Orçamentos', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textLight),
            tooltip: 'Atualizar',
            onPressed: () {
              _carregarDados();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lista atualizada!'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: BudgetsScreen.listaOrcamentosGlobais.isEmpty
          ? const Center(
              child: Text('Nenhum orçamento cadastrado.', style: TextStyle(color: AppColors.textSub)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: BudgetsScreen.listaOrcamentosGlobais.length,
              itemBuilder: (context, index) {
                final orc = BudgetsScreen.listaOrcamentosGlobais[index];
                final corStatus = _obterCorStatus(orc['status']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(orc['cliente'], style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('Itens: ${orc['item']}', style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('R\$ ${(orc['valor'] as num).toStringAsFixed(2)} • ${orc['formaPagamento'] ?? 'Pix'}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: corStatus.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(orc['status'] ?? 'Pendente', style: TextStyle(color: corStatus, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.warningOrange),
                          color: AppColors.surfaceDark,
                          onSelected: (value) async {
                            if (value == 'orcamento') {
                              final pdfBytes = await PdfService.gerarPdfOrcamento(orcamento: orc);
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfPreviewScreen(
                                    pdfBytes: pdfBytes,
                                    nomeArquivo: 'Orcamento_${orc['cliente']}.pdf',
                                    titulo: 'Pré-visualização do Orçamento',
                                  ),
                                ),
                              );
                            } else if (value == 'recibo') {
                              final pdfBytes = await PdfService.gerarPdfRecibo(orcamento: orc);
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfPreviewScreen(
                                    pdfBytes: pdfBytes,
                                    nomeArquivo: 'Recibo_${orc['cliente']}.pdf',
                                    titulo: 'Pré-visualização do Recibo',
                                  ),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'orcamento',
                              child: Text('Gerar Orçamento (PDF)', style: TextStyle(color: AppColors.textLight)),
                            ),
                            const PopupMenuItem(
                              value: 'recibo',
                              child: Text('Gerar Recibo (PDF)', style: TextStyle(color: AppColors.textLight)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppColors.textSub, size: 20),
                          onPressed: () => _adicionarOuEditarOrcamento(orcamentoExistente: orc, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                          onPressed: () => _deletarOrcamento(index),
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
        onPressed: () => _adicionarOuEditarOrcamento(),
        child: const Icon(Icons.add),
      ),
    );
  }
}