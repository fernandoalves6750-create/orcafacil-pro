import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  static List<Map<String, dynamic>> listaFinanceiraGlobal = [];

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await StorageService.carregarTudo();
    if (mounted) setState(() {});
  }

  void _alternarStatus(int index) async {
    setState(() {
      String statusAtual = FinanceScreen.listaFinanceiraGlobal[index]['status'] ?? 'Recebido';
      if (statusAtual == 'Recebido') {
        FinanceScreen.listaFinanceiraGlobal[index]['status'] = 'Pendente';
      } else if (statusAtual == 'Pendente') {
        FinanceScreen.listaFinanceiraGlobal[index]['status'] = 'Recebido';
      }
    });
    await StorageService.salvarFinance();
  }

  void _adicionarOuEditarTransacao({Map<String, dynamic>? transacaoExistente, int? index}) {
    final descricaoController = TextEditingController(text: transacaoExistente?['descricao'] ?? '');
    final valorController = TextEditingController(text: transacaoExistente != null ? transacaoExistente['valor'].toString() : '');
    String tipoSelecionado = transacaoExistente?['tipo'] ?? 'Receita';
    String statusSelecionado = transacaoExistente?['status'] ?? 'Recebido';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Text(
                transacaoExistente == null ? 'Nova Transação' : 'Editar Transação',
                style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descricaoController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(labelText: 'Descrição', labelStyle: TextStyle(color: AppColors.textSub)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(labelText: 'Valor (R\$)', labelStyle: TextStyle(color: AppColors.textSub)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipoSelecionado,
                      dropdownColor: AppColors.surfaceDark,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(labelText: 'Tipo', labelStyle: TextStyle(color: AppColors.textSub)),
                      items: ['Receita', 'Despesa'].map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => tipoSelecionado = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: statusSelecionado,
                      dropdownColor: AppColors.surfaceDark,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: AppColors.textSub)),
                      items: ['Recebido', 'Pendente', 'Pago'].map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => statusSelecionado = v);
                        }
                      },
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  onPressed: () async {
                    final descricao = descricaoController.text.trim();
                    final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;

                    if (descricao.isNotEmpty && valor > 0) {
                      final novoRegistro = {
                        'descricao': descricao,
                        'valor': valor,
                        'tipo': tipoSelecionado,
                        'status': statusSelecionado,
                      };

                      setState(() {
                        if (index == null) {
                          FinanceScreen.listaFinanceiraGlobal.add(novoRegistro);
                        } else {
                          FinanceScreen.listaFinanceiraGlobal[index] = novoRegistro;
                        }
                      });

                      await StorageService.salvarFinance();

                      if (!context.mounted) return;
                      Navigator.pop(context);
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

  void _deletarTransacao(int index) async {
    setState(() {
      FinanceScreen.listaFinanceiraGlobal.removeAt(index);
    });
    await StorageService.salvarFinance();
  }

  @override
  Widget build(BuildContext context) {
    double totalRecebido = 0;
    double totalAReceber = 0;
    double totalDespesas = 0;

    for (var tr in FinanceScreen.listaFinanceiraGlobal) {
      double val = (tr['valor'] as num).toDouble();
      String tipo = tr['tipo'] ?? '';
      String status = tr['status'] ?? '';

      if (tipo == 'Receita') {
        if (status == 'Recebido') {
          totalRecebido += val;
        } else if (status == 'Pendente') {
          totalAReceber += val;
        }
      } else if (tipo == 'Despesa') {
        totalDespesas += val;
      }
    }

    double saldoEmCaixa = totalRecebido - totalDespesas;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Controle Financeiro', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textLight),
            tooltip: 'Atualizar financeiro',
            onPressed: () {
              _carregarDados();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dados financeiros atualizados!'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCardResumo('Saldo em Caixa', saldoEmCaixa, AppColors.primaryBlue, Icons.account_balance_wallet_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCardResumo('Recebido', totalRecebido, AppColors.successGreen, Icons.check_circle_outline)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCardResumo('A Receber', totalAReceber, AppColors.warningOrange, Icons.access_time_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCardResumo('Despesas', totalDespesas, AppColors.errorRed, Icons.trending_down_rounded)),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Histórico de Lançamentos',
              style: TextStyle(color: AppColors.textSub, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FinanceScreen.listaFinanceiraGlobal.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.textMedium),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum lançamento financeiro.',
                          style: TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aprove orçamentos ou adicione gastos no botão +.',
                          style: TextStyle(color: AppColors.textSub, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: FinanceScreen.listaFinanceiraGlobal.length,
                    itemBuilder: (context, index) {
                      final tr = FinanceScreen.listaFinanceiraGlobal[index];
                      final isReceita = tr['tipo'] == 'Receita';
                      final status = tr['status'] ?? 'Recebido';
                      final isRecebido = status == 'Recebido';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          // Checkbox adicionado nas receitas para marcar como recebido instantaneamente
                          leading: isReceita
                              ? Checkbox(
                                  value: isRecebido,
                                  activeColor: AppColors.successGreen,
                                  onChanged: (bool? value) {
                                    _alternarStatus(index);
                                  },
                                )
                              : const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.trending_down_rounded, color: AppColors.errorRed),
                                ),
                          title: Text(tr['descricao'], style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${tr['tipo']} ($status) • R\$ ${(tr['valor'] as num).toStringAsFixed(2)}',
                            style: TextStyle(color: isRecebido ? AppColors.successGreen : (isReceita ? AppColors.warningOrange : AppColors.errorRed)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: AppColors.textSub, size: 20),
                                onPressed: () => _adicionarOuEditarTransacao(transacaoExistente: tr, index: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                                onPressed: () => _deletarTransacao(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _adicionarOuEditarTransacao(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCardResumo(String titulo, double valor, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: cor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}