import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class SubscriptionService {
  static const String _baseKeyInstallDate = 'orcafacil_app_install_date_v1';
  static const String _baseKeySubscriptionActive = 'orcafacil_subscription_active_v1';
  static const String _baseKeySubscriptionExpiry = 'orcafacil_subscription_expiry_v1';
  
  static const int trialDays = 7;

  /// Retorna a chave personalizada com o UID do utilizador atual para isolamento perfeito
  static String _getPrefKey(String baseKey) {
    final uid = AuthService.currentUid ?? 'global';
    return '${baseKey}_$uid';
  }

  // Verifica se o usuÃ¡rio tem acesso completo (Teste grÃ¡tis de 7 dias ou Assinatura Mensal ativa)
  static Future<bool> isAccessGranted() async {
    final prefs = await SharedPreferences.getInstance();
    
    final keySubActive = _getPrefKey(_baseKeySubscriptionActive);
    final keySubExpiry = _getPrefKey(_baseKeySubscriptionExpiry);
    final keyInstallDate = _getPrefKey(_baseKeyInstallDate);

    // 1. Verifica assinatura mensal ativa
    bool isSubscribed = prefs.getBool(keySubActive) ?? false;
    if (isSubscribed) {
      final String? expiryStr = prefs.getString(keySubExpiry);
      if (expiryStr != null) {
        try {
          DateTime expiryDate = DateTime.parse(expiryStr);
          if (DateTime.now().isBefore(expiryDate)) {
            return true;
          }
        } catch (_) {}
      }
    }

    // 2. Verifica perÃ­odo de teste grÃ¡tis de 7 dias isolado por utilizador
    final String? installDateStr = prefs.getString(keyInstallDate);
    if (installDateStr == null) {
      final hojeStr = DateTime.now().toIso8601String();
      await prefs.setString(keyInstallDate, hojeStr);
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
    final keyInstallDate = _getPrefKey(_baseKeyInstallDate);
    final String? installDateStr = prefs.getString(keyInstallDate);

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

  // Ativa a assinatura mensal por 30 dias (R$ 5,99) vinculada ao UID atual
  static Future<void> ativarAssinaturaMensal() async {
    final prefs = await SharedPreferences.getInstance();
    final keySubActive = _getPrefKey(_baseKeySubscriptionActive);
    final keySubExpiry = _getPrefKey(_baseKeySubscriptionExpiry);

    final DateTime novaValidade = DateTime.now().add(const Duration(days: 30));
    
    await prefs.setBool(keySubActive, true);
    await prefs.setString(keySubExpiry, novaValidade.toIso8601String());
  }
}
