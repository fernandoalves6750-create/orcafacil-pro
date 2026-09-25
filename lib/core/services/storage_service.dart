import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/budgets/budgets_screen.dart';
import '../../screens/appointments/appointments_screen.dart';
import '../../screens/products/products_services_screen.dart';
import '../../screens/finance/finance_screen.dart';
import '../services/auth_service.dart';
import 'cloud_backup_service.dart';

class StorageService {
  static const String _keyBudgets = 'orcafacil_budgets_list';
  static const String _keyAppointments = 'orcafacil_appointments_list';
  static const String _keyProducts = 'produtos_cadastrados_key_oficial';
  static const String _keyFinance = 'orcafacil_finance_list';
  static const String _keySignature = 'orcafacil_user_signature_bytes';
  static const String _keyLogo = 'orcafacil_user_logo_bytes'; // Chave exclusiva para a logo

  static List<Map<String, dynamic>> produtosCacheGlobal = [];
  static Uint8List? assinaturaCacheGlobal;
  static Uint8List? logoCacheGlobal; // Cache global da Logo

  /// Retorna a chave personalizada com o UID do utilizador atual para isolamento perfeito
  static String _getPrefKey(String baseKey) {
    final uid = AuthService.currentUid ?? 'global';
    return '${baseKey}_$uid';
  }

  static Future<void> carregarTudo() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. OrÃ§amentos
    final String? budgetsStr = prefs.getString(_getPrefKey(_keyBudgets));
    if (budgetsStr != null) {
      try {
        final List decoded = jsonDecode(budgetsStr);
        BudgetsScreen.listaOrcamentosGlobais = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (_) {
        BudgetsScreen.listaOrcamentosGlobais = [];
      }
    } else {
      BudgetsScreen.listaOrcamentosGlobais = [];
    }

    // 2. Agendamentos
    final String? appointmentsStr = prefs.getString(_getPrefKey(_keyAppointments));
    if (appointmentsStr != null) {
      try {
        final List decoded = jsonDecode(appointmentsStr);
        AppointmentsScreen.agendaGlobal = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (_) {
        AppointmentsScreen.agendaGlobal = [];
      }
    } else {
      AppointmentsScreen.agendaGlobal = [];
    }

    // 3. Financeiro
    final String? financeStr = prefs.getString(_getPrefKey(_keyFinance));
    if (financeStr != null) {
      try {
        final List decoded = jsonDecode(financeStr);
        FinanceScreen.listaFinanceiraGlobal = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (_) {
        FinanceScreen.listaFinanceiraGlobal = [];
      }
    } else {
      FinanceScreen.listaFinanceiraGlobal = [];
    }

    // 4. Produtos e ServiÃ§os
    final String? productsStr = prefs.getString(_getPrefKey(_keyProducts));
    if (productsStr != null) {
      try {
        final List decoded = jsonDecode(productsStr);
        produtosCacheGlobal = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        ProductsServicesScreen.listaProdutosGlobais = produtosCacheGlobal;
      } catch (_) {
        produtosCacheGlobal = [];
        ProductsServicesScreen.listaProdutosGlobais = [];
      }
    } else {
      produtosCacheGlobal = [];
      ProductsServicesScreen.listaProdutosGlobais = [];
    }

    // 5. Carregar Assinatura
    final String? signatureBase64 = prefs.getString(_getPrefKey(_keySignature));
    if (signatureBase64 != null && signatureBase64.isNotEmpty) {
      try {
        assinaturaCacheGlobal = base64Decode(signatureBase64);
      } catch (_) {
        assinaturaCacheGlobal = null;
      }
    } else {
      assinaturaCacheGlobal = null;
    }

    // 6. Carregar Logo da Empresa
    final String? logoBase64 = prefs.getString(_getPrefKey(_keyLogo));
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      try {
        logoCacheGlobal = base64Decode(logoBase64);
      } catch (_) {
        logoCacheGlobal = null;
      }
    } else {
      logoCacheGlobal = null;
    }
  }

  // MÃ©todo para salvar a assinatura isolado por UID e disparar backup na nuvem
  static Future<void> salvarAssinatura(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    assinaturaCacheGlobal = bytes;
    await prefs.setString(_getPrefKey(_keySignature), base64Encode(bytes));
    await CloudBackupService.fazerBackupNaNuvem();
  }

  // MÃ©todo para salvar o Logotipo permanentemente isolado por UID e disparar backup na nuvem
  static Future<void> salvarLogo(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    logoCacheGlobal = bytes;
    await prefs.setString(_getPrefKey(_keyLogo), base64Encode(bytes));
    await CloudBackupService.fazerBackupNaNuvem();
  }

  static Future<void> salvarBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getPrefKey(_keyBudgets), jsonEncode(BudgetsScreen.listaOrcamentosGlobais));
    await CloudBackupService.fazerBackupNaNuvem();
  }

  static Future<void> salvarAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getPrefKey(_keyAppointments), jsonEncode(AppointmentsScreen.agendaGlobal));
    await CloudBackupService.fazerBackupNaNuvem();
  }

  static Future<void> salvarProducts() async {
    final prefs = await SharedPreferences.getInstance();
    produtosCacheGlobal = List<Map<String, dynamic>>.from(ProductsServicesScreen.listaProdutosGlobais);
    await prefs.setString(_getPrefKey(_keyProducts), jsonEncode(produtosCacheGlobal));
    await CloudBackupService.fazerBackupNaNuvem();
  }

  static Future<void> salvarFinance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getPrefKey(_keyFinance), jsonEncode(FinanceScreen.listaFinanceiraGlobal));
    await CloudBackupService.fazerBackupNaNuvem();
  }

  static Future<void> limparTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getPrefKey(_keyBudgets));
    await prefs.remove(_getPrefKey(_keyAppointments));
    await prefs.remove(_getPrefKey(_keyProducts));
    await prefs.remove(_getPrefKey(_keyFinance));
    await prefs.remove(_getPrefKey(_keySignature));
    await prefs.remove(_getPrefKey(_keyLogo));
    
    BudgetsScreen.listaOrcamentosGlobais.clear();
    AppointmentsScreen.agendaGlobal.clear();
    ProductsServicesScreen.listaProdutosGlobais.clear();
    FinanceScreen.listaFinanceiraGlobal.clear();
    produtosCacheGlobal.clear();
    assinaturaCacheGlobal = null;
    logoCacheGlobal = null;
  }
}
