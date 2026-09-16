import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

class ProductsServicesScreen extends StatefulWidget {
  const ProductsServicesScreen({super.key});

  static List<Map<String, dynamic>> listaProdutosGlobais = [];
  static const String _storageKey = 'produtos_storage_key';

  static Future<void> carregarDadosPersistidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dadosString = prefs.getString(_storageKey);
      if (dadosString != null) {
        final List<dynamic> decodificado = jsonDecode(dadosString);
        listaProdutosGlobais = decodificado.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar produtos: $e');
    }
  }

  static Future<void> salvarDadosPersistidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String codificado = jsonEncode(listaProdutosGlobais);
      await prefs.setString(_storageKey, codificado);
    } catch (e) {
      debugPrint('Erro ao salvar produtos: $e');
    }
  }

  @override
  State<ProductsServicesScreen> createState() => _ProductsServicesScreenState();
}

class _ProductsServicesScreenState extends State<ProductsServicesScreen> {
  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    await ProductsServicesScreen.carregarDadosPersistidos();
    if (mounted) setState(() {});
  }

  void _adicionarOuEditarProduto({Map<String, dynamic>? produtoExistente, int? index}) {
    final nomeController = TextEditingController(text: produtoExistente?['nome'] ?? '');
    final valorController = TextEditingController(text: produtoExistente != null ? produtoExistente['valor'].toString() : '');
    String tipoSelecionado = produtoExistente?['tipo'] ?? 'Produto';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Text(
                produtoExistente == null ? 'Novo Item' : 'Editar Item',
                style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(
                        labelText: 'Nome do Produto / Serviço',
                        labelStyle: TextStyle(color: AppColors.textSub),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(
                        labelText: 'Preço (R\$)',
                        labelStyle: TextStyle(color: AppColors.textSub),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipoSelecionado,
                      dropdownColor: AppColors.surfaceDark,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        labelStyle: TextStyle(color: AppColors.textSub),
                      ),
                      items: ['Produto', 'Serviço'].map((tipo) {
                        return DropdownMenuItem(value: tipo, child: Text(tipo));
                      }).toList(),
                      onChanged: (novoValor) {
                        if (novoValor != null) {
                          setDialogState(() => tipoSelecionado = novoValor);
                        }
                      },
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
                    final nome = nomeController.text.trim();
                    final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;

                    if (nome.isNotEmpty && valor > 0) {
                      final novoRegistro = {
                        'nome': nome,
                        'valor': valor,
                        'tipo': tipoSelecionado,
                      };

                      setState(() {
                        if (index == null) {
                          ProductsServicesScreen.listaProdutosGlobais.add(novoRegistro);
                        } else {
                          ProductsServicesScreen.listaProdutosGlobais[index] = novoRegistro;
                        }
                      });

                      await ProductsServicesScreen.salvarDadosPersistidos();

                      if (!context.mounted) return;
                      Navigator.pop(context);
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

  void _deletarProduto(int index) async {
    setState(() {
      ProductsServicesScreen.listaProdutosGlobais.removeAt(index);
    });
    await ProductsServicesScreen.salvarDadosPersistidos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Produtos & Serviços', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textLight),
            tooltip: 'Atualizar lista',
            onPressed: () {
              _carregarProdutos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lista de produtos atualizada!'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: ProductsServicesScreen.listaProdutosGlobais.isEmpty
          ? const Center(
              child: Text('Nenhum produto ou serviço cadastrado.', style: TextStyle(color: AppColors.textSub)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ProductsServicesScreen.listaProdutosGlobais.length,
              itemBuilder: (context, index) {
                final prod = ProductsServicesScreen.listaProdutosGlobais[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: ListTile(
                    title: Text(prod['nome'], style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                    subtitle: Text('${prod['tipo']} • R\$ ${(prod['valor'] as num).toDouble().toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSub)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppColors.textSub, size: 20),
                          onPressed: () => _adicionarOuEditarProduto(produtoExistente: prod, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                          onPressed: () => _deletarProduto(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _adicionarOuEditarProduto(),
        child: const Icon(Icons.add),
      ),
    );
  }
}