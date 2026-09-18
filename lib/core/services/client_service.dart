import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientService {
  static const String _keyClientesStorage = 'orcafacil_clientes_storage_v1';

  // Lista global de clientes em memória
  static List<Map<String, dynamic>> listaClientesGlobal = [];

  // Carregar clientes salvos
  static Future<void> carregarClientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_keyClientesStorage);
      if (dataStr != null) {
        final decoded = jsonDecode(dataStr) as List;
        listaClientesGlobal = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar clientes: $e');
    }
  }

  // Salvar a lista atual de clientes
  static Future<void> salvarClientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyClientesStorage, jsonEncode(listaClientesGlobal));
    } catch (e) {
      debugPrint('Erro ao salvar clientes: $e');
    }
  }

  // Adicionar ou atualizar cliente (Salva automaticamente se não existir)
  static Future<void> adicionarOuAtualizarCliente({
    required String nome,
    String telefone = '',
    String email = '',
  }) async {
    if (nome.trim().isEmpty) return;

    final nomeFormatado = nome.trim();
    
    // Verifica se já existe um cliente com o mesmo nome (ignorando maiúsculas/minúsculas)
    final index = listaClientesGlobal.indexWhere(
      (c) => c['nome'].toString().toLowerCase() == nomeFormatado.toLowerCase(),
    );

    if (index >= 0) {
      // Atualiza dados se necessário
      listaClientesGlobal[index]['telefone'] = telefone.isNotEmpty ? telefone : listaClientesGlobal[index]['telefone'];
      listaClientesGlobal[index]['email'] = email.isNotEmpty ? email : listaClientesGlobal[index]['email'];
    } else {
      // Cadastra novo cliente automaticamente
      listaClientesGlobal.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'nome': nomeFormatado,
        'telefone': telefone,
        'email': email,
      });
    }

    await salvarClientes();
  }
}