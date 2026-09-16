import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final List<ClientModel> _clients = []; // Lista limpa para testes

  void _abrirModalCadastro(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Cadastrar Novo Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome do Cliente', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefone / WhatsApp', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: cityController, decoration: const InputDecoration(labelText: 'Cidade/UF', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      _clients.add(ClientModel(
                        id: DateTime.now().toString(),
                        name: nameController.text,
                        phone: phoneController.text,
                        whatsapp: phoneController.text,
                        email: 'contato@email.com',
                        city: cityController.text,
                        state: 'SP',
                      ));
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente cadastrado com sucesso!')));
                  }
                },
                child: const Text('Salvar Cliente'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _enviarMensagemWhatsApp(ClientModel client) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abrindo chat do WhatsApp para ${client.name} (${client.whatsapp})...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes Cadastrados')),
      body: _clients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: AppColors.textMedium),
                  const SizedBox(height: 16),
                  const Text('Nenhum cliente cadastrado ainda.', style: TextStyle(fontSize: 16, color: AppColors.textMedium)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                    onPressed: () => _abrirModalCadastro(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Cadastrar primeiro cliente'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _clients.length,
              itemBuilder: (context, index) {
                final client = _clients[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.person, color: AppColors.primaryBlue)),
                    title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${client.phone} • ${client.city}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat, color: AppColors.successGreen),
                      onPressed: () => _enviarMensagemWhatsApp(client),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _abrirModalCadastro(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}