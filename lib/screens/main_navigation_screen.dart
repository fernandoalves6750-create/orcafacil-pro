import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orcafacil_pro/core/services/storage_service.dart';
import 'package:orcafacil_pro/core/services/empresa_service.dart';
import 'package:orcafacil_pro/core/services/subscription_service.dart';
import 'package:orcafacil_pro/core/theme/app_colors.dart';
import 'package:orcafacil_pro/screens/budgets/budgets_screen.dart';
import 'package:orcafacil_pro/screens/products/products_services_screen.dart';
import 'package:orcafacil_pro/screens/appointments/appointments_screen.dart';
import 'package:orcafacil_pro/screens/finance/finance_screen.dart';
import 'package:orcafacil_pro/screens/clients/clients_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isTrialExpired = false;

  @override
  void initState() {
    super.initState();
    _verificarAssinatura();
    _atualizarTudo();
  }

  Future<void> _verificarAssinatura() async {
    bool ativo = await SubscriptionService.isAccessGranted();
    if (mounted) {
      setState(() {
        _isTrialExpired = !ativo;
      });
    }
  }

  Future<void> _atualizarTudo() async {
    await StorageService.carregarTudo();
    await EmpresaService.carregarEmpresa();
    await ClientService.carregarClientes();
    await _verificarAssinatura();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardTab(),
      const ClientFormScreen(),
      const BudgetsScreen(),
      const ProductsServicesScreen(),
      _isTrialExpired ? const PaywallScreen(recurso: 'Agenda de Compromissos') : const AppointmentsScreen(),
      _isTrialExpired ? const PaywallScreen(recurso: 'Controle Financeiro Completo') : const FinanceScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
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
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'InÃ­cio'),
          const BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Clientes'),
          const BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'OrÃ§amentos'),
          const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Produtos'),
          BottomNavigationBarItem(
            icon: Icon(_isTrialExpired ? Icons.lock_outline : Icons.calendar_today_outlined),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(_isTrialExpired ? Icons.lock_outline : Icons.account_balance_wallet_outlined),
            label: 'Financeiro',
          ),
        ],
      ),
    );
  }
}

class PaywallScreen extends StatelessWidget {
  final String recurso;
  const PaywallScreen({super.key, required this.recurso});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 70, color: AppColors.warningOrange),
              const SizedBox(height: 20),
              const Text(
                'PerÃ­odo de Teste Encerrado',
                style: TextStyle(color: AppColors.textLight, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'O acesso ao recurso "$recurso" requer a assinatura do OrÃ§aFÃ¡cil Pro.\n\nAssine o plano mensal por R\$ 5,99 para desbloquear a agenda, o financeiro e a emissÃ£o de recibos!',
                style: const TextStyle(color: AppColors.textSub, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                  );
                },
                child: const Text('Ver Planos e Assinar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    await ClientService.carregarClientes();
    if (mounted) setState(() {});
  }

  void _mostrarMenuEmpresa(BuildContext context) async {
    int dias = await SubscriptionService.diasRestantesTrial();

    if (!context.mounted) return;

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
                'GestÃ£o da Empresa',
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
                title: const Text('Gerar Assinatura EletrÃ´nica', style: TextStyle(color: AppColors.textLight)),
                subtitle: const Text('Configurar carimbo/assinatura digital nos documentos', style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _abrirLousaAssinatura(context);
                },
              ),
              const Divider(color: AppColors.borderDark),
              ListTile(
                leading: const Icon(Icons.card_membership_rounded, color: AppColors.warningOrange),
                title: const Text('Plano e Assinatura (Pro)', style: TextStyle(color: AppColors.textLight)),
                subtitle: Text(
                  dias > 0 ? 'PerÃ­odo de Teste Gratuito: Restam $dias dias' : 'Plano Mensal (R\$ 5,99 / mÃªs)',
                  style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                  );
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
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
                      decoration: const InputDecoration(labelText: 'Nome da Empresa / Profissional', labelStyle: TextStyle(color: AppColors.textSub)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cnpjController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: const InputDecoration(labelText: 'CNPJ / CPF', labelStyle: TextStyle(color: AppColors.textSub)),
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
                    if (logoPathTemp.isNotEmpty && !logoPathTemp.startsWith('http')) {
                      try {
                        final file = File(logoPathTemp);
                        if (await file.exists()) {
                          final bytes = await file.readAsBytes();
                          await StorageService.salvarLogo(bytes);
                        }
                      } catch (e) {
                        debugPrint('Erro ao salvar bytes da logo: $e');
                      }
                    }

                    await EmpresaService.salvarEmpresa({
                      'nome': nomeController.text.trim(),
                      'responsavel': EmpresaService.dadosEmpresa['responsavel'] ?? nomeController.text.trim(),
                      'cnpj': cnpjController.text.trim(),
                      'contato': contatoController.text.trim(),
                      'assinatura': EmpresaService.dadosEmpresa['assinatura'],
                      'logoPath': logoPathTemp,
                    });

                    await StorageService.carregarTudo();
                    await EmpresaService.carregarEmpresa();

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dados e logo da empresa atualizados com sucesso!')),
                    );
                    setState(() {});
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

  void _abrirLousaAssinatura(BuildContext context) {
    List<Offset?> pontosTemporarios = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text('Lousa de Assinatura Digital', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Desenhe sua assinatura no espaÃ§o abaixo:', style: TextStyle(fontSize: 13, color: AppColors.textSub)),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setDialogState(() {
                              pontosTemporarios.add(details.localPosition);
                            });
                          },
                          onPanEnd: (details) {
                            setDialogState(() {
                              pontosTemporarios.add(null);
                            });
                          },
                          child: CustomPaint(
                            painter: AssinaturaPainter(pontosTemporarios),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            pontosTemporarios.clear();
                          });
                        },
                        icon: const Icon(Icons.clear, color: AppColors.errorRed, size: 18),
                        label: const Text('Limpar', style: TextStyle(color: AppColors.errorRed)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (pontosTemporarios.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, desenhe a assinatura antes de salvar.')),
                      );
                      return;
                    }

                    try {
                      final recorder = ui.PictureRecorder();
                      final canvas = Canvas(recorder);
                      const size = Size(400, 200);

                      final paintBg = Paint()..color = Colors.white;
                      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBg);

                      final paintLine = Paint()
                        ..color = Colors.black87
                        ..strokeCap = StrokeCap.round
                        ..strokeWidth = 3.0;

                      for (int i = 0; i < pontosTemporarios.length - 1; i++) {
                        if (pontosTemporarios[i] != null && pontosTemporarios[i + 1] != null) {
                          canvas.drawLine(pontosTemporarios[i]!, pontosTemporarios[i + 1]!, paintLine);
                        }
                      }

                      final picture = recorder.endRecording();
                      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
                      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

                      if (byteData != null) {
                        Uint8List pngBytes = byteData.buffer.asUint8List();
                        await StorageService.salvarAssinatura(pngBytes);
                      }
                    } catch (e) {
                      debugPrint('Erro ao salvar assinatura manuscrita: $e');
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assinatura eletrÃ´nica desenhada e salva com sucesso!')),
                    );
                  },
                  child: const Text('Salvar Assinatura'),
                ),
              ],
            );
          },
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

    final hoje = DateTime.now();
    final dataHojeStr = "${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}";
    
    final compromissosHoje = AppointmentsScreen.agendaGlobal.where((item) {
      return item['data'] == dataHojeStr;
    }).toList();

    final orcamentosPendentes = BudgetsScreen.listaOrcamentosGlobais.where((item) {
      return (item['status'] ?? 'Pendente') == 'Pendente';
    }).toList();

    String nomeUsuario = '';
    if (EmpresaService.dadosEmpresa['responsavel']?.isNotEmpty == true) {
      nomeUsuario = EmpresaService.dadosEmpresa['responsavel'];
    } else if (EmpresaService.dadosEmpresa['nome']?.isNotEmpty == true) {
      nomeUsuario = EmpresaService.dadosEmpresa['nome'];
    }

    final saudacao = nomeUsuario.isNotEmpty ? 'Bom dia, $nomeUsuario!' : 'Bom dia!';

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
                  Expanded(
                    child: Text(
                      saudacao,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                'OrÃ§amentos Pendentes',
                style: TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              orcamentosPendentes.isEmpty
                  ? _buildCardMensagemVazia('Nenhum orÃ§amento pendente no momento.')
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(orc['cliente'] ?? '', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(orc['item'] ?? '', style: const TextStyle(color: AppColors.textSub, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
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

class AssinaturaPainter extends CustomPainter {
  final List<Offset?> pontos;
  AssinaturaPainter(this.pontos);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < pontos.length - 1; i++) {
      if (pontos[i] != null && pontos[i + 1] != null) {
        canvas.drawLine(pontos[i]!, pontos[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isAtivo = false;
  int _diasRestantes = 0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _verificarStatus();
  }

  Future<void> _verificarStatus() async {
    bool ativo = await SubscriptionService.isAccessGranted();
    int dias = await SubscriptionService.diasRestantesTrial();
    if (mounted) {
      setState(() {
        _isAtivo = ativo;
        _diasRestantes = dias;
        _carregando = false;
      });
    }
  }

  Future<void> _simularAssinatura() async {
    await SubscriptionService.ativarAssinaturaMensal();
    await _verificarStatus();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ParabÃ©ns! Assinatura mensal ativada com sucesso por 30 dias.'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Minha Assinatura', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isAtivo ? AppColors.successGreen : AppColors.warningOrange,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isAtivo ? Icons.verified_rounded : Icons.timer_outlined,
                          size: 48,
                          color: _isAtivo ? AppColors.successGreen : AppColors.warningOrange,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isAtivo ? 'OrÃ§aFÃ¡cil Pro Ativo' : 'PerÃ­odo de Teste Expirado',
                          style: const TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAtivo
                              ? 'VocÃª possui acesso total a todos os recursos do aplicativo.'
                              : 'Assine o plano mensal para desbloquear a Agenda, Financeiro e EmissÃ£o de Recibos.',
                          style: const TextStyle(color: AppColors.textSub, fontSize: 13, height: 1.3),
                          textAlign: TextAlign.center,
                        ),
                        if (!_isAtivo && _diasRestantes > 0) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Restam $_diasRestantes dias de teste gratuito.',
                            style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Detalhes do Plano',
                    style: TextStyle(color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      children: [
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.check_circle, color: AppColors.successGreen),
                          title: Text('Plano Mensal Pro', style: TextStyle(color: AppColors.textLight)),
                          subtitle: Text('R\$ 5,99 / mÃªs (Cancele quando quiser)', style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                        ),
                        const Divider(color: AppColors.borderDark),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.star, color: AppColors.warningOrange),
                          title: const Text('Recursos Inclusos', style: TextStyle(color: AppColors.textLight)),
                          subtitle: const Text(
                            'OrÃ§amentos, Produtos, Agenda de Compromissos, Controle Financeiro e EmissÃ£o de Recibos em PDF.',
                            style: TextStyle(color: AppColors.textSub, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _simularAssinatura,
                    child: const Text('Assinar por R\$ 5,99 / mÃªs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
