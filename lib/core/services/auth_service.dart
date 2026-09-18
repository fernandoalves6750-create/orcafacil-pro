import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'orcafacil_is_logged_in';
  static const String _keyUserEmail = 'orcafacil_user_email';
  static const String _keyUserName = 'orcafacil_user_name';
  static const String _keyUserPhoto = 'orcafacil_user_photo';

  static String? nomeUsuario;
  static String? emailUsuario;
  static String? fotoUsuario;
  static bool isLoggedIn = false;

  static Future<void> carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    nomeUsuario = prefs.getString(_keyUserName);
    emailUsuario = prefs.getString(_keyUserEmail);
    fotoUsuario = prefs.getString(_keyUserPhoto);
  }

  // 1. Cadastrar novo usuário (Email e Senha)
  static Future<bool> cadastrarUsuario(String email, String senha, String nome) async {
    if (email.isEmpty || senha.isEmpty || nome.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('pass_$email', senha);
    await prefs.setString('name_$email', nome);
    
    return true;
  }

  // 2. Validar Login com Email e Senha
  static Future<bool> validarLogin(String email, String senha) async {
    final prefs = await SharedPreferences.getInstance();
    final senhaSalva = prefs.getString('pass_$email');
    final nomeSalvo = prefs.getString('name_$email');

    if (senhaSalva != null && senhaSalva == senha) {
      nomeUsuario = nomeSalvo ?? 'Profissional';
      emailUsuario = email;
      fotoUsuario = null;
      isLoggedIn = true;

      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserName, nomeUsuario!);
      await prefs.setString(_keyUserEmail, emailUsuario!);
      await prefs.remove(_keyUserPhoto);
      return true;
    }
    return false;
  }

  // 3. Encerrar Sessão
  static Future<void> signOut() async {
    isLoggedIn = false;
    nomeUsuario = null;
    emailUsuario = null;
    fotoUsuario = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPhoto);
  }
}