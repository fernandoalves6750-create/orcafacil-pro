import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmpresaService {
  static const String _keyEmpresaData = 'empresa_dados_storage_key_v2';

  static Map<String, dynamic> dadosEmpresa = {
    'nome': 'FS Manutenção e Suporte em Informática',
    'cnpj': '00.000.000/0001-00',
    'contato': 'contato@fsmanutencao.com.br | (11) 90000-0000',
    'assinatura': 'Assinado digitalmente por FS Manutenção',
    'logoPath': '', // Caminho ou URI da imagem do logo selecionada
  };

  static Future<void> carregarEmpresa() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_keyEmpresaData);
      if (dataStr != null) {
        dadosEmpresa = Map<String, dynamic>.from(jsonDecode(dataStr));
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados da empresa: $e');
    }
  }

  static Future<void> salvarEmpresa(Map<String, dynamic> novosDados) async {
    try {
      dadosEmpresa = novosDados;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEmpresaData, jsonEncode(dadosEmpresa));
    } catch (e) {
      debugPrint('Erro ao salvar dados da empresa: $e');
    }
  }
}