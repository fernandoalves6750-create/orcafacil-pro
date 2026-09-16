import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../budgets/budgets_screen.dart';
import '../finance/finance_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  static List<Map<String, dynamic>> agendaGlobal = [];

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _dataSelecionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await StorageService.carregarTudo();
    if (mounted) setState(() {});
  }

  String _formatarDataParaStr(DateTime data) {
    return "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";
  }

  String _formatarDataBr(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";
  }

  void _adicionarOuEditarCompromisso({Map<String, dynamic>? compromissoExistente, int? index}) {
    final titleController = TextEditingController(text: compromissoExistente?['title'] ?? '');
    final horaController = TextEditingController(text: compromissoExistente?['hora'] ?? '09:00');
    final obsController = TextEditingController(text: compromissoExistente?['observacoes'] ?? '');
    
    String? orcamentoVinculadoCliente = compromissoExistente?['cliente'];
    double? valorVinculado = compromissoExistente?['valor'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Text(
                compromissoExistente == null ? 'Novo Agendamento' : 'Editar Agendamento',
                style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(
                        labelText: 'Título do Compromisso / Serviço',
                        labelStyle: TextStyle(color: AppColors.textSub),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: horaController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(
                        labelText: 'Horário (HH:MM)',
                        labelStyle: TextStyle(color: AppColors.textSub),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vincular Orçamento (Aprova e gera "A Receber")',
                      style: TextStyle(color: AppColors.textSub, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: orcamentoVinculadoCliente,
                      dropdownColor: AppColors.surfaceDark,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(
                        labelText: 'Selecionar Cliente / Orçamento',
                        labelStyle: TextStyle(color: AppColors.textSub),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Nenhum (Avulso)', style: TextStyle(color: AppColors.textSub)),
                        ),
                        ...BudgetsScreen.listaOrcamentosGlobais.map((orc) {
                          String label = "${orc['cliente']} - R\$ ${(orc['valor'] as num).toStringAsFixed(2)}";
                          return DropdownMenuItem<String>(
                            value: orc['cliente'],
                            child: Text(label, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          orcamentoVinculadoCliente = v;
                          if (v != null) {
                            final orc = BudgetsScreen.listaOrcamentosGlobais.firstWhere(
                              (o) => o['cliente'] == v,
                              orElse: () => {},
                            );
                            if (orc.isNotEmpty) {
                              valorVinculado = (orc['valor'] as num).toDouble();
                              if (titleController.text.isEmpty) {
                                titleController.text = 'Serviço para $v';
                              }
                            }
                          } else {
                            valorVinculado = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: obsController,
                      style: const TextStyle(color: AppColors.textLight),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        labelStyle: TextStyle(color: AppColors.textSub),
                      ),
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
                    final title = titleController.text.trim();
                    final hora = horaController.text.trim();

                    if (title.isNotEmpty && hora.isNotEmpty) {
                      // 1. Atualiza status do orçamento para Aprovado
                      if (compromissoExistente != null && compromissoExistente['cliente'] != null) {
                        final antigoCliente = compromissoExistente['cliente'];
                        if (antigoCliente != orcamentoVinculadoCliente) {
                          for (var o in BudgetsScreen.listaOrcamentosGlobais) {
                            if (o['cliente'] == antigoCliente) {
                              o['status'] = 'Pendente';
                            }
                          }
                        }
                      }

                      if (orcamentoVinculadoCliente != null) {
                        for (var o in BudgetsScreen.listaOrcamentosGlobais) {
                          if (o['cliente'] == orcamentoVinculadoCliente) {
                            o['status'] = 'Aprovado';
                          }
                        }
                      }

                      final dataStr = compromissoExistente?['data'] ?? _formatarDataParaStr(_dataSelecionada);

                      final novoCompromisso = {
                        'title': title,
                        'data': dataStr,
                        'hora': hora,
                        'cliente': orcamentoVinculadoCliente ?? '',
                        'valor': valorVinculado ?? 0.0,
                        'observacoes': obsController.text.trim(),
                      };

                      // 2. Lança automaticamente no Financeiro como "Pendente" (A Receber) se houver valor
                      if (valorVinculado != null && valorVinculado! > 0) {
                        final registroFinanceiro = {
                          'descricao': 'Serviço: $title (${orcamentoVinculadoCliente ?? 'Agenda'})',
                          'valor': valorVinculado!,
                          'tipo': 'Receita',
                          'status': 'Pendente',
                        };

                        if (compromissoExistente == null) {
                          FinanceScreen.listaFinanceiraGlobal.add(registroFinanceiro);
                        } else {
                          // Tenta achar o registro anterior no financeiro para atualizar
                          int finIndex = FinanceScreen.listaFinanceiraGlobal.indexWhere(
                            (f) => f['descricao'].toString().contains(compromissoExistente['title']),
                          );
                          if (finIndex != -1) {
                            FinanceScreen.listaFinanceiraGlobal[finIndex] = registroFinanceiro;
                          } else {
                            FinanceScreen.listaFinanceiraGlobal.add(registroFinanceiro);
                          }
                        }
                        await StorageService.salvarFinance();
                      }

                      setState(() {
                        if (index == null) {
                          AppointmentsScreen.agendaGlobal.add(novoCompromisso);
                        } else {
                          AppointmentsScreen.agendaGlobal[index] = novoCompromisso;
                        }
                      });

                      await StorageService.salvarAppointments();
                      await StorageService.salvarBudgets();

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Compromisso agendado e lançado no Financeiro!')),
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

  void _deletarCompromisso(int indexGlobal) async {
    final comp = AppointmentsScreen.agendaGlobal[indexGlobal];
    final clienteVinculado = comp['cliente'];
    final tituloComp = comp['title'];

    // Retorna orçamento para Pendente se houver
    if (clienteVinculado != null && clienteVinculado.toString().isNotEmpty) {
      for (var o in BudgetsScreen.listaOrcamentosGlobais) {
        if (o['cliente'] == clienteVinculado) {
          o['status'] = 'Pendente';
        }
      }
      await StorageService.salvarBudgets();
    }

    // Remove do financeiro correspondente
    FinanceScreen.listaFinanceiraGlobal.removeWhere(
      (f) => f['descricao'].toString().contains(tituloComp),
    );
    await StorageService.salvarFinance();

    setState(() {
      AppointmentsScreen.agendaGlobal.removeAt(indexGlobal);
    });

    await StorageService.salvarAppointments();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compromisso excluído e removido do Financeiro.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));
    final diasDaSemana = List.generate(7, (index) => inicioSemana.add(Duration(days: index)));

    final dataSelecionadaStr = _formatarDataParaStr(_dataSelecionada);
    final compromissosDoDia = AppointmentsScreen.agendaGlobal.where((item) {
      return item['data'] == dataSelecionadaStr;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Agenda', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textLight),
            tooltip: 'Atualizar',
            onPressed: () {
              _carregarDados();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agenda atualizada!'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.surfaceDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: diasDaSemana.map((dia) {
                bool selecionado = _formatarDataParaStr(dia) == dataSelecionadaStr;
                String nomeDia = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][dia.weekday - 1];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _dataSelecionada = dia;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selecionado ? AppColors.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          nomeDia,
                          style: TextStyle(
                            color: selecionado ? Colors.white : AppColors.textSub,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dia.day.toString(),
                          style: TextStyle(
                            color: selecionado ? Colors.white : AppColors.textLight,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Compromissos de ${_formatarDataBr(_dataSelecionada)}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: compromissosDoDia.isEmpty
                ? const Center(
                    child: Text('Nenhum compromisso agendado para esta data.', style: TextStyle(color: AppColors.textSub)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: compromissosDoDia.length,
                    itemBuilder: (context, index) {
                      final comp = compromissosDoDia[index];
                      final indiceGlobal = AppointmentsScreen.agendaGlobal.indexOf(comp);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withAlpha(38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              comp['hora'] ?? '',
                              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          title: Text(
                            comp['title'] ?? '',
                            style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((comp['cliente'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Cliente: ${comp['cliente']}', style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
                              ],
                              if (comp['valor'] != null && (comp['valor'] as num) > 0) ...[
                                const SizedBox(height: 2),
                                Text('Valor: R\$ ${(comp['valor'] as num).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.successGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: AppColors.textSub, size: 20),
                                onPressed: () => _adicionarOuEditarCompromisso(compromissoExistente: comp, index: indiceGlobal),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                                onPressed: () => _deletarCompromisso(indiceGlobal),
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
        onPressed: () => _adicionarOuEditarCompromisso(),
        child: const Icon(Icons.add),
      ),
    );
  }
}