import 'package:flutter/material.dart';

class AppColors {
  // Cores Principais e de Destaque
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFFB74D);
  static const Color errorRed = Color(0xFFE53935);

  // Padrão Cinza Elegante para o Modo Escuro
  static const Color backgroundDark = Color(0xFF12161F);
  static const Color surfaceDark = Color(0xFF1E2530);
  static const Color borderDark = Color(0xFF2C3545);
  
  // Compatibilidade com nomes antigos para evitar erros nas telas
  static const Color borderLight = Color(0xFF2C3545); 
  static const Color backgroundLight = Color(0xFF12161F);

  // Cores de Texto de Alta Legibilidade
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textSub = Color(0xFFB0BEC5);
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF90A4AE); // Ajustado para cinza claro legível no escuro
}