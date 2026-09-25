import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../budgets/budgets_screen.dart'; // ContÃ©m o ClientService centralizado

class ClientFormScreen extends StatefulWidget {
  final ClientModel? clienteExistente;

  const ClientFormScreen({super.key, this.clienteExistente});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;

  bool get _isEdicao => widget.clienteExistente != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.clienteExistente?.name ?? '');
    _cnpjController = TextEditingController(text: widget.clienteExistente?.cnpj ?? '');
    _phoneController = TextEditingController(text: widget.clienteExistente?.phone ?? '');
    _addressController = TextEditingController(text: widget.clienteExistente?.address ?? '');
    _cityController = TextEditingController(text: widget.clienteExistente?.city ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _salvar() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome do cliente Ã© obrigatÃ³rio.')),
      );
      return;
    }

    final telefoneInformado = _phoneController.text.trim();

    if (_isEdicao) {
      widget.clienteExistente!.name = _nameController.text.trim();
      widget.clienteExistente!.cnpj = _cnpjController.text.trim();
      widget.clienteExistente!.phone = telefoneInformado;
      widget.clienteExistente!.whatsapp = telefoneInformado;
      widget.clienteExistente!.address = _addressController.text.trim();
      widget.clienteExistente!.city = _cityController.text.trim();
    } else {
      final novoCliente = ClientModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        cnpj: _cnpjController.text.trim(),
        phone: telefoneInformado,
        whatsapp: telefoneInformado,
        email: '',
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: 'SP',
      );
      ClientService.listaClientesGlobal.add(novoCliente);
    }

    await ClientService.salvarClientes();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          _isEdicao ? 'Editar Cliente' : 'Cadastrar Novo Cliente',
          style: const TextStyle(color: AppColors.textLight),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(
                  labelText: 'Nome do Cliente / Empresa',
                  labelStyle: TextStyle(color: AppColors.textSub),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cnpjController,
                style: const TextStyle(color: AppColors.textLight),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CNPJ / CPF (Opcional)',
                  labelStyle: TextStyle(color: AppColors.textSub),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: AppColors.textLight),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone / WhatsApp',
                  labelStyle: TextStyle(color: AppColors.textSub),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(
                  labelText: 'EndereÃ§o (Rua, NÃºmero, Bairro)',
                  labelStyle: TextStyle(color: AppColors.textSub),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cityController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(
                  labelText: 'Cidade/UF',
                  labelStyle: TextStyle(color: AppColors.textSub),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _salvar,
                child: Text(
                  _isEdicao ? 'Salvar AlteraÃ§Ãµes' : 'Salvar Cliente',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
