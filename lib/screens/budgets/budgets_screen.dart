import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/empresa_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/subscription_service.dart';
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
    await EmpresaService.carregarEmpresa();
    if (mounted) setState(() {});
  }

  void _abrirTelaFormularioOrcamento({Map<String, dynamic>? orcamentoExistente, int? index}) async {
    await StorageService.carregarTudo();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioOrcamentoScreen(
          orcamentoExistente: orcamentoExistente,
          index: index,
          onSalvo: () => _carregarDados(),
        ),
      ),
    );
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
                const SnackBar(content: Text('Lista atualizada!'), backgroundColor: AppColors.surfaceDark, duration: Duration(seconds: 1)),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(orc['cliente'], style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('Itens: ${orc['item']}', style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('R\$ ${(orc['valor'] as num).toStringAsFixed(2)} • ${orc['formaPagamento'] ?? 'Pix'}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
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
                            await StorageService.carregarTudo();
                            await EmpresaService.carregarEmpresa();

                            // Trava de segurança para o Recibo após o fim do teste gratuito
                            bool acessoGeral = await SubscriptionService.isAccessGranted();
                            if (value == 'recibo' && !acessoGeral) {
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.surfaceDark,
                                  title: const Text('Recurso da Versão Pro', style: TextStyle(color: AppColors.textLight)),
                                  content: const Text(
                                    'A emissão de recibos está disponível apenas na versão completa do aplicativo após o período de teste de 7 dias.',
                                    style: TextStyle(color: AppColors.textSub),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Entendi', style: TextStyle(color: AppColors.primaryBlue)),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            final dadosEmpresaMap = {
                              'nome': EmpresaService.dadosEmpresa['nome'] ?? '',
                              'cnpj': EmpresaService.dadosEmpresa['cnpj'] ?? '',
                              'contato': EmpresaService.dadosEmpresa['contato'] ?? '',
                              'logoBytes': StorageService.logoCacheGlobal,
                            };

                            if (value == 'orcamento') {
                              final pdfBytes = await PdfService.gerarPdfOrcamento(
                                orcamento: orc,
                                dadosEmpresa: dadosEmpresaMap,
                              );
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
                              final pdfBytes = await PdfService.gerarPdfRecibo(
                                orcamento: orc,
                                dadosEmpresa: dadosEmpresaMap,
                              );
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
                          onPressed: () => _abrirTelaFormularioOrcamento(orcamentoExistente: orc, index: index),
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
        onPressed: () => _abrirTelaFormularioOrcamento(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// TELA CHEIA SEPARADA PARA ORÇAMENTO (Elimina travamentos do teclado)
class FormularioOrcamentoScreen extends StatefulWidget {
  final Map<String, dynamic>? orcamentoExistente;
  final int? index;
  final VoidCallback onSalvo;

  const FormularioOrcamentoScreen({super.key, this.orcamentoExistente, this.index, required this.onSalvo});

  @override
  State<FormularioOrcamentoScreen> createState() => _FormularioOrcamentoScreenState();
}

class _FormularioOrcamentoScreenState extends State<FormularioOrcamentoScreen> {
  late final TextEditingController clienteController;
  late final TextEditingController entradaController;
  
  List<Map<String, dynamic>> itensOrcamento = [];
  List<TextEditingController> descControllers = [];
  List<TextEditingController> precoControllers = [];
  List<TextEditingController> qtdControllers = [];

  String statusSelecionado = 'Pendente';
  String formaPagamentoSelecionada = 'Pix';

  @override
  void initState() {
    super.initState();
    clienteController = TextEditingController(text: widget.orcamentoExistente?['cliente'] ?? '');
    entradaController = TextEditingController(text: widget.orcamentoExistente != null ? widget.orcamentoExistente!['entrada'].toString() : '0.0');

    statusSelecionado = widget.orcamentoExistente?['status'] ?? 'Pendente';
    formaPagamentoSelecionada = widget.orcamentoExistente?['formaPagamento'] ?? 'Pix';

    if (widget.orcamentoExistente != null && widget.orcamentoExistente!['itens'] != null) {
      itensOrcamento = List<Map<String, dynamic>>.from(
        (widget.orcamentoExistente!['itens'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } else if (widget.orcamentoExistente != null && widget.orcamentoExistente!['item'] != null) {
      itensOrcamento.add({
        'descricao': widget.orcamentoExistente!['item'],
        'quantidade': 1,
        'valorUnitario': widget.orcamentoExistente!['valor'] ?? 0.0,
      });
    } else {
      itensOrcamento.add({'descricao': '', 'quantidade': 1, 'valorUnitario': 0.0});
    }

    descControllers = itensOrcamento.map((item) => TextEditingController(text: item['descricao']?.toString() ?? '')).toList();
    precoControllers = itensOrcamento.map((item) => TextEditingController(text: item['valorUnitario']?.toString() ?? '0.0')).toList();
    qtdControllers = itensOrcamento.map((item) => TextEditingController(text: item['quantidade']?.toString() ?? '1')).toList();
  }

  @override
  void dispose() {
    clienteController.dispose();
    entradaController.dispose();
    for (var c in descControllers) {
      c.dispose();
    }
    for (var c in precoControllers) {
      c.dispose();
    }
    for (var c in qtdControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double calcularTotal() {
    double total = 0;
    for (int i = 0; i < itensOrcamento.length; i++) {
      double qtd = double.tryParse(qtdControllers[i].text) ?? 1.0;
      double val = double.tryParse(precoControllers[i].text.replaceAll(',', '.')) ?? 0.0;
      total += qtd * val;
    }
    return total;
  }

  String itensOrcamentoResumo(List<Map<String, dynamic>> itens) {
    if (itens.isEmpty) return 'Orçamento Geral';
    return itens.map((i) => "${i['quantidade']}x ${i['descricao']}").join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> listaProdutos = [
      ...StorageService.produtosCacheGlobal,
      ...ProductsServicesScreen.listaProdutosGlobais,
    ].fold<Map<String, Map<String, dynamic>>>({}, (map, item) {
      final nome = item['name'] ?? item['nome'] ?? '';
      if (nome.isNotEmpty) map[nome] = item;
      return map;
    }).values.toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(widget.orcamentoExistente == null ? 'Novo Orçamento' : 'Editar Orçamento', style: const TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.surfaceDark,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: clienteController,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(labelText: 'Nome do Cliente', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('Itens / Produtos / Serviços', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            ...itensOrcamento.asMap().entries.map((entry) {
              int idx = entry.key;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Item ${idx + 1}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                        ),
                        if (itensOrcamento.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.errorRed, size: 18),
                            onPressed: () {
                              setState(() {
                                itensOrcamento.removeAt(idx);
                                descControllers.removeAt(idx);
                                precoControllers.removeAt(idx);
                                qtdControllers.removeAt(idx);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: listaProdutos.any((p) => (p['name'] ?? p['nome'] ?? '') == descControllers[idx].text) ? descControllers[idx].text : null,
                      dropdownColor: AppColors.surfaceDark,
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(
                        labelText: 'Puxar do Cadastro (Opcional)',
                        labelStyle: TextStyle(color: AppColors.textSub, fontSize: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Digitação Manual', style: TextStyle(color: AppColors.textSub)),
                        ),
                        ...listaProdutos.map((prod) {
                          final nomeProd = prod['name'] ?? prod['nome'] ?? '';
                          final precoProd = (prod['price'] ?? prod['preco'] ?? prod['valor'] ?? 0.0) as num;
                          return DropdownMenuItem<String>(
                            value: nomeProd.toString(),
                            child: Text("$nomeProd (R\$ ${precoProd.toStringAsFixed(2)})", overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (selectedName) {
                        setState(() {
                          if (selectedName != null) {
                            final prod = listaProdutos.firstWhere(
                              (p) => (p['name'] ?? p['nome'] ?? '') == selectedName,
                              orElse: () => {},
                            );
                            final nomeEncontrado = prod['name'] ?? prod['nome'] ?? '';
                            final precoEncontrado = (prod['price'] ?? prod['preco'] ?? prod['valor'] ?? 0.0) as double;
                            
                            descControllers[idx].text = nomeEncontrado;
                            precoControllers[idx].text = precoEncontrado.toStringAsFixed(2);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descControllers[idx],
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(labelText: 'Descrição do Item', labelStyle: TextStyle(color: AppColors.textSub, fontSize: 12), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: qtdControllers[idx],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textLight),
                            decoration: const InputDecoration(labelText: 'Qtd', labelStyle: TextStyle(color: AppColors.textSub, fontSize: 12), border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: precoControllers[idx],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppColors.textLight),
                            decoration: const InputDecoration(labelText: 'Preço Unit. (R\$)', labelStyle: TextStyle(color: AppColors.textSub, fontSize: 12), border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primaryBlue), minimumSize: const Size(double.infinity, 45)),
              onPressed: () {
                setState(() {
                  itensOrcamento.add({'descricao': '', 'quantidade': 1, 'valorUnitario': 0.0});
                  descControllers.add(TextEditingController());
                  precoControllers.add(TextEditingController(text: '0.0'));
                  qtdControllers.add(TextEditingController(text: '1'));
                });
              },
              icon: const Icon(Icons.add, color: AppColors.primaryBlue),
              label: const Text('Adicionar Outro Item / Extra', style: TextStyle(color: AppColors.primaryBlue)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderDark)),
              child: Text(
                'Valor Total: R\$ ${calcularTotal().toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: entradaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(labelText: 'Valor de Entrada / Sinal (R\$)', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: formaPagamentoSelecionada,
              dropdownColor: AppColors.surfaceDark,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(labelText: 'Forma de Pagamento', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
              items: ['Pix', 'Cartão de Crédito', 'Dinheiro', 'Boleto', 'A combinar'].map((fp) {
                return DropdownMenuItem(value: fp, child: Text(fp));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => formaPagamentoSelecionada = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: statusSelecionado,
              dropdownColor: AppColors.surfaceDark,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(labelText: 'Status do Orçamento', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
              items: ['Pendente', 'Aprovado', 'Concluído', 'Cancelado'].map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (novoValor) {
                if (novoValor != null) setState(() => statusSelecionado = novoValor);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                final cliente = clienteController.text.trim();
                final valorTotal = calcularTotal();
                final entrada = double.tryParse(entradaController.text.replaceAll(',', '.')) ?? 0.0;

                List<Map<String, dynamic>> itensFinais = [];
                for (int i = 0; i < itensOrcamento.length; i++) {
                  itensFinais.add({
                    'descricao': descControllers[i].text.trim(),
                    'quantidade': int.tryParse(qtdControllers[i].text) ?? 1,
                    'valorUnitario': double.tryParse(precoControllers[i].text.replaceAll(',', '.')) ?? 0.0,
                  });
                }

                if (cliente.isNotEmpty && itensFinais.isNotEmpty && valorTotal > 0) {
                  final dataAtual = DateTime.now().toString().substring(0, 10);
                  final numeroSeq = '#${(BudgetsScreen.listaOrcamentosGlobais.length + 1).toString().padLeft(3, '0')}';

                  final novoRegistro = {
                    'numero': widget.orcamentoExistente?['numero'] ?? numeroSeq,
                    'cliente': cliente,
                    'item': itensOrcamentoResumo(itensFinais),
                    'itens': itensFinais,
                    'valor': valorTotal,
                    'entrada': entrada,
                    'formaPagamento': formaPagamentoSelecionada,
                    'status': statusSelecionado,
                    'data': widget.orcamentoExistente?['data'] ?? dataAtual,
                  };

                  if (widget.index == null) {
                    BudgetsScreen.listaOrcamentosGlobais.add(novoRegistro);
                  } else {
                    BudgetsScreen.listaOrcamentosGlobais[widget.index!] = novoRegistro;
                  }

                  await StorageService.salvarBudgets();
                  widget.onSalvo();

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Orçamento salvo com sucesso!'), backgroundColor: AppColors.surfaceDark),
                  );
                }
              },
              child: const Text('Salvar Orçamento', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}