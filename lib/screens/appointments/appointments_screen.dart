import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../budgets/budgets_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  static final List<Map<String, String>> agendaGlobal = [];

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  void _abrirModalAgendamento([Map<String, String>? itemExistente, int? index]) {
    final titleController = TextEditingController(text: itemExistente?['title'] ?? '');
    final horaController = TextEditingController(text: itemExistente?['hora'] ?? '09:00');
    final dataStr = "${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      builder: (context) {
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
              Text(itemExistente == null ? 'Novo Agendamento ($dataStr)' : 'Editar Agendamento', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(labelText: 'Cliente / Serviço', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: horaController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(labelText: 'Horário (Ex: 14:30)', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    setState(() {
                      final novoCompromisso = {
                        'title': titleController.text,
                        'hora': horaController.text,
                        'data': dataStr,
                      };
                      if (itemExistente == null) {
                        AppointmentsScreen.agendaGlobal.add(novoCompromisso);
                      } else {
                        AppointmentsScreen.agendaGlobal[index!] = novoCompromisso;
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Salvar Agendamento'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStr = "${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}";
    final compromissosDoDia = AppointmentsScreen.agendaGlobal.where((a) => a['data'] == dataStr).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de Atendimentos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendário Visual Simples e Elegante
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mês: ${_selectedDay.month}/${_selectedDay.year}', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.calendar_month, color: AppColors.primaryBlue),
                        onPressed: () {
                          setState(() {
                            _selectedDay = DateTime.now();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CalendarDatePicker(
                    initialDate: _selectedDay,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDay = date;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Compromissos de $dataStr', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSub)),
            const SizedBox(height: 8),
            Expanded(
              child: compromissosDoDia.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.event_busy, size: 44, color: AppColors.textSub),
                          SizedBox(height: 8),
                          Text('Nenhum agendamento para este dia.', style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: compromissosDoDia.length,
                      itemBuilder: (context, index) {
                        final item = compromissosDoDia[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.schedule, color: AppColors.primaryBlue),
                            title: Text(item['title']!, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                            subtitle: Text('Horário: ${item['hora']}', style: const TextStyle(color: AppColors.textSub)),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, size: 16, color: AppColors.textSub),
                              onPressed: () => _abrirModalAgendamento(item, index),
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
        onPressed: () => _abrirModalAgendamento(),
        child: const Icon(Icons.add),
      ),
    );
  }
}