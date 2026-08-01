# OficinaApp — Relatório de Estado do Projeto

> Gerado em 2026-07-31 para revisão de arquitetura por analista Flutter sênior. Coleta bruta, sem correções ou sugestões.

---

## 1. Estrutura do projeto (`lib/`)

`tree` não está instalado no ambiente; segue a árvore obtida via `find lib -type f | sort` (excluindo `*.g.dart`, dos quais não há nenhum no projeto):

```
lib
├── archive
│   ├── dashboard_screen_old_full.dart
│   ├── financeiro_screen_old.dart
│   ├── financeiro_screen_old_full.dart
│   ├── main_old_backup.dart
│   ├── main_old.dart
│   └── orcamentos_screen_old_full.dart
├── core
│   ├── components
│   │   ├── app_buttons.dart
│   │   ├── app_card.dart
│   │   ├── app_snackbar.dart
│   │   ├── attachment_widgets.dart
│   │   ├── cliente_form_dialog.dart
│   │   ├── common_widgets.dart
│   │   ├── form_styles.dart
│   │   ├── orcamento_form_dialog.dart
│   │   ├── responsive_components.dart
│   │   └── status_pill.dart
│   ├── constants
│   │   ├── app_constants.dart
│   │   └── app_version.dart
│   ├── theme
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── utils
│   │   ├── app_feedback.dart
│   │   ├── cnpj_input_formatter.dart
│   │   ├── currency_input_formatter.dart
│   │   ├── formatters.dart
│   │   ├── phone_input_formatter.dart
│   │   └── version_utils.dart
│   └── widgets
│       ├── app_logo.dart
│       ├── pdf_preview_dialog.dart
│       ├── skeletons.dart
│       ├── stat_card.dart
│       └── update_gate.dart
├── main.dart
├── models
│   ├── attachment.dart
│   ├── backup_manifest.dart
│   ├── cliente.dart
│   ├── empresa.dart
│   ├── nota.dart
│   ├── nota_servico.dart
│   ├── orcamento.dart
│   ├── ordem_servico.dart
│   ├── servico_item.dart
│   ├── transacao.dart
│   ├── user.dart
│   └── veiculo.dart
├── providers
│   ├── app_provider.dart
│   └── auth_provider.dart
├── screens
│   ├── clientes_screen.dart
│   ├── dashboard_screen.dart
│   ├── empresa_screen.dart
│   ├── financeiro_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── orcamentos_screen.dart
│   ├── order_detail_screen.dart
│   └── register_screen.dart
└── services
    ├── app_logger.dart
    ├── app_logger_io.dart
    ├── app_logger_web.dart
    ├── attachment_service.dart
    ├── attachment_service_io.dart
    ├── attachment_service_web.dart
    ├── auth_service.dart
    ├── db_service.dart
    ├── db_service_io.dart
    ├── db_service_web.dart
    ├── empresa_service.dart
    ├── pdf_file_service.dart
    ├── pdf_service.dart
    ├── secure_storage_service.dart
    ├── update_service.dart
    └── whatsapp_service.dart
```

**Nota de mapeamento de caminhos** (o pedido original referenciava `lib/theme/` e `lib/widgets/design_system/`; a estrutura real do projeto usa `lib/core/theme/` e `lib/core/components/`):

| Caminho pedido | Caminho real |
|---|---|
| `lib/theme/app_colors.dart` | `lib/core/theme/app_colors.dart` |
| `lib/theme/app_spacing.dart` | `lib/core/theme/app_spacing.dart` |
| `lib/theme/app_text_styles.dart` | `lib/core/theme/app_text_styles.dart` |
| `lib/theme/app_theme.dart` | `lib/core/theme/app_theme.dart` |
| `lib/widgets/design_system/` | `lib/core/components/` (status_pill.dart, app_buttons.dart, app_card.dart, app_snackbar.dart) |
| `lib/widgets/responsive_layout.dart` | `lib/core/components/responsive_components.dart` (classe `ResponsiveLayout`) |
| `lib/widgets/cliente_form_dialog.dart` | `lib/core/components/cliente_form_dialog.dart` |
| backup/restore service | Não existe arquivo dedicado — lógica embutida em `lib/services/db_service_io.dart` (seção `// ================= BACKUP =================`) |

---

## 2. Configuração

### `pubspec.yaml`

```yaml
name: oficina_app
description: "Sistema de gestão para oficinas automotivas - OficinaApp"
publish_to: 'none'

version: 1.0.4+11

environment:
  sdk: ^3.9.2

dependencies:
  flutter:
    sdk: flutter

  # UI & State
  cupertino_icons: ^1.0.8
  provider: ^6.1.2

  # Storage & Auth
  shared_preferences: ^2.1.0
  flutter_secure_storage: ^9.2.2

  # Banco de dados (mobile)
  sqflite: ^2.2.7+3
  path: ^1.8.3
  path_provider: ^2.0.14

  # Imagens e câmera
  image_picker: ^0.8.7+4
  flutter_image_compress: ^2.4.0

  # Assinatura
  signature: ^6.3.0

  # PDF e impressão
  pdf: ^3.10.1
  printing: ^5.10.0

  # Gráficos
  fl_chart: ^0.68.0

  # Utilitários
  intl: ^0.18.0
  crypto: ^3.0.2
  uuid: ^3.0.7
  url_launcher: ^6.3.0
  file_picker: ^8.1.7

  # Compartilhamento (novo — para backup e PDF via WhatsApp)
  share_plus: ^12.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.14.4
  # msix removido — exclusivo de Windows

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/fonts/

  fonts:
    - family: Work Sans
      fonts:
        - asset: assets/fonts/WorkSans-Regular.ttf
          weight: 400
        - asset: assets/fonts/WorkSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/WorkSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/WorkSans-Bold.ttf
          weight: 700
        - asset: assets/fonts/WorkSans-ExtraBold.ttf
          weight: 800

flutter_icons:
  android: true
  ios: true
  image_path: assets/images/logo.png

# msix_config removido — exclusivo de Windows
```

### `android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()

if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.funilaria.app_funilaria"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.funilaria.app_funilaria"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Se não houver key.properties, mantém assinatura debug para facilitar builds locais.
            // Para entregar ao cliente/Play Store, crie o keystore e configure key.properties.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
```

**Nota:** `namespace`/`applicationId` = `com.funilaria.app_funilaria` mas o label do app no `AndroidManifest.xml` é `"Grau Car"` — nomes de pacote e de marca divergentes (ver seção 11).

### `analysis_options.yaml`

```yaml
# This file configures the analyzer, which statically analyzes Dart code to
# check for errors, warnings, and lints.
#
# The issues identified by the analyzer are surfaced in the UI of Dart-enabled
# IDEs (https://dart.dev/tools#ides-and-editors). The analyzer can also be
# invoked from the command line by running `flutter analyze`.

# The following line activates a set of recommended lints for Flutter apps,
# packages, and plugins designed to encourage good coding practices.
include: package:flutter_lints/flutter.yaml

linter:
  # The lint rules applied to this project can be customized in the
  # section below to disable rules from the `package:flutter_lints/flutter.yaml`
  # included above or to enable additional rules. A list of all available lints
  # and their documentation is published at https://dart.dev/lints.
  #
  # Instead of disabling a lint rule for the entire project in the
  # section below, it can also be suppressed for a single line of code
  # or a specific dart file by using the `// ignore: name_of_lint` and
  # `// ignore_for_file: name_of_lint` syntax on the line or in the file
  # producing the lint.
  rules:
    # avoid_print: false  # Uncomment to disable the `avoid_print` rule
    # prefer_single_quotes: true  # Uncomment to enable the `prefer_single_quotes` rule

# Exclude archived/backup files from analysis to avoid noise from non-compilable
# snapshots stored under `lib/archive/`.
analyzer:
  exclude:
    - lib/archive/**
    - tool/_orcamento_form_dialog_prev.dart

# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options
```

---

## 3. Design system (Sprint 0)

### `lib/core/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

/// Paleta única do OficinaApp. NENHUM widget deve declarar cores soltas —
/// tudo referencia estes tokens. Isso garante consistência entre telas
/// (mobile e desktop) e permite ajuste global em um só lugar.
class AppColors {
  AppColors._();

  // ---------- Superfícies (camadas, do fundo para o topo) ----------
  /// Fundo base da tela.
  static const Color bg = Color(0xFF0A0A0B);

  /// Superfície de cards / campos.
  static const Color surface = Color(0xFF16171A);

  /// Superfície elevada (menus, chips, elementos sobre cards).
  static const Color elevated = Color(0xFF1E2024);

  /// Borda/divisor hairline (1px).
  static const Color line = Color(0xFF2A2C30);

  // ---------- Marca / ação ----------
  static const Color primary = Color(0xFFF5C518);
  static const Color primaryPressed = Color(0xFFD9AD12);

  /// Texto/ícone sobre superfície amarela (contraste alto).
  static const Color onPrimary = Color(0xFF0A0A0B);

  // ---------- Texto ----------
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA1A1A6);
  static const Color textTertiary = Color(0xFF6E6E73);

  // ---------- Semântico (USO EXCLUSIVO em status e valores) ----------
  static const Color success = Color(0xFF34C759); // concluído / entradas
  static const Color pending = Color(0xFFFF9F0A); // pendente
  static const Color info = Color(0xFF0A84FF); // aprovado
  static const Color danger = Color(0xFFFF453A); // excluir / saídas

  // ---------- Versões "tint" (fundo 12–14% para pílulas) ----------
  static const Color primaryTint = Color(0x24F5C518); // ~14%
  static const Color successTint = Color(0x2434C759);
  static const Color pendingTint = Color(0x1FFF9F0A); // ~12%
  static const Color infoTint = Color(0x240A84FF);
  static const Color dangerTint = Color(0x24FF453A);

  // ---------- Aliases de compatibilidade (telas pré-Sprint 0) ----------
  // As telas antigas ainda referenciam os nomes abaixo. Mantidos aqui para
  // não quebrar compilação; remover conforme cada tela for migrada para os
  // tokens novos acima.
  static const Color primaryYellow = primary;
  static const Color primaryDark = primaryPressed;
  static const Color secondaryGray = elevated;
  static const Color surface2 = elevated;
  static const Color lightGray = textTertiary;
  static const Color white = textPrimary;
  static const Color border = line;
  static const Color warning = pending;
  static const Color error = danger;
}
```

### `lib/core/theme/app_spacing.dart`

```dart
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
```

### `lib/core/theme/app_text_styles.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Escala tipográfica. Uma família só (Work Sans, declarada no pubspec com os
/// pesos 400/500/600/700/800). Pesos e tamanhos são intencionais; não invente
/// variações nas telas.
class AppText {
  AppText._();

  static const String _family = 'Work Sans';

  /// Título grande de tela ("Orçamentos", "Clientes").
  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Título de card / seção.
  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Valor monetário em destaque.
  static const TextStyle money = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Corpo padrão.
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Texto secundário (metadados, subtítulos).
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Texto de botão.
  static const TextStyle button = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// Rótulo pequeno / caption.
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
  );

  /// Micro-label uppercase (eyebrows de seção).
  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textTertiary,
  );
}
```

### `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

/// Tema único do app. Aplicado via `MaterialApp(theme: AppTheme.dark)`.
///
/// IMPORTANTE (desktop-first): isto substitui APENAS a aparência. Nenhuma
/// regra de negócio muda. Desktop e mobile compartilham o mesmo tema, então
/// aplicar aqui já unifica as duas plataformas sem regressão de lógica.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.primary,
        error: AppColors.danger,
        onSurface: AppColors.textPrimary,
      ),

      // ---------- AppBar ----------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // ---------- Cards ----------
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),

      // ---------- Campos ----------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        // Um rótulo só: usamos label flutuante e NÃO hint ao mesmo tempo,
        // evitando a sobreposição de textos vista no formulário de orçamento.
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppText.body.copyWith(color: AppColors.textTertiary),
        labelStyle: AppText.bodySecondary,
        floatingLabelStyle: AppText.caption.copyWith(color: AppColors.primary),
        border: _fieldBorder(AppColors.line),
        enabledBorder: _fieldBorder(AppColors.line),
        focusedBorder: _fieldBorder(AppColors.primary, width: 1.5),
        errorBorder: _fieldBorder(AppColors.danger),
        focusedErrorBorder: _fieldBorder(AppColors.danger, width: 1.5),
        errorStyle: AppText.caption.copyWith(color: AppColors.danger),
      ),

      // ---------- Bottom navigation ----------
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
      ),

      // ---------- Divisores ----------
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),

      // ---------- SnackBar (padrão neutro; cor por tipo vem via helper) ----------
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.elevated,
        contentTextStyle: AppText.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          side: const BorderSide(color: AppColors.line),
        ),
      ),

      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
```

### `lib/core/components/status_pill.dart`

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Estados de um orçamento/OS. Mapeados 1:1 para cor + rótulo, para que
/// nenhuma tela precise decidir cor de status manualmente.
enum AppStatus { pendente, aprovado, emAndamento, concluido, cancelado }

extension AppStatusStyle on AppStatus {
  Color get color => switch (this) {
        AppStatus.pendente => AppColors.pending,
        AppStatus.aprovado => AppColors.info,
        AppStatus.emAndamento => AppColors.primary,
        AppStatus.concluido => AppColors.success,
        AppStatus.cancelado => AppColors.danger,
      };

  Color get tint => switch (this) {
        AppStatus.pendente => AppColors.pendingTint,
        AppStatus.aprovado => AppColors.infoTint,
        AppStatus.emAndamento => AppColors.primaryTint,
        AppStatus.concluido => AppColors.successTint,
        AppStatus.cancelado => AppColors.dangerTint,
      };

  String get label => switch (this) {
        AppStatus.pendente => 'Pendente',
        AppStatus.aprovado => 'Aprovado',
        AppStatus.emAndamento => 'Em andamento',
        AppStatus.concluido => 'Concluído',
        AppStatus.cancelado => 'Cancelado',
      };
}

/// Pílula de status. Fundo tint + texto na cor cheia — legível e discreta.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}
```

### `lib/core/components/app_buttons.dart`

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Ação PRIMÁRIA. Amarelo preenchido, texto preto. Regra: uma por tela/card.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.onPrimary),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(label, style: AppText.button.copyWith(color: AppColors.onPrimary)),
      ],
    );

    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 13,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Ação SECUNDÁRIA. Transparente + borda hairline. Nunca colorida por status.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 13,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppText.button.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão só-ícone contido (ex.: menu ⋮). Mesma linguagem do ghost.
class GhostIconButton extends StatelessWidget {
  const GhostIconButton({super.key, required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
```

### `lib/core/components/app_card.dart`

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Container padrão de conteúdo: superfície + borda hairline + raio de card.
/// Sem sombra — profundidade vem da camada de cor, não de blur.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: content,
      ),
    );
  }
}

/// Cabeçalho de seção com micro-label opcional.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.eyebrow, this.trailing});

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow!.toUpperCase(), style: AppText.label),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(title, style: AppText.title),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Placa em fonte mono, uppercase — trata a placa como dado, não texto solto.
class PlateChip extends StatelessWidget {
  const PlateChip(this.plate, {super.key});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        plate.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
```

### `lib/core/components/app_snackbar.dart`

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Feedback padronizado. Substitui os SnackBars verdes full-width por um
/// componente flutuante consistente, com cor apenas na barra lateral/ícone.
enum SnackType { success, error, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.info,
  }) {
    final (color, icon) = switch (type) {
      SnackType.success => (AppColors.success, Icons.check_circle_outline),
      SnackType.error => (AppColors.danger, Icons.error_outline),
      SnackType.info => (AppColors.primary, Icons.info_outline),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message, style: AppText.body)),
            ],
          ),
          backgroundColor: AppColors.elevated,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
        ),
      );
  }
}
```

**Observação:** o design system novo (Sprint 0/1: `AppColors` com tokens semânticos, `StatusPill`, `AppCard`, `PrimaryButton`/`GhostButton`, `AppSnackbar`) coexiste com os aliases legados (`primaryYellow`, `secondaryGray`, etc.) e com o componente pré-existente `ResponsiveDialog`/`ResponsiveListCard` (em `responsive_components.dart`), que ainda usa exclusivamente os aliases antigos. Ver seção 8.

---

## 4. Telas já migradas/redesenhadas

### `lib/screens/dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/utils/formatters.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transacao.dart';
import 'clientes_screen.dart';
import 'financeiro_screen.dart';
import 'orcamentos_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final faturamento = provider.entradasMesAtual;
        final faturamentoAnterior = provider.entradasMesAnterior;
        final faturamentoVar = provider.percentageChange(
          faturamento,
          faturamentoAnterior,
        );

        final ordensAtivas = provider.orcamentosEmAndamento.length;
        final concluidosHoje = provider.orcamentosConcluidos.where((o) {
          if (o.dataConclusao == null) return false;
          final now = DateTime.now();
          return o.dataConclusao!.day == now.day &&
              o.dataConclusao!.month == now.month &&
              o.dataConclusao!.year == now.year;
        }).length;

        final pendentes = provider.orcamentosPendentes.length;

        return ResponsiveContainer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final spacing = ResponsiveUtils.getCardSpacing(context);
              final isMobile = ResponsiveUtils.isMobile(context);

              // Limita a largura máxima dos cards para evitar ficar “gigante”
              // quando o app estiver em uma largura intermediária.
              final maxCardWidth =
                  isMobile ? (constraints.maxWidth / 2) - 8 : 290.0;

              // Altura estável dos stat cards (evita RenderFlex overflow).
              const statCardHeight = 112.0;

              final statCards = <Widget>[
                _buildStatCard(
                  context,
                  title: 'Faturamento Mensal',
                  value: Formatters.currency(faturamento),
                  icon: Icons.monetization_on,
                  trend: faturamentoVar['label'],
                  trendUp: faturamentoVar['up'] ?? true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: AppColors.surface,
                          automaticallyImplyLeading: true,
                          title: const Text('Financeiro'),
                        ),
                        body: const FinanceiroScreen(),
                      ),
                    ),
                  ),
                ),
                _buildStatCard(
                  context,
                  title: 'Ordens Ativas',
                  value: ordensAtivas.toString(),
                  icon: Icons.build_circle,
                ),
                _buildStatCard(
                  context,
                  title: 'Concluídos Hoje',
                  value: concluidosHoje.toString(),
                  icon: Icons.check_circle,
                ),
                _buildStatCard(
                  context,
                  title: 'Pendentes',
                  value: pendentes.toString(),
                  icon: Icons.pending_actions,
                ),
              ];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      context,
                      ordensAtivas: ordensAtivas,
                      pendentes: pendentes,
                      concluidosHoje: concluidosHoje,
                    ),

                    SizedBox(height: spacing),

                    /// ======= CARDS (GRID ALINHADO) =======
                    GridView.builder(
                      itemCount: statCards.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxCardWidth,
                        mainAxisExtent: statCardHeight,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                      ),
                      itemBuilder: (context, index) => statCards[index],
                    ),

                    SizedBox(height: spacing * 1.5),

                    /// ======= INSIGHTS (CHART + RESUMO) =======
                    _buildInsights(context, provider, spacing: spacing),

                    SizedBox(height: spacing * 2),

                    /// ======= ORDENS + AGENDA =======
                    isMobile
                        ? Column(
                            children: [
                              _buildRecentOrders(context, provider),
                              SizedBox(height: spacing),
                              _buildSchedule(context, provider),
                            ],
                          )
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildRecentOrders(context, provider),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: _buildSchedule(context, provider),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// ================= INSIGHTS =================
  Widget _buildInsights(
    BuildContext context,
    AppProvider provider, {
    required double spacing,
  }) {
    final isMobile = ResponsiveUtils.isMobile(context);

    final months = _lastMonths(6);
    final entradas = months
        .map((m) => _sumTransacoesMes(provider, m, TipoTransacao.entrada))
        .toList();
    final saidas = months
        .map((m) => _sumTransacoesMes(provider, m, TipoTransacao.saida))
        .toList();

    final now = DateTime.now();
    final entradasHoje = provider.transacoes
        .where(
          (t) =>
              t.tipo == TipoTransacao.entrada &&
              t.data.day == now.day &&
              t.data.month == now.month &&
              t.data.year == now.year,
        )
        .fold<double>(0, (s, t) => s + t.valor);
    final saidasHoje = provider.transacoes
        .where(
          (t) =>
              t.tipo == TipoTransacao.saida &&
              t.data.day == now.day &&
              t.data.month == now.month &&
              t.data.year == now.year,
        )
        .fold<double>(0, (s, t) => s + t.valor);

    final saldoHoje = entradasHoje - saidasHoje;

    final chart = _sectionContainer(
      title: 'Evolução de Faturamento',
      child: SizedBox(
        height: isMobile ? 180 : 260,
        child: _buildLineChart(
          context,
          months: months,
          entradas: entradas,
          saidas: saidas,
        ),
      ),
    );

    final resumo = _sectionContainer(
      title: 'Resumo Diário',
      child: Column(
        children: [
          _buildMiniMetricRow(
            context,
            label: 'Entradas hoje',
            value: Formatters.currency(entradasHoje),
            icon: Icons.trending_up,
            iconColor: AppColors.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMiniMetricRow(
            context,
            label: 'Saídas hoje',
            value: Formatters.currency(saidasHoje),
            icon: Icons.trending_down,
            iconColor: AppColors.danger,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMiniMetricRow(
            context,
            label: 'Saldo do dia',
            value: Formatters.currency(saldoHoje),
            icon: Icons.account_balance_wallet,
            iconColor: saldoHoje >= 0 ? AppColors.success : AppColors.danger,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Botão principal amarelo + atalhos embaixo.
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: AppColors.surface,
                          automaticallyImplyLeading: true,
                          title: const Text('Orçamentos'),
                        ),
                        body: const OrcamentosScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Orçamento'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: AppColors.surface,
                          automaticallyImplyLeading: true,
                          title: const Text('Clientes'),
                        ),
                        body: const ClientesScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.people_alt),
                  label: const Text('Clientes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: AppColors.surface,
                          automaticallyImplyLeading: true,
                          title: const Text('Financeiro'),
                        ),
                        body: const FinanceiroScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Financeiro'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          chart,
          SizedBox(height: spacing),
          resumo,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: chart),
        SizedBox(width: spacing),
        Expanded(child: resumo),
      ],
    );
  }

  Widget _buildMiniMetricRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppText.bodySecondary.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(value, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(
    BuildContext context, {
    required List<DateTime> months,
    required List<double> entradas,
    required List<double> saidas,
  }) {
    final maxY = <double>[
      ...entradas,
      ...saidas,
    ].fold<double>(0, (m, v) => v > m ? v : m);
    final double safeMaxY = maxY <= 0 ? 100.0 : (maxY * 1.2);

    List<FlSpot> spotsFrom(List<double> values) {
      return List.generate(
        values.length,
        (i) => FlSpot(i.toDouble(), values[i]),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (months.length - 1).toDouble(),
        minY: 0,
        maxY: safeMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeMaxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.line, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: safeMaxY / 4,
              // Rótulo curto e de linha única: sem prefixo "R$" (o título do
              // card já dá o contexto) e compactado. Corrige a quebra de linha.
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _compactAxis(value),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= months.length) {
                  return const SizedBox.shrink();
                }
                final d = months[i];
                final label =
                    '${_monthShort(d.month)}/${(d.year % 100).toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spotsFrom(entradas),
            isCurved: true,
            barWidth: 3,
            color: AppColors.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          LineChartBarData(
            spots: spotsFrom(saidas),
            isCurved: true,
            barWidth: 2,
            color: AppColors.danger.withValues(alpha: 0.85),
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.danger.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  /// Formata o rótulo do eixo Y de forma curta e em linha única.
  String _compactAxis(double v) {
    if (v <= 0) return '0';
    if (v >= 1000000) {
      final n = v / 1000000;
      return '${n.toStringAsFixed(n % 1 == 0 ? 0 : 1).replaceAll('.', ',')}M';
    }
    if (v >= 1000) {
      final n = v / 1000;
      return '${n.toStringAsFixed(n % 1 == 0 ? 0 : 1).replaceAll('.', ',')}k';
    }
    return v.toStringAsFixed(0);
  }

  List<DateTime> _lastMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = DateTime(now.year, now.month - (count - 1 - i), 1);
      return d;
    });
  }

  double _sumTransacoesMes(
    AppProvider provider,
    DateTime month,
    TipoTransacao tipo,
  ) {
    return provider.transacoes
        .where(
          (t) =>
              t.tipo == tipo &&
              t.data.month == month.month &&
              t.data.year == month.year,
        )
        .fold<double>(0, (s, t) => s + t.valor);
  }

  String _monthShort(int month) {
    const m = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    if (month < 1 || month > 12) return '';
    return m[month - 1];
  }

  /// ================= HEADER =================
  Widget _buildHeader(
    BuildContext context, {
    required int ordensAtivas,
    required int pendentes,
    required int concluidosHoje,
  }) {
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.name.trim() ?? '';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: AppText.display.copyWith(fontSize: 26)),
                const SizedBox(height: 2),
                Text(
                  'Visão geral da sua oficina hoje',
                  style: AppText.bodySecondary,
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 18,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: AppText.display),
              const SizedBox(height: 6),
              Text(
                'Visão geral da sua oficina hoje',
                style: AppText.bodySecondary,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 44,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.04),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 14,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    name.isNotEmpty ? name.split(' ').first : 'Admin',
                    style: AppText.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ================= CARD ESTATÍSTICA =================
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    String? trend,
    bool trendUp = true,
    VoidCallback? onTap,
  }) {
    bool hover = false;

    return StatefulBuilder(
      builder: (ctx, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => hover = true),
          onExit: (_) => setState(() => hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.identity()
              ..scaleByDouble(
                hover ? 1.02 : 1.0,
                hover ? 1.02 : 1.0,
                1.0,
                1.0,
              ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Ink(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.line, width: 1),
                    boxShadow: hover
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Ícone monocromático em caixa neutra (sem arco-íris).
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.elevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                          if (trend != null) ...[
                            const Spacer(),
                            _TrendPill(label: trend, up: trendUp),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySecondary.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.money.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ================= ORDENS RECENTES =================
  Widget _buildRecentOrders(BuildContext context, AppProvider provider) {
    final orders = provider.orcamentos.take(5).toList();

    return _sectionContainer(
      title: 'Ordens Recentes',
      child: orders.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Nenhuma ordem recente',
                style: AppText.bodySecondary,
              ),
            )
          : Column(
              children: orders
                  .map(
                    (o) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: ListTile(
                        title: Text(
                          o.clienteNome,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          o.veiculoDescricao,
                          style: AppText.bodySecondary,
                        ),
                        trailing: Text(
                          Formatters.currency(o.valorTotal),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  /// ================= AGENDA =================
  Widget _buildSchedule(BuildContext context, AppProvider provider) {
    final pendentes = provider.orcamentosPendentes.take(3).toList();

    return _sectionContainer(
      title: 'Próximos Agendamentos',
      child: pendentes.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Sem agendamentos', style: AppText.bodySecondary),
            )
          : Column(
              children: pendentes
                  .map(
                    (o) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.calendar_today,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        title: Text(
                          o.clienteNome,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          o.veiculoDescricao,
                          style: AppText.bodySecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  /// ================= CONTAINER PADRÃO =================
  Widget _sectionContainer({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppText.title)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Pílula de tendência (variação % vs. mês anterior). Único ponto de cor
/// semântica dos stat cards — é um indicador de valor, uso permitido.
class _TrendPill extends StatelessWidget {
  final String label;
  final bool up;
  const _TrendPill({required this.label, required this.up});

  @override
  Widget build(BuildContext context) {
    final color = up ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

### `lib/screens/orcamentos_screen.dart` (contém `_OrcamentoMobileCard` e `_OrcamentoPremiumCard`) — parte 1/2

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/common_widgets.dart';
import '../core/components/orcamento_form_dialog.dart';
// Sprint 1 — componentes do design system (mobile).
import '../core/components/app_card.dart';
import '../core/components/status_pill.dart';
import '../core/components/app_buttons.dart';
import '../core/components/app_snackbar.dart';
import '../core/utils/formatters.dart';
import '../providers/app_provider.dart';
import '../models/orcamento.dart';
import '../services/pdf_service.dart';
import '../services/pdf_file_service.dart';
import '../services/whatsapp_service.dart';
import '../core/widgets/pdf_preview_dialog.dart';
import 'order_detail_screen.dart';

class OrcamentosScreen extends StatefulWidget {
  const OrcamentosScreen({super.key});

  @override
  State<OrcamentosScreen> createState() => _OrcamentosScreenState();
}

enum _OrcSort { recent, valorDesc, valorAsc, nomeAZ }

class _OrcamentosScreenState extends State<OrcamentosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  _OrcSort _sort = _OrcSort.recent;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateOrcamentoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OrcamentoFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderWithAction(
                title: 'Orçamentos',
                onAdd: () => _showCreateOrcamentoDialog(context),
                addLabelLong: 'Novo Orçamento',
                addLabelShort: 'Novo',
              ),
              SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
              _OrcToolbar(
                isMobile: isMobile,
                controller: _searchCtrl,
                sort: _sort,
                totalCount: provider.orcamentos.length,
                onSortChanged: (v) => setState(() => _sort = v),
                onClearSearch: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      _PremiumTabBar(isDesktop: isDesktop),
                      const SizedBox(height: 14),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildOrcamentosList(
                              context,
                              _applyQueryAndSort(
                                provider.orcamentosPendentes,
                                query: _searchCtrl.text,
                                sort: _sort,
                              ),
                            ),
                            _buildOrcamentosList(
                              context,
                              _applyQueryAndSort(
                                provider.orcamentosAprovados,
                                query: _searchCtrl.text,
                                sort: _sort,
                              ),
                            ),
                            _buildOrcamentosList(
                              context,
                              _applyQueryAndSort(
                                provider.orcamentosEmAndamento,
                                query: _searchCtrl.text,
                                sort: _sort,
                              ),
                            ),
                            _buildOrcamentosList(
                              context,
                              _applyQueryAndSort(
                                provider.orcamentosConcluidos,
                                query: _searchCtrl.text,
                                sort: _sort,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Orcamento> _applyQueryAndSort(
    List<Orcamento> src, {
    required String query,
    required _OrcSort sort,
  }) {
    final q = query.trim().toLowerCase();
    var list = src;

    if (q.isNotEmpty) {
      list = list.where((o) {
        final a = o.clienteNome.toLowerCase();
        final b = o.veiculoDescricao.toLowerCase();
        final c = o.id.toString();
        return a.contains(q) || b.contains(q) || c.contains(q);
      }).toList();
    } else {
      list = List<Orcamento>.from(list);
    }

    switch (sort) {
      case _OrcSort.recent:
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case _OrcSort.valorDesc:
        list.sort((a, b) => b.valorTotal.compareTo(a.valorTotal));
        break;
      case _OrcSort.valorAsc:
        list.sort((a, b) => a.valorTotal.compareTo(b.valorTotal));
        break;
      case _OrcSort.nomeAZ:
        list.sort(
          (a, b) => a.clienteNome.toLowerCase().compareTo(
            b.clienteNome.toLowerCase(),
          ),
        );
        break;
    }

    return list;
  }

  Widget _buildOrcamentosList(
    BuildContext context,
    List<Orcamento> orcamentos,
  ) {
    if (orcamentos.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.description_outlined,
        title: _searchCtrl.text.trim().isEmpty
            ? 'Nenhum orçamento nesta categoria'
            : 'Nenhum resultado para a busca',
        subtitle: _searchCtrl.text.trim().isEmpty
            ? ''
            : 'Tente mudar os filtros ou limpar a pesquisa.',
        actionLabel: _searchCtrl.text.trim().isEmpty
            ? 'Novo Orçamento'
            : 'Limpar pesquisa',
        onAction: () {
          if (_searchCtrl.text.trim().isEmpty) {
            _showCreateOrcamentoDialog(context);
          } else {
            _searchCtrl.clear();
            setState(() {});
          }
        },
      );
    }

    final isMobile = ResponsiveUtils.isMobile(context);

    return ListView.separated(
      itemCount: orcamentos.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
      itemBuilder: (context, index) {
        final orcamento = orcamentos[index];

        Future<void> onEdit() async {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => OrcamentoFormDialog(orcamentoEditar: orcamento),
          );
        }

        // Mobile: card redesenhado (design system). Desktop: card atual intacto.
        if (isMobile) {
          return _OrcamentoMobileCard(
            orcamento: orcamento,
            onOpen: () => _openDetails(context, orcamento),
            onEdit: onEdit,
          );
        }

        return _OrcamentoPremiumCard(
          orcamento: orcamento,
          onOpen: () => _openDetails(context, orcamento),
          onEdit: onEdit,
        );
      },
    );
  }

  void _openDetails(BuildContext context, Orcamento orcamento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orcamento: orcamento),
      ),
    );
  }
}

// ===========================================================================
// SPRINT 1 — CARD MOBILE (novo, baseado no design system)
// ===========================================================================

/// Mapeia o status de domínio para o status visual do design system.
AppStatus _toAppStatus(OrcamentoStatus s) {
  switch (s) {
    case OrcamentoStatus.pendente:
      return AppStatus.pendente;
    case OrcamentoStatus.aprovado:
      return AppStatus.aprovado;
    case OrcamentoStatus.emAndamento:
      return AppStatus.emAndamento;
    case OrcamentoStatus.concluido:
      return AppStatus.concluido;
    case OrcamentoStatus.cancelado:
      return AppStatus.cancelado;
  }
}

/// Descreve a ação primária (amarela) de um card conforme o status.
class _PrimaryAction {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;
  const _PrimaryAction(this.label, this.icon, this.onTap);
}

class _OrcamentoMobileCard extends StatelessWidget {
  final Orcamento orcamento;
  final VoidCallback onOpen;
  final Future<void> Function() onEdit;

  const _OrcamentoMobileCard({
    required this.orcamento,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final primary = _resolvePrimary(context, provider);

    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: cliente + veículo à esquerda, status à direita.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orcamento.clienteNome,
                      style: AppText.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // veiculoDescricao já inclui a placa; PlateChip entra quando
                    // o model expuser a placa isolada.
                    Text(
                      orcamento.veiculoDescricao,
                      style: AppText.bodySecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              StatusPill(_toAppStatus(orcamento.status)),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Valor.
          Text(Formatters.currency(orcamento.valorTotal), style: AppText.money),

          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Linha de ações: primária (amarela) + PDF (ghost) + menu.
          Row(
            children: [
              if (primary != null) ...[
                Expanded(
                  child: PrimaryButton(
                    label: primary.label,
                    icon: primary.icon,
                    expanded: true,
                    onPressed: () => primary.onTap(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GhostButton(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () =>
                      _OrcamentoActions.pdfWhatsapp(context, provider, orcamento),
                ),
              ] else ...[
                GhostButton(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () =>
                      _OrcamentoActions.pdfWhatsapp(context, provider, orcamento),
                ),
                const Spacer(),
              ],
              const SizedBox(width: AppSpacing.sm),
              _buildMenu(context, provider),
            ],
          ),
        ],
      ),
    );
  }

  /// Ação primária por status (mesma posição, sempre amarela).
  _PrimaryAction? _resolvePrimary(BuildContext context, AppProvider provider) {
    switch (orcamento.status) {
      case OrcamentoStatus.pendente:
        return _PrimaryAction(
          'Aprovar',
          Icons.check,
          () => _OrcamentoActions.aprovar(context, provider, orcamento),
        );
      case OrcamentoStatus.aprovado:
        return _PrimaryAction(
          'Iniciar',
          Icons.play_arrow,
          () => _OrcamentoActions.iniciar(context, provider, orcamento),
        );
      case OrcamentoStatus.emAndamento:
        return _PrimaryAction(
          'Concluir',
          Icons.done,
          () => _OrcamentoActions.concluir(context, provider, orcamento),
        );
      case OrcamentoStatus.concluido:
        if (!orcamento.pago) {
          return _PrimaryAction(
            'Receber',
            Icons.attach_money,
            () => _OrcamentoActions.receber(context, provider, orcamento),
          );
        }
        return null;
      case OrcamentoStatus.cancelado:
        return null;
    }
  }

  Widget _buildMenu(BuildContext context, AppProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
      color: AppColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        side: const BorderSide(color: AppColors.line),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'editar':
            await onEdit();
            break;
          case 'imprimir':
            await _OrcamentoActions.imprimir(context, orcamento);
            break;
          case 'cancelar':
            await _OrcamentoActions.cancelar(context, provider, orcamento);
            break;
          case 'excluir':
            await _OrcamentoActions.excluir(context, provider, orcamento);
            break;
        }
      },
      itemBuilder: (_) => [
        if (orcamento.status == OrcamentoStatus.pendente)
          const PopupMenuItem(
            value: 'editar',
            child: Row(children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Editar'),
            ]),
          ),
        const PopupMenuItem(
          value: 'imprimir',
          child: Row(children: [
            Icon(Icons.print, size: 18),
            SizedBox(width: 8),
            Text('Imprimir'),
          ]),
        ),
        if (orcamento.status == OrcamentoStatus.pendente)
          const PopupMenuItem(
            value: 'cancelar',
            child: Row(children: [
              Icon(Icons.cancel, size: 18),
              SizedBox(width: 8),
              Text('Cancelar'),
            ]),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'excluir',
          child: Row(children: [
            const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
            const SizedBox(width: 8),
            Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ]),
        ),
      ],
    );
  }
}

/// Ações de negócio dos orçamentos — fonte única de verdade para o card mobile.
/// (O card desktop mantém suas chamadas inline até ser migrado.)
class _OrcamentoActions {
  const _OrcamentoActions._();

  static Future<void> aprovar(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.aprovarOrcamento(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Orçamento aprovado!', type: SnackType.success);
  }

  static Future<void> iniciar(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.iniciarServico(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Serviço iniciado!', type: SnackType.success);
  }

  static Future<void> concluir(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.concluirOrcamento(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Serviço concluído! Pagamento pendente.',
        type: SnackType.success);
  }

  static Future<void> receber(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.registrarPagamento(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Pagamento registrado!', type: SnackType.success);
  }

  static Future<void> cancelar(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.cancelarOrcamento(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Orçamento cancelado!', type: SnackType.info);
  }

  static Future<void> imprimir(BuildContext context, Orcamento o) async {
    final filename = PDFService.buildPdfFilename(o);
    final title =
        o.status == OrcamentoStatus.concluido ? 'Nota de Serviço' : 'Orçamento';
    await showPdfPreviewDialog(
      context,
      title: title,
      fileName: filename,
      buildPdf: (_) => PDFService.generateOrcamentoPdf(o),
    );
  }

  static Future<void> excluir(
      BuildContext context, AppProvider provider, Orcamento o) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir orçamento?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      await provider.deleteOrcamento(o.id);
      if (!context.mounted) return;
      AppSnackbar.show(context, 'Orçamento excluído', type: SnackType.error);
    }
  }

  /// Gera PDF e abre o WhatsApp. Lógica preservada da versão original;
  /// o tratamento amigável do PlatformException fica para a Sprint 5.
  static Future<void> pdfWhatsapp(
      BuildContext context, AppProvider provider, Orcamento o) async {
    try {
      final cliente = provider.getClienteById(o.clienteId);
      if (cliente == null || cliente.telefone.trim().isEmpty) {
        if (!context.mounted) return;
        AppSnackbar.show(context, 'Cliente sem telefone cadastrado.',
            type: SnackType.info);
        return;
      }
      final bytes = await PDFService.generateOrcamentoPdf(o);
      final filename = PDFService.buildPdfFilename(o);
      final savedPath = await PdfFileService.savePdfToUserFolder(
        bytes: bytes,
        filename: filename,
      );
      final mensagem =
          'Olá ${o.clienteNome}, segue seu orçamento referente ao veículo '
          '${o.veiculoDescricao}.';
      await PdfFileService.openFileFolder(savedPath);
      await WhatsAppService.openChat(
        phone: cliente.telefone,
        message: mensagem,
      );
      if (!context.mounted) return;
      AppSnackbar.show(context, 'PDF gerado! Escolha o app para compartilhar.',
          type: SnackType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(context, 'Erro ao preparar envio: $e',
          type: SnackType.error);
    }
  }
}
```

### `lib/screens/orcamentos_screen.dart` — parte 2/2 (toolbar desktop + `_OrcamentoPremiumCard`)

```dart
// ===========================================================================
// DESKTOP + TOOLBAR — inalterados nesta sprint (exceto correção do typo).
// ===========================================================================

class _PremiumTabBar extends StatelessWidget {
  final bool isDesktop;
  const _PremiumTabBar({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.secondaryGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: TabBar(
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
          isScrollable: !isDesktop,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: AppColors.primaryYellow.withValues(alpha: 0.95),
              width: 3,
            ),
            insets: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          ),
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Aprovados'),
            Tab(text: 'Em Andamento'),
            Tab(text: 'Concluídos'),
          ],
        ),
      ),
    );
  }
}

class _OrcToolbar extends StatelessWidget {
  final bool isMobile;
  final TextEditingController controller;
  final _OrcSort sort;
  final int totalCount;
  final ValueChanged<_OrcSort> onSortChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onChanged;

  const _OrcToolbar({
    required this.isMobile,
    required this.controller,
    required this.sort,
    required this.totalCount,
    required this.onSortChanged,
    required this.onClearSearch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Correção do typo: 'orcamento' -> 'orçamento'.
    final countLabel =
        '$totalCount ${totalCount == 1 ? 'orçamento' : 'orçamentos'}';

    if (isMobile) {
      return Column(
        children: [
          _SearchField(
            controller: controller,
            hint: 'Buscar por cliente, veículo ou ID...',
            onChanged: onChanged,
            onClear: onClearSearch,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ToolbarSelect<_OrcSort>(
                  value: sort,
                  items: const {
                    _OrcSort.recent: 'Recentes',
                    _OrcSort.valorDesc: 'Maior valor',
                    _OrcSort.valorAsc: 'Menor valor',
                    _OrcSort.nomeAZ: 'Nome A–Z',
                  },
                  icon: Icons.sort,
                  onChanged: onSortChanged,
                ),
              ),
              const SizedBox(width: 12),
              _CountChip(label: countLabel),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _SearchField(
            controller: controller,
            hint: 'Buscar por cliente, veículo ou ID…',
            onChanged: onChanged,
            onClear: onClearSearch,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180,
          child: _ToolbarSelect<_OrcSort>(
            value: sort,
            items: const {
              _OrcSort.recent: 'Recentes',
              _OrcSort.valorDesc: 'Maior valor',
              _OrcSort.valorAsc: 'Menor valor',
              _OrcSort.nomeAZ: 'Nome A–Z',
            },
            icon: Icons.sort,
            onChanged: onSortChanged,
          ),
        ),
        const SizedBox(width: 12),
        _CountChip(label: countLabel),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty)
            IconButton(
              tooltip: 'Limpar',
              onPressed: onClear,
              icon: Icon(
                Icons.close,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolbarSelect<T> extends StatelessWidget {
  final T value;
  final Map<T, String> items;
  final IconData icon;
  final ValueChanged<T> onChanged;

  const _ToolbarSelect({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          dropdownColor: AppColors.secondaryGray,
          icon: Icon(
            Icons.expand_more,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
          items: items.entries
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        e.value,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  const _CountChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrcamentoPremiumCard extends StatelessWidget {
  final Orcamento orcamento;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const _OrcamentoPremiumCard({
    required this.orcamento,
    required this.onOpen,
    required this.onEdit,
  });

  Color _statusColor(OrcamentoStatus status) {
    switch (status) {
      case OrcamentoStatus.pendente:
        return AppColors.warning;
      case OrcamentoStatus.aprovado:
        return AppColors.info;
      case OrcamentoStatus.emAndamento:
        return AppColors.primaryYellow;
      case OrcamentoStatus.concluido:
        return AppColors.success;
      case OrcamentoStatus.cancelado:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(orcamento.status);

    return ResponsiveListCard(
      title: orcamento.clienteNome,
      subtitle: orcamento.veiculoDescricao,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusPill(
            text: orcamento.statusDescricao,
            color: statusColor,
            suffixIcon:
                (orcamento.status == OrcamentoStatus.concluido && orcamento.pago)
                ? Icons.verified
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(orcamento.valorTotal),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
      onTap: onOpen,
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final List<Widget> actions = [];

    // Ação principal por status
    switch (orcamento.status) {
      case OrcamentoStatus.pendente:
        actions.addAll([
          _ActionPill(
            icon: Icons.check,
            label: 'Aprovar',
            tone: _ActionTone.success,
            filled: true,
            onPressed: () async {
              await provider.aprovarOrcamento(orcamento.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Orçamento aprovado!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
          if (!isMobile)
            _ActionPill(
              icon: Icons.edit,
              label: 'Editar',
              tone: _ActionTone.neutral,
              onPressed: onEdit,
            ),
          if (!isMobile)
            _ActionPill(
              icon: Icons.cancel,
              label: 'Cancelar',
              tone: _ActionTone.danger,
              onPressed: () async {
                await provider.cancelarOrcamento(orcamento.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Orçamento cancelado!'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
            ),
        ]);
        break;

      case OrcamentoStatus.aprovado:
        actions.add(
          _ActionPill(
            icon: Icons.play_arrow,
            label: 'Iniciar',
            tone: _ActionTone.primary,
            filled: true,
            onPressed: () async {
              await provider.iniciarServico(orcamento.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Serviço iniciado!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        );
        break;

      case OrcamentoStatus.emAndamento:
        actions.add(
          _ActionPill(
            icon: Icons.done,
            label: 'Concluir',
            tone: _ActionTone.success,
            filled: true,
            onPressed: () async {
              await provider.concluirOrcamento(orcamento.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Serviço concluído! Pagamento pendente.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        );
        break;

      case OrcamentoStatus.concluido:
        if (!orcamento.pago) {
          actions.add(
            _ActionPill(
              icon: Icons.attach_money,
              label: 'Receber',
              tone: _ActionTone.success,
              filled: true,
              onPressed: () async {
                await provider.registrarPagamento(orcamento.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pagamento registrado!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          );
        }
        break;

      case OrcamentoStatus.cancelado:
        break;
    }

    // PDF + WhatsApp — sempre visível
    actions.add(
      _ActionPill(
        icon: Icons.chat,
        label: isMobile ? 'PDF' : 'PDF + WhatsApp',
        tone: _ActionTone.success,
        filled: true,
        onPressed: () async {
          try {
            final cliente = provider.getClienteById(orcamento.clienteId);
            if (cliente == null || cliente.telefone.trim().isEmpty) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cliente sem telefone cadastrado.'),
                ),
              );
              return;
            }
            final bytes = await PDFService.generateOrcamentoPdf(orcamento);
            final filename = PDFService.buildPdfFilename(orcamento);
            final savedPath = await PdfFileService.savePdfToUserFolder(
              bytes: bytes,
              filename: filename,
            );
            final mensagem =
                'Olá ${orcamento.clienteNome}, segue seu orçamento referente ao veículo '
                '${orcamento.veiculoDescricao}.';
            await PdfFileService.openFileFolder(savedPath);
            await WhatsAppService.openChat(
              phone: cliente.telefone,
              message: mensagem,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF gerado! Escolha o app para compartilhar.'),
                backgroundColor: AppColors.success,
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao preparar envio: $e')),
            );
          }
        },
      ),
    );

    // No mobile: botões secundários condensados num menu
    if (isMobile) {
      actions.add(
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_horiz,
            color: AppColors.textSecondary,
          ),
          color: AppColors.secondaryGray,
          onSelected: (value) async {
            switch (value) {
              case 'editar':
                onEdit();
                break;
              case 'imprimir':
                final filename = PDFService.buildPdfFilename(orcamento);
                final title = orcamento.status == OrcamentoStatus.concluido
                    ? 'Nota de Serviço'
                    : 'Orçamento';
                await showPdfPreviewDialog(
                  context,
                  title: title,
                  fileName: filename,
                  buildPdf: (_) => PDFService.generateOrcamentoPdf(orcamento),
                );
                break;
              case 'cancelar':
                await provider.cancelarOrcamento(orcamento.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Orçamento cancelado!')),
                );
                break;
              case 'excluir':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Excluir orçamento?'),
                    content: const Text('Esta ação não pode ser desfeita.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
                if (confirmed == true) {
                  await provider.deleteOrcamento(orcamento.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Orçamento excluído'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                break;
            }
          },
          itemBuilder: (_) => [
            if (orcamento.status == OrcamentoStatus.pendente)
              const PopupMenuItem(
                value: 'editar',
                child: Row(children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ]),
              ),
            const PopupMenuItem(
              value: 'imprimir',
              child: Row(children: [
                Icon(Icons.print, size: 18),
                SizedBox(width: 8),
                Text('Imprimir'),
              ]),
            ),
            if (orcamento.status == OrcamentoStatus.pendente)
              const PopupMenuItem(
                value: 'cancelar',
                child: Row(children: [
                  Icon(Icons.cancel, size: 18),
                  SizedBox(width: 8),
                  Text('Cancelar'),
                ]),
              ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'excluir',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Excluir', style: TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      );
    } else {
      // Desktop: botões completos
      actions.addAll([
        _ActionPill(
          icon: Icons.print,
          label: 'Imprimir',
          tone: _ActionTone.neutral,
          onPressed: () async {
            final filename = PDFService.buildPdfFilename(orcamento);
            final title = orcamento.status == OrcamentoStatus.concluido
                ? 'Nota de Serviço'
                : 'Orçamento';
            await showPdfPreviewDialog(
              context,
              title: title,
              fileName: filename,
              buildPdf: (_) => PDFService.generateOrcamentoPdf(orcamento),
            );
          },
        ),
        _ActionPill(
          icon: Icons.delete_outline,
          label: 'Excluir',
          tone: _ActionTone.danger,
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Excluir orçamento?'),
                content: const Text('Esta ação não pode ser desfeita.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            );
            if (!context.mounted) return;
            if (confirmed == true) {
              await provider.deleteOrcamento(orcamento.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Orçamento excluído'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ]);
    }

    return actions;
  }
}

enum _ActionTone { primary, success, danger, neutral }

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final _ActionTone tone;
  final bool filled;
  final VoidCallback onPressed;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.tone,
    this.filled = false,
    required this.onPressed,
  });

  Color _fg() {
    switch (tone) {
      case _ActionTone.primary:
        return AppColors.primaryYellow;
      case _ActionTone.success:
        return AppColors.success;
      case _ActionTone.danger:
        return AppColors.error;
      case _ActionTone.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fg();
    final background = filled ? fg : fg.withValues(alpha: 0.10);
    final foreground = filled
        ? ((tone == _ActionTone.primary) ? Colors.black : Colors.white)
        : fg;
    final borderColor = filled ? fg : fg.withValues(alpha: 0.35);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? suffixIcon;

  const _StatusPill({required this.text, required this.color, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (suffixIcon != null) ...[
            const SizedBox(width: 6),
            Icon(suffixIcon, size: 14, color: color),
          ],
        ],
      ),
    );
  }
}
```

**Observação de arquitetura:** `_OrcamentoMobileCard` (novo, usa `AppCard`/`StatusPill`/`PrimaryButton`/`AppSnackbar` do design system, cores via `AppColors.primary`/`.success`/`.danger`) e `_OrcamentoPremiumCard` (card desktop antigo, usa `ResponsiveListCard`, `AppColors.primaryYellow`/`.secondaryGray`/`.warning`/`.error` e `ScaffoldMessenger` direto) coexistem no mesmo arquivo com convenções de cor e feedback completamente diferentes — a divisão é por `ResponsiveUtils.isMobile(context)` em `_buildOrcamentosList`, não por uma migração completa da tela.

### `lib/screens/clientes_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/common_widgets.dart';
import '../core/components/form_styles.dart';
import '../core/components/orcamento_form_dialog.dart';
import '../core/components/cliente_form_dialog.dart';
import '../providers/app_provider.dart';
import '../models/cliente.dart';
import '../models/veiculo.dart';
import '../core/utils/formatters.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

enum _SortClientes { nomeAsc, recentes }

class _ClienteInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ClienteInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  TipoCliente? _tipoFiltro;
  _SortClientes _sort = _SortClientes.nomeAsc;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final filtered = _applyFilters(provider.clientes);

        return ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderWithAction(
                title: 'Clientes',
                onAdd: () => _showAddClienteDialog(context),
                addLabelLong: 'Novo Cliente',
                addLabelShort: 'Novo',
              ),
              const SizedBox(height: 12),
              _buildToolbar(
                context,
                total: provider.clientes.length,
                showing: filtered.length,
              ),
              SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
              Flexible(
                child: provider.clientes.isEmpty
                    ? _buildEmptyState(context)
                    : (filtered.isEmpty
                          ? _buildNoResults(context)
                          : ResponsiveWidget(
                              mobile: _buildMobileList(
                                context,
                                filtered,
                                provider,
                              ),
                              tablet: _buildTabletGrid(
                                context,
                                filtered,
                                provider,
                              ),
                              desktop: _buildDesktopGrid(
                                context,
                                filtered,
                                provider,
                              ),
                            )),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Cliente> _applyFilters(List<Cliente> src) {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = src.where((c) {
      if (_tipoFiltro != null && c.tipo != _tipoFiltro) return false;
      if (q.isEmpty) return true;
      final nome = c.nome.toLowerCase();
      final tel = c.telefone.toLowerCase();
      final seg = (c.nomeSeguradora ?? '').toLowerCase();
      return nome.contains(q) || tel.contains(q) || seg.contains(q);
    }).toList();

    switch (_sort) {
      case _SortClientes.nomeAsc:
        list.sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );
        break;
      case _SortClientes.recentes:
        list.sort((a, b) => b.dataCadastro.compareTo(a.dataCadastro));
        break;
    }
    return list;
  }

  Widget _buildToolbar(
    BuildContext context, {
    required int total,
    required int showing,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final theme = Theme.of(context);

    const double kToolbarHeight = 48;

    final search = SizedBox(
      width: isDesktop ? 420 : double.infinity,
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar clientes por nome, telefone ou seguradora…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar',
                  onPressed: () {
                    _searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
    );

    final count = SizedBox(
      height: kToolbarHeight,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          showing == total ? '$total clientes' : '$showing de $total',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    // Desktop e tablet: tudo em linha
    if (isDesktop || isTablet) {
      final tipo = DropdownButtonHideUnderline(
        child: DropdownButton<TipoCliente?>(
          value: _tipoFiltro,
          onChanged: (v) => setState(() => _tipoFiltro = v),
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem<TipoCliente?>(value: null, child: Text('Todos')),
            DropdownMenuItem<TipoCliente?>(
              value: TipoCliente.particular,
              child: Text('Particular'),
            ),
            DropdownMenuItem<TipoCliente?>(
              value: TipoCliente.seguradora,
              child: Text('Seguradora'),
            ),
            DropdownMenuItem<TipoCliente?>(
              value: TipoCliente.frota,
              child: Text('Frota'),
            ),
            DropdownMenuItem<TipoCliente?>(
              value: TipoCliente.oficinaParceira,
              child: Text('Oficina parceira'),
            ),
          ],
        ),
      );

      final sort = DropdownButtonHideUnderline(
        child: DropdownButton<_SortClientes>(
          value: _sort,
          onChanged: (v) => setState(() => _sort = v ?? _SortClientes.nomeAsc),
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: _SortClientes.nomeAsc, child: Text('A–Z')),
            DropdownMenuItem(
              value: _SortClientes.recentes,
              child: Text('Recentes'),
            ),
          ],
        ),
      );

      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          _toolbarChip(
            context,
            icon: Icons.filter_list,
            child: tipo,
            height: kToolbarHeight,
          ),
          const SizedBox(width: 12),
          _toolbarChip(
            context,
            icon: Icons.sort,
            child: sort,
            height: kToolbarHeight,
          ),
          const SizedBox(width: 12),
          count,
        ],
      );
    }

    // Mobile: busca em cima, filtros embaixo com isExpanded: true
    return Column(
      children: [
        search,
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _toolbarChip(
                context,
                icon: Icons.filter_list,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TipoCliente?>(
                    value: _tipoFiltro,
                    isExpanded: true,
                    onChanged: (v) => setState(() => _tipoFiltro = v),
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem<TipoCliente?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem<TipoCliente?>(
                        value: TipoCliente.particular,
                        child: Text('Particular'),
                      ),
                      DropdownMenuItem<TipoCliente?>(
                        value: TipoCliente.seguradora,
                        child: Text('Seguradora'),
                      ),
                      DropdownMenuItem<TipoCliente?>(
                        value: TipoCliente.frota,
                        child: Text('Frota'),
                      ),
                      DropdownMenuItem<TipoCliente?>(
                        value: TipoCliente.oficinaParceira,
                        child: Text('Oficina parceira'),
                      ),
                    ],
                  ),
                ),
                height: kToolbarHeight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _toolbarChip(
                context,
                icon: Icons.sort,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_SortClientes>(
                    value: _sort,
                    isExpanded: true,
                    onChanged: (v) =>
                        setState(() => _sort = v ?? _SortClientes.nomeAsc),
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(
                        value: _SortClientes.nomeAsc,
                        child: Text('A–Z'),
                      ),
                      DropdownMenuItem(
                        value: _SortClientes.recentes,
                        child: Text('Recentes'),
                      ),
                    ],
                  ),
                ),
                height: kToolbarHeight,
              ),
            ),
            const SizedBox(width: 10),
            count,
          ],
        ),
      ],
    );
  }

  Widget _toolbarChip(
    BuildContext context, {
    required IconData icon,
    required Widget child,
    double height = 48,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'Nenhum cliente cadastrado',
      subtitle: 'Adicione seu primeiro cliente para começar',
      actionLabel: 'Adicionar Cliente',
      onAction: () => _showAddClienteDialog(context),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List<Cliente> clientes,
    AppProvider provider,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: clientes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(context, cliente, provider);
      },
    );
  }

  Widget _buildTabletGrid(
    BuildContext context,
    List<Cliente> clientes,
    AppProvider provider,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(context, cliente, provider);
      },
    );
  }

  Widget _buildDesktopGrid(
    BuildContext context,
    List<Cliente> clientes,
    AppProvider provider,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(context, cliente, provider);
      },
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Nenhum resultado',
      subtitle: 'Tente ajustar o termo de busca ou remover filtros.',
      actionLabel: 'Limpar filtros',
      onAction: () {
        setState(() {
          _searchCtrl.clear();
          _tipoFiltro = null;
          _sort = _SortClientes.nomeAsc;
        });
      },
    );
  }

  Widget _buildClienteCard(
    BuildContext context,
    Cliente cliente,
    AppProvider provider,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final veiculos = provider.getVeiculosByCliente(cliente.id);
    final orcamentos = provider.getOrcamentosByCliente(cliente.id);
    final ultimoOrcamento = orcamentos.isEmpty
        ? null
        : (List.of(orcamentos)
              ..sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao)))
            .first;

    return ResponsiveListCard(
      title: cliente.nome,
      subtitle:
          '${cliente.telefone}${cliente.nomeSeguradora != null ? ' • ${cliente.nomeSeguradora}' : ''}',
      leading: CircleAvatar(
        backgroundColor: _getTipoClienteColor(cliente.tipo),
        radius: isMobile ? 20 : 24,
        child: Text(
          cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 18,
          ),
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
        color: AppColors.secondaryGray,
        onSelected: (value) {
          switch (value) {
            case 'editar':
              _showEditClienteDialog(context, cliente);
              break;
            case 'veiculo':
              _showAddVeiculoDialog(context, cliente);
              break;
            case 'orcamento':
              _showCreateOrcamentoDialog(context, cliente);
              break;
            case 'excluir':
              _showDeleteClienteDialog(context, cliente, provider);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'orcamento',
            child: Row(children: [
              Icon(Icons.description, size: 20),
              SizedBox(width: 8),
              Text('Novo Orçamento'),
            ]),
          ),
          const PopupMenuItem(
            value: 'veiculo',
            child: Row(children: [
              Icon(Icons.directions_car, size: 20),
              SizedBox(width: 8),
              Text('Add Veículo'),
            ]),
          ),
          const PopupMenuItem(
            value: 'editar',
            child: Row(children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Editar'),
            ]),
          ),
          PopupMenuItem(
            value: 'excluir',
            child: Row(children: [
              Icon(Icons.delete, size: 20, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Excluir', style: TextStyle(color: AppColors.error)),
            ]),
          ),
        ],
      ),
      onTap: () => _showClienteDetails(context, cliente, provider),
      actions: isMobile
          ? [
              _ClienteInfoChip(
                icon: Icons.directions_car_outlined,
                label:
                    '${veiculos.length} veículo${veiculos.length == 1 ? '' : 's'}',
              ),
              _ClienteInfoChip(
                icon: Icons.description_outlined,
                label:
                    '${orcamentos.length} orçamento${orcamentos.length == 1 ? '' : 's'}',
              ),
              if (ultimoOrcamento != null)
                _ClienteInfoChip(
                  icon: Icons.schedule,
                  label:
                      'Último ${Formatters.dateShort(ultimoOrcamento.dataCriacao)}',
                ),
            ]
          : [
              _ClienteInfoChip(
                icon: Icons.directions_car_outlined,
                label:
                    '${veiculos.length} veiculo${veiculos.length == 1 ? '' : 's'}',
              ),
              _ClienteInfoChip(
                icon: Icons.description_outlined,
                label:
                    '${orcamentos.length} orcamento${orcamentos.length == 1 ? '' : 's'}',
              ),
              if (ultimoOrcamento != null)
                _ClienteInfoChip(
                  icon: Icons.schedule,
                  label:
                      'Ultimo em ${Formatters.dateShort(ultimoOrcamento.dataCriacao)}',
                ),
              FilledButton.tonalIcon(
                onPressed: () => _showCreateOrcamentoDialog(context, cliente),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Orcamento'),
              ),
            ],
    );
  }

  Color _getTipoClienteColor(TipoCliente tipo) {
    switch (tipo) {
      case TipoCliente.particular:
        return AppColors.primaryYellow;
      case TipoCliente.seguradora:
        return AppColors.info;
      case TipoCliente.oficinaParceira:
        return AppColors.success;
      case TipoCliente.frota:
        return AppColors.warning;
    }
  }

  void _showAddClienteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ClienteFormDialog(),
    );
  }

  void _showEditClienteDialog(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      builder: (_) => ClienteFormDialog(clienteEditar: cliente),
    );
  }

  void _showDeleteClienteDialog(
    BuildContext context,
    Cliente cliente,
    AppProvider provider,
  ) {
    final scaffoldContext = context;
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: AppColors.secondaryGray,
            title: const Text(
              'Excluir Cliente',
              style: TextStyle(color: AppColors.error),
            ),
            content: Text(
              'Tem certeza que deseja excluir o cliente ${cliente.nome}? Esta ação não pode ser desfeita.',
              style: const TextStyle(color: AppColors.white),
            ),
            actions: [
              OutlinedButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);
                        try {
                          await provider.deleteCliente(cliente.id);
                          if (dialogContext.mounted &&
                              Navigator.of(dialogContext).canPop()) {
                            Navigator.pop(dialogContext);
                          }
                          if (scaffoldContext.mounted) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text('Cliente excluído com sucesso!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (scaffoldContext.mounted) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao excluir cliente: $e'),
                              ),
                            );
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            setState(() => isDeleting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: isDeleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Excluir'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddVeiculoDialog(BuildContext context, Cliente cliente) {
    final scaffoldContext = context;
    final formKey = GlobalKey<FormState>();

    const otherOptionValue = '__other__';
    String? selectedMarca;
    String? selectedModelo;
    final marcaCustomController = TextEditingController();
    final modeloCustomController = TextEditingController();
    final corController = TextEditingController();
    final placaController = TextEditingController();
    final anoController = TextEditingController();
    final observacoesController = TextEditingController();
    final corFocus = FocusNode();
    final placaFocus = FocusNode();
    final anoFocus = FocusNode();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> submit() async {
            if (isSaving) return;
            if (!formKey.currentState!.validate()) return;
            setState(() => isSaving = true);

            final provider =
                Provider.of<AppProvider>(scaffoldContext, listen: false);

            final marcaFinal = (selectedMarca == otherOptionValue)
                ? marcaCustomController.text.trim()
                : (selectedMarca ?? '').trim();
            final modeloFinal = (selectedMarca == otherOptionValue)
                ? modeloCustomController.text.trim()
                : (selectedModelo == otherOptionValue)
                    ? modeloCustomController.text.trim()
                    : (selectedModelo ?? '').trim();

            final anoText = anoController.text.trim();
            final anoValue = anoText.isEmpty ? null : int.tryParse(anoText);
            if (anoText.isNotEmpty && anoValue == null) {
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(
                      content: Text('Ano inválido. Use apenas números.')),
                );
              }
              if (dialogContext.mounted) setState(() => isSaving = false);
              return;
            }

            final veiculo = Veiculo(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              clienteId: cliente.id,
              marca: marcaFinal,
              modelo: modeloFinal,
              cor: corController.text,
              placa: placaController.text,
              ano: anoValue,
              observacoes: observacoesController.text.isEmpty
                  ? null
                  : observacoesController.text,
            );
            try {
              await provider.addMarcaModeloCustom(
                  marca: marcaFinal, modelo: modeloFinal);
              await provider.addVeiculo(veiculo);
              if (dialogContext.mounted &&
                  Navigator.of(dialogContext).canPop()) {
                Navigator.pop(dialogContext);
              }
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(
                    content: Text('Veículo adicionado com sucesso!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(content: Text('Erro ao adicionar veículo: $e')),
                );
              }
            } finally {
              if (dialogContext.mounted) setState(() => isSaving = false);
            }
          }

          final dialog = ResponsiveDialog(
            title: 'Novo Veículo - ${cliente.nome}',
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedMarca,
                        decoration: formFieldDecoration(
                          label: 'Marca *',
                          prefixIcon: Icons.directions_car,
                        ),
                        items: [
                          ...Provider.of<AppProvider>(scaffoldContext,
                                  listen: false)
                              .marcasDisponiveis
                              .map<DropdownMenuItem<String>>(
                                (m) =>
                                    DropdownMenuItem<String>(
                                        value: m, child: Text(m)),
                              ),
                          const DropdownMenuItem<String>(
                            value: otherOptionValue,
                            child: Text('Outra... (digitar)'),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          selectedMarca = v;
                          selectedModelo = null;
                          if (v != otherOptionValue) {
                            marcaCustomController.clear();
                          }
                          modeloCustomController.clear();
                        }),
                        validator: (v) {
                          if (v == null) return 'Marca é obrigatória';
                          if (v == otherOptionValue &&
                              marcaCustomController.text.trim().isEmpty) {
                            return 'Informe a marca';
                          }
                          return null;
                        },
                      ),
                      if (selectedMarca == otherOptionValue) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: marcaCustomController,
                          decoration: formFieldDecoration(
                            label: 'Digite a marca *',
                            prefixIcon: Icons.edit,
                          ),
                          validator: (v) {
                            if (selectedMarca != otherOptionValue) return null;
                            return (v == null || v.trim().isEmpty)
                                ? 'Marca é obrigatória'
                                : null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (selectedMarca == null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selecione a marca primeiro',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else if (selectedMarca == otherOptionValue)
                        TextFormField(
                          controller: modeloCustomController,
                          decoration: formFieldDecoration(
                            label: 'Modelo *',
                            prefixIcon: Icons.drive_eta,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Modelo é obrigatório'
                              : null,
                        )
                      else
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedModelo,
                          decoration: formFieldDecoration(
                            label: 'Modelo *',
                            prefixIcon: Icons.drive_eta,
                          ),
                          items: [
                            ...Provider.of<AppProvider>(scaffoldContext,
                                    listen: false)
                                .modelosDisponiveis(selectedMarca)
                                .map<DropdownMenuItem<String>>(
                                  (m) => DropdownMenuItem<String>(
                                      value: m, child: Text(m)),
                                ),
                            const DropdownMenuItem<String>(
                              value: otherOptionValue,
                              child: Text('Outro... (digitar)'),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            selectedModelo = v;
                            if (v != otherOptionValue) {
                              modeloCustomController.clear();
                            }
                          }),
                          validator: (v) {
                            if (selectedMarca == null)
                              return 'Selecione a marca';
                            if (v == null) return 'Modelo é obrigatório';
                            if (v == otherOptionValue &&
                                modeloCustomController.text.trim().isEmpty) {
                              return 'Informe o modelo';
                            }
                            return null;
                          },
                          hint: const Text('Selecione o modelo'),
                        ),
                      if (selectedMarca != null &&
                          selectedMarca != otherOptionValue &&
                          selectedModelo == otherOptionValue) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: modeloCustomController,
                          decoration: formFieldDecoration(
                            label: 'Digite o modelo *',
                            prefixIcon: Icons.edit,
                          ),
                          validator: (v) {
                            if (selectedModelo != otherOptionValue) return null;
                            return (v == null || v.trim().isEmpty)
                                ? 'Modelo é obrigatório'
                                : null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: corController,
                        focusNode: corFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => placaFocus.requestFocus(),
                        decoration: formFieldDecoration(
                          label: 'Cor *',
                          prefixIcon: Icons.color_lens,
                        ),
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Cor é obrigatória'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: placaController,
                        focusNode: placaFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => anoFocus.requestFocus(),
                        decoration: formFieldDecoration(
                          label: 'Placa *',
                          prefixIcon: Icons.confirmation_number,
                        ),
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Placa é obrigatória'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: anoController,
                        focusNode: anoFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(dialogContext).nextFocus(),
                        decoration: formFieldDecoration(
                          label: 'Ano',
                          prefixIcon: Icons.calendar_today,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: observacoesController,
                        decoration: formFieldDecoration(
                          label: 'Observações',
                          prefixIcon: Icons.note,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed:
                    isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : submit,
                child: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          );

          return Focus(autofocus: false, child: dialog);
        },
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        marcaCustomController.dispose();
        modeloCustomController.dispose();
        corController.dispose();
        placaController.dispose();
        anoController.dispose();
        observacoesController.dispose();
        corFocus.dispose();
        placaFocus.dispose();
        anoFocus.dispose();
      });
    });
  }

  void _showCreateOrcamentoDialog(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          OrcamentoFormDialog(clientePreSelecionado: cliente),
    );
  }

  void _showClienteDetails(
    BuildContext context,
    Cliente cliente,
    AppProvider provider,
  ) {
    final veiculos = provider.getVeiculosByCliente(cliente.id);
    final orcamentos = provider.getOrcamentosByCliente(cliente.id);

    showDialog(
      context: context,
      builder: (context) {
        final dialog = ResponsiveDialog(
          title: cliente.nome,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(Icons.phone, 'Telefone', cliente.telefone),
                if (cliente.endereco != null)
                  _buildDetailRow(
                      Icons.location_on, 'Endereço', cliente.endereco!),
                if (cliente.observacoes != null)
                  _buildDetailRow(
                      Icons.note, 'Observações', cliente.observacoes!),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                ResponsiveText(
                  'Veículos (${veiculos.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 8),
                if (veiculos.isEmpty)
                  const ResponsiveText('Nenhum veículo cadastrado')
                else
                  ...veiculos.map(
                    (v) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ResponsiveText('• ${v.descricaoCompleta}'),
                    ),
                  ),
                const SizedBox(height: 16),
                ResponsiveText(
                  'Orçamentos (${orcamentos.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 8),
                if (orcamentos.isEmpty)
                  const ResponsiveText('Nenhum orçamento criado')
                else
                  ...orcamentos.map(
                    (o) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ResponsiveText(
                        '• ${o.status} - ${Formatters.currency(o.valorTotal)}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditClienteDialog(context, cliente);
              },
              child: const Text('Editar'),
            ),
          ],
        );

        return Focus(autofocus: false, child: dialog);
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryYellow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
                ResponsiveText(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Nota:** o modal de detalhe do cliente (`_showClienteDetails`, chamado a partir de `onTap` do card em `_buildClienteCard`) é o `ResponsiveDialog` da seção 10 (bug do tint amarelo) — o título "Veículos (N)"/"Orçamentos (N)" e o ícone de cada linha (`_buildDetailRow`) também usam `AppColors.primaryYellow` diretamente.

### `lib/core/components/cliente_form_dialog.dart` — parte 1/2

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../models/veiculo.dart';
import '../../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/cnpj_input_formatter.dart';
import '../utils/phone_input_formatter.dart';
import 'form_styles.dart';
import 'responsive_components.dart';

class ClienteFormDialog extends StatefulWidget {
  final Cliente? clienteEditar;

  const ClienteFormDialog({super.key, this.clienteEditar});

  @override
  State<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<ClienteFormDialog> {
  static const _otherOptionValue = '__other__';

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _observacoesController;
  late final TextEditingController _nomeSeguradoraController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _contatoController;

  final _nomeSeguradoraFocus = FocusNode();
  final _cnpjFocus = FocusNode();
  final _contatoFocus = FocusNode();
  final _nomeFocus = FocusNode();
  final _telefoneFocus = FocusNode();
  final _enderecoFocus = FocusNode();

  late TipoCliente _tipoSelecionado;
  bool _isSaving = false;

  // Estado exclusivo do fluxo de criação (passo do primeiro veículo).
  int _currentStep = 0;
  bool _showClientStepErrors = false;
  bool _showVehicleStepErrors = false;
  bool _showVehicleStepAlert = false;

  String? _selectedMarca;
  String? _selectedModelo;
  final _marcaCustomController = TextEditingController();
  final _modeloCustomController = TextEditingController();
  final _corController = TextEditingController();
  final _placaController = TextEditingController();
  final _anoController = TextEditingController();
  final _observacoesVeiculoController = TextEditingController();

  final _corFocus = FocusNode();
  final _placaFocus = FocusNode();
  final _anoFocus = FocusNode();

  Veiculo? _veiculoPreparado;

  bool get _isEdit => widget.clienteEditar != null;

  @override
  void initState() {
    super.initState();
    final cliente = widget.clienteEditar;
    _nomeController = TextEditingController(text: cliente?.nome ?? '');
    _telefoneController = TextEditingController(text: cliente?.telefone ?? '');
    _enderecoController =
        TextEditingController(text: cliente?.endereco ?? '');
    _observacoesController =
        TextEditingController(text: cliente?.observacoes ?? '');
    _nomeSeguradoraController =
        TextEditingController(text: cliente?.nomeSeguradora ?? '');
    _cnpjController = TextEditingController(text: cliente?.cnpj ?? '');
    _contatoController = TextEditingController(text: cliente?.contato ?? '');
    _tipoSelecionado = cliente?.tipo ?? TipoCliente.particular;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _observacoesController.dispose();
    _nomeSeguradoraController.dispose();
    _cnpjController.dispose();
    _contatoController.dispose();
    _nomeSeguradoraFocus.dispose();
    _cnpjFocus.dispose();
    _contatoFocus.dispose();
    _nomeFocus.dispose();
    _telefoneFocus.dispose();
    _enderecoFocus.dispose();
    _marcaCustomController.dispose();
    _modeloCustomController.dispose();
    _corController.dispose();
    _placaController.dispose();
    _anoController.dispose();
    _observacoesVeiculoController.dispose();
    _corFocus.dispose();
    _placaFocus.dispose();
    _anoFocus.dispose();
    super.dispose();
  }

  bool _validarPrimeiroVeiculo() {
    setState(() => _showVehicleStepErrors = true);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      if (_selectedMarca == _otherOptionValue &&
          _marcaCustomController.text.trim().isEmpty) {
        FocusScope.of(context).requestFocus();
      } else if ((_selectedMarca == _otherOptionValue ||
              _selectedModelo == _otherOptionValue) &&
          _modeloCustomController.text.trim().isEmpty) {
        FocusScope.of(context).requestFocus();
      } else if (_corController.text.trim().isEmpty) {
        _corFocus.requestFocus();
      } else if (_placaController.text.trim().isEmpty) {
        _placaFocus.requestFocus();
      } else if (_anoController.text.trim().isNotEmpty &&
          int.tryParse(_anoController.text.trim()) == null) {
        _anoFocus.requestFocus();
      }
    }
    return isValid;
  }

  Future<void> _prepararPrimeiroVeiculo() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final marcaFinal = (_selectedMarca == _otherOptionValue)
        ? _marcaCustomController.text.trim()
        : (_selectedMarca ?? '').trim();

    final modeloFinal = (_selectedMarca == _otherOptionValue)
        ? _modeloCustomController.text.trim()
        : (_selectedModelo == _otherOptionValue)
            ? _modeloCustomController.text.trim()
            : (_selectedModelo ?? '').trim();

    final cor = _corController.text.trim();
    final placa = _placaController.text.trim().toUpperCase();
    final anoText = _anoController.text.trim();

    if (!_validarPrimeiroVeiculo()) return;

    final anoValue = anoText.isEmpty ? null : int.tryParse(anoText);

    final veiculo = Veiculo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clienteId: '__pending__',
      marca: marcaFinal,
      modelo: modeloFinal,
      cor: cor,
      placa: placa,
      ano: anoValue,
      observacoes: _observacoesVeiculoController.text.trim().isEmpty
          ? null
          : _observacoesVeiculoController.text.trim(),
    );

    await provider.addMarcaModeloCustom(marca: marcaFinal, modelo: modeloFinal);

    if (!mounted) return;
    setState(() {
      _veiculoPreparado = veiculo;
      _showVehicleStepAlert = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Primeiro veículo preparado com sucesso!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  bool _validarDadosCliente() {
    setState(() => _showClientStepErrors = true);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) return true;

    if (_tipoSelecionado == TipoCliente.seguradora &&
        _nomeSeguradoraController.text.trim().isEmpty) {
      _nomeSeguradoraFocus.requestFocus();
    } else if (_nomeController.text.trim().isEmpty) {
      _nomeFocus.requestFocus();
    } else if (_telefoneController.text.trim().isEmpty) {
      _telefoneFocus.requestFocus();
    }

    return false;
  }

  void _avancarPasso() {
    if (!_validarDadosCliente()) return;
    setState(() {
      _currentStep = 1;
      _showVehicleStepErrors = false;
      _showVehicleStepAlert = false;
    });
  }

  void _voltarPasso() {
    setState(() => _currentStep = 0);
  }

  Future<void> _submitAdd() async {
    if (_isSaving) return;
    if (!_validarDadosCliente()) {
      setState(() => _currentStep = 0);
      return;
    }

    if (_veiculoPreparado == null) {
      setState(() {
        _currentStep = 1;
        _showVehicleStepAlert = true;
      });
      return;
    }

    setState(() => _isSaving = true);

    final clienteId = DateTime.now().millisecondsSinceEpoch.toString();

    final cliente = Cliente(
      id: clienteId,
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim(),
      endereco: _enderecoController.text.trim().isEmpty
          ? null
          : _enderecoController.text.trim(),
      dataCadastro: DateTime.now(),
      observacoes: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
      tipo: _tipoSelecionado,
      nomeSeguradora: _tipoSelecionado == TipoCliente.seguradora &&
              _nomeSeguradoraController.text.trim().isNotEmpty
          ? _nomeSeguradoraController.text.trim()
          : null,
      cnpj: _tipoSelecionado == TipoCliente.seguradora &&
              _cnpjController.text.trim().isNotEmpty
          ? _cnpjController.text.trim()
          : null,
      contato: _tipoSelecionado == TipoCliente.seguradora &&
              _contatoController.text.trim().isNotEmpty
          ? _contatoController.text.trim()
          : null,
    );

    final veiculoFinal = _veiculoPreparado!.copyWith(clienteId: clienteId);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.addCliente(cliente);
      await provider.addVeiculo(veiculoFinal);

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cliente e primeiro veículo salvos com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao adicionar cliente: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitEdit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updated = widget.clienteEditar!.copyWith(
      nome: _nomeController.text,
      telefone: _telefoneController.text,
      endereco:
          _enderecoController.text.isEmpty ? null : _enderecoController.text,
      observacoes: _observacoesController.text.isEmpty
          ? null
          : _observacoesController.text,
      tipo: _tipoSelecionado,
      nomeSeguradora: _tipoSelecionado == TipoCliente.seguradora &&
              _nomeSeguradoraController.text.isNotEmpty
          ? _nomeSeguradoraController.text
          : null,
      cnpj: _tipoSelecionado == TipoCliente.seguradora &&
              _cnpjController.text.isNotEmpty
          ? _cnpjController.text
          : null,
      contato: _tipoSelecionado == TipoCliente.seguradora &&
              _contatoController.text.isNotEmpty
          ? _contatoController.text
          : null,
    );

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await Provider.of<AppProvider>(context, listen: false)
          .updateCliente(updated);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cliente atualizado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao atualizar cliente: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _isLastStep => _isEdit || _currentStep == 1;

  void _handlePrimaryAction() {
    if (_isSaving) return;
    if (_isEdit) {
      _submitEdit();
    } else if (_currentStep == 0) {
      _avancarPasso();
    } else {
      _submitAdd();
    }
  }

  Widget _buildStepChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStepChip(
          icon: Icons.person_outline,
          label: _currentStep == 0 ? '1. Dados do cliente' : '1. Cliente',
        ),
        _buildStepChip(
          icon: Icons.directions_car_outlined,
          label: _currentStep == 1 ? '2. Primeiro veículo' : '2. Veículo',
        ),
      ],
    );
  }

  Widget _buildClientFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<TipoCliente>(
          initialValue: _tipoSelecionado,
          decoration: formFieldDecoration(
            label: 'Tipo de Cliente *',
            prefixIcon: Icons.category,
          ),
          items: TipoCliente.values
              .map(
                (tipo) => DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo.displayName),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _tipoSelecionado = value!;
            if (_tipoSelecionado == TipoCliente.seguradora) {
              _nomeSeguradoraFocus.requestFocus();
            } else {
              _nomeFocus.requestFocus();
            }
          }),
        ),
        const SizedBox(height: 16),
        if (_tipoSelecionado == TipoCliente.seguradora) ...[
          TextFormField(
            controller: _nomeSeguradoraController,
            focusNode: _nomeSeguradoraFocus,
            autofocus: true,
            style: const TextStyle(color: AppColors.white),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _cnpjFocus.requestFocus(),
            decoration: formFieldDecoration(
              label: 'Nome da Seguradora *',
              prefixIcon: Icons.business,
            ),
            validator: (value) {
              if (_tipoSelecionado == TipoCliente.seguradora &&
                  (value == null || value.trim().isEmpty)) {
                return 'Nome da seguradora é obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cnpjController,
            focusNode: _cnpjFocus,
            style: const TextStyle(color: AppColors.white),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _contatoFocus.requestFocus(),
            decoration: formFieldDecoration(
              label: 'CNPJ da Seguradora',
              prefixIcon: Icons.numbers,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CnpjInputFormatter(),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contatoController,
            focusNode: _contatoFocus,
            style: const TextStyle(color: AppColors.white),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _nomeFocus.requestFocus(),
            decoration: formFieldDecoration(
              label: 'Pessoa de Contato',
              prefixIcon: Icons.contact_phone,
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _nomeController,
          focusNode: _nomeFocus,
          autofocus: _tipoSelecionado != TipoCliente.seguradora,
          style: const TextStyle(color: AppColors.white),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _telefoneFocus.requestFocus(),
          decoration: formFieldDecoration(
            label: 'Nome *',
            prefixIcon: Icons.person,
          ),
          validator: (value) =>
              (value?.trim().isEmpty ?? true) ? 'Nome é obrigatório' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _telefoneController,
          focusNode: _telefoneFocus,
          style: const TextStyle(color: AppColors.white),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _enderecoFocus.requestFocus(),
          decoration: formFieldDecoration(
            label: 'Telefone *',
            prefixIcon: Icons.phone,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          validator: (value) => (value?.trim().isEmpty ?? true)
              ? 'Telefone é obrigatório'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _enderecoController,
          focusNode: _enderecoFocus,
          style: const TextStyle(color: AppColors.white),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: formFieldDecoration(
            label: 'Endereço',
            prefixIcon: Icons.location_on,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacoesController,
          style: const TextStyle(color: AppColors.white),
          decoration: formFieldDecoration(
            label: 'Observações',
            prefixIcon: Icons.note,
          ),
          maxLines: 3,
        ),
      ],
    );
  }
```

### `lib/core/components/cliente_form_dialog.dart` — parte 2/2

```dart
  Widget _buildVehicleFields(AppProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showVehicleStepAlert && _veiculoPreparado == null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.28),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adicione pelo menos um veículo para concluir o cadastro do cliente.',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              const Icon(Icons.directions_car, color: AppColors.primaryYellow),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Primeiro veículo do cliente',
                  style: TextStyle(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (_veiculoPreparado != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'Veículo adicionado',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Para concluir o primeiro cadastro do cliente, é obrigatório adicionar pelo menos um veículo.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedMarca,
            decoration: formFieldDecoration(
              label: 'Marca do veículo *',
              prefixIcon: Icons.directions_car,
            ),
            items: [
              ...provider.marcasDisponiveis.map<DropdownMenuItem<String>>(
                (m) => DropdownMenuItem<String>(value: m, child: Text(m)),
              ),
              const DropdownMenuItem<String>(
                value: _otherOptionValue,
                child: Text('Outra... (digitar)'),
              ),
            ],
            onChanged: (v) => setState(() {
              _selectedMarca = v;
              _selectedModelo = null;
              if (v != _otherOptionValue) {
                _marcaCustomController.clear();
              }
              _modeloCustomController.clear();
              _veiculoPreparado = null;
              _showVehicleStepAlert = false;
            }),
            validator: (value) {
              if (_currentStep != 1) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Selecione a marca';
              }
              return null;
            },
          ),
          if (_selectedMarca == _otherOptionValue) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _marcaCustomController,
              decoration: formFieldDecoration(
                label: 'Digite a marca *',
                prefixIcon: Icons.edit,
              ),
              validator: (_) {
                if (_currentStep != 1 || _selectedMarca != _otherOptionValue) {
                  return null;
                }
                if (_marcaCustomController.text.trim().isEmpty) {
                  return 'Digite a marca';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 12),
          if (_selectedMarca == null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selecione a marca primeiro',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else if (_selectedMarca == _otherOptionValue)
            TextFormField(
              controller: _modeloCustomController,
              decoration: formFieldDecoration(
                label: 'Modelo *',
                prefixIcon: Icons.drive_eta,
              ),
            )
          else
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedModelo,
              decoration: formFieldDecoration(
                label: 'Modelo *',
                prefixIcon: Icons.drive_eta,
              ),
              items: [
                ...provider
                    .modelosDisponiveis(_selectedMarca)
                    .map<DropdownMenuItem<String>>(
                      (m) => DropdownMenuItem<String>(
                        value: m,
                        child: Text(m),
                      ),
                    ),
                const DropdownMenuItem<String>(
                  value: _otherOptionValue,
                  child: Text('Outro... (digitar)'),
                ),
              ],
              onChanged: (v) => setState(() {
                _selectedModelo = v;
                if (v != _otherOptionValue) {
                  _modeloCustomController.clear();
                }
                _veiculoPreparado = null;
              }),
              hint: const Text('Selecione o modelo'),
              validator: (value) {
                if (_currentStep != 1 ||
                    _selectedMarca == null ||
                    _selectedMarca == _otherOptionValue) {
                  return null;
                }
                if (value == null || value.trim().isEmpty) {
                  return 'Selecione o modelo';
                }
                return null;
              },
            ),
          if (_selectedMarca != null &&
              _selectedMarca != _otherOptionValue &&
              _selectedModelo == _otherOptionValue) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _modeloCustomController,
              decoration: formFieldDecoration(
                label: 'Digite o modelo *',
                prefixIcon: Icons.edit,
              ),
              validator: (_) {
                if (_currentStep != 1) return null;
                final needsCustomModel = _selectedMarca == _otherOptionValue ||
                    (_selectedMarca != null &&
                        _selectedMarca != _otherOptionValue &&
                        _selectedModelo == _otherOptionValue);
                if (!needsCustomModel) return null;
                if (_modeloCustomController.text.trim().isEmpty) {
                  return 'Digite o modelo';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _corController,
            focusNode: _corFocus,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _placaFocus.requestFocus(),
            decoration: formFieldDecoration(
              label: 'Cor *',
              prefixIcon: Icons.color_lens,
            ),
            validator: (_) {
              if (_currentStep != 1) return null;
              if (_corController.text.trim().isEmpty) {
                return 'Informe a cor';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _placaController,
            focusNode: _placaFocus,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _anoFocus.requestFocus(),
            decoration: formFieldDecoration(
              label: 'Placa *',
              prefixIcon: Icons.confirmation_number,
            ),
            validator: (_) {
              if (_currentStep != 1) return null;
              if (_placaController.text.trim().isEmpty) {
                return 'Informe a placa';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _anoController,
            focusNode: _anoFocus,
            textInputAction: TextInputAction.next,
            decoration: formFieldDecoration(
              label: 'Ano',
              prefixIcon: Icons.calendar_today,
            ),
            keyboardType: TextInputType.number,
            validator: (_) {
              if (_currentStep != 1) return null;
              final value = _anoController.text.trim();
              if (value.isNotEmpty && int.tryParse(value) == null) {
                return 'Ano inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _observacoesVeiculoController,
            decoration: formFieldDecoration(
              label: 'Observações do veículo',
              prefixIcon: Icons.note,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _prepararPrimeiroVeiculo,
                  icon: Icon(
                    _veiculoPreparado == null ? Icons.add : Icons.save,
                  ),
                  label: Text(
                    _veiculoPreparado == null
                        ? 'Adicionar primeiro veículo'
                        : 'Atualizar veículo',
                  ),
                ),
              ),
              if (_veiculoPreparado != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _veiculoPreparado = null;
                            _selectedMarca = null;
                            _selectedModelo = null;
                            _marcaCustomController.clear();
                            _modeloCustomController.clear();
                            _corController.clear();
                            _placaController.clear();
                            _anoController.clear();
                            _observacoesVeiculoController.clear();
                            _showVehicleStepAlert = false;
                          });
                        },
                  child: const Text('Limpar'),
                ),
              ],
            ],
          ),
          if (_veiculoPreparado != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo do primeiro veículo',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _veiculoPreparado!.descricaoCompleta,
                    style: const TextStyle(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(AppProvider provider) {
    if (_isEdit) return _buildClientFields();
    return _currentStep == 0
        ? _buildClientFields()
        : _buildVehicleFields(provider);
  }

  AutovalidateMode get _autovalidateMode {
    if (_isEdit) return AutovalidateMode.disabled;
    return _currentStep == 0
        ? (_showClientStepErrors
            ? AutovalidateMode.always
            : AutovalidateMode.disabled)
        : (_showVehicleStepErrors
            ? AutovalidateMode.always
            : AutovalidateMode.disabled);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isEdit = _isEdit;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEdit ? 'Editar Cliente' : 'Novo Cliente',
            style: const TextStyle(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _handlePrimaryAction,
              child: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryYellow,
                      ),
                    )
                  : Text(
                      _isLastStep ? 'Salvar' : 'Próximo',
                      style: const TextStyle(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            children: [
              if (!isEdit)
                Container(
                  color: AppColors.secondaryGray,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _buildStepperHeader(),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentStepContent(provider),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    if (!isEdit && _currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _voltarPasso,
                          child: const Text('← Voltar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handlePrimaryAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                _isLastStep ? 'Salvar' : 'Próximo →',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Desktop: dialog original
    final dialog = ResponsiveDialog(
      title: isEdit ? 'Editar Cliente' : 'Novo Cliente',
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isEdit ? 600 : 700),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEdit) ...[
                  _buildStepperHeader(),
                  const SizedBox(height: 18),
                ],
                _buildCurrentStepContent(provider),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (!isEdit && _currentStep > 0)
          OutlinedButton(
            onPressed: _isSaving ? null : _voltarPasso,
            child: const Text('Voltar'),
          ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handlePrimaryAction,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isLastStep ? 'Salvar' : 'Próximo'),
        ),
      ],
    );

    return Focus(autofocus: false, child: dialog);
  }
}
```

**Nota:** o formulário de edição/criação de cliente (`ClienteFormDialog`) é um widget diferente do modal de detalhe (`_showClienteDetails` em `clientes_screen.dart`) — ambos usam `ResponsiveDialog` no desktop, mas `ClienteFormDialog` tem sua própria versão full-screen (`Scaffold`) no mobile, com `AppBar` e `backgroundColor: AppColors.primaryYellow` no botão principal.

---

## 5. Camada de dados

Não existe um serviço de backup/restore dedicado — a lógica está embutida em `DBService` (`lib/services/db_service_io.dart`, seção `// ================= BACKUP =================`), exposta via `lib/services/db_service.dart` (export condicional por plataforma).

### `lib/services/db_service.dart`

```dart
export 'db_service_io.dart' if (dart.library.html) 'db_service_web.dart';
```

### `lib/services/db_service_web.dart`

```dart
import '../models/cliente.dart';
import '../models/backup_manifest.dart';
import '../models/veiculo.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import '../models/nota.dart';

/// Web placeholder.
///
/// This project currently relies on `sqflite` + file-system backups (`dart:io`),
/// which are not supported on Flutter Web in the current architecture.
///
/// The app entrypoint shows a "Web not supported" screen and avoids creating
/// providers that would call into this service.
class DBService {
  static final DBService instance = DBService._internal();
  factory DBService() => instance;
  DBService._internal();

  Never _unsupported() => throw UnsupportedError(
        'DBService não é suportado no Web nesta versão do app.',
      );

  Future<void> insertCliente(Cliente cliente) async => _unsupported();
  Future<void> updateCliente(Cliente cliente) async => _unsupported();
  Future<void> deleteCliente(String id) async => _unsupported();
  Future<List<Cliente>> getClientes() async => _unsupported();

  Future<void> insertVeiculo(Veiculo veiculo) async => _unsupported();
  Future<void> updateVeiculo(Veiculo veiculo) async => _unsupported();
  Future<void> deleteVeiculo(String id) async => _unsupported();
  Future<List<Veiculo>> getVeiculos() async => _unsupported();

  Future<void> insertOrcamento(Orcamento o) async => _unsupported();
  Future<void> updateOrcamento(Orcamento o) async => _unsupported();
  Future<void> deleteOrcamento(String id) async => _unsupported();
  Future<List<Orcamento>> getOrcamentos() async => _unsupported();

  Future<void> insertNota(Nota n) async => _unsupported();

  Future<void> insertTransacao(Transacao t) async => _unsupported();
  Future<void> deleteTransacao(String id) async => _unsupported();
  Future<List<Transacao>> getTransacoes() async => _unsupported();

  Future<String> exportBackupToUserDocuments() async => _unsupported();
  Future<List<BackupManifest>> listAvailableBackups() async => _unsupported();
  Future<String> restoreBackupFromUserDocuments([String? manifestId]) async =>
      _unsupported();
  Future<String> restoreBackupFromFilePath(String filePath) async =>
      _unsupported();
}
```

### `lib/services/pdf_file_service.dart`

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfFileService {
  /// Salva o PDF na pasta interna do app (funciona em desktop e Android)
  static Future<String> savePdfToUserFolder({
    required Uint8List bytes,
    required String filename,
  }) async {
    final baseDir = await _resolveBaseDir();

    final pdfDir = Directory(
      p.join(baseDir.path, 'OficinaApp', 'PDFs'),
    );

    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final filePath = p.join(pdfDir.path, filename);
    await File(filePath).writeAsBytes(bytes, flush: true);

    return filePath;
  }

  /// No Android compartilha o PDF via share_plus (WhatsApp, Drive, etc)
  /// No desktop abre a pasta onde o PDF foi salvo
  static Future<void> openFileFolder(String filePath) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Orçamento OficinaApp',
      );
      return;
    }

    // Desktop: abre a pasta
    final dirPath = File(filePath).parent.path;
    final uri = Uri.file(dirPath);
    // url_launcher só no desktop — import condicional não necessário
    // pois o código mobile nunca chega aqui
    throw UnimplementedError(
      'Abertura de pasta não suportada nesta plataforma.',
    );
  }

  static Future<Directory> _resolveBaseDir() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.trim().isNotEmpty) {
        final docsDir = Directory(p.join(userProfile, 'Documents'));
        if (await docsDir.exists()) return docsDir;
      }
    }
    return getApplicationDocumentsDirectory();
  }
}
```

**Observação:** em `openFileFolder`, o branch desktop monta `uri` (`Uri.file(dirPath)`) e nunca o usa — a função lança `UnimplementedError` incondicionalmente para desktop, e o `flutter analyze` reporta essa variável como `unused_local_variable` (ver seção 7).

### `lib/services/db_service_io.dart` — parte 1/2 (schema, migrações, integridade)

```dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cliente.dart';
import '../models/backup_manifest.dart';
import '../models/empresa.dart';
import '../models/nota.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import '../models/veiculo.dart';
import '../core/constants/app_version.dart';
import 'app_logger.dart';

class DBService {
  DBService._();
  static final DBService instance = DBService._();
  static const int schemaVersion = 2;
  static const String _backupFolderName = 'OficinaAppBackups';

  Database? _database;
  String? _activeUserId;

  Future<void> setActiveUserId(
    String? userId, {
    bool migrateLegacyIfNeeded = false,
  }) async {
    if (_activeUserId == userId) return;

    _activeUserId = userId;

    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
  if (_database != null) return _database!;

  final dir = await getApplicationDocumentsDirectory();
  final path = join(
    dir.path,
    "oficina_${_activeUserId ?? "default"}.db",
  );

  _database = await openDatabase(
    path,
    version: schemaVersion,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
    onOpen: _onOpen,
  );

  return _database!;
}

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE clientes(
id TEXT PRIMARY KEY,
nome TEXT,
telefone TEXT,
endereco TEXT,
dataCadastro TEXT,
observacoes TEXT,
tipo TEXT,
nomeSeguradora TEXT,
cnpj TEXT,
contato TEXT
)
''');

    await db.execute('''
CREATE TABLE veiculos(
id TEXT PRIMARY KEY,
clienteId TEXT,
marca TEXT,
modelo TEXT,
cor TEXT,
placa TEXT,
ano INTEGER,
observacoes TEXT
)
''');

    await db.execute('''
CREATE TABLE orcamentos(
id TEXT PRIMARY KEY,
clienteId TEXT,
clienteNome TEXT,
veiculoId TEXT,
veiculoDescricao TEXT,
itens TEXT,
valorTotal REAL,
status TEXT,
dataCriacao TEXT,
dataAprovacao TEXT,
dataConclusao TEXT,
dataPagamento TEXT,
pago INTEGER,
observacoes TEXT,
observacoesCliente TEXT,
observacoesInternas TEXT,
dataPrevistaEntrega TEXT,
tipoAtendimento TEXT
)
''');

    await db.execute('''
CREATE TABLE transacoes(
id TEXT PRIMARY KEY,
tipo TEXT,
descricao TEXT,
valor REAL,
categoria TEXT,
data TEXT,
orcamentoId TEXT,
observacoes TEXT
)
''');

    await db.execute('''
CREATE TABLE notas(
id TEXT PRIMARY KEY,
orcamentoId TEXT,
clienteId TEXT,
clienteNome TEXT,
veiculoId TEXT,
veiculoDescricao TEXT,
itens TEXT,
valorTotal REAL,
dataEmissao TEXT
)
''');

    await db.execute('''
CREATE TABLE empresa(
id TEXT PRIMARY KEY,
nome TEXT,
telefone TEXT,
endereco TEXT,
cnpj TEXT
)
''');

    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await AppLogger.instance.info(
      'Migrando banco do schema $oldVersion para $newVersion',
    );
    await _ensureLatestSchema(db);
  }

  Future<void> _onOpen(Database db) async {
    await _ensureLatestSchema(db);
    await _validateDatabaseIntegrity(db);
  }

  Future<void> _ensureLatestSchema(Database db) async {
    await _ensureTableExists(
      db,
      'clientes',
      '''
CREATE TABLE clientes(
id TEXT PRIMARY KEY,
nome TEXT,
telefone TEXT,
endereco TEXT,
dataCadastro TEXT,
observacoes TEXT,
tipo TEXT,
nomeSeguradora TEXT,
cnpj TEXT,
contato TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'veiculos',
      '''
CREATE TABLE veiculos(
id TEXT PRIMARY KEY,
clienteId TEXT,
marca TEXT,
modelo TEXT,
cor TEXT,
placa TEXT,
ano INTEGER,
observacoes TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'orcamentos',
      '''
CREATE TABLE orcamentos(
id TEXT PRIMARY KEY,
clienteId TEXT,
clienteNome TEXT,
veiculoId TEXT,
veiculoDescricao TEXT,
itens TEXT,
valorTotal REAL,
status TEXT,
dataCriacao TEXT,
dataAprovacao TEXT,
dataConclusao TEXT,
dataPagamento TEXT,
pago INTEGER,
observacoes TEXT,
observacoesCliente TEXT,
observacoesInternas TEXT,
dataPrevistaEntrega TEXT,
tipoAtendimento TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'transacoes',
      '''
CREATE TABLE transacoes(
id TEXT PRIMARY KEY,
tipo TEXT,
descricao TEXT,
valor REAL,
categoria TEXT,
data TEXT,
orcamentoId TEXT,
observacoes TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'notas',
      '''
CREATE TABLE notas(
id TEXT PRIMARY KEY,
orcamentoId TEXT,
clienteId TEXT,
clienteNome TEXT,
veiculoId TEXT,
veiculoDescricao TEXT,
itens TEXT,
valorTotal REAL,
dataEmissao TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'empresa',
      '''
CREATE TABLE empresa(
id TEXT PRIMARY KEY,
nome TEXT,
telefone TEXT,
endereco TEXT,
cnpj TEXT
)
''',
    );

    await _ensureColumnExists(db, 'clientes', 'endereco', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'dataCadastro', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'observacoes', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'tipo', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'nomeSeguradora', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'cnpj', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'contato', 'TEXT');

    await _ensureColumnExists(db, 'veiculos', 'cor', 'TEXT');
    await _ensureColumnExists(db, 'veiculos', 'observacoes', 'TEXT');

    await _ensureColumnExists(db, 'orcamentos', 'veiculoId', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'veiculoDescricao', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'itens', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'observacoes', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'observacoesCliente', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'observacoesInternas', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'dataPrevistaEntrega', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'tipoAtendimento', 'TEXT');

    await _ensureColumnExists(db, 'transacoes', 'observacoes', 'TEXT');

    await _ensureColumnExists(db, 'notas', 'clienteId', 'TEXT');
    await _ensureColumnExists(db, 'notas', 'veiculoId', 'TEXT');
    await _ensureColumnExists(db, 'notas', 'veiculoDescricao', 'TEXT');
    await _ensureColumnExists(db, 'notas', 'itens', 'TEXT');
    await _ensureColumnExists(db, 'notas', 'valorTotal', 'REAL');
    await _ensureColumnExists(db, 'notas', 'dataEmissao', 'TEXT');

    await _ensureColumnExists(db, 'empresa', 'cnpj', 'TEXT');

    await _migrateLegacyData(db);
    await _createIndexes(db);
  }

  Future<void> _ensureTableExists(
    Database db,
    String table,
    String createSql,
  ) async {
    final rows = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', table],
      limit: 1,
    );
    if (rows.isNotEmpty) return;
    await db.execute(createSql);
  }

  Future<void> _ensureColumnExists(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (exists) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _migrateLegacyData(Database db) async {
    await db.execute('''
UPDATE clientes
SET dataCadastro = COALESCE(dataCadastro, CURRENT_TIMESTAMP),
    tipo = COALESCE(tipo, 'particular')
''');

    final notaColumns = await db.rawQuery('PRAGMA table_info(notas)');
    final hasLegacyDataColumn = notaColumns.any((row) => row['name'] == 'data');
    final hasValorTotalColumn =
        notaColumns.any((row) => row['name'] == 'valorTotal');
    final hasLegacyValorColumn =
        notaColumns.any((row) => row['name'] == 'valor');

    if (hasLegacyDataColumn) {
      await db.execute('''
UPDATE notas
SET dataEmissao = COALESCE(dataEmissao, data)
''');
    }

    if (hasLegacyValorColumn && hasValorTotalColumn) {
      await db.execute('''
UPDATE notas
SET valorTotal = COALESCE(valorTotal, valor)
''');
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
CREATE UNIQUE INDEX IF NOT EXISTS idx_transacoes_orcamento_unique
ON transacoes(orcamentoId)
WHERE orcamentoId IS NOT NULL
''');
  }

  Future<void> _validateDatabaseIntegrity(Database db) async {
    final result = await db.rawQuery('PRAGMA integrity_check');
    final value = result.isNotEmpty ? result.first.values.first?.toString() : null;
    if (value != 'ok') {
      throw StateError('Falha na integridade do banco local.');
    }
  }
```

### `lib/services/db_service_io.dart` — parte 2/2 (CRUD, backup/restore)

```dart
  // ================= CLIENTES =================

  Future<void> insertCliente(Cliente c) async {
    final db = await database;

    await db.insert(
      "clientes",
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Cliente>> getClientes() async {
    final db = await database;
    final result = await db.query("clientes");

    return result.map((e) => Cliente.fromMap(e)).toList();
  }

  Future<void> updateCliente(Cliente c) async {
    final db = await database;

    await db.update(
      "clientes",
      c.toMap(),
      where: "id = ?",
      whereArgs: [c.id],
    );
  }

  Future<void> deleteCliente(String id) async {
    final db = await database;

    await db.delete(
      "clientes",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ================= VEÍCULOS =================

  Future<void> insertVeiculo(Veiculo v) async {
    final db = await database;

    await db.insert(
      "veiculos",
      v.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Veiculo>> getVeiculos() async {
    final db = await database;

    final result = await db.query("veiculos");

    return result.map((e) => Veiculo.fromMap(e)).toList();
  }

  Future<void> updateVeiculo(Veiculo v) async {
    final db = await database;

    await db.update(
      "veiculos",
      v.toMap(),
      where: "id = ?",
      whereArgs: [v.id],
    );
  }

  Future<void> deleteVeiculo(String id) async {
    final db = await database;

    await db.delete(
      "veiculos",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ================= ORÇAMENTOS =================

  Future<void> insertOrcamento(Orcamento o) async {
    final db = await database;

    await db.insert(
      "orcamentos",
      _serializeOrcamento(o),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Orcamento>> getOrcamentos() async {
    final db = await database;

    final result = await db.query("orcamentos");

    return result.map((e) => Orcamento.fromMap(_deserializeOrcamento(e))).toList();
  }

  Future<void> updateOrcamento(Orcamento o) async {
    final db = await database;

    await db.update(
      "orcamentos",
      _serializeOrcamento(o),
      where: "id = ?",
      whereArgs: [o.id],
    );
  }

  Future<void> deleteOrcamento(String id) async {
    final db = await database;

    await db.delete(
      "orcamentos",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ================= TRANSAÇÕES =================

  Future<void> insertTransacao(Transacao t) async {
    final db = await database;

    await db.insert(
      "transacoes",
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Transacao>> getTransacoes() async {
    final db = await database;

    final result = await db.query(
      "transacoes",
      orderBy: "data DESC",
    );

    return result.map((e) => Transacao.fromMap(e)).toList();
  }

  Future<void> deleteTransacao(String id) async {
    final db = await database;

    await db.delete(
      "transacoes",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<Transacao?> getTransacaoById(String id) async {
    final db = await database;

    final rows = await db.query(
      "transacoes",
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Transacao.fromMap(rows.first);
  }

  // 🔐 proteção contra duplicidade por orçamento

  Future<Transacao?> getTransacaoByOrcamentoId(String orcamentoId) async {
    final db = await database;

    final rows = await db.query(
      "transacoes",
      where: "orcamentoId = ?",
      whereArgs: [orcamentoId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Transacao.fromMap(rows.first);
  }

  // ================= NOTAS =================

  Future<void> insertNota(Nota nota) async {
    final db = await database;

    await db.insert(
      "notas",
      _serializeNota(nota),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Nota>> getNotas() async {
    final db = await database;

    final result = await db.query(
      "notas",
      orderBy: "dataEmissao DESC",
    );

    return result.map((e) => Nota.fromMap(_deserializeNota(e))).toList();
  }

  // ================= EMPRESA =================

  Future<Empresa?> getEmpresa() async {
    final db = await database;

    final result = await db.query("empresa", limit: 1);

    if (result.isEmpty) return null;

    return Empresa.fromMap(result.first);
  }

  Future<void> saveEmpresa(Empresa empresa) async {
    final db = await database;

    await db.insert(
      "empresa",
      empresa.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateEmpresa(Empresa empresa) async {
    final db = await database;

    await db.update(
      "empresa",
      empresa.toMap(),
      where: "id = ?",
      whereArgs: [empresa.id],
    );
  }

  // ================= BACKUP =================

  Future<String> exportBackupToUserDocuments() async {
    final db = await database;

    final dbPath = db.path;
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = await _ensureBackupDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final userId = _activeUserId ?? 'default';
    final backupBaseName = 'backup_oficina_${userId}_$stamp';
    final backupPath = join(backupDir.path, '$backupBaseName.db');
    final manifestPath = join(backupDir.path, '$backupBaseName.json');
    final legacyBackupPath = join(docsDir.path, 'backup_oficina.db');

    final backupFile = await File(dbPath).copy(backupPath);
    await File(dbPath).copy(legacyBackupPath);
    final manifest = BackupManifest(
      id: backupBaseName,
      dbPath: backupFile.path,
      manifestPath: manifestPath,
      fileName: '$backupBaseName.db',
      createdAtIso: DateTime.now().toIso8601String(),
      userId: userId,
      appVersion: AppVersion.current,
      schemaVersion: schemaVersion,
      fileSizeBytes: await backupFile.length(),
    );

    await File(manifestPath).writeAsString(jsonEncode(manifest.toMap()));
    await AppLogger.instance.info('Backup exportado: ${backupFile.path}');
    return backupFile.path;
  }

  Future<List<BackupManifest>> listAvailableBackups() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = await _ensureBackupDirectory();
    final manifestFiles = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => extension(f.path).toLowerCase() == '.json')
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    final backups = <BackupManifest>[];
    for (final file in manifestFiles) {
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        final manifest = BackupManifest.fromMap(decoded);
        final dbFile = File(manifest.dbPath);
        if (!await dbFile.exists()) continue;
        backups.add(manifest);
      } catch (_) {
        continue;
      }
    }

    final legacyBackup = File(join(docsDir.path, 'backup_oficina.db'));
    if (await legacyBackup.exists()) {
      final stat = await legacyBackup.stat();
      backups.add(
        BackupManifest(
          id: 'legacy_backup_oficina',
          dbPath: legacyBackup.path,
          manifestPath: '',
          fileName: 'backup_oficina.db',
          createdAtIso: stat.modified.toIso8601String(),
          userId: _activeUserId ?? 'default',
          appVersion: 'legado',
          schemaVersion: 1,
          fileSizeBytes: await legacyBackup.length(),
        ),
      );
    }

    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  Future<String> restoreBackupFromUserDocuments([String? manifestId]) async {
    final backups = await listAvailableBackups();
    if (backups.isEmpty) {
      throw StateError('Nenhum backup disponível para restauração.');
    }

    BackupManifest? selected;
    if (manifestId == null) {
      selected = backups.first;
    } else {
      for (final backup in backups) {
        if (backup.id == manifestId) {
          selected = backup;
          break;
        }
      }
    }

    if (selected == null) {
      throw StateError('Backup selecionado não encontrado.');
    }

    await _validateBackupManifest(selected);

    final dir = await getApplicationDocumentsDirectory();
    final targetPath = join(dir.path, "oficina_${_activeUserId ?? "default"}.db");

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      final safetyPath = join(
        dir.path,
        "oficina_${_activeUserId ?? "default"}_antes_restauracao.db",
      );
      await targetFile.copy(safetyPath);
      await targetFile.delete();
    }

    await _deleteIfExists('$targetPath-wal');
    await _deleteIfExists('$targetPath-shm');

    return _restoreBackupFile(
      sourcePath: selected.dbPath,
      sourceLabel: selected.fileName,
      targetPath: targetPath,
    );
  }

  Future<String> restoreBackupFromFilePath(String filePath) async {
    final sourceFile = File(filePath);
    if (!await sourceFile.exists()) {
      throw StateError('Arquivo de backup não encontrado.');
    }
    if (await sourceFile.length() <= 0) {
      throw StateError('Arquivo de backup está vazio.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final targetPath = join(dir.path, "oficina_${_activeUserId ?? "default"}.db");

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      final safetyPath = join(
        dir.path,
        "oficina_${_activeUserId ?? "default"}_antes_restauracao.db",
      );
      await targetFile.copy(safetyPath);
      await targetFile.delete();
    }

    await _deleteIfExists('$targetPath-wal');
    await _deleteIfExists('$targetPath-shm');

    return _restoreBackupFile(
      sourcePath: filePath,
      sourceLabel: basename(filePath),
      targetPath: targetPath,
    );
  }

  Future<String> _restoreBackupFile({
    required String sourcePath,
    required String sourceLabel,
    required String targetPath,
  }) async {
    await File(sourcePath).copy(targetPath);
    await AppLogger.instance.warning(
      'Backup restaurado para ${_activeUserId ?? "default"} a partir de $sourceLabel',
    );
    return targetPath;
  }

  Future<void> _validateBackupManifest(BackupManifest manifest) async {
    if (manifest.userId.trim().isEmpty) {
      throw StateError('Backup inválido: usuário não informado.');
    }
    if (_activeUserId != null && manifest.userId != _activeUserId) {
      throw StateError(
        'Este backup pertence ao usuário ${manifest.userId} e não ao usuário atual.',
      );
    }
    if (manifest.schemaVersion > schemaVersion) {
      throw StateError(
        'O backup foi criado por uma versão mais nova do aplicativo.',
      );
    }
    final dbFile = File(manifest.dbPath);
    if (!await dbFile.exists()) {
      throw StateError('Arquivo do backup não encontrado.');
    }
    if (await dbFile.length() <= 0) {
      throw StateError('Arquivo do backup está vazio.');
    }
  }

  Map<String, dynamic> _serializeOrcamento(Orcamento o) {
    final map = Map<String, dynamic>.from(o.toMap());
    map['itens'] = jsonEncode(map['itens']);
    return map;
  }

  Map<String, dynamic> _deserializeOrcamento(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['itens'] = _decodeJsonList(map['itens']);
    return map;
  }

  Map<String, dynamic> _serializeNota(Nota nota) {
    final map = Map<String, dynamic>.from(nota.toMap());
    map['itens'] = jsonEncode(map['itens']);
    return map;
  }

  Map<String, dynamic> _deserializeNota(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['itens'] = _decodeJsonList(map['itens']);
    if (map['dataEmissao'] == null && row['data'] != null) {
      map['dataEmissao'] = row['data'];
    }
    if (map['valorTotal'] == null && row['valor'] != null) {
      map['valorTotal'] = row['valor'];
    }
    return map;
  }

  List<dynamic> _decodeJsonList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    }
    return const [];
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _ensureBackupDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(join(docsDir.path, _backupFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
```

**Observações da camada de dados:**
- Um único arquivo `.db` por usuário (`oficina_<userId>.db`) em `ApplicationDocumentsDirectory`; sem migração/journaling além de `_ensureTableExists`/`_ensureColumnExists` manuais (não usa `ALTER TABLE` idempotente do sqflite nem um sistema de migrations versionado por arquivo).
- `exportBackupToUserDocuments` grava **dois** arquivos de backup redundantes: o novo (`OficinaAppBackups/backup_oficina_<user>_<timestamp>.db` + `.json` de manifest) e um "legado" fixo (`backup_oficina.db`, sobrescrito a cada export, sem versionamento).
- `restoreBackupFromFilePath`/`restoreBackupFromUserDocuments` fecham a conexão, copiam um "safety backup" (`_antes_restauracao.db`) antes de sobrescrever, e removem os arquivos `-wal`/`-shm` remanescentes — mas não há transação atômica entre a cópia do safety backup e a substituição do banco ativo (uma falha entre as duas operações pode deixar o app sem `_database` referenciando um arquivo inconsistente até o próximo `database` getter).
- `setActiveUserId` fecha a conexão ao trocar de usuário, mas não há lock contra chamadas concorrentes (`database` getter e troca de usuário podem correr em paralelo).

---

## 6. Responsividade e navegação

Não existe `lib/widgets/responsive_layout.dart` como arquivo isolado — toda a lógica de responsividade (breakpoints, utilitários, `ResponsiveLayout` app-level, `ResponsiveDialog`, `ResponsiveListCard`, etc.) está em `lib/core/components/responsive_components.dart` (1199 linhas). Segue completo, em 4 partes.

### `lib/core/components/responsive_components.dart` — parte 1/4 (breakpoints, `ResponsiveUtils`, widgets utilitários)

```dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../constants/app_version.dart';
import '../../models/backup_manifest.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/db_service.dart';
import '../../screens/empresa_screen.dart';
import 'package:share_plus/share_plus.dart';

// --- Responsive utilities (consolidated)
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;

  static const double maxContentWidth = 1200;
  static const double maxMobileContent = 400;
  static const double maxTabletContent = 800;
}

enum DeviceType { mobile, tablet, desktop }

class ResponsiveUtils {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.mobile) return DeviceType.mobile;
    if (width < ResponsiveBreakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;
  static bool isMobileOrTablet(BuildContext context) => !isDesktop(context);

  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth * 0.95;
      case DeviceType.tablet:
        return screenWidth * 0.85;
      case DeviceType.desktop:
        return screenWidth > ResponsiveBreakpoints.maxContentWidth
            ? ResponsiveBreakpoints.maxContentWidth
            : screenWidth * 0.8;
    }
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(24);
      case DeviceType.desktop:
        return const EdgeInsets.all(32);
    }
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return const EdgeInsets.all(12);
      case DeviceType.tablet:
        return const EdgeInsets.all(14);
      case DeviceType.desktop:
        return const EdgeInsets.all(16);
    }
  }

  static double getCardSpacing(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return 12;
      case DeviceType.tablet:
        return 14;
      case DeviceType.desktop:
        return 16;
    }
  }

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.mobile) return 1;
    if (width < ResponsiveBreakpoints.tablet) return 2;
    if (width < ResponsiveBreakpoints.desktop) return 3;
    return 4;
  }

  static double getFontSizeMultiplier(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.2;
    }
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    switch (ResponsiveUtils.getDeviceType(context)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool centerContent;
  final EdgeInsets? customPadding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.centerContent = true,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    final contentWidth = ResponsiveUtils.getContentWidth(context);
    final padding = customPadding ?? ResponsiveUtils.getScreenPadding(context);

    return Container(
      width: double.infinity,
      padding: padding,
      child: centerContent
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: child,
              ),
            )
          : child,
    );
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final EdgeInsets? padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.getGridColumns(context);
    final spacing = ResponsiveUtils.getCardSpacing(context);
    final screenPadding = padding ?? ResponsiveUtils.getScreenPadding(context);

    return Padding(
      padding: screenPadding,
      child: GridView.count(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio ?? 1.0,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        children: children,
      ),
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final multiplier = ResponsiveUtils.getFontSizeMultiplier(context);
    final base = style ?? const TextStyle(fontSize: 14);
    final adjusted = base.copyWith(
      fontSize: (base.fontSize ?? 14) * multiplier,
    );

    return Text(
      text,
      style: adjusted,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = padding ?? ResponsiveUtils.getCardPadding(context);
    final radius = BorderRadius.circular(18);

    return Card(
      color: color,
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: cardPadding, child: child),
        ),
      ),
    );
  }
}

class ResponsiveStatsGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;

  const ResponsiveStatsGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.getCardSpacing(context) * 0.5;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final crossAxisCount = isDesktop ? 4 : isTablet ? 2 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio:
            childAspectRatio ?? (ResponsiveUtils.isMobile(context) ? 1.9 : 1.6),
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}
```

### `lib/core/components/responsive_components.dart` — parte 2/4 (`ResponsiveLayout`: shell, logout, backup/restore, ajuda)

```dart
// --- App-level Responsive Layout
class ResponsiveLayout extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTap;
  final String title;

  const ResponsiveLayout({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará fazer login novamente para acessar o sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _confirmAndRestoreBackup(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Selecione o arquivo de backup',
      type: FileType.custom,
      allowedExtensions: const ['db'],
      allowMultiple: false,
    );
    if (!context.mounted || picked == null || picked.files.isEmpty) return;

    final selectedPath = picked.files.single.path;
    final selectedName = picked.files.single.name;
    if (selectedPath == null || selectedPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel acessar o arquivo selecionado.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: Text(
          'O banco atual sera substituido pelos dados do backup '
          '$selectedName.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Restaurando backup...')),
    );

    try {
      final restoredPath = await DBService.instance.restoreBackupFromFilePath(
        selectedPath,
      );
      if (!context.mounted) return;
      await context.read<AppProvider>().reloadActiveUserData();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup restaurado com sucesso: $restoredPath'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao restaurar backup: $e')),
      );
    }
  }

  Future<BackupManifest?> _selectBackupToRestore(
    BuildContext context,
    List<BackupManifest> backups,
  ) async {
    return showDialog<BackupManifest>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escolha um backup'),
        content: SizedBox(
          width: 560,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: backups.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final backup = backups[index];
                final dateLabel = DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(backup.createdAt.toLocal());
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(backup.fileName),
                  subtitle: Text(
                    'Usuario: ${backup.userId}  •  Data: $dateLabel  •  ${_formatBytes(backup.fileSizeBytes)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(ctx).pop(backup),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        Widget sectionTitle(String text) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }

        Widget bullet(String text) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• $text',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.86),
                height: 1.25,
              ),
            ),
          );
        }

        return ResponsiveDialog(
          title: 'Ajuda',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guia rápido do OficinaApp',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                ),
              ),
              sectionTitle('Dashboard'),
              bullet('Mostra os principais números e atalhos do dia.'),
              bullet('Clique em um card para abrir detalhes (quando disponível).'),
              sectionTitle('Clientes'),
              bullet('Cadastre e gerencie os clientes da oficina.'),
              bullet('Use a busca para localizar rapidamente por nome/telefone.'),
              sectionTitle('Orçamentos / Ordens'),
              bullet('Crie, edite e acompanhe o status do orçamento.'),
              bullet('Ações comuns: Aprovar, Iniciar, Concluir, Registrar pagamento.'),
              bullet('Você pode gerar/compartilhar o PDF do orçamento ou da nota de serviço.'),
              sectionTitle('Financeiro'),
              bullet('Acompanhe faturamento e indicadores do período.'),
              bullet('Use os filtros/visões para analisar receitas e despesas.'),
              sectionTitle('Backup (manual)'),
              bullet('Gera um arquivo de backup no seu Documentos.'),
              bullet('Recomendado fazer backup periodicamente.'),
              sectionTitle('PDF / Impressão'),
              bullet('No orçamento/ordem, use “Enviar PDF” para compartilhar.'),
              bullet('Use “Imprimir” para pré-visualizar e imprimir.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
```

**Nota:** `_selectBackupToRestore` está definido mas nunca é chamado — o fluxo real de restauração (`_confirmAndRestoreBackup`, ligado ao menu "Restaurar backup") usa `FilePicker` para escolher o arquivo `.db` diretamente, não a lista de `BackupManifest`. É exatamente o warning `unused_element` reportado pelo `flutter analyze` (seção 7).

### `lib/core/components/responsive_components.dart` — parte 3/4 (layouts mobile/tablet/desktop, bottom nav, nav rail, drawer)

```dart
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarLogo(),
        backgroundColor: AppColors.surface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.white),
            color: AppColors.surface,
            onSelected: (value) async {
              switch (value) {
                case 'empresa':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmpresaScreen()),
                  );
                  break;
                case 'backup':
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Gerando backup...')),
                  );
                  try {
                    final backupPath =
                        await DBService.instance.exportBackupToUserDocuments();
                    // Compartilha o arquivo via share_plus
                    await Share.shareXFiles(
                      [XFile(backupPath)],
                      subject: 'Backup OficinaApp',
                      text: 'Backup do banco de dados da oficina.',
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao gerar backup: $e')),
                    );
                  }
                  break;
                case 'restaurar':
                  if (!context.mounted) return;
                  await _confirmAndRestoreBackup(context);
                  break;
                case 'ajuda':
                  if (!context.mounted) return;
                  _showHelpDialog(context);
                  break;
                case 'sair':
                  if (!context.mounted) return;
                  await _confirmAndLogout(context);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'empresa',
                child: Row(children: [
                  Icon(Icons.business, size: 18),
                  SizedBox(width: 10),
                  Text('Dados da Oficina'),
                ]),
              ),
              PopupMenuItem(
                value: 'backup',
                child: Row(children: [
                  Icon(Icons.cloud_upload, size: 18),
                  SizedBox(width: 10),
                  Text('Backup'),
                ]),
              ),
              PopupMenuItem(
                value: 'restaurar',
                child: Row(children: [
                  Icon(Icons.restore, size: 18),
                  SizedBox(width: 10),
                  Text('Restaurar backup'),
                ]),
              ),
              PopupMenuItem(
                value: 'ajuda',
                child: Row(children: [
                  Icon(Icons.help, size: 18),
                  SizedBox(width: 10),
                  Text('Ajuda'),
                ]),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'sair',
                child: Row(children: [
                  Icon(Icons.logout, size: 18, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Sair', style: TextStyle(color: Colors.redAccent)),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: body,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSideNavigationRail(context),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(title),
                centerTitle: true,
                backgroundColor: AppColors.surface,
                automaticallyImplyLeading: false,
              ),
              body: body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSideNavigationDrawer(context),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(title),
                centerTitle: true,
                backgroundColor: AppColors.surface,
                automaticallyImplyLeading: false,
              ),
              body: body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primaryYellow,
      unselectedItemColor: AppColors.white.withValues(alpha: 0.6),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: 'Orçamentos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Financeiro',
        ),
      ],
    );
  }

  Widget _buildSideNavigationRail(BuildContext context) {
    return NavigationRail(
      backgroundColor: AppColors.surface,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: AppColors.primaryYellow),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.primaryYellow,
        fontWeight: FontWeight.w600,
      ),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      unselectedLabelTextStyle: const TextStyle(color: AppColors.textSecondary),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IconButton(
          icon: const Icon(Icons.logout, color: AppColors.white),
          tooltip: 'Sair',
          onPressed: () => _confirmAndLogout(context),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people),
          label: Text('Clientes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.description),
          label: Text('Orçamentos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.attach_money),
          label: Text('Financeiro'),
        ),
      ],
    );
  }

  Widget _buildSideNavigationDrawer(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            height: 96,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                const DrawerLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'OficinaApp',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gestão completa',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people,
                  title: 'Clientes',
                  index: 1,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.description,
                  title: 'Orçamentos',
                  index: 2,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.attach_money,
                  title: 'Financeiro',
                  index: 3,
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.border, height: 1),
                _buildDrawerActionItem(
                  context,
                  icon: Icons.business,
                  title: 'Dados da Oficina',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmpresaScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerActionItem(
                  context,
                  icon: Icons.cloud_upload,
                  title: 'Backup (manual)',
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Iniciando backup...')),
                    );
                    try {
                      final backupPath = await DBService.instance
                          .exportBackupToUserDocuments();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Backup salvo em: $backupPath'),
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Erro ao gerar backup: $e')),
                      );
                    }
                  },
                ),
                _buildDrawerActionItem(
                  context,
                  icon: Icons.restore,
                  title: 'Restaurar backup',
                  onTap: () => _confirmAndRestoreBackup(context),
                ),
                _buildDrawerActionItem(
                  context,
                  icon: Icons.help,
                  title: 'Ajuda',
                  onTap: () => _showHelpDialog(context),
                ),
                const Divider(color: AppColors.border, height: 1),
                _buildDrawerActionItem(
                  context,
                  icon: Icons.logout,
                  title: 'Sair',
                  onTap: () => _confirmAndLogout(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Versão ${AppVersion.current}',
              style: const TextStyle(color: AppColors.lightGray, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
  }) {
    return _buildDrawerEntry(
      context,
      icon: icon,
      title: title,
      isSelected: currentIndex == index,
      onTap: () => onTap(index),
    );
  }

  Widget _buildDrawerActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return _buildDrawerEntry(
      context,
      icon: icon,
      title: title,
      isSelected: false,
      onTap: onTap,
    );
  }

  Widget _buildDrawerEntry(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    bool hovering = false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: StatefulBuilder(
        builder: (ctx, setState) {
          return MouseRegion(
            onEnter: (_) => setState(() => hovering = true),
            onExit: (_) => setState(() => hovering = false),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.surface2
                      : (hovering
                          ? AppColors.surface.withValues(alpha: 0.45)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.border : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: hovering && !isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isSelected ? 6 : (hovering ? 6 : 4),
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryYellow
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      icon,
                      color: isSelected
                          ? AppColors.primaryYellow
                          : (hovering
                              ? AppColors.white.withValues(alpha: 0.95)
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : (hovering
                                  ? AppColors.white.withValues(alpha: 0.95)
                                  : AppColors.textSecondary),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

**Breakpoints do app (`ResponsiveBreakpoints`):** mobile `< 600`, tablet `600–1023`, desktop `≥ 1024` (largura lógica). `ResponsiveLayout` troca a casca inteira por tipo de dispositivo: mobile = `Scaffold` + `AppBar` + `BottomNavigationBar`; tablet = `NavigationRail` lateral + `AppBar` centralizado; desktop = drawer lateral fixo de 280px + `AppBar` centralizado. As três variantes duplicam os itens de menu (Dashboard/Clientes/Orçamentos/Financeiro) e as ações de backup/restaurar/ajuda/sair de forma independente (sem uma fonte única de verdade para a lista de destinos).

### `lib/core/components/responsive_components.dart` — parte 4/4 (`ResponsiveListCard`, `ResponsiveDialog`)

```dart
class ResponsiveListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const ResponsiveListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final fontMultiplier = ResponsiveUtils.getFontSizeMultiplier(context);

    return ResponsiveCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: isDesktop ? 16 : 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: (isDesktop ? 17 : 15) * fontMultiplier,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: (isDesktop ? 13 : 11) * fontMultiplier,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (ctx, c) {
                final isNarrow = c.maxWidth < 420;
                return Wrap(
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 6,
                  children: actions!
                      .map(
                        (w) => ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: isNarrow ? 96 : 108,
                          ),
                          child: w,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class ResponsiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final fontMultiplier = ResponsiveUtils.getFontSizeMultiplier(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 150),
        curve: Curves.decelerate,
        child: Container(
          width: isDesktop ? 520 : ResponsiveUtils.getContentWidth(context),
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20 * fontMultiplier,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 16),
                content,
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: actions!
                        .map(
                          (a) => ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 140),
                            child: a,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

`ResponsiveDialog` é o dialog genérico compartilhado por praticamente todos os modais desktop do app (`_showClienteDetails`, `ClienteFormDialog` no desktop, `_showAddVeiculoDialog`, `_showHelpDialog`, etc.) — é aqui, na linha do título (`color: AppColors.primaryYellow`), que está o bug relatado na seção 10.

### `lib/main.dart`

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/widgets/update_gate.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const WebNotSupportedScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AppProvider>(
          create: (_) => AppProvider()..initApp(),
          update: (_, auth, app) {
            app ??= AppProvider()..initApp();
            app.syncAuthUser(auth.currentUser);
            return app;
          },
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (_) => const UpdateGate(child: AuthWrapper()),
          '/home': (_) => const HomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
        },
      ),
    );
  }
}

class WebNotSupportedScreen extends StatelessWidget {
  const WebNotSupportedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plataforma não suportada'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este app usa banco local (SQLite) e recursos de arquivos (dart:io).\n'
            'Nesta versão, o Flutter Web não é suportado.\n\n'
            'Use Android/iOS/Windows/Linux/macOS para rodar o sistema.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
```

**Navegação:** rotas nomeadas simples (`'/'`, `'/home'`, `'/login'`, `'/register'`) via `MaterialApp.routes`, sem `onGenerateRoute`/`onUnknownRoute` nem pacote de roteamento (`go_router` etc.). A navegação entre as 4 telas principais (Dashboard/Clientes/Orçamentos/Financeiro) **não** usa rotas nomeadas — é feita via `_currentIndex` local em `HomeScreen` (ver abaixo), então essas telas nunca aparecem na pilha do `Navigator` nem têm URL/rota própria.

### `lib/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/components/responsive_components.dart';
import '../core/utils/app_feedback.dart';
import '../providers/app_provider.dart';
import 'dashboard_screen.dart';
import 'clientes_screen.dart';
import 'orcamentos_screen.dart';
import 'financeiro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ClientesScreen(),
    OrcamentosScreen(),
    FinanceiroScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Clientes',
    'Orçamentos',
    'Financeiro',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final error = app.lastErrorMessage;
    if (error != null && error.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        AppFeedback.showError(context, error);
        context.read<AppProvider>().clearLastError();
      });
    }

    return ResponsiveLayout(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      title: _titles[_currentIndex],
      body: _screens[_currentIndex],
    );
  }
}
```

**Nota:** os 4 `_screens` são criados uma única vez em uma `List<Widget> const`, mas `ResponsiveLayout` recebe apenas `body: _screens[_currentIndex]` (um único widget por vez, não um `IndexedStack`) — ou seja, ao trocar de aba a tela anterior é desmontada e a nova é remontada do zero (sem preservação de scroll/estado local entre abas), apesar da lista de widgets em si ser criada apenas uma vez.

---

## 7. Estado de qualidade

### `flutter --version`

```
Flutter 3.35.7 • channel stable • https://github.com/flutter/flutter.git
Framework • revision adc9010625 (9 months ago) • 2025-10-21 14:16:03 -0400
Engine • hash 6b24e1b529bc46df7ff397667502719a2a8b6b72 (revision 035316565a) (9 months ago) • 2025-10-21 14:28:01.000Z
Tools • Dart 3.9.2 • DevTools 2.48.0
```

### `flutter analyze`

```
Analyzing OficinaApp...                                         

warning • The declaration '_selectBackupToRestore' isn't referenced • lib/core/components/responsive_components.dart:424:27 • unused_element
   info • 'Share' is deprecated and shouldn't be used. Use SharePlus instead • lib/core/components/responsive_components.dart:567:27 • deprecated_member_use
   info • 'shareXFiles' is deprecated and shouldn't be used. Use SharePlus.instance.share() instead • lib/core/components/responsive_components.dart:567:33 • deprecated_member_use
   info • Statements in an if should be enclosed in a block • lib/screens/clientes_screen.dart:910:31 • curly_braces_in_flow_control_structures
   info • 'Share' is deprecated and shouldn't be used. Use SharePlus instead • lib/screens/order_detail_screen.dart:170:15 • deprecated_member_use
   info • 'shareXFiles' is deprecated and shouldn't be used. Use SharePlus.instance.share() instead • lib/screens/order_detail_screen.dart:170:21 • deprecated_member_use
   info • 'Share' is deprecated and shouldn't be used. Use SharePlus instead • lib/services/pdf_file_service.dart:34:13 • deprecated_member_use
   info • 'shareXFiles' is deprecated and shouldn't be used. Use SharePlus.instance.share() instead • lib/services/pdf_file_service.dart:34:19 • deprecated_member_use
warning • The value of the local variable 'uri' isn't used • lib/services/pdf_file_service.dart:43:11 • unused_local_variable

9 issues found. (ran in 29.2s)
```

(`lib/archive/**` e `tool/_orcamento_form_dialog_prev.dart` estão excluídos da análise via `analysis_options.yaml` — ver seção 2.)

### `flutter pub outdated`

```
Showing outdated packages.
[*] indicates versions that are not the latest available.

Package Name                               Current     Upgradable  Resolvable  Latest     

direct dependencies:                      
cupertino_icons                            *1.0.8      1.0.9       1.0.9       1.0.9      
file_picker                                *8.3.7      *8.3.7      11.0.3      11.0.3     
fl_chart                                   *0.68.0     *0.68.0     1.2.0       1.2.0      
flutter_image_compress                     *2.4.0      2.5.1       2.5.1       2.5.1      
flutter_secure_storage                     *9.2.4      *9.2.4      10.3.1      10.3.1     
image_picker                               *0.8.9      *0.8.9      *1.2.2      1.2.3      
intl                                       *0.18.1     *0.18.1     0.20.3      0.20.3     
path_provider                              *2.1.5      *2.1.5      *2.1.5      2.1.6      
pdf                                        *3.11.3     *3.12.0     *3.12.0     3.13.0     
printing                                   *5.14.2     *5.14.3     *5.14.3     5.15.0     
share_plus                                 *12.0.2     *12.0.2     *12.0.2     13.3.0     
shared_preferences                         *2.5.4      2.5.5       2.5.5       2.5.5      
signature                                  *6.3.0      6.4.0       6.4.0       6.4.0      
sqflite                                    *2.4.2      *2.4.2      *2.4.2      2.4.3      
uuid                                       *3.0.7      *3.0.7      4.6.0       4.6.0      

dev_dependencies:                         
flutter_lints                              *5.0.0      *5.0.0      6.0.0       6.0.0      

transitive dependencies:                  
archive                                    *4.0.7      4.0.9       4.0.9       4.0.9      
async                                      *2.13.0     2.13.1      2.13.1      2.13.1     
characters                                 *1.4.0      *1.4.0      *1.4.0      1.4.1      
cross_file                                 *0.3.5+1    *0.3.5+2    *0.3.5+2    0.3.5+4    
dbus                                       -           -           0.7.14      0.7.14     
equatable                                  *2.0.8      2.1.0       2.1.0       2.1.0      
ffi                                        *2.1.5      2.2.0       2.2.0       2.2.0      
fixnum                                     -           -           1.1.1       1.1.1      
flutter_image_compress_common              *1.0.6      1.1.1       1.1.1       1.1.1      
flutter_image_compress_macos               *1.0.3      1.1.0       1.1.0       1.1.0      
flutter_image_compress_ohos                *0.0.3      0.0.3+1     0.0.3+1     0.0.3+1    
flutter_image_compress_platform_interface  *1.0.5      1.1.0       1.1.0       1.1.0      
flutter_image_compress_web                 *0.1.5      0.1.5+1     0.1.5+1     0.1.5+1    
flutter_plugin_android_lifecycle           *2.0.33     *2.0.34     *2.0.34     2.0.35     
flutter_secure_storage_darwin              -           -           *0.3.2      0.4.0      
flutter_secure_storage_linux               *1.2.3      *1.2.3      3.0.1       3.0.1      
flutter_secure_storage_macos               *3.1.3      *3.1.3      -           4.0.0      
flutter_secure_storage_platform_interface  *1.1.2      *1.1.2      2.0.2       2.0.2      
flutter_secure_storage_web                 *1.2.1      *1.2.1      2.1.1       2.1.1      
flutter_secure_storage_windows             *3.1.2      *3.1.2      *4.1.0      4.2.2      
flutter_svg                                *2.2.3      2.3.0       2.3.0       2.3.0      
image                                      *4.5.4      *4.8.0      *4.8.0      4.9.1      
image_picker_android                       *0.8.13+10  *0.8.13+17  *0.8.13+17  0.8.13+19  
image_picker_for_web                       *2.2.0      *2.1.12     3.1.1       3.1.1      
image_picker_ios                           *0.8.13+3   *0.8.13+3   *0.8.13+3   0.8.13+6   
jni                                        -           1.0.3       1.0.3       1.0.3      
jni_flutter                                -           1.0.2       1.0.2       1.0.2      
jni_util                                   -           1.0.0       1.0.0       1.0.0      
js                                         *0.6.7      *0.6.7      -           0.7.2      (discontinued)  
material_color_utilities                   *0.11.1     *0.11.1     *0.11.1     0.13.0     
meta                                       *1.16.0     *1.16.0     *1.16.0     1.19.0     
mime                                       *1.0.6      2.0.0       2.0.0       2.0.0      
package_config                             -           *2.2.0      *2.2.0      3.0.0      
path_provider_android                      *2.2.22     2.3.1       2.3.1       2.3.1      
path_provider_foundation                   *2.5.1      *2.5.1      *2.5.1      2.6.0      
path_provider_linux                        *2.2.1      *2.2.1      *2.2.1      2.2.2      
path_provider_platform_interface           *2.1.2      *2.1.2      *2.1.2      2.1.3      
petitparser                                *7.0.1      7.0.2       7.0.2       7.0.2      
posix                                      *6.0.3      6.5.2       6.5.2       6.5.2      
qr                                         *3.0.2      *3.0.2      *3.0.2      4.0.0      
share_plus_platform_interface              *6.1.0      *6.1.0      *6.1.0      7.2.0      
shared_preferences_android                 *2.4.18     *2.4.23     *2.4.23     2.4.27     
shared_preferences_platform_interface      *2.4.1      2.4.2       2.4.2       2.4.2      
source_span                                *1.10.1     1.10.2      1.10.2      1.10.2     
sqflite_android                            *2.4.2+2    *2.4.2+2    *2.4.2+2    2.4.3      
sqflite_common                             *2.5.6      *2.5.6      *2.5.6      2.5.11     
sqflite_darwin                             *2.4.2      *2.4.2      *2.4.2      2.4.3+1    
sqflite_platform_interface                 *2.4.0      *2.4.0      *2.4.0      2.4.1      
synchronized                               *3.4.0      *3.4.0      *3.4.0      3.4.1+1    
url_launcher_android                       *6.3.29     *6.3.29     *6.3.29     6.3.32     
url_launcher_ios                           *6.3.6      *6.3.6      *6.3.6      6.4.1      
url_launcher_web                           *2.4.1      *2.4.1      *2.4.1      2.4.3      
vector_graphics                            *1.1.19     *1.2.2      *1.2.2      1.2.3      
vector_graphics_compiler                   *1.1.19     *1.2.3      *1.2.3      1.3.0      
vector_math                                *2.2.0      *2.2.0      *2.2.0      2.4.2      
win32                                      *5.15.0     *5.15.0     *5.15.0     6.3.0      
xml                                        *6.6.1      *6.6.1      *6.6.1      7.0.1      

transitive dev_dependencies:              
cli_util                                   *0.4.2      *0.4.2      *0.4.2      0.5.2      
json_annotation                            *4.9.0      4.12.0      4.12.0      4.12.0     
lints                                      *5.1.1      *5.1.1      6.1.0       6.1.0      
matcher                                    *0.12.17    *0.12.17    *0.12.17    0.12.20    
test_api                                   *0.7.6      *0.7.6      *0.7.6      0.7.13     
vm_service                                 *15.0.2     15.2.0      15.2.0      15.2.0     

31 upgradable dependencies are locked (in pubspec.lock) to older versions.
To update these dependencies, use `flutter pub upgrade`.

13  dependencies are constrained to versions that are older than a resolvable version.
To update these dependencies, edit pubspec.yaml, or run `flutter pub upgrade --major-versions`.

js
    Package js has been discontinued. See https://dart.dev/go/package-discontinue
```

**Destaques:** `file_picker` (8→11), `fl_chart` (0.68→1.2, major), `share_plus` (12→13, major, e já reportado como deprecated internamente pelo próprio `flutter analyze` acima), `flutter_secure_storage` (9→10, major), `uuid` (3→4, major), `intl` (0.18→0.20). Pacote transitivo `js` está descontinuado (`discontinued`).

---

## 8. Rastreio de aliases (débito técnico)

O comando pedido (`grep -rn "primaryYellow\|error\|primaryDark\|surface2\|secondaryGray\|lightGray\b" lib/ --include="*.dart"`) foi executado, mas `error`, `white`, `border` e `warning` são palavras muito comuns em Dart/Flutter (nomes de variáveis locais, parâmetros, classes do SDK como `FormFieldState.errorText`, `Border.all`, etc.) — a versão literal do comando retorna **384 linhas**, boa parte delas identificadores não relacionados a `AppColors`.

Para o objetivo real (mapear o uso do design system legado), a busca foi refinada para `AppColors\.(primaryYellow|error|primaryDark|surface2|secondaryGray|lightGray|white|border|warning|textSecondary)\b`, que aponta exatamente as leituras dos aliases/tokens definidos em `app_colors.dart`. Resultado completo (295 ocorrências, todas em `lib/`; `textSecondary` **não é alias** — é um token novo do design system incluído porque o pedido do usuário listou o nome — mantido aqui para completude):

```
lib/archive/dashboard_screen_old_full.dart:101:                AppColors.error,
lib/archive/dashboard_screen_old_full.dart:173:                AppColors.warning,
lib/archive/dashboard_screen_old_full.dart:193:                AppColors.primaryYellow,
lib/archive/dashboard_screen_old_full.dart:19:                color: AppColors.white.withValues(alpha: 0.8),
lib/archive/dashboard_screen_old_full.dart:290:          Icon(icon, color: AppColors.primaryYellow, size: 20),
lib/archive/dashboard_screen_old_full.dart:300:              color: AppColors.primaryYellow,
lib/archive/dashboard_screen_old_full.dart:67:                provider.saldo >= 0 ? AppColors.success : AppColors.error,
lib/archive/dashboard_screen_old_full.dart:77:                provider.saldoMesAtual >= 0 ? AppColors.success : AppColors.error,
lib/archive/financeiro_screen_old_full.dart:125:                AppColors.error,
lib/archive/financeiro_screen_old_full.dart:135:          provider.saldo >= 0 ? AppColors.success : AppColors.error,
lib/archive/financeiro_screen_old_full.dart:158:                color: AppColors.white.withValues(alpha: 0.7),
lib/archive/financeiro_screen_old_full.dart:179:                AppColors.error,
lib/archive/financeiro_screen_old_full.dart:189:          provider.saldoMesAtual >= 0 ? AppColors.success : AppColors.error,
lib/archive/financeiro_screen_old_full.dart:224:                                color: AppColors.primaryYellow,
lib/archive/financeiro_screen_old_full.dart:234:                                color: AppColors.error,
lib/archive/financeiro_screen_old_full.dart:271:                            : AppColors.error,
lib/archive/financeiro_screen_old_full.dart:276:                          color: AppColors.white,
lib/archive/financeiro_screen_old_full.dart:289:                              : AppColors.error,
lib/archive/financeiro_screen_old_full.dart:49:          labelColor: AppColors.primaryYellow,
lib/archive/financeiro_screen_old_full.dart:50:          unselectedLabelColor: AppColors.white,
lib/archive/financeiro_screen_old_full.dart:51:          indicatorColor: AppColors.primaryYellow,
lib/archive/orcamentos_screen_old_full.dart:111:                              color: AppColors.white.withValues(alpha: 0.7),
lib/archive/orcamentos_screen_old_full.dart:133:                              color: AppColors.primaryYellow,
lib/archive/orcamentos_screen_old_full.dart:145:                        color: AppColors.white.withValues(alpha: 0.7),
lib/archive/orcamentos_screen_old_full.dart:155:                        color: AppColors.primaryYellow,
lib/archive/orcamentos_screen_old_full.dart:196:        color = AppColors.warning;
lib/archive/orcamentos_screen_old_full.dart:202:        color = AppColors.primaryYellow;
lib/archive/orcamentos_screen_old_full.dart:208:        color = AppColors.error;
lib/archive/orcamentos_screen_old_full.dart:289:          backgroundColor: AppColors.warning,
lib/archive/orcamentos_screen_old_full.dart:308:            backgroundColor: AppColors.secondaryGray,
lib/archive/orcamentos_screen_old_full.dart:382:                            color: AppColors.lightGray.withValues(alpha: 0.5),
lib/archive/orcamentos_screen_old_full.dart:46:          labelColor: AppColors.primaryYellow,
lib/archive/orcamentos_screen_old_full.dart:47:          unselectedLabelColor: AppColors.white,
lib/archive/orcamentos_screen_old_full.dart:48:          indicatorColor: AppColors.primaryYellow,
lib/core/components/app_buttons.dart:120:          child: Icon(icon, size: 18, color: AppColors.textSecondary),
lib/core/components/cliente_form_dialog.dart:1002:                          backgroundColor: AppColors.primaryYellow,
lib/core/components/cliente_form_dialog.dart:360:        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
lib/core/components/cliente_form_dialog.dart:365:          Icon(icon, size: 16, color: AppColors.textSecondary),
lib/core/components/cliente_form_dialog.dart:370:              color: AppColors.white,
lib/core/components/cliente_form_dialog.dart:431:            style: const TextStyle(color: AppColors.white),
lib/core/components/cliente_form_dialog.dart:450:            style: const TextStyle(color: AppColors.white),
lib/core/components/cliente_form_dialog.dart:467:            style: const TextStyle(color: AppColors.white),
lib/core/components/cliente_form_dialog.dart:481:          style: const TextStyle(color: AppColors.white),
lib/core/components/cliente_form_dialog.dart:495:          style: const TextStyle(color: AppColors.white),
lib/core/components/cliente_form_dialog.dart:512:          style: const TextStyle(color: AppColors.white),
lib/core/components/cliente_form_dialog.dart:523:          style: const TextStyle(color: AppColors.white),
lib/core/components/cliente_form_dialog.dart:539:        color: AppColors.lightGray.withValues(alpha: 0.08),
lib/core/components/cliente_form_dialog.dart:541:        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.25)),
lib/core/components/cliente_form_dialog.dart:552:                color: AppColors.warning.withValues(alpha: 0.10),
lib/core/components/cliente_form_dialog.dart:555:                  color: AppColors.warning.withValues(alpha: 0.28),
lib/core/components/cliente_form_dialog.dart:561:                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
lib/core/components/cliente_form_dialog.dart:567:                        color: AppColors.warning,
lib/core/components/cliente_form_dialog.dart:578:              const Icon(Icons.directions_car, color: AppColors.primaryYellow),
lib/core/components/cliente_form_dialog.dart:584:                    color: AppColors.primaryYellow,
lib/core/components/cliente_form_dialog.dart:615:            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
lib/core/components/cliente_form_dialog.dart:883:                    style: const TextStyle(color: AppColors.white),
lib/core/components/cliente_form_dialog.dart:930:              color: AppColors.primaryYellow,
lib/core/components/cliente_form_dialog.dart:943:                        color: AppColors.primaryYellow,
lib/core/components/cliente_form_dialog.dart:949:                        color: AppColors.primaryYellow,
lib/core/components/cliente_form_dialog.dart:965:                  color: AppColors.secondaryGray,
lib/core/components/cliente_form_dialog.dart:985:                  border: Border(top: BorderSide(color: AppColors.border)),
lib/core/components/common_widgets.dart:28:                color: AppColors.primaryYellow,
lib/core/components/common_widgets.dart:71:              color: AppColors.white.withValues(alpha: 0.3),
lib/core/components/common_widgets.dart:78:                color: AppColors.white.withValues(alpha: 0.5),
lib/core/components/common_widgets.dart:85:                color: AppColors.white.withValues(alpha: 0.4),
lib/core/components/form_styles.dart:17:        ? Icon((prefixIcon ?? icon)!, color: AppColors.primaryYellow)
lib/core/components/form_styles.dart:28:      borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
lib/core/components/orcamento_form_dialog.dart:1006:                    color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:1232:                color: hasPeca ? AppColors.white : AppColors.textSecondary,
lib/core/components/orcamento_form_dialog.dart:1244:              color: AppColors.textSecondary.withValues(alpha: 0.85),
lib/core/components/orcamento_form_dialog.dart:1306:              color: AppColors.lightGray.withValues(alpha: 0.08),
lib/core/components/orcamento_form_dialog.dart:1309:                color: AppColors.lightGray.withValues(alpha: 0.25),
lib/core/components/orcamento_form_dialog.dart:1331:                          color: AppColors.white,
lib/core/components/orcamento_form_dialog.dart:1341:                          color: AppColors.white.withValues(alpha: 0.70),
lib/core/components/orcamento_form_dialog.dart:1350:                          color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:1362:                        color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:1391:                        color: AppColors.error,
lib/core/components/orcamento_form_dialog.dart:1427:                  style: TextStyle(color: AppColors.white),
lib/core/components/orcamento_form_dialog.dart:1467:                style: TextStyle(color: AppColors.white),
lib/core/components/orcamento_form_dialog.dart:1518:                  color: AppColors.white,
lib/core/components/orcamento_form_dialog.dart:1526:                  color: AppColors.white,
lib/core/components/orcamento_form_dialog.dart:1539:                    color: AppColors.white,
lib/core/components/orcamento_form_dialog.dart:1546:                    color: AppColors.white,
lib/core/components/orcamento_form_dialog.dart:1559:                    color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:1567:                    color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:193:                        color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:201:                      style: const TextStyle(color: AppColors.white),
lib/core/components/orcamento_form_dialog.dart:228:                                color: AppColors.primaryYellow.withValues(alpha: 0.08),
lib/core/components/orcamento_form_dialog.dart:231:                                  color: AppColors.primaryYellow.withValues(alpha: 0.30),
lib/core/components/orcamento_form_dialog.dart:237:                                  color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:242:                                    color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:248:                                  style: TextStyle(color: AppColors.textSecondary),
lib/core/components/orcamento_form_dialog.dart:259:                                        color: AppColors.textSecondary,
lib/core/components/orcamento_form_dialog.dart:266:                                      color: AppColors.lightGray.withValues(alpha: 0.18),
lib/core/components/orcamento_form_dialog.dart:279:                                            ? AppColors.primaryYellow.withValues(alpha: 0.10)
lib/core/components/orcamento_form_dialog.dart:285:                                                ? AppColors.primaryYellow
lib/core/components/orcamento_form_dialog.dart:286:                                                : AppColors.white,
lib/core/components/orcamento_form_dialog.dart:431:              color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:443:                  color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:461:                color: AppColors.secondaryGray,
lib/core/components/orcamento_form_dialog.dart:489:                    top: BorderSide(color: AppColors.border),
lib/core/components/orcamento_form_dialog.dart:508:                          backgroundColor: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:676:                ? AppColors.primaryYellow.withValues(alpha: 0.14)
lib/core/components/orcamento_form_dialog.dart:683:                  ? AppColors.primaryYellow
lib/core/components/orcamento_form_dialog.dart:686:                      : AppColors.border.withValues(alpha: 0.75),
lib/core/components/orcamento_form_dialog.dart:697:                      ? AppColors.primaryYellow
lib/core/components/orcamento_form_dialog.dart:700:                          : AppColors.lightGray.withValues(alpha: 0.18),
lib/core/components/orcamento_form_dialog.dart:707:                    color: isActive || isDone ? Colors.black : AppColors.white,
lib/core/components/orcamento_form_dialog.dart:718:                    ? AppColors.primaryYellow
lib/core/components/orcamento_form_dialog.dart:721:                        : AppColors.textSecondary,
lib/core/components/orcamento_form_dialog.dart:728:                      ? AppColors.primaryYellow
lib/core/components/orcamento_form_dialog.dart:731:                          : AppColors.textSecondary,
lib/core/components/orcamento_form_dialog.dart:769:                  color: AppColors.warning.withValues(alpha: 0.10),
lib/core/components/orcamento_form_dialog.dart:772:                    color: AppColors.warning.withValues(alpha: 0.28),
lib/core/components/orcamento_form_dialog.dart:780:                      color: AppColors.warning,
lib/core/components/orcamento_form_dialog.dart:788:                          color: AppColors.warning,
lib/core/components/orcamento_form_dialog.dart:902:          color: AppColors.lightGray.withValues(alpha: 0.08),
lib/core/components/orcamento_form_dialog.dart:905:            color: AppColors.lightGray.withValues(alpha: 0.22),
lib/core/components/orcamento_form_dialog.dart:914:                color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:925:                color: AppColors.textSecondary.withValues(alpha: 0.82),
lib/core/components/orcamento_form_dialog.dart:937:                    color: AppColors.border.withValues(alpha: 0.75),
lib/core/components/orcamento_form_dialog.dart:945:                      color: AppColors.primaryYellow,
lib/core/components/orcamento_form_dialog.dart:952:                          color: AppColors.white,
lib/core/components/orcamento_form_dialog.dart:965:                  color: AppColors.lightGray.withValues(alpha: 0.08),
lib/core/components/orcamento_form_dialog.dart:991:        color: AppColors.lightGray.withValues(alpha: 0.08),
lib/core/components/orcamento_form_dialog.dart:994:          color: AppColors.lightGray.withValues(alpha: 0.25),
lib/core/components/responsive_components.dart:1006:                              ? AppColors.white
lib/core/components/responsive_components.dart:1008:                                  ? AppColors.white.withValues(alpha: 0.95)
lib/core/components/responsive_components.dart:1009:                                  : AppColors.textSecondary),
lib/core/components/responsive_components.dart:1076:                        color: AppColors.white,
lib/core/components/responsive_components.dart:1087:                          color: AppColors.white.withValues(alpha: 0.7),
lib/core/components/responsive_components.dart:1101:            const Divider(color: AppColors.border),
lib/core/components/responsive_components.dart:1171:                    color: AppColors.primaryYellow,
lib/core/components/responsive_components.dart:478:                color: AppColors.white,
lib/core/components/responsive_components.dart:492:                color: AppColors.white.withValues(alpha: 0.86),
lib/core/components/responsive_components.dart:507:                  color: AppColors.textSecondary.withValues(alpha: 0.95),
lib/core/components/responsive_components.dart:549:            icon: const Icon(Icons.more_vert, color: AppColors.white),
lib/core/components/responsive_components.dart:693:      selectedItemColor: AppColors.primaryYellow,
lib/core/components/responsive_components.dart:694:      unselectedItemColor: AppColors.white.withValues(alpha: 0.6),
lib/core/components/responsive_components.dart:719:      selectedIconTheme: const IconThemeData(color: AppColors.primaryYellow),
lib/core/components/responsive_components.dart:721:        color: AppColors.primaryYellow,
lib/core/components/responsive_components.dart:724:      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
lib/core/components/responsive_components.dart:725:      unselectedLabelTextStyle: const TextStyle(color: AppColors.textSecondary),
lib/core/components/responsive_components.dart:729:          icon: const Icon(Icons.logout, color: AppColors.white),
lib/core/components/responsive_components.dart:767:                bottom: BorderSide(color: AppColors.border, width: 1),
lib/core/components/responsive_components.dart:783:                          color: AppColors.white,
lib/core/components/responsive_components.dart:792:                          color: AppColors.textSecondary,
lib/core/components/responsive_components.dart:830:                const Divider(color: AppColors.border, height: 1),
lib/core/components/responsive_components.dart:879:                const Divider(color: AppColors.border, height: 1),
lib/core/components/responsive_components.dart:893:              style: const TextStyle(color: AppColors.lightGray, fontSize: 12),
lib/core/components/responsive_components.dart:959:                      ? AppColors.surface2
lib/core/components/responsive_components.dart:965:                    color: isSelected ? AppColors.border : Colors.transparent,
lib/core/components/responsive_components.dart:986:                            ? AppColors.primaryYellow
lib/core/components/responsive_components.dart:995:                          ? AppColors.primaryYellow
lib/core/components/responsive_components.dart:997:                              ? AppColors.white.withValues(alpha: 0.95)
lib/core/components/responsive_components.dart:998:                              : AppColors.textSecondary),
lib/core/theme/app_text_styles.dart:52:    color: AppColors.textSecondary,
lib/core/utils/app_feedback.dart:10:        backgroundColor: AppColors.error,
lib/core/widgets/app_logo.dart:105:            color: AppColors.primaryYellow.withValues(alpha: 0.28),
lib/core/widgets/app_logo.dart:134:          colors: [AppColors.primaryYellow, Color(0xFFFFB000)],
lib/core/widgets/app_logo.dart:142:        color: AppColors.primaryDark,
lib/core/widgets/app_logo.dart:194:      textColor: AppColors.primaryYellow,
lib/core/widgets/app_logo.dart:208:      textColor: AppColors.primaryYellow,
lib/core/widgets/app_logo.dart:222:      textColor: AppColors.primaryDark,
lib/core/widgets/app_logo.dart:27:    final effectiveTextColor = textColor ?? AppColors.primaryYellow;
lib/core/widgets/app_logo.dart:99:          colors: [AppColors.primaryYellow, Color(0xFFFFB000)],
lib/core/widgets/skeletons.dart:13:        color: AppColors.lightGray.withValues(alpha: 0.06),
lib/core/widgets/skeletons.dart:21:            color: AppColors.lightGray.withValues(alpha: 0.08),
lib/core/widgets/skeletons.dart:32:                  color: AppColors.lightGray.withValues(alpha: 0.08),
lib/core/widgets/skeletons.dart:38:                  color: AppColors.lightGray.withValues(alpha: 0.06),
lib/core/widgets/stat_card.dart:108:                        color: AppColors.white.withValues(alpha: 0.6),
lib/core/widgets/stat_card.dart:117:                        color: AppColors.white,
lib/core/widgets/stat_card.dart:127:                          color: AppColors.white.withValues(alpha: 0.65),
lib/core/widgets/stat_card.dart:44:              color: AppColors.secondaryGray,
lib/core/widgets/stat_card.dart:47:                color: AppColors.lightGray.withValues(alpha: 0.1),
lib/core/widgets/stat_card.dart:85:                          color: (trendUp ? AppColors.success : AppColors.error)
lib/core/widgets/stat_card.dart:94:                                : AppColors.error,
lib/screens/clientes_screen.dart:1071:                    color: AppColors.primaryYellow,
lib/screens/clientes_screen.dart:1089:                    color: AppColors.primaryYellow,
lib/screens/clientes_screen.dart:1133:          Icon(icon, size: 20, color: AppColors.primaryYellow),
lib/screens/clientes_screen.dart:1143:                    color: AppColors.white.withValues(alpha: 0.7),
lib/screens/clientes_screen.dart:39:        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
lib/screens/clientes_screen.dart:44:          Icon(icon, size: 16, color: AppColors.textSecondary),
lib/screens/clientes_screen.dart:491:            color: AppColors.primaryDark,
lib/screens/clientes_screen.dart:498:        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
lib/screens/clientes_screen.dart:499:        color: AppColors.secondaryGray,
lib/screens/clientes_screen.dart:49:              color: AppColors.white,
lib/screens/clientes_screen.dart:544:              Icon(Icons.delete, size: 20, color: AppColors.error),
lib/screens/clientes_screen.dart:546:              Text('Excluir', style: TextStyle(color: AppColors.error)),
lib/screens/clientes_screen.dart:600:        return AppColors.primaryYellow;
lib/screens/clientes_screen.dart:606:        return AppColors.warning;
lib/screens/clientes_screen.dart:637:            backgroundColor: AppColors.secondaryGray,
lib/screens/clientes_screen.dart:640:              style: TextStyle(color: AppColors.error),
lib/screens/clientes_screen.dart:644:              style: const TextStyle(color: AppColors.white),
lib/screens/clientes_screen.dart:687:                    backgroundColor: AppColors.error),
lib/screens/clientes_screen.dart:694:                          color: AppColors.white,
lib/screens/dashboard_screen.dart:789:                              color: AppColors.textSecondary,
lib/screens/dashboard_screen.dart:893:                          color: AppColors.textSecondary,
lib/screens/empresa_screen.dart:148:                                      color: AppColors.primaryYellow,
lib/screens/empresa_screen.dart:160:                                      color: AppColors.textSecondary,
lib/screens/financeiro_screen.dart:128:          backgroundColor: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:139:                backgroundColor: AppColors.error,
lib/screens/financeiro_screen.dart:140:                foregroundColor: AppColors.white,
lib/screens/financeiro_screen.dart:191:                  color: AppColors.primaryYellow,
lib/screens/financeiro_screen.dart:200:                backgroundColor: AppColors.primaryYellow,
lib/screens/financeiro_screen.dart:201:                foregroundColor: AppColors.primaryDark,
lib/screens/financeiro_screen.dart:229:                    color: AppColors.primaryYellow,
lib/screens/financeiro_screen.dart:236:                    color: AppColors.white.withValues(alpha: 0.72),
lib/screens/financeiro_screen.dart:250:              backgroundColor: AppColors.primaryYellow,
lib/screens/financeiro_screen.dart:251:              foregroundColor: AppColors.primaryDark,
lib/screens/financeiro_screen.dart:277:        color: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:279:        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
lib/screens/financeiro_screen.dart:315:          color: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:318:            color: AppColors.lightGray.withValues(alpha: 0.7),
lib/screens/financeiro_screen.dart:335:            color: AppColors.white.withValues(alpha: 0.65),
lib/screens/financeiro_screen.dart:338:          fillColor: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:347:              color: AppColors.lightGray.withValues(alpha: 0.7),
lib/screens/financeiro_screen.dart:353:              color: AppColors.lightGray.withValues(alpha: 0.7),
lib/screens/financeiro_screen.dart:359:              color: AppColors.primaryYellow,
lib/screens/financeiro_screen.dart:371:          dropdownColor: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:398:          dropdownColor: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:490:              chipColor: AppColors.error,
lib/screens/financeiro_screen.dart:499:              chipColor: saldo >= 0 ? AppColors.success : AppColors.error,
lib/screens/financeiro_screen.dart:530:        color: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:533:          color: AppColors.lightGray.withValues(alpha: 0.7),
lib/screens/financeiro_screen.dart:557:                    color: AppColors.white.withValues(alpha: 0.75),
lib/screens/financeiro_screen.dart:595:                          color: AppColors.white.withValues(alpha: 0.75),
lib/screens/financeiro_screen.dart:630:            color: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:633:              color: AppColors.lightGray.withValues(alpha: 0.7),
lib/screens/financeiro_screen.dart:664:    final badgeColor = isEntrada ? AppColors.success : AppColors.error;
lib/screens/financeiro_screen.dart:671:        color: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:673:        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
lib/screens/financeiro_screen.dart:704:                    color: AppColors.white.withValues(alpha: 0.7),
lib/screens/financeiro_screen.dart:715:              color: isEntrada ? AppColors.success : AppColors.error,
lib/screens/financeiro_screen.dart:760:      backgroundColor: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:775:                      dropdownColor: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:812:                                  primary: AppColors.primaryYellow,
lib/screens/financeiro_screen.dart:813:                                  surface: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:816:                                  backgroundColor: AppColors.secondaryGray,
lib/screens/financeiro_screen.dart:899:            backgroundColor: AppColors.primaryYellow,
lib/screens/financeiro_screen.dart:900:            foregroundColor: AppColors.primaryDark,
lib/screens/login_screen.dart:113:                                      color: AppColors.white.withValues(alpha: 0.75),
lib/screens/login_screen.dart:190:                                            color: AppColors.white.withValues(
lib/screens/login_screen.dart:226:                                          color: AppColors.white.withValues(
lib/screens/login_screen.dart:55:            colors: [AppColors.primaryDark, Color(0xFF111111)],
lib/screens/login_screen.dart:76:                                  AppColors.primaryYellow,
lib/screens/orcamentos_screen.dart:1124:            color: AppColors.textSecondary,
lib/screens/orcamentos_screen.dart:1126:          color: AppColors.secondaryGray,
lib/screens/orcamentos_screen.dart:1176:                      backgroundColor: AppColors.error,
lib/screens/orcamentos_screen.dart:1214:                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
lib/screens/orcamentos_screen.dart:1216:                Text('Excluir', style: TextStyle(color: AppColors.error)),
lib/screens/orcamentos_screen.dart:1271:                  backgroundColor: AppColors.error,
lib/screens/orcamentos_screen.dart:1304:        return AppColors.primaryYellow;
lib/screens/orcamentos_screen.dart:1308:        return AppColors.error;
lib/screens/orcamentos_screen.dart:1310:        return AppColors.textSecondary;
lib/screens/orcamentos_screen.dart:413:      icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
lib/screens/orcamentos_screen.dart:608:          color: AppColors.secondaryGray,
lib/screens/orcamentos_screen.dart:610:          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
lib/screens/orcamentos_screen.dart:613:          labelColor: AppColors.white,
lib/screens/orcamentos_screen.dart:614:          unselectedLabelColor: AppColors.textSecondary,
lib/screens/orcamentos_screen.dart:622:              color: AppColors.primaryYellow.withValues(alpha: 0.95),
lib/screens/orcamentos_screen.dart:747:        color: AppColors.secondaryGray,
lib/screens/orcamentos_screen.dart:749:        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
lib/screens/orcamentos_screen.dart:756:            color: AppColors.textSecondary.withValues(alpha: 0.9),
lib/screens/orcamentos_screen.dart:763:              style: const TextStyle(color: AppColors.white),
lib/screens/orcamentos_screen.dart:767:                  color: AppColors.textSecondary.withValues(alpha: 0.7),
lib/screens/orcamentos_screen.dart:786:                color: AppColors.textSecondary.withValues(alpha: 0.9),
lib/screens/orcamentos_screen.dart:814:        color: AppColors.secondaryGray,
lib/screens/orcamentos_screen.dart:816:        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
lib/screens/orcamentos_screen.dart:822:          dropdownColor: AppColors.secondaryGray,
lib/screens/orcamentos_screen.dart:825:            color: AppColors.textSecondary.withValues(alpha: 0.9),
lib/screens/orcamentos_screen.dart:836:                        color: AppColors.textSecondary.withValues(alpha: 0.9),
lib/screens/orcamentos_screen.dart:842:                          color: AppColors.white,
lib/screens/orcamentos_screen.dart:871:        color: AppColors.secondaryGray,
lib/screens/orcamentos_screen.dart:873:        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
lib/screens/orcamentos_screen.dart:879:          color: AppColors.textSecondary.withValues(alpha: 0.95),
lib/screens/orcamentos_screen.dart:901:        return AppColors.warning;
lib/screens/orcamentos_screen.dart:905:        return AppColors.primaryYellow;
lib/screens/orcamentos_screen.dart:909:        return AppColors.error;
lib/screens/orcamentos_screen.dart:936:              color: AppColors.white,
lib/screens/orcamentos_screen.dart:991:                    backgroundColor: AppColors.warning,
lib/screens/order_detail_screen.dart:125:                    color: AppColors.error,
lib/screens/order_detail_screen.dart:147:                    color: AppColors.warning,
lib/screens/order_detail_screen.dart:271:        return AppColors.warning;
lib/screens/order_detail_screen.dart:275:        return AppColors.primaryYellow;
lib/screens/order_detail_screen.dart:279:        return AppColors.error;
lib/screens/order_detail_screen.dart:484:                  foregroundColor: AppColors.error,
lib/screens/order_detail_screen.dart:685:    final color = pago ? AppColors.success : AppColors.warning;
lib/screens/order_detail_screen.dart:734:        color = AppColors.warning;
lib/screens/order_detail_screen.dart:738:        color = AppColors.primaryYellow;
lib/screens/order_detail_screen.dart:742:        color = AppColors.error;
lib/screens/register_screen.dart:113:                                      color: AppColors.white.withValues(alpha: 0.75),
lib/screens/register_screen.dart:197:                                            color: AppColors.white.withValues(
lib/screens/register_screen.dart:39:            colors: [AppColors.primaryDark, Color(0xFF111111)],
lib/screens/register_screen.dart:60:                                  AppColors.primaryYellow,
```

**Resumo por arquivo (nº de ocorrências de aliases legados):**

| Arquivo | Ocorrências |
|---|---:|
| `lib/core/components/orcamento_form_dialog.dart` | 56 |
| `lib/screens/financeiro_screen.dart` | 39 |
| `lib/core/components/responsive_components.dart` | 33 |
| `lib/screens/orcamentos_screen.dart` | 29 |
| `lib/core/components/cliente_form_dialog.dart` | 24 |
| `lib/archive/*` (excluído da análise, não compilado) | 24 |
| `lib/screens/clientes_screen.dart` | 15 |
| `lib/screens/order_detail_screen.dart` | 11 |
| `lib/core/widgets/app_logo.dart` | 9 |
| `lib/core/widgets/stat_card.dart` | 7 |
| `lib/core/widgets/skeletons.dart` | 4 |
| `lib/core/components/common_widgets.dart` | 4 |
| `lib/screens/login_screen.dart` / `register_screen.dart` | 5 / 4 |
| `lib/screens/dashboard_screen.dart` / `empresa_screen.dart` | 2 / 2 |
| `lib/core/components/form_styles.dart` / `app_buttons.dart` | 2 / 1 |
| `lib/core/theme/app_text_styles.dart` / `lib/core/utils/app_feedback.dart` | 1 / 1 |

`primaryYellow` e `secondaryGray` são, disparadamente, os aliases mais usados fora de `lib/archive/`. Os únicos arquivos do design system novo (`app_card.dart`, `app_snackbar.dart`, `status_pill.dart`) que **não** aparecem nesta lista já usam exclusivamente os tokens novos (`AppColors.surface`, `.line`, `.textPrimary` etc.).

---

## 9. Git

```
$ git status
fatal: not a git repository (or any of the parent directories): .git
```

O diretório do projeto (`/home/thiago/Documentos/OficinaApp`) **não é um repositório git** — não há pasta `.git` na raiz nem em nenhum diretório pai. Consequentemente `git log --oneline -20` e `git diff --stat HEAD~5` também não puderam ser executados (mesmo erro). Não há histórico de commits, branches ou controle de versão ativo neste momento; o único versionamento disponível é o `pubspec.yaml` (`version: 1.0.4+11`) e o timestamp de modificação dos arquivos no filesystem.

---

## 10. Bug conhecido — tint amarelo no modal de Cliente

**Widget responsável:** `ResponsiveDialog` em [`lib/core/components/responsive_components.dart:1131-1199`](lib/core/components/responsive_components.dart#L1131-L1199) — é o `Dialog` genérico usado por `_showClienteDetails` (`clientes_screen.dart:1039`) para renderizar o modal de detalhe do cliente (e por praticamente todo modal desktop do app: `ClienteFormDialog`, `_showAddVeiculoDialog`, `_showHelpDialog`, etc.).

O `Dialog` em si usa `backgroundColor: AppColors.surface` (cinza escuro, correto). O "tint amarelo" vem do **título** do dialog, que é fixado em `AppColors.primaryYellow` incondicionalmente — não é uma cor de fundo, mas a cor de texto do título aparece amarela em qualquer chamada de `ResponsiveDialog`, incluindo quando o título é o nome do cliente (`_showClienteDetails` passa `title: cliente.nome`):

```dart
class ResponsiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final fontMultiplier = ResponsiveUtils.getFontSizeMultiplier(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 150),
        curve: Curves.decelerate,
        child: Container(
          width: isDesktop ? 520 : ResponsiveUtils.getContentWidth(context),
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20 * fontMultiplier,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,   // <-- linha do bug
                  ),
                ),
                const SizedBox(height: 16),
                content,
                // ...
```

Além disso, dentro do próprio conteúdo do modal (`_showClienteDetails`, `clientes_screen.dart`), os títulos de seção "Veículos (N)" e "Orçamentos (N)" (linhas 1071 e 1089) **e** o ícone de cada linha de detalhe em `_buildDetailRow` (linha 1133) também usam `AppColors.primaryYellow` explicitamente — ou seja, o amarelo aparece em pelo menos 4 pontos distintos do mesmo modal (título do dialog + 2 headers de seção + ícones), todos referenciando o mesmo alias.

---

## 11. Permissões Android

### `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Needed for AttachmentPicker camera/gallery -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />

    <uses-feature android:name="android.hardware.camera" android:required="false" />

    <application
        android:label="Grau Car"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

**Observações:**
- Label do app no manifest: `"Grau Car"` — diverge do `applicationId`/`namespace` (`com.funilaria.app_funilaria`, seção 2) e do nome do pacote pub (`oficina_app`, `pubspec.yaml`). Três nomes diferentes para o mesmo produto (pacote pub / package ID Android / label visível ao usuário).
- Permissões declaradas: `CAMERA`, `READ_MEDIA_IMAGES` (Android 13+), `READ_EXTERNAL_STORAGE` com `maxSdkVersion="32"` (compatibilidade com Android ≤ 12). Não há `WRITE_EXTERNAL_STORAGE` nem `MANAGE_EXTERNAL_STORAGE` — coerente com o uso de `path_provider`/diretório interno do app para PDFs e backups (seção 5), que não exige permissão de armazenamento em versões modernas do Android.
- Nenhuma permissão de rede (`INTERNET`) declarada — coerente com o app ser 100% local/offline (SQLite + arquivos), sem chamadas de API externas identificadas na camada de dados.
- `<queries>` para `ACTION_PROCESS_TEXT` é boilerplate padrão do Flutter (necessário para o plugin de manipulação de texto do engine funcionar sob as regras de package visibility do Android 11+), não específico do app.

