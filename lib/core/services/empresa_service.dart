import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmpresaService {
  static const String _keyEmpresaData = 'empresa_dados_storage_key_v2';

  static Map<String, dynamic> dadosEmpresa = {
    'nome': '',
    'responsavel': '', // <-- Adicionado aqui para guardar o nome do utilizador
    'cnpj': '',
    'contato': '',
    'assinatura': '',
    'logoPath': '',
  };

  static Future<void> carregarEmpresa() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_keyEmpresaData);
      if (dataStr != null) {
        final decoded = Map<String, dynamic>.from(jsonDecode(dataStr));
        dadosEmpresa = {...dadosEmpresa, ...decoded};
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados da empresa: $e');
    }
  }

  static Future<void> salvarEmpresa(Map<String, dynamic> novosDados) async {
    try {
      dadosEmpresa = {...dadosEmpresa, ...novosDados};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEmpresaData, jsonEncode(dadosEmpresa));
    } catch (e) {
      debugPrint('Erro ao salvar dados da empresa: $e');
    }
  }
}