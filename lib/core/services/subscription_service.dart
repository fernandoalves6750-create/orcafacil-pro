import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _keyInstallDate = 'orcafacil_app_install_date_v1';
  static const String _keySubscriptionActive = 'orcafacil_subscription_active_v1';
  static const String _keySubscriptionExpiry = 'orcafacil_subscription_expiry_v1';
  
  static const int trialDays = 7;

  // Verifica se o usuário tem acesso completo (Teste grátis de 7 dias ou Assinatura Mensal ativa)
  static Future<bool> isAccessGranted() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Verifica assinatura mensal ativa
    bool isSubscribed = prefs.getBool(_keySubscriptionActive) ?? false;
    if (isSubscribed) {
      final String? expiryStr = prefs.getString(_keySubscriptionExpiry);
      if (expiryStr != null) {
        try {
          DateTime expiryDate = DateTime.parse(expiryStr);
          if (DateTime.now().isBefore(expiryDate)) {
            return true;
          }
        } catch (_) {}
      }
    }

    // 2. Verifica período de teste grátis de 7 dias
    final String? installDateStr = prefs.getString(_keyInstallDate);
    if (installDateStr == null) {
      final hojeStr = DateTime.now().toIso8601String();
      await prefs.setString(_keyInstallDate, hojeStr);
      return true;
    }

    try {
      final DateTime installDate = DateTime.parse(installDateStr);
      final DateTime trialExpiryDate = installDate.add(const Duration(days: trialDays));
      return DateTime.now().isBefore(trialExpiryDate);
    } catch (_) {
      return true;
    }
  }

  // Retorna quantos dias restam do teste gratuito
  static Future<int> diasRestantesTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final String? installDateStr = prefs.getString(_keyInstallDate);

    if (installDateStr == null) return trialDays;

    try {
      final DateTime installDate = DateTime.parse(installDateStr);
      final DateTime trialExpiryDate = installDate.add(const Duration(days: trialDays));
      final Duration diferenca = trialExpiryDate.difference(DateTime.now());

      int dias = diferenca.inDays;
      return dias < 0 ? 0 : dias + 1;
    } catch (_) {
      return 0;
    }
  }

  // Ativa a assinatura mensal por 30 dias (R$ 5,99)
  static Future<void> ativarAssinaturaMensal() async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime novaValidade = DateTime.now().add(const Duration(days: 30));
    
    await prefs.setBool(_keySubscriptionActive, true);
    await prefs.setString(_keySubscriptionExpiry, novaValidade.toIso8601String());
  }
}