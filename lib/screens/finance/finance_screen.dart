import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  static final List<Map<String, dynamic>> listaFinanceiraGlobal = [];

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  void _abrirModalLancamento([Map<String, dynamic>? itemExistente, int? index]) {
    final clienteController = TextEditingController(text: itemExistente?['cliente'] ?? '');
    final descricaoController = TextEditingController(text: itemExistente?['descricao'] ?? '');
    final valorController = TextEditingController(text: itemExistente != null ? itemExistente['valor'].toString() : '');
    String tipoAtual = itemExistente?['tipo'] ?? 'Receita';
    String statusAtual = itemExistente?['status'] ?? 'Pendente';

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
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryBlue),
                      const SizedBox(width: 10),
                      Text(itemExistente == null ? 'Novo Lançamento' : 'Editar Lançamento', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.surfaceDark,
                    style: const TextStyle(color: AppColors.textLight),
                    value: tipoAtual,
                    decoration: const InputDecoration(labelText: 'Tipo de Lançamento', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Receita', child: Text('Receita (Entrada)', style: TextStyle(color: AppColors.textLight))),
                      DropdownMenuItem(value: 'Despesa', child: Text('Despesa (Gasto)', style: TextStyle(color: AppColors.textLight))),
                    ],
                    onChanged: (val) => setModalState(() => tipoAtual = val!),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: clienteController,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: const InputDecoration(labelText: 'Cliente / Fornecedor', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: descricaoController,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: const InputDecoration(labelText: 'Descrição do Serviço / Gasto', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: valorController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: const InputDecoration(labelText: 'Valor (R\$)', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.surfaceDark,
                    style: const TextStyle(color: AppColors.textLight),
                    value: statusAtual,
                    decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Pendente', child: Text('Pendente', style: TextStyle(color: AppColors.textLight))),
                      DropdownMenuItem(value: 'Recebido', child: Text('Pago / Recebido', style: TextStyle(color: AppColors.textLight))),
                    ],
                    onChanged: (val) => setModalState(() => statusAtual = val!),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final valorDouble = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;
                      if (clienteController.text.isNotEmpty && valorDouble > 0) {
                        setState(() {
                          final novoRegistro = {
                            'cliente': clienteController.text,
                            'descricao': descricaoController.text.isEmpty ? 'Geral' : descricaoController.text,
                            'valor': valorDouble,
                            'tipo': tipoAtual,
                            'status': statusAtual,
                          };

                          if (itemExistente == null) {
                            FinanceScreen.listaFinanceiraGlobal.add(novoRegistro);
                          } else {
                            FinanceScreen.listaFinanceiraGlobal[index!] = novoRegistro;
                          }
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Salvar Lançamento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    for (var t in FinanceScreen.listaFinanceiraGlobal) {
      if (t['tipo'] == null) {
        t['tipo'] = 'Receita';
      }
    }

    final totalAReceber = FinanceScreen.listaFinanceiraGlobal
        .where((t) => t['tipo'] == 'Receita' && t['status'] == 'Pendente')
        .fold(0.0, (s, i) => s + (i['valor'] as double));

    final totalRecebido = FinanceScreen.listaFinanceiraGlobal
        .where((t) => t['tipo'] == 'Receita' && t['status'] == 'Recebido')
        .fold(0.0, (s, i) => s + (i['valor'] as double));

    final totalDespesas = FinanceScreen.listaFinanceiraGlobal
        .where((t) => t['tipo'] == 'Despesa')
        .fold(0.0, (s, i) => s + (i['valor'] as double));

    final saldoEmCaixa = totalRecebido - totalDespesas;
    final corSaldo = saldoEmCaixa >= 0 ? AppColors.primaryBlue : AppColors.errorRed;

    return Scaffold(
      appBar: AppBar(title: const Text('Controle Financeiro')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grid de 4 Cards Compactos e Elegantes Otimizados para Celular
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.6, // Proporção mais baixa para ocupar pouco espaço vertical
              children: [
                _cardResumo('Saldo em Caixa', 'R\$ ${saldoEmCaixa.toStringAsFixed(2)}', corSaldo, Icons.account_balance_wallet_rounded, isDestaque: true),
                _cardResumo('Recebido', 'R\$ ${totalRecebido.toStringAsFixed(2)}', AppColors.successGreen, Icons.check_circle_rounded),
                _cardResumo('A Receber', 'R\$ ${totalAReceber.toStringAsFixed(2)}', AppColors.warningOrange, Icons.schedule_rounded),
                _cardResumo('Despesas', 'R\$ ${totalDespesas.toStringAsFixed(2)}', AppColors.errorRed, Icons.trending_down_rounded),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Histórico de Lançamentos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSub)),
            const SizedBox(height: 8),

            Expanded(
              child: FinanceScreen.listaFinanceiraGlobal.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.account_balance_wallet_outlined, size: 40, color: AppColors.textSub),
                          SizedBox(height: 8),
                          Text('Nenhum lançamento financeiro.', style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Aprove orçamentos ou adicione gastos no botão +.', style: TextStyle(color: AppColors.textMedium, fontSize: 11)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: FinanceScreen.listaFinanceiraGlobal.length,
                      itemBuilder: (context, index) {
                        final item = FinanceScreen.listaFinanceiraGlobal[index];
                        bool isRecebido = item['status'] == 'Recebido';
                        bool isDespesa = item['tipo'] == 'Despesa';

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: isDespesa
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: AppColors.errorRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                    child: const Icon(Icons.remove, color: AppColors.errorRed, size: 16),
                                  )
                                : Checkbox(
                                    activeColor: AppColors.successGreen,
                                    value: isRecebido,
                                    onChanged: (bool? valor) {
                                      setState(() {
                                        item['status'] = (valor == true) ? 'Recebido' : 'Pendente';
                                      });
                                    },
                                  ),
                            title: Text(item['cliente'], style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('${item['descricao']} • R\$ ${(item['valor'] as double).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isDespesa ? AppColors.errorRed : (isRecebido ? AppColors.successGreen : AppColors.warningOrange)).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isDespesa ? 'Despesa' : item['status'],
                                    style: TextStyle(
                                      color: isDespesa ? AppColors.errorRed : (isRecebido ? AppColors.successGreen : AppColors.warningOrange),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSub),
                                  onPressed: () => _abrirModalLancamento(item, index),
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _abrirModalLancamento(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _cardResumo(String titulo, String valor, Color cor, IconData icone, {bool isDestaque = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDestaque ? AppColors.primaryBlue.withValues(alpha: 0.08) : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDestaque ? AppColors.primaryBlue.withValues(alpha: 0.4) : AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 13),
              const SizedBox(width: 4),
              Expanded(child: Text(titulo, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDestaque ? AppColors.textLight : AppColors.textSub), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 2),
          Text(valor, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cor), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}