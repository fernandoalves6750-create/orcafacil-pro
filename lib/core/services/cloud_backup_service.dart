import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'storage_service.dart';
import 'client_service.dart' as clientSvc;
import 'empresa_service.dart';
import '../../screens/budgets/budgets_screen.dart';
import '../../screens/appointments/appointments_screen.dart';
import '../../screens/products/products_services_screen.dart';
import '../../screens/finance/finance_screen.dart';

class CloudBackupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Salva todos os dados locais atuais na nuvem do Firestore vinculados ao UID do utilizador
  static Future<void> fazerBackupNaNuvem() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;

    try {
      String assinaturaBase64 = StorageService.assinaturaCacheGlobal != null
          ? base64Encode(StorageService.assinaturaCacheGlobal!)
          : '';

      String logoBase64 = StorageService.logoCacheGlobal != null
          ? base64Encode(StorageService.logoCacheGlobal!)
          : '';

      Map<String, dynamic> dadosBackup = {
        'budgets': BudgetsScreen.listaOrcamentosGlobais,
        'appointments': AppointmentsScreen.agendaGlobal,
        'finance': FinanceScreen.listaFinanceiraGlobal,
        'products': ProductsServicesScreen.listaProdutosGlobais,
        'clients': clientSvc.ClientService.listaClientesGlobal,
        'empresa': EmpresaService.dadosEmpresa,
        'assinaturaBase64': assinaturaBase64,
        'logoBase64': logoBase64,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('usuarios').doc(uid).set(dadosBackup, SetOptions(merge: true));
      debugPrint('Backup na nuvem realizado com sucesso para o UID: $uid');
    } catch (e) {
      debugPrint('Erro ao fazer backup na nuvem: $e');
    }
  }

  /// Restaura os dados da nuvem do Firestore para o armazenamento local e memÃ³ria
  static Future<void> restaurarDaNuvem() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;

    try {
      DocumentSnapshot doc = await _firestore.collection('usuarios').doc(uid).get();
      if (!doc.exists || doc.data() == null) return;

      final data = doc.data() as Map<String, dynamic>;

      // 1. Restaurar OrÃ§amentos
      if (data['budgets'] != null) {
        final List decoded = data['budgets'];
        BudgetsScreen.listaOrcamentosGlobais = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        await StorageService.salvarBudgets();
      }

      // 2. Restaurar Agendamentos
      if (data['appointments'] != null) {
        final List decoded = data['appointments'];
        AppointmentsScreen.agendaGlobal = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        await StorageService.salvarAppointments();
      }

      // 3. Restaurar Financeiro
      if (data['finance'] != null) {
        final List decoded = data['finance'];
        FinanceScreen.listaFinanceiraGlobal = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        await StorageService.salvarFinance();
      }

      // 4. Restaurar Produtos
      if (data['products'] != null) {
        final List decoded = data['products'];
        StorageService.produtosCacheGlobal = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        ProductsServicesScreen.listaProdutosGlobais = StorageService.produtosCacheGlobal;
        await StorageService.salvarProducts();
      }

      // 5. Restaurar Clientes
      if (data['clients'] != null) {
        final List decoded = data['clients'];
        clientSvc.ClientService.listaClientesGlobal = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        await clientSvc.ClientService.salvarClientes();
      }

      // 6. Restaurar Empresa
      if (data['empresa'] != null) {
        final Map<String, dynamic> empresaMap = Map<String, dynamic>.from(data['empresa']);
        await EmpresaService.salvarEmpresa(empresaMap);
      }

      // 7. Restaurar Assinatura
      if (data['assinaturaBase64'] != null && (data['assinaturaBase64'] as String).isNotEmpty) {
        Uint8List sigBytes = base64Decode(data['assinaturaBase64']);
        await StorageService.salvarAssinatura(sigBytes);
      }

      // 8. Restaurar Logotipo
      if (data['logoBase64'] != null && (data['logoBase64'] as String).isNotEmpty) {
        Uint8List logoBytes = base64Decode(data['logoBase64']);
        await StorageService.salvarLogo(logoBytes);
      }

      debugPrint('Dados restaurados da nuvem com sucesso para o UID: $uid');
    } catch (e) {
      debugPrint('Erro ao restaurar dados da nuvem: $e');
    }
  }
}
