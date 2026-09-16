import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orcafacil_pro/core/services/storage_service.dart';
import 'package:orcafacil_pro/core/services/empresa_service.dart';
import 'package:orcafacil_pro/core/theme/app_colors.dart';
import 'package:orcafacil_pro/screens/budgets/budgets_screen.dart';
import 'package:orcafacil_pro/screens/products/products_services_screen.dart';
import 'package:orcafacil_pro/screens/appointments/appointments_screen.dart';
import 'package:orcafacil_pro/screens/finance/finance_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _atualizarTudo();
  }

  Future<void> _atualizarTudo() async {
    await StorageService.carregarTudo();
    await EmpresaService.carregarEmpresa();
    if (mounted) setState(() {});
  }

  final List<Widget> _screens = [
    const DashboardTab(),
    const BudgetsScreen(),
    const ProductsServicesScreen(),
    const AppointmentsScreen(),
    const FinanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _atualizarTudo();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSub,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Orçamentos'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Produtos'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Financeiro'),
        ],
      ),
    );
  }
}

// Aba de Início / Dashboard
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await StorageService.carregarTudo();
    await EmpresaService.carregarEmpresa();
    if (mounted) setState(() {});
  }

  void _mostrarMenuEmpresa(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestão da Empresa',
                style: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.business, color: AppColors.primaryBlue),
                title: const Text('Incluir ou Alterar Dados e Logo', style: TextStyle(color: AppColors.textLight)),
                subtitle: const Text('Nome, CNPJ, Contato e Logo da Galeria', style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _abrirModalDadosEmpresa(context);
                },
              ),
              const Divider(color: AppColors.borderDark),
              ListTile(
                leading: const Icon(Icons.verified, color: AppColors.successGreen),
                title: const Text('Gerar Assinatura Eletrônica', style: TextStyle(color: AppColors.textLight)),
                subtitle: const Text('Configurar carimbo/assinatura digital nos documentos', style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _abrirModalAssinatura(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _abrirModalDadosEmpresa(BuildContext context) {
    final nomeController = TextEditingController(text: EmpresaService.dadosEmpresa['nome']);
    final cnpjController = TextEditingController(text: EmpresaService.dadosEmpresa['cnpj']);
    final contatoController = TextEditingController(text: EmpresaService.dadosEmpresa['contato']);
    String logoPathTemp = EmpresaService.dadosEmpresa['logoPath'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: const Text('Dados da Empresa e Logo', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setDialogState(() {
                              logoPathTemp = pickedFile.path;
                            });
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: logoPathTemp.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? Image.network(logoPathTemp, fit: BoxFit.cover)
                                      : Image.file(File(logoPathTemp), fit: BoxFit.cover),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_rounded, color: AppColors.primaryBlue, size: 28),
                                    SizedBox(height: 4),
                                    Text('Logo', style: TextStyle(color: AppColors.textSub, fontSize: 10)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nomeController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(labelText: 'Nome da Empresa', labelStyle: TextStyle(color: AppColors.textSub)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cnpjController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(labelText: 'CNPJ', labelStyle: TextStyle(color: AppColors.textSub)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contatoController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(labelText: 'Contato / E-mail / Tel', labelStyle: TextStyle(color: AppColors.textSub)),
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
                    await EmpresaService.salvarEmpresa({
                      'nome': nomeController.text.trim(),
                      'cnpj': cnpjController.text.trim(),
                      'contato': contatoController.text.trim(),
                      'assinatura': EmpresaService.dadosEmpresa['assinatura'],
                      'logoPath': logoPathTemp,
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dados e logo da empresa atualizados com sucesso!')),
                    );
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

  void _abrirModalAssinatura(BuildContext context) {
    final assinaturaController = TextEditingController(text: EmpresaService.dadosEmpresa['assinatura']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Assinatura Eletrônica', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Defina o texto ou código de validação que aparecerá como assinatura eletrônica nos orçamentos e recibos:',
                style: TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: assinaturaController,
                style: const TextStyle(color: AppColors.textLight),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Texto da Assinatura / Hash',
                  labelStyle: TextStyle(color: AppColors.textSub),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSub)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen),
              onPressed: () async {
                final dadosAtuais = Map<String, dynamic>.from(EmpresaService.dadosEmpresa);
                dadosAtuais['assinatura'] = assinaturaController.text.trim();
                await EmpresaService.salvarEmpresa(dadosAtuais);

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Assinatura eletrônica gerada e salva com sucesso!')),
                );
              },
              child: const Text('Gerar e Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalRecebido = 0;
    double totalAReceber = 0;
    double totalDespesas = 0;

    for (var tr in FinanceScreen.listaFinanceiraGlobal) {
      double val = (tr['valor'] as num).toDouble();
      String tipo = tr['tipo'] ?? '';
      String status = tr['status'] ?? '';

      if (tipo == 'Receita') {
        if (status == 'Recebido') {
          totalRecebido += val;
        } else if (status == 'Pendente') {
          totalAReceber += val;
        }
      } else if (tipo == 'Despesa') {
        totalDespesas += val;
      }
    }
    double saldoEmCaixa = totalRecebido - totalDespesas;

    // Formatação nativa de data (YYYY-MM-DD) sem dependência externa
    final hoje = DateTime.now();
    final dataHojeStr = "${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}";
    
    final compromissosHoje = AppointmentsScreen.agendaGlobal.where((item) {
      return item['data'] == dataHojeStr;
    }).toList();

    final orcamentosPendentes = BudgetsScreen.listaOrcamentosGlobais.where((item) {
      return (item['status'] ?? 'Pendente') == 'Pendente';
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bom dia, Fernando!',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.textLight),
                        tooltip: 'Atualizar dados',
                        onPressed: () {
                          _carregarDados();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dashboard atualizado!'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.business_outlined, color: AppColors.textLight),
                        tooltip: 'Perfil e Dados da Empresa',
                        onPressed: () => _mostrarMenuEmpresa(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
                        tooltip: 'Sair da Conta',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/welcome');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildCardResumo('Saldo em Caixa', saldoEmCaixa, AppColors.primaryBlue, Icons.account_balance_wallet_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCardResumo('Recebido', totalRecebido, AppColors.successGreen, Icons.check_circle_outline)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildCardResumo('A Receber', totalAReceber, AppColors.warningOrange, Icons.access_time_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCardResumo('Despesas', totalDespesas, AppColors.errorRed, Icons.trending_down_rounded)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Agenda do Dia',
                style: TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              compromissosHoje.isEmpty
                  ? _buildCardMensagemVazia('Nenhum compromisso agendado para hoje.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: compromissosHoje.length,
                      itemBuilder: (context, index) {
                        final comp = compromissosHoje[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(comp['title'] ?? '', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                              Text(comp['hora'] ?? '', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 24),
              const Text(
                'Orçamentos Pendentes',
                style: TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              orcamentosPendentes.isEmpty
                  ? _buildCardMensagemVazia('Nenhum orçamento pendente no momento.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orcamentosPendentes.length,
                      itemBuilder: (context, index) {
                        final orc = orcamentosPendentes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(orc['cliente'] ?? '', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(orc['item'] ?? '', style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
                                ],
                              ),
                              Text('R\$ ${(orc['valor'] as num).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardResumo(String titulo, double valor, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: cor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCardMensagemVazia(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Text(
        mensagem,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSub, fontSize: 13),
      ),
    );
  }
}