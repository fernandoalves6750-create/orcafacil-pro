import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Substitua os caminhos relativos por imports absolutos do pacote:
import 'package:orcafacil_pro/core/services/cloud_backup_service.dart';
import 'package:orcafacil_pro/core/services/storage_service.dart';
import 'package:orcafacil_pro/core/services/empresa_service.dart';
import 'package:orcafacil_pro/core/services/client_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _keyIsLoggedIn = 'orcafacil_is_logged_in';
  static const String _keyUserEmail = 'orcafacil_user_email';
  static const String _keyUserName = 'orcafacil_user_name';
  static const String _keyUserPhoto = 'orcafacil_user_photo';
  static const String _keyRememberDevice = 'orcafacil_remember_device';

  static String? nomeUsuario;
  static String? emailUsuario;
  static String? fotoUsuario;
  static bool isLoggedIn = false;

  static String? get currentUid => _auth.currentUser?.uid;

  static Future<void> carregarSessao() async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    final bool lembrar = prefs.getBool(_keyRememberDevice) ?? false;

    if (user != null && lembrar) {
      isLoggedIn = true;
      emailUsuario = user.email;
      nomeUsuario = prefs.getString(_keyUserName) ?? user.displayName ?? 'Profissional';
      fotoUsuario = prefs.getString(_keyUserPhoto) ?? user.photoURL;
      
      await CloudBackupService.restaurarDaNuvem();
      await StorageService.carregarTudo();
      await EmpresaService.carregarEmpresa();
      await ClientService.carregarClientes();
    } else {
      if (!lembrar) {
        await _auth.signOut();
      }
      isLoggedIn = false;
      nomeUsuario = prefs.getString(_keyUserName);
      emailUsuario = prefs.getString(_keyUserEmail);
      fotoUsuario = prefs.getString(_keyUserPhoto);
    }
  }

  static Future<String?> cadastrarUsuario({
    required String email,
    required String senha,
    required String nomeEmpresa,
    bool lembrarDispositivo = true,
  }) async {
    if (email.isEmpty || senha.isEmpty || nomeEmpresa.isEmpty) {
      return 'Preencha todos os campos obrigatÃ³rios.';
    }
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        await _firestore.collection('usuarios').doc(uid).set({
          'email': email,
          'nomeEmpresa': nomeEmpresa,
          'criadoEm': FieldValue.serverTimestamp(),
        });
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyRememberDevice, lembrarDispositivo);
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserName, nomeEmpresa);
        await prefs.setString(_keyUserEmail, email);

        await CloudBackupService.fazerBackupNaNuvem();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Este e-mail jÃ¡ estÃ¡ a ser utilizado por outra conta.';
        case 'weak-password':
          return 'A senha Ã© muito fraca (mÃ­nimo de 6 caracteres).';
        case 'invalid-email':
          return 'O formato do e-mail Ã© invÃ¡lido.';
        default:
          return e.message ?? 'Erro ao criar conta.';
      }
    } catch (e) {
      return 'Ocorreu um erro inesperado: $e';
    }
  }

  static Future<String?> fazerLogin({
    required String email,
    required String senha,
    bool lembrarDispositivo = true,
  }) async {
    if (email.isEmpty || senha.isEmpty) {
      return 'Preencha o e-mail e a senha.';
    }
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final user = credential.user;
      if (user != null) {
        String nomeEncontrado = 'Profissional';
        try {
          DocumentSnapshot doc = await _firestore.collection('usuarios').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>;
            nomeEncontrado = data['nomeEmpresa'] ?? data['nome'] ?? 'Profissional';
          }
        } catch (_) {}

        nomeUsuario = nomeEncontrado;
        emailUsuario = user.email ?? email;
        fotoUsuario = user.photoURL;
        isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyRememberDevice, lembrarDispositivo);
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserName, nomeUsuario!);
        await prefs.setString(_keyUserEmail, emailUsuario!);
        if (fotoUsuario != null) {
          await prefs.setString(_keyUserPhoto, fotoUsuario!);
        } else {
          await prefs.remove(_keyUserPhoto);
        }

        await CloudBackupService.restaurarDaNuvem();
        await StorageService.carregarTudo();
        await EmpresaService.carregarEmpresa();
        await ClientService.carregarClientes();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Nenhum utilizador encontrado com este e-mail.';
        case 'wrong-password':
          return 'Senha incorreta. Verifique os dados.';
        case 'invalid-email':
          return 'O formato do e-mail Ã© invÃ¡lido.';
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';
        default:
          return e.message ?? 'Erro ao autenticar.';
      }
    } catch (e) {
      return 'Ocorreu um erro inesperado: $e';
    }
  }

  static Future<String?> fazerLoginComGoogle({bool lembrarDispositivo = true}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return 'Login com Google cancelado pelo utilizador.';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final uid = user.uid;
        
        DocumentReference userDocRef = _firestore.collection('usuarios').doc(uid);
        DocumentSnapshot doc = await userDocRef.get();

        String nomeEncontrado = user.displayName ?? 'Profissional';

        if (!doc.exists) {
          await userDocRef.set({
            'email': user.email ?? '',
            'nomeEmpresa': nomeEncontrado,
            'criadoEm': FieldValue.serverTimestamp(),
          });
        } else if (doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          nomeEncontrado = data['nomeEmpresa'] ?? data['nome'] ?? nomeEncontrado;
        }

        nomeUsuario = nomeEncontrado;
        emailUsuario = user.email;
        fotoUsuario = user.photoURL;
        isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyRememberDevice, lembrarDispositivo);
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserName, nomeUsuario!);
        if (emailUsuario != null) await prefs.setString(_keyUserEmail, emailUsuario!);
        if (fotoUsuario != null) {
          await prefs.setString(_keyUserPhoto, fotoUsuario!);
        } else {
          await prefs.remove(_keyUserPhoto);
        }

        await CloudBackupService.restaurarDaNuvem();
        await StorageService.carregarTudo();
        await EmpresaService.carregarEmpresa();
        await ClientService.carregarClientes();
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao autenticar com Google: $e');
      return 'Erro ao autenticar com o Google. Tente novamente.';
    }
  }

  static Future<bool> validarLogin(String email, String senha) async {
    String? erro = await fazerLogin(email: email, senha: senha);
    return erro == null;
  }

  static Future<void> signOut() async {
    await CloudBackupService.fazerBackupNaNuvem();

    await GoogleSignIn().signOut();
    await _auth.signOut();

    isLoggedIn = false;
    nomeUsuario = null;
    emailUsuario = null;
    fotoUsuario = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyRememberDevice);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPhoto);
  }
}
