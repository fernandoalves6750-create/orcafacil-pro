import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String _keyRegisteredUsers = 'registered_users_db_key_v2';
  static const String _keyCurrentUser = 'current_logged_user_key';

  // Configuração do Google Sign-In com o Client ID fornecido
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '1098844585019-osrcpkkju2lgo255vrskudld3jlhllop.apps.googleusercontent.com' : null,
    serverClientId: '1098844585019-osrcpkkju2lgo255vrskudld3jlhllop.apps.googleusercontent.com',
  );

  // Cadastra um novo usuário localmente (E-mail e Senha)
  static Future<bool> registrarUsuario(String email, String senha) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersString = prefs.getString(_keyRegisteredUsers);
      List<dynamic> usersList = usersString != null ? jsonDecode(usersString) : [];

      // Verifica se o e-mail já existe
      bool existe = usersList.any((u) => u['email'].toString().toLowerCase() == email.toLowerCase());
      if (existe) return false;

      // Adiciona o novo usuário
      usersList.add({'email': email, 'senha': senha});
      await prefs.setString(_keyRegisteredUsers, jsonEncode(usersList));
      return true;
    } catch (e) {
      debugPrint('Erro ao registrar usuário: $e');
      return false;
    }
  }

  // Validação de login local (E-mail e Senha)
  static Future<bool> validarLogin(String email, String senha) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersString = prefs.getString(_keyRegisteredUsers);
      
      List<dynamic> usersList = usersString != null ? jsonDecode(usersString) : [];

      // Se não houver nenhum usuário cadastrado ainda, cadastra este automaticamente para testes
      if (usersList.isEmpty) {
        usersList.add({'email': email, 'senha': senha});
        await prefs.setString(_keyRegisteredUsers, jsonEncode(usersList));
        await prefs.setString(_keyCurrentUser, email);
        return true;
      }

      // Valida se o e-mail e a senha conferem exatamente com o cadastro
      bool senhaValida = usersList.any((u) => u['email'].toString().toLowerCase() == email.toLowerCase() && u['senha'] == senha);

      if (senhaValida) {
        await prefs.setString(_keyCurrentUser, email);
      }

      return senhaValida;
    } catch (e) {
      debugPrint('Erro ao validar login: $e');
      return false;
    }
  }

  // Login com o Google
  static Future<bool> loginComGoogle() async {
    try {
      // Abre a janela de seleção de conta do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser != null) {
        final prefs = await SharedPreferences.getInstance();
        // Salva o e-mail do Google como usuário logado atual
        await prefs.setString(_keyCurrentUser, googleUser.email);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro no login com Google: $e');
      return false;
    }
  }

  // Retorna o e-mail do usuário atualmente logado
  static Future<String?> obterUsuarioAtual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyCurrentUser);
    } catch (e) {
      return null;
    }
  }

  // Logout geral (limpa a sessão local e desconecta do Google)
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCurrentUser);
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
    }
  }
}