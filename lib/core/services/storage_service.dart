import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/budgets/budgets_screen.dart';
import '../../screens/finance/finance_screen.dart';
import '../../screens/products/products_services_screen.dart';
import '../../screens/appointments/appointments_screen.dart';
import '../../screens/settings/business_screen.dart';

class StorageService {
  static const String _keyBudgets = 'saved_budgets';
  static const String _keyFinance = 'saved_finance';
  static const String _keyProducts = 'saved_products';
  static const String _keyAppointments = 'saved_appointments';
  static const String _keyBusiness = 'saved_business';

  // Salvar tudo
  static Future<void> salvarTudo() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyBudgets, jsonEncode(BudgetsScreen.listaOrcamentosGlobais));
    await prefs.setString(_keyFinance, jsonEncode(FinanceScreen.listaFinanceiraGlobal));
    
    final prodList = ProductsServicesScreen.itensGlobais.map((p) => {'name': p.name, 'price': p.price, 'type': p.type}).toList();
    await prefs.setString(_keyProducts, jsonEncode(prodList));

    await prefs.setString(_keyAppointments, jsonEncode(AppointmentsScreen.agendaGlobal));

    final businessData = {
      'nome': BusinessScreen.empresaNome,
      'cnpj': BusinessScreen.empresaCnpj,
      'whatsapp': BusinessScreen.empresaWhatsapp,
      'assinaturaTexto': BusinessScreen.empresaAssinaturaTexto,
      'logo': BusinessScreen.empresaLogo,
    };
    await prefs.setString(_keyBusiness, jsonEncode(businessData));
  }

  // Carregar tudo ao abrir o app
  static Future<void> carregarTudo() async {
    final prefs = await SharedPreferences.getInstance();

    // Orçamentos
    final budgetsStr = prefs.getString(_keyBudgets);
    if (budgetsStr != null) {
      BudgetsScreen.listaOrcamentosGlobais.clear();
      BudgetsScreen.listaOrcamentosGlobais.addAll(List<Map<String, dynamic>>.from(jsonDecode(budgetsStr)));
    }

    // Financeiro
    final financeStr = prefs.getString(_keyFinance);
    if (financeStr != null) {
      FinanceScreen.listaFinanceiraGlobal.clear();
      FinanceScreen.listaFinanceiraGlobal.addAll(List<Map<String, dynamic>>.from(jsonDecode(financeStr)));
    }

    // Produtos e Serviços
    final productsStr = prefs.getString(_keyProducts);
    if (productsStr != null) {
      ProductsServicesScreen.itensGlobais.clear();
      final decoded = List<Map<String, dynamic>>.from(jsonDecode(productsStr));
      for (var item in decoded) {
        ProductsServicesScreen.itensGlobais.add(ProductServiceItem(
          name: item['name'],
          price: item['price'],
          type: item['type'],
        ));
      }
    }

    // Agenda
    final appointmentsStr = prefs.getString(_keyAppointments);
    if (appointmentsStr != null) {
      AppointmentsScreen.agendaGlobal.clear();
      AppointmentsScreen.agendaGlobal.addAll(List<Map<String, String>>.from(jsonDecode(appointmentsStr).map((item) => Map<String, String>.from(item))));
    }

    // Empresa
    final businessStr = prefs.getString(_keyBusiness);
    if (businessStr != null) {
      final biz = jsonDecode(businessStr);
      BusinessScreen.empresaNome = biz['nome'] ?? '';
      BusinessScreen.empresaCnpj = biz['cnpj'] ?? '';
      BusinessScreen.empresaWhatsapp = biz['whatsapp'] ?? '';
      BusinessScreen.empresaAssinaturaTexto = biz['assinaturaTexto'] ?? '';
      BusinessScreen.empresaLogo = biz['logo'] ?? '';
    }
  }
}