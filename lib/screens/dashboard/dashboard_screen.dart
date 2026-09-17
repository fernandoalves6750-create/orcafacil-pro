import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/empresa_service.dart';
import '../budgets/budgets_screen.dart';
import '../appointments/appointments_screen.dart';
import '../finance/finance_screen.dart';
import '../settings/business_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Função para confirmar e executar o Logout
  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text(
            'Encerrar Sessão',
            style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Deseja realmente sair do OrçaFácil Pro?',
            style: TextStyle(color: AppColors.textSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSub)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Fecha o diálogo
                // Encerra a sessão e retorna para a tela de boas-vindas limpando o histórico
                Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orcamentosPendentes = BudgetsScreen.listaOrcamentosGlobais.where((b) => b['status'] == 'Pendente').toList();
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

    // Nome da empresa vindo do EmpresaService (com fallback caso esteja vazio)
    final nomeEmpresa = EmpresaService.dadosEmpresa['nome']?.isNotEmpty == true
        ? EmpresaService.dadosEmpresa['nome']
        : 'OrçaFácil Pro';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Text(
          nomeEmpresa,
          style: const TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Botão de Configurar Empresa
          IconButton(
            icon: const Icon(Icons.business_rounded, color: AppColors.primaryBlue),
            tooltip: 'Configurar Empresa, Logo e Assinatura',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BusinessScreen()),
              );
            },
          ),
          // Botão de Logout posicionado logo ao lado
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
            tooltip: 'Sair do Aplicativo',
            onPressed: () => _confirmarLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação profissional
            const Text(
              'Bom dia, Fernando!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),

            // 1. Grid de 4 Cards Financeiros Compactos e Elegantes
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              children: [
                _cardResumo('Saldo em Caixa', 'R\$ ${saldoEmCaixa.toStringAsFixed(2)}', corSaldo, Icons.account_balance_wallet_rounded, isDestaque: true),
                _cardResumo('Recebido', 'R\$ ${totalRecebido.toStringAsFixed(2)}', AppColors.successGreen, Icons.check_circle_rounded),
                _cardResumo('A Receber', 'R\$ ${totalAReceber.toStringAsFixed(2)}', AppColors.warningOrange, Icons.schedule_rounded),
                _cardResumo('Despesas', 'R\$ ${totalDespesas.toStringAsFixed(2)}', AppColors.errorRed, Icons.trending_down_rounded),
              ],
            ),

            const SizedBox(height: 24),
            
            // Seção: Agenda do Dia
            const Text(
              'Agenda do Dia',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 10),
            agendaHoje.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: const Center(
                      child: Text(
                        'Nenhum compromisso agendado para hoje.',
                        style: TextStyle(color: AppColors.textSub, fontSize: 13),
                      ),
                    ),
                  )
                : Column(
                    children: agendaHoje.map((ag) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.schedule, color: AppColors.primaryBlue, size: 20),
                          ),
                          title: Text(
                            ag['title']!,
                            style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Horário: ${ag['hora']}',
                            style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 24),
            
            // Seção: Orçamentos Pendentes
            const Text(
              'Orçamentos Pendentes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 10),
            orcamentosPendentes.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: const Center(
                      child: Text(
                        'Nenhum orçamento pendente no momento.',
                        style: TextStyle(color: AppColors.textSub, fontSize: 13),
                      ),
                    ),
                  )
                : Column(
                    children: orcamentosPendentes.map((orc) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warningOrange.withAlpha(38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description, color: AppColors.warningOrange, size: 20),
                          ),
                          title: Text(
                            orc['cliente'],
                            style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${orc['item']} • R\$ ${(orc['valor'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warningOrange.withAlpha(38),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pendente',
                              style: TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDestaque ? AppColors.primaryBlue.withAlpha(25) : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestaque ? AppColors.primaryBlue.withAlpha(128) : AppColors.borderDark,
          width: isDestaque ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDestaque ? AppColors.textLight : AppColors.textSub,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}