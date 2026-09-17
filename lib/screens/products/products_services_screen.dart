import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';

class ProductsServicesScreen extends StatefulWidget {
  const ProductsServicesScreen({super.key});

  static List<Map<String, dynamic>> listaProdutosGlobais = [];

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
    await StorageService.carregarTudo();
    if (mounted) setState(() {});
  }

  void _abrirTelaFormularioProduto({Map<String, dynamic>? produtoExistente, int? index}) async {
    await StorageService.carregarTudo();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioProdutoScreen(
          produtoExistente: produtoExistente,
          index: index,
          onSalvo: () => _carregarProdutos(),
        ),
      ),
    );
  }

  void _deletarProduto(int index) async {
    setState(() {
      ProductsServicesScreen.listaProdutosGlobais.removeAt(index);
    });
    await StorageService.salvarProducts();
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
            tooltip: 'Atualizar',
            onPressed: () {
              _carregarProdutos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lista atualizada!'), backgroundColor: AppColors.surfaceDark, duration: Duration(seconds: 1)),
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
                final nome = prod['name'] ?? prod['nome'] ?? '';
                final preco = (prod['price'] ?? prod['preco'] ?? prod['valor'] ?? 0.0) as num;
                final tipo = prod['type'] ?? prod['tipo'] ?? 'Produto';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(nome, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('R\$ ${preco.toStringAsFixed(2)} • $tipo', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppColors.textSub, size: 20),
                          onPressed: () => _abrirTelaFormularioProduto(produtoExistente: prod, index: index),
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
        onPressed: () => _abrirTelaFormularioProduto(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// TELA CHEIA SEPARADA PARA PRODUTOS/SERVIÇOS
class FormularioProdutoScreen extends StatefulWidget {
  final Map<String, dynamic>? produtoExistente;
  final int? index;
  final VoidCallback onSalvo;

  const FormularioProdutoScreen({super.key, this.produtoExistente, this.index, required this.onSalvo});

  @override
  State<FormularioProdutoScreen> createState() => _FormularioProdutoScreenState();
}

class _FormularioProdutoScreenState extends State<FormularioProdutoScreen> {
  late final TextEditingController nomeController;
  late final TextEditingController precoController;
  String tipoSelecionado = 'Produto';

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.produtoExistente?['name'] ?? widget.produtoExistente?['nome'] ?? '');
    precoController = TextEditingController(text: widget.produtoExistente != null ? (widget.produtoExistente!['price'] ?? widget.produtoExistente!['preco'] ?? widget.produtoExistente!['valor'] ?? 0.0).toString() : '0.0');
    tipoSelecionado = widget.produtoExistente?['type'] ?? widget.produtoExistente?['tipo'] ?? 'Produto';
  }

  @override
  void dispose() {
    nomeController.dispose();
    precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(widget.produtoExistente == null ? 'Novo Item' : 'Editar Item', style: const TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.surfaceDark,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nomeController,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(labelText: 'Nome do Produto ou Serviço', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: precoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(labelText: 'Preço (R\$)', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: tipoSelecionado,
              dropdownColor: AppColors.surfaceDark,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(labelText: 'Tipo', labelStyle: TextStyle(color: AppColors.textSub), border: OutlineInputBorder()),
              items: ['Produto', 'Serviço'].map((t) {
                return DropdownMenuItem(value: t, child: Text(t));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => tipoSelecionado = v);
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                final nome = nomeController.text.trim();
                final preco = double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0.0;

                if (nome.isNotEmpty && preco > 0) {
                  final novoItem = {
                    'name': nome,
                    'price': preco,
                    'type': tipoSelecionado,
                  };

                  if (widget.index == null) {
                    ProductsServicesScreen.listaProdutosGlobais.add(novoItem);
                  } else {
                    ProductsServicesScreen.listaProdutosGlobais[widget.index!] = novoItem;
                  }

                  await StorageService.salvarProducts();
                  widget.onSalvo();

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item salvo com sucesso!'), backgroundColor: AppColors.surfaceDark),
                  );
                }
              },
              child: const Text('Salvar Item', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}