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
  DateTime _mesAtual = DateTime(DateTime.now().year, DateTime.now().month, 1);
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

  void _abrirTelaFormularioCompromisso({Map<String, dynamic>? compromissoExistente, int? index}) async {
    await StorageService.carregarTudo();
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioCompromissoScreen(
          compromissoExistente: compromissoExistente,
          index: index,
          dataInicialPadrao: _dataSelecionada,
          onSalvo: (novaData) {
            setState(() {
              _dataSelecionada = novaData;
              _mesAtual = DateTime(novaData.year, novaData.month, 1);
            });
            _carregarDados();
          },
        ),
      ),
    );
  }

  void _deletarCompromisso(int indexGlobal) async {
    final comp = AppointmentsScreen.agendaGlobal[indexGlobal];
    final clienteVinculado = comp['cliente'];
    final tituloComp = comp['title'];

    if (clienteVinculado != null && clienteVinculado.toString().isNotEmpty) {
      for (var o in BudgetsScreen.listaOrcamentosGlobais) {
        if (o['cliente'] == clienteVinculado) {
          o['status'] = 'Pendente';
        }
      }
      await StorageService.salvarBudgets();
    }

    FinanceScreen.listaFinanceiraGlobal.removeWhere(
      (f) => f['descricao'].toString().contains(tituloComp),
    );
    await StorageService.salvarFinance();

    setState(() {
      AppointmentsScreen.agendaGlobal.removeAt(indexGlobal);
    });

    await StorageService.salvarAppointments();
    await StorageService.salvarFinance();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compromisso excluído e orçamento retornado para Pendente.')),
    );
  }

  List<DateTime> _gerarDiasDoMes(DateTime mes) {
    final primeiroDiaMes = DateTime(mes.year, mes.month, 1);
    int diaSemanaInicio = primeiroDiaMes.weekday - 1;
    DateTime inicioCalendario = primeiroDiaMes.subtract(Duration(days: diaSemanaInicio));
    
    List<DateTime> dias = [];
    DateTime diaAtual = inicioCalendario;
    for (int i = 0; i < 42; i++) {
      dias.add(diaAtual);
      diaAtual = diaAtual.add(const Duration(days: 1));
    }
    return dias;
  }

  @override
  Widget build(BuildContext context) {
    final dataSelecionadaStr = _formatarDataParaStr(_dataSelecionada);
    final compromissosDoDia = AppointmentsScreen.agendaGlobal.where((item) {
      return item['data'] == dataSelecionadaStr;
    }).toList();

    final diasDoMes = _gerarDiasDoMes(_mesAtual);
    const nomesMeses = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Agenda Mensal', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${nomesMeses[_mesAtual.month - 1]} ${_mesAtual.year}',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppColors.textLight),
                      onPressed: () {
                        setState(() {
                          _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1, 1);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppColors.textLight),
                      onPressed: () {
                        setState(() {
                          _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1, 1);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.surfaceDark,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'].map((d) {
                return Text(d, style: const TextStyle(color: AppColors.textSub, fontWeight: FontWeight.bold, fontSize: 12));
              }).toList(),
            ),
          ),
          Container(
            color: AppColors.surfaceDark,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: diasDoMes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 40,
              ),
              itemBuilder: (context, index) {
                final dia = diasDoMes[index];
                final diaStr = _formatarDataParaStr(dia);
                bool isMesAtual = dia.month == _mesAtual.month;
                bool isSelecionado = _formatarDataParaStr(_dataSelecionada) == diaStr;
                bool temCompromisso = AppointmentsScreen.agendaGlobal.any((item) => item['data'] == diaStr);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _dataSelecionada = dia;
                      if (!isMesAtual) {
                        _mesAtual = DateTime(dia.year, dia.month, 1);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelecionado
                          ? AppColors.primaryBlue
                          : (temCompromisso ? AppColors.primaryBlue.withAlpha(50) : Colors.transparent),
                      shape: BoxShape.circle,
                      border: temCompromisso && !isSelecionado
                          ? Border.all(color: AppColors.primaryBlue, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        dia.day.toString(),
                        style: TextStyle(
                          color: isSelecionado
                              ? Colors.white
                              : (isMesAtual ? AppColors.textLight : AppColors.textSub.withAlpha(100)),
                          fontWeight: isSelecionado || temCompromisso ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: AppColors.borderDark, height: 1),
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
                              if ((comp['observacoes'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text('Obs: ${comp['observacoes']}', style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: AppColors.textSub, size: 20),
                                onPressed: () => _abrirTelaFormularioCompromisso(compromissoExistente: comp, index: indiceGlobal),
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
        onPressed: () => _abrirTelaFormularioCompromisso(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// TELA CHEIA SEPARADA PARA O FORMULÁRIO DE AGENDAMENTO (Garante rolagem e elimina o estouro com o teclado)
class FormularioCompromissoScreen extends StatefulWidget {
  final Map<String, dynamic>? compromissoExistente;
  final int? index;
  final DateTime dataInicialPadrao;
  final Function(DateTime) onSalvo;

  const FormularioCompromissoScreen({
    super.key,
    this.compromissoExistente,
    this.index,
    required this.dataInicialPadrao,
    required this.onSalvo,
  });

  @override
  State<FormularioCompromissoScreen> createState() => _FormularioCompromissoScreenState();
}

class _FormularioCompromissoScreenState extends State<FormularioCompromissoScreen> {
  late final TextEditingController titleController;
  late final TextEditingController horaController;
  late final TextEditingController obsController;
  
  String? orcamentoVinculadoCliente;
  double? valorVinculado;
  late DateTime dataCompromissoTemp;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.compromissoExistente?['title'] ?? '');
    horaController = TextEditingController(text: widget.compromissoExistente?['hora'] ?? '09:00');
    obsController = TextEditingController(text: widget.compromissoExistente?['observacoes'] ?? '');
    
    orcamentoVinculadoCliente = widget.compromissoExistente?['cliente'];
    valorVinculado = widget.compromissoExistente?['valor'];

    dataCompromissoTemp = widget.compromissoExistente != null && widget.compromissoExistente!['data'] != null
        ? DateTime.parse(widget.compromissoExistente!['data'])
        : widget.dataInicialPadrao;
  }

  @override
  void dispose() {
    titleController.dispose();
    horaController.dispose();
    obsController.dispose();
    super.dispose();
  }

  String _formatarDataParaStr(DateTime data) {
    return "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";
  }

  String _formatarDataBr(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          widget.compromissoExistente == null ? 'Novo Agendamento' : 'Editar Agendamento',
          style: const TextStyle(color: AppColors.textLight),
        ),
        backgroundColor: AppColors.surfaceDark,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(
                labelText: 'Título do Compromisso / Serviço',
                labelStyle: TextStyle(color: AppColors.textSub),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: horaController,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: const InputDecoration(
                      labelText: 'Horário (HH:MM)',
                      labelStyle: TextStyle(color: AppColors.textSub),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? dataEscolhida = await showDatePicker(
                        context: context,
                        initialDate: dataCompromissoTemp,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );
                      if (dataEscolhida != null) {
                        setState(() {
                          dataCompromissoTemp = dataEscolhida;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        labelStyle: TextStyle(color: AppColors.textSub),
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatarDataBr(dataCompromissoTemp),
                            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                          ),
                          const Icon(Icons.calendar_month, color: AppColors.primaryBlue, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Vincular Orçamento (Aprova e gera "A Receber")',
              style: TextStyle(color: AppColors.textSub, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: orcamentoVinculadoCliente,
              dropdownColor: AppColors.surfaceDark,
              isExpanded: true,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(
                labelText: 'Selecionar Cliente / Orçamento',
                labelStyle: TextStyle(color: AppColors.textSub),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Nenhum (Avulso)', style: TextStyle(color: AppColors.textSub)),
                ),
                ...BudgetsScreen.listaOrcamentosGlobais.where((orc) {
                  bool isPendente = (orc['status'] ?? 'Pendente') == 'Pendente';
                  bool isVinculadoAtual = orc['cliente'] == orcamentoVinculadoCliente;
                  return isPendente || isVinculadoAtual;
                }).map((orc) {
                  String label = "${orc['cliente']} - R\$ ${(orc['valor'] as num).toStringAsFixed(2)}";
                  return DropdownMenuItem<String>(
                    value: orc['cliente'],
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (v) {
                setState(() {
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
            const SizedBox(height: 16),
            TextField(
              controller: obsController,
              style: const TextStyle(color: AppColors.textLight),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações',
                labelStyle: TextStyle(color: AppColors.textSub),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                final hora = horaController.text.trim();

                if (title.isNotEmpty && hora.isNotEmpty) {
                  if (widget.compromissoExistente != null && widget.compromissoExistente!['cliente'] != null) {
                    final antigoCliente = widget.compromissoExistente!['cliente'];
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

                  final dataStr = _formatarDataParaStr(dataCompromissoTemp);

                  final novoCompromisso = {
                    'title': title,
                    'data': dataStr,
                    'hora': hora,
                    'cliente': orcamentoVinculadoCliente ?? '',
                    'valor': valorVinculado ?? 0.0,
                    'observacoes': obsController.text.trim(),
                  };

                  if (valorVinculado != null && valorVinculado! > 0) {
                    final registroFinanceiro = {
                      'descricao': 'Serviço: $title (${orcamentoVinculadoCliente ?? 'Agenda'})',
                      'valor': valorVinculado!,
                      'tipo': 'Receita',
                      'status': 'Pendente',
                    };

                    if (widget.compromissoExistente == null) {
                      FinanceScreen.listaFinanceiraGlobal.add(registroFinanceiro);
                    } else {
                      int finIndex = FinanceScreen.listaFinanceiraGlobal.indexWhere(
                        (f) => f['descricao'].toString().contains(widget.compromissoExistente!['title']),
                      );
                      if (finIndex != -1) {
                        FinanceScreen.listaFinanceiraGlobal[finIndex] = registroFinanceiro;
                      } else {
                        FinanceScreen.listaFinanceiraGlobal.add(registroFinanceiro);
                      }
                    }
                    await StorageService.salvarFinance();
                  }

                  if (widget.index == null) {
                    AppointmentsScreen.agendaGlobal.add(novoCompromisso);
                  } else {
                    AppointmentsScreen.agendaGlobal[widget.index!] = novoCompromisso;
                  }

                  await StorageService.salvarAppointments();
                  await StorageService.salvarBudgets();
                  await StorageService.salvarFinance();

                  widget.onSalvo(dataCompromissoTemp);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compromisso salvo com sucesso!')),
                  );
                }
              },
              child: const Text('Salvar Compromisso', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}