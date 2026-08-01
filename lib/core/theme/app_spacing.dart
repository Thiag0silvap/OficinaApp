/// Escala de espaçamento base-4. Use SEMPRE estes valores para padding,
/// margin e gap. Nada de números mágicos (13, 22, 7...) nas telas.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Padding horizontal padrão de tela.
  static const double screen = 20;
}

/// Raios de borda. Campo < card < pílula(full).
class AppRadius {
  AppRadius._();

  static const double field = 12;
  static const double card = 18;
  static const double button = 12;
  static const double pill = 999;
}