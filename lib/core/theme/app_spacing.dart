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

/// Raios de borda ("Confiança Noturna" — Sprint 0). Campo < botão < card <
/// modal < pílula/avatar (full).
class AppRadius {
  AppRadius._();

  static const double field = 12;

  /// Handoff: 8–10px. Escolhido 10 (mesmo tom do handoff para o teto da
  /// faixa); ajuste se o design system tiver um valor mais específico.
  static const double card = 10;

  /// Handoff: 8–10px. Escolhido 8 (piso da faixa, levemente menor que card).
  static const double button = 8;

  /// Handoff: modais 14px.
  static const double modal = 14;

  /// Avatares/dots: totalmente arredondado (círculo).
  static const double pill = 999;
}