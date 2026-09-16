import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/budgets/budgets_screen.dart';
import '../../screens/appointments/appointments_screen.dart';
import '../../screens/products/products_services_screen.dart';

class StorageService {
  static const String _keyBudgets = 'orcafacil_budgets_list';
  static const String _keyAppointments = 'orcafacil_appointments_list';
  static const String _keyProducts = 'produtos_cadastrados';
  static const String _keyCompany = 'orcafacil_company_data';

  // Cache global unificado de produtos
  static List<Map<String, dynamic>> produtosCacheGlobal = [];

  // Carrega todos os dados do SharedPreferences para as listas globais
  static Future<void> carregarTudo() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Carregar Orçamentos
    final String? budgetsStr = prefs.getString(_keyBudgets);
    if (budgetsStr != null) {
      try {
        final List decoded = jsonDecode(budgetsStr);
        BudgetsScreen.listaOrcamentosGlobais = decoded
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } catch (_) {
        BudgetsScreen.listaOrcamentosGlobais = [];
      }
    }

    // 2. Carregar Agendamentos (Agenda)
    final String? appointmentsStr = prefs.getString(_keyAppointments);
    if (appointmentsStr != null) {
      try {
        final List decoded = jsonDecode(appointmentsStr);
        AppointmentsScreen.agendaGlobal = decoded
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } catch (_) {
        AppointmentsScreen.agendaGlobal = [];
      }
    }

    // 3. Carregar Produtos e Serviços de forma unificada
    final String? productsStr = prefs.getString(_keyProducts);
    if (productsStr != null) {
      try {
        final List decoded = jsonDecode(productsStr);
        produtosCacheGlobal = decoded
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        ProductsServicesScreen.listaProdutosGlobais = produtosCacheGlobal;
      } catch (_) {
        produtosCacheGlobal = [];
        ProductsServicesScreen.listaProdutosGlobais = [];
      }
    } else {
      produtosCacheGlobal = [];
      ProductsServicesScreen.listaProdutosGlobais = [];
    }
  }

  // Salvar Orçamentos
  static Future<void> salvarBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBudgets, jsonEncode(BudgetsScreen.listaOrcamentosGlobais));
  }

  // Salvar Agendamentos
  static Future<void> salvarAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppointments, jsonEncode(AppointmentsScreen.agendaGlobal));
  }

  // Salvar Produtos e Serviços
  static Future<void> salvarProducts() async {
    final prefs = await SharedPreferences.getInstance();
    produtosCacheGlobal = List<Map<String, dynamic>>.from(ProductsServicesScreen.listaProdutosGlobais);
    await prefs.setString(_keyProducts, jsonEncode(produtosCacheGlobal));
  }

  static Future<void> salvarFinance() async {}

  // Limpar dados do app
  static Future<void> limparTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    BudgetsScreen.listaOrcamentosGlobais.clear();
    AppointmentsScreen.agendaGlobal.clear();
    ProductsServicesScreen.listaProdutosGlobais.clear();
    produtosCacheGlobal.clear();
  }
}