import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../budgets/budgets_screen.dart';
import '../appointments/appointments_screen.dart';
import '../finance/finance_screen.dart';
import '../settings/business_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orcamentosPendentes = BudgetsScreen.listaOrcamentosGlobais.where((b) => b['status'] == 'Pendente').toList();
    final orcamentosAprovados = BudgetsScreen.listaOrcamentosGlobais.where((b) => b['status'] == 'Aprovado').toList();
    final agendaHoje = AppointmentsScreen.agendaGlobal;

    // Cálculos financeiros idênticos ao Financeiro
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
      appBar: AppBar(
        title: Text(BusinessScreen.empresaNome),
        actions: [
          IconButton(
            icon: const Icon(Icons.business_rounded, color: AppColors.textLight),
            tooltip: 'Configurar Empresa, Logo e Assinatura',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BusinessScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bom dia, Fernando!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            const SizedBox(height: 14),

            // 1. Grid de 4 Cards Financeiros Compactos
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.6,
              children: [
                _cardResumo('Saldo em Caixa', 'R\$ ${saldoEmCaixa.toStringAsFixed(2)}', corSaldo, Icons.account_balance_wallet_rounded, isDestaque: true),
                _cardResumo('Recebido', 'R\$ ${totalRecebido.toStringAsFixed(2)}', AppColors.successGreen, Icons.check_circle_rounded),
                _cardResumo('A Receber', 'R\$ ${totalAReceber.toStringAsFixed(2)}', AppColors.warningOrange, Icons.schedule_rounded),
                _cardResumo('Despesas', 'R\$ ${totalDespesas.toStringAsFixed(2)}', AppColors.errorRed, Icons.trending_down_rounded),
              ],
            ),

            const SizedBox(height: 22),
            const Text('Agenda do Dia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSub)),
            const SizedBox(height: 8),
            agendaHoje.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: const Center(
                      child: Text('Nenhum compromisso agendado para hoje.', style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                    ),
                  )
                : Column(
                    children: agendaHoje.map((ag) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.schedule, color: AppColors.primaryBlue),
                          title: Text(ag['title']!, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('Horário: ${ag['hora']}', style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 22),
            const Text('Orçamentos Pendentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSub)),
            const SizedBox(height: 8),
            orcamentosPendentes.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: const Center(
                      child: Text('Nenhum orçamento pendente no momento.', style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                    ),
                  )
                : Column(
                    children: orcamentosPendentes.map((orc) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.description, color: AppColors.warningOrange),
                          title: Text(orc['cliente'], style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${orc['item']} • R\$ ${(orc['valor'] as double).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
                          trailing: const Text('Pendente', style: TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
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