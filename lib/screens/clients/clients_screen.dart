import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../budgets/budgets_screen.dart'; // Contém o ClientService centralizado

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _pesquisa = '';

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    await ClientService.carregarClientes();
    if (mounted) setState(() {});
  }

  void _abrirModalCadastro(BuildContext context, {ClientModel? clienteExistente}) {
    final isEdicao = clienteExistente != null;
    final nameController = TextEditingController(text: clienteExistente?.name ?? '');
    final cnpjController = TextEditingController(text: clienteExistente?.cnpj ?? '');
    final phoneController = TextEditingController(text: clienteExistente?.phone ?? '');
    final addressController = TextEditingController(text: clienteExistente?.address ?? '');
    final cityController = TextEditingController(text: clienteExistente?.city ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdicao ? 'Editar Cliente' : 'Cadastrar Novo Cliente',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: const InputDecoration(
                    labelText: 'Nome do Cliente / Empresa',
                    labelStyle: TextStyle(color: AppColors.textSub),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cnpjController,
                  style: const TextStyle(color: AppColors.textLight),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CNPJ / CPF (Opcional)',
                    labelStyle: TextStyle(color: AppColors.textSub),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: AppColors.textLight),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone / WhatsApp',
                    labelStyle: TextStyle(color: AppColors.textSub),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: const InputDecoration(
                    labelText: 'Endereço (Rua, Número, Bairro)',
                    labelStyle: TextStyle(color: AppColors.textSub),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: const InputDecoration(
                    labelText: 'Cidade/UF',
                    labelStyle: TextStyle(color: AppColors.textSub),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      final telefoneInformado = phoneController.text.trim();
                      
                      if (isEdicao) {
                        clienteExistente.name = nameController.text.trim();
                        clienteExistente.cnpj = cnpjController.text.trim();
                        clienteExistente.phone = telefoneInformado;
                        clienteExistente.whatsapp = telefoneInformado;
                        clienteExistente.address = addressController.text.trim();
                        clienteExistente.city = cityController.text.trim();
                      } else {
                        final novoCliente = ClientModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          cnpj: cnpjController.text.trim(),
                          phone: telefoneInformado,
                          whatsapp: telefoneInformado,
                          email: '',
                          address: addressController.text.trim(),
                          city: cityController.text.trim(),
                          state: 'SP',
                        );
                        ClientService.listaClientesGlobal.add(novoCliente);
                      }

                      await ClientService.salvarClientes();

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      setState(() {});

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdicao ? 'Cliente atualizado com sucesso!' : 'Cliente cadastrado com sucesso!'),
                          backgroundColor: AppColors.surfaceDark,
                        ),
                      );
                    }
                  },
                  child: Text(isEdicao ? 'Salvar Alterações' : 'Salvar Cliente'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _enviarMensagemWhatsApp(ClientModel client) async {
    final telefone = client.whatsapp.isNotEmpty ? client.whatsapp : client.phone;
    
    if (telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este cliente não possui um número de telefone cadastrado.')),
      );
      return;
    }

    String numeroLimpo = telefone.replaceAll(RegExp(r'\D'), '');
    if (!numeroLimpo.startsWith('55') && numeroLimpo.length <= 11) {
      numeroLimpo = '55$numeroLimpo';
    }

    final mensagem = Uri.encodeComponent('Olá ${client.name}, tudo bem? Entramos em contato referente aos nossos serviços.');
    final url = Uri.parse('https://wa.me/$numeroLimpo?text=$mensagem');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir o WhatsApp: $e')),
        );
      }
    }
  }

  void _excluirCliente(ClientModel client) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Excluir Cliente', style: TextStyle(color: AppColors.textLight)),
        content: Text('Deseja realmente excluir ${client.name}?', style: const TextStyle(color: AppColors.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              ClientService.listaClientesGlobal.removeWhere((c) => c.id == client.id);
              await ClientService.salvarClientes();
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cliente excluído com sucesso!')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientesFiltrados = ClientService.listaClientesGlobal.where((client) {
      return client.name.toLowerCase().contains(_pesquisa.toLowerCase()) ||
          client.phone.toLowerCase().contains(_pesquisa.toLowerCase()) ||
          client.cnpj.contains(_pesquisa);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Clientes Cadastrados', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textLight),
            tooltip: 'Atualizar',
            onPressed: () {
              _carregarClientes();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: AppColors.textLight),
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome, CNPJ ou telefone...',
                hintStyle: const TextStyle(color: AppColors.textSub),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _pesquisa = value;
                });
              },
            ),
          ),
          Expanded(
            child: clientesFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: AppColors.textSub),
                        const SizedBox(height: 16),
                        const Text('Nenhum cliente encontrado.', style: TextStyle(fontSize: 16, color: AppColors.textSub)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final client = clientesFiltrados[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryBlue.withAlpha(40),
                            child: Text(
                              client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(client.name, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (client.cnpj.isNotEmpty)
                                Text('CNPJ: ${client.cnpj}', style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
                              Text(
                                '${client.phone.isNotEmpty ? client.phone : 'Sem telefone'} • ${client.city.isNotEmpty ? client.city : 'Sem cidade'}',
                                style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                              ),
                              if (client.address.isNotEmpty)
                                Text('End: ${client.address}', style: const TextStyle(color: AppColors.textSub, fontSize: 11), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botão WhatsApp
                              IconButton(
                                icon: const Icon(Icons.chat, color: AppColors.successGreen),
                                tooltip: 'Enviar WhatsApp',
                                onPressed: () => _enviarMensagemWhatsApp(client),
                              ),
                              // Botão Editar
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                                tooltip: 'Editar Cliente',
                                onPressed: () => _abrirModalCadastro(context, clienteExistente: client),
                              ),
                              // Botão Excluir
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Excluir Cliente',
                                onPressed: () => _excluirCliente(client),
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
        onPressed: () => _abrirModalCadastro(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}