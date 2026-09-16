import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProductServiceItem {
  String name;
  double price;
  String type; // 'PRODUTO' ou 'SERVIÇO'

  ProductServiceItem({required this.name, required this.price, required this.type});
}

class ProductsServicesScreen extends StatefulWidget {
  const ProductsServicesScreen({super.key});

  // Iniciado vazio conforme solicitado
  static final List<ProductServiceItem> itensGlobais = [];

  @override
  State<ProductsServicesScreen> createState() => _ProductsServicesScreenState();
}

class _ProductsServicesScreenState extends State<ProductsServicesScreen> {
  void _abrirModalItem([ProductServiceItem? itemExistente, int? index]) {
    final nomeController = TextEditingController(text: itemExistente?.name ?? '');
    final precoController = TextEditingController(text: itemExistente != null ? itemExistente.price.toString() : '');
    String tipoSelecionado = itemExistente?.type ?? 'SERVIÇO';

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
                  Text(itemExistente == null ? 'Novo Produto ou Serviço' : 'Editar Item', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: const InputDecoration(labelText: 'Nome do Item', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: precoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: const InputDecoration(labelText: 'Preço (R\$)', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.surfaceDark,
                    style: const TextStyle(color: AppColors.textLight),
                    initialValue: tipoSelecionado, // Corrigido para initialValue
                    decoration: const InputDecoration(labelText: 'Tipo', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'SERVIÇO', child: Text('Serviço', style: TextStyle(color: AppColors.textLight))),
                      DropdownMenuItem(value: 'PRODUTO', child: Text('Produto', style: TextStyle(color: AppColors.textLight))),
                    ],
                    onChanged: (val) => setModalState(() => tipoSelecionado = val!),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      final precoDouble = double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0.0;
                      if (nomeController.text.isNotEmpty && precoDouble > 0) {
                        setState(() {
                          final novoItem = ProductServiceItem(name: nomeController.text, price: precoDouble, type: tipoSelecionado);
                          if (itemExistente == null) {
                            ProductsServicesScreen.itensGlobais.add(novoItem);
                          } else {
                            ProductsServicesScreen.itensGlobais[index!] = novoItem;
                          }
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Salvar Item'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos e Serviços')),
      body: ProductsServicesScreen.itensGlobais.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSub),
                  SizedBox(height: 12),
                  Text('Nenhum item cadastrado.', style: TextStyle(color: AppColors.textSub, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Toque no botão + para adicionar produtos ou serviços.', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: ProductsServicesScreen.itensGlobais.length,
              itemBuilder: (context, index) {
                final item = ProductsServicesScreen.itensGlobais[index];
                bool isServico = item.type == 'SERVIÇO';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: ListTile(
                    leading: Icon(isServico ? Icons.room_service : Icons.inventory, color: AppColors.primaryBlue),
                    title: Text(item.name, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                    subtitle: Text('R\$ ${item.price.toStringAsFixed(2)} • ${item.type}', style: const TextStyle(color: AppColors.textSub)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.textSub, size: 18),
                      onPressed: () => _abrirModalItem(item, index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _abrirModalItem(),
        child: const Icon(Icons.add),
      ),
    );
  }
}