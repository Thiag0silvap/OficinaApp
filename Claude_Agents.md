# Claude_Agents.md

> Documento gerado por investigação direta do código (grep, leitura de arquivos, `pubspec.yaml`, `flutter analyze`) em 2026-09-16. Toda afirmação abaixo é rastreável a uma evidência concreta do repositório nesta data. Divergências com premissas anteriores estão sinalizadas na Seção 9 — leia-a antes de assumir qualquer coisa deste documento como definitiva no futuro, pois o código muda mais rápido que a documentação.

## 1. Visão geral do projeto

- **Nome:** `oficina_app` (OficinaApp) — sistema de gestão para oficinas de funilaria/pintura automotiva (`pubspec.yaml`).
- **Versão atual:** `1.0.15+15` (`pubspec.yaml`).
- **Plataformas-alvo confirmadas no código:** Android e Windows/Linux/macOS desktop via `dart:io` + `sqflite`. **Flutter Web é explicitamente bloqueado**: `lib/main.dart` tem um branch `if (kIsWeb)` que renderiza uma tela `WebNotSupportedScreen` dizendo "Este app usa banco local (SQLite) e recursos de arquivos (dart:io) [...] Nesta versão, o Flutter Web não é suportado." Ainda assim existem `*_web.dart` (stubs condicionais: `db_service_web.dart`, `app_logger_web.dart`, `attachment_service_web.dart`) para permitir compilar sem quebrar imports condicionais — não é suporte funcional a Web.
- **Estado de produção:** app em produção (evidenciado por `sentry_flutter` configurado com DSN real e `environment: kReleaseMode ? 'production' : 'development'`, mais fluxo completo de auth/onboarding/convite de colaborador).
- **Stack confirmada (pubspec.yaml):**
  - UI/estado: `provider: ^6.1.2`
  - Storage: `shared_preferences: ^2.1.0`, `flutter_secure_storage: ^9.2.2`
  - Banco local: `sqflite: ^2.2.7+3`, `path`, `path_provider`
  - Backend: `supabase_flutter: ^2.17.2` (comentário no pubspec diz "Fase 3: só o cliente, sem auth/dados ainda" — **desatualizado**, ver Seção 9)
  - Erros: `sentry_flutter: ^9.29.0`
  - PDF/impressão: `pdf`, `printing`
  - Gráficos: `fl_chart`
  - Imagem/assinatura: `image_picker`, `flutter_image_compress`, `signature`
  - Outros: `intl`, `crypto`, `uuid`, `url_launcher`, `file_picker`, `share_plus`
  - Dev: `flutter_test`, `flutter_lints: ^5.0.0`, `flutter_launcher_icons`, `flutter_native_splash`, `sqflite_common_ffi` (para testes com SQLite em memória)

## 2. Arquitetura atual (com evidência)

### Gerenciamento de estado
Confirmado via imports reais (não pelo nome de pastas): **Provider + ChangeNotifier**, nada de Riverpod/Bloc.
```
grep -rl "package:provider"        → 24 arquivos
grep -rl "package:flutter_riverpod" → 0
grep -rl "package:flutter_bloc"     → 0
grep -rn "extends ChangeNotifier"
  lib/providers/auth_provider.dart:11
  lib/providers/app_provider.dart:30
  lib/core/components/veiculo_form_fields.dart:18  (VeiculoFormController, escopo local de formulário)
```
`lib/main.dart` monta a árvore assim:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProxyProvider<AuthProvider, AppProvider>(
      create: (_) => AppProvider()..initApp(),
      update: (_, auth, app) { app!.syncAuthUser(auth.currentUser); return app; },
    ),
  ],
  ...
)
```
`AuthProvider` (autenticação/sessão Supabase) alimenta `AppProvider` (dados de negócio) via `ChangeNotifierProxyProvider` — quando o usuário muda, `AppProvider.syncAuthUser` limpa o estado em memória e recarrega.

### Mapa de pastas (`lib/`, até 3 níveis)
```
lib/
  archive/            — telas antigas ("_old", "_old_full"), NÃO importadas por nada em uso (dead code isolado, ver Seção 9)
  core/
    components/       — design system + diálogos/forms reutilizáveis (24 arquivos)
    constants/        — app_constants.dart, app_version.dart
    theme/            — tokens: app_colors, app_spacing, app_text_styles, app_theme
    utils/            — formatters, error_translator, app_feedback, normalizadores
    widgets/          — app_logo, pdf_preview_dialog, skeletons, stat_card, update_gate
    id_generator.dart — gera UUID v4 (chave primária TEXT)
  models/             — classes de dados puras (Cliente, Veiculo, Orcamento, Transacao, Nota, Empresa, User, ...)
  providers/          — AuthProvider, AppProvider (únicos ChangeNotifier de escopo de app)
  screens/            — telas de nível de rota
  services/           — acesso a dados, integrações externas, infra (ver Seção 3)
    mappers/          — conversão modelo Dart <-> linha Supabase (snake_case)
  main.dart
```
Não existe pasta `repositories/`. **O papel de "repositório único" é cumprido por `AppProvider`**, que é o único ponto que os `screens/` chamam para ler/escrever dados — `DBService` (SQLite) e `SyncService` (Supabase) são sempre acessados através dele, nunca diretamente pelas telas (confirmado por leitura de `app_provider.dart`, 2238 linhas, e ausência de `DBService.instance`/`SyncService()` fora de `lib/providers/app_provider.dart` e `lib/services/`).

### Padrão io/web condicional
Três serviços usam `export 'x_io.dart' if (dart.library.html) 'x_web.dart'` para dar suporte a compilação condicional, mesmo com Web desabilitado na prática: `db_service.dart`, `app_logger.dart`, `attachment_service.dart`.

## 3. Inventário de componentes reutilizáveis

**Sempre verificar esta tabela antes de criar um novo service/mapper/widget — grep pelo nome da entidade primeiro.**

### Services
| Arquivo | Responsabilidade |
|---|---|
| `services/db_service.dart` + `db_service_io.dart`/`_web.dart` | Gateway único ao SQLite local (schema v4). CRUD de clientes, veículos, orçamentos, transações, notas, catálogos custom, cache FIPE, fila `operacoes_pendentes`. |
| `services/supabase_client.dart` | Ponto único de acesso ao `SupabaseClient` (`SupabaseService.client`). |
| `services/sync_service.dart` | Sincroniza escrita (`sincronizar`) com fila offline em `operacoes_pendentes`; leitura online-first (`buscarXRemoto`) por entidade. |
| `services/auth_service.dart` | Login/cadastro/reset de senha via Supabase Auth; validação de formulário de registro. |
| `services/supabase_local_storage.dart` | Implementa `LocalStorage` do supabase_flutter usando `SecureStorageService` (sessão não fica em SharedPreferences puro). |
| `services/secure_storage_service.dart` | Wrapper de `flutter_secure_storage` com fallback em SharedPreferences se o storage seguro falhar. |
| `services/app_logger.dart` + `_io`/`_web` | Log local em arquivo (`OficinaAppLogs/app_YYYY-MM-DD.log`), best-effort, silencioso em erro. |
| `services/attachment_service.dart` + `_io`/`_web` | Gerencia anexos (fotos/assinatura) — usado por `attachment_widgets.dart`. |
| `services/fipe_service.dart` | Cliente da API FIPE (marcas/modelos), cacheado via `DBService`. |
| `services/pdf_service.dart` | Gera PDF de orçamento e de relatório financeiro (`pw.Widget`). |
| `services/pdf_file_service.dart` | Salva/compartilha o PDF gerado (usa `share_plus`, ainda com chamada à API antiga `Share`/`shareXFiles` — ver Seção 7). |
| `services/whatsapp_service.dart` | Monta link/abre WhatsApp com o PDF — usado por `orcamento_actions.dart`. |
| `services/update_service.dart` | Verifica versão/atualização do app — usado por `splash_screen.dart`. |
| `services/empresa_service.dart` | **Dead code confirmado.** Só `SharedPreferences`-based, nenhum outro arquivo importa `EmpresaService` (grep de uso = zero ocorrências fora da própria definição). `EmpresaScreen`/`AppProvider` não o usam. |

### Mappers (`services/mappers/`)
Um par `paraSupabase` / `xFromSupabase` por entidade sincronizada: `cliente_mapper.dart`, `veiculo_mapper.dart`, `orcamento_mapper.dart`, `transacao_mapper.dart`, `nota_mapper.dart`, `catalogo_custom_mapper.dart` (cobre os 3 catálogos: marcas/modelos, peças, serviços). Todos têm teste de round-trip em `test/services/mappers/`.

### Models (`models/`)
| Arquivo | Papel |
|---|---|
| `cliente.dart`, `veiculo.dart`, `orcamento.dart`, `transacao.dart`, `nota.dart`, `empresa.dart`, `user.dart` | Entidades de negócio ativas — usadas por `AppProvider`, telas e mappers. |
| `backup_manifest.dart` | Estrutura do manifesto de backup/restore. |
| `relatorio_financeiro.dart` | Enum de período + agregações de relatório. |
| `ordem_servico.dart`, `nota_servico.dart`, `servico_item.dart` | **Cluster órfão.** Só se importam entre si (`grep import` confirma zero import externo). Não usados por `AppProvider`, `screens/` ou `services/`. Candidatos a dead code, distintos do fluxo real (`Orcamento`/`ItemOrcamento` em `orcamento.dart`). |

### Providers
| Arquivo | Papel |
|---|---|
| `providers/auth_provider.dart` | Sessão Supabase Auth, `currentUser`, role, `oficinaId`, login/registro/reset/logout. |
| `providers/app_provider.dart` | Estado de negócio inteiro do app (clientes, veículos, orçamentos, transações, catálogos, FIPE) + orquestra `DBService` e `SyncService`. **Ponto de entrada obrigatório para qualquer nova feature de dados.** |

### Design system (ver também Seção 5)
| Arquivo | Papel |
|---|---|
| `core/theme/app_colors.dart` | Paleta única ("Confiança Noturna"). |
| `core/theme/app_spacing.dart` | Escala de espaçamento base-4. |
| `core/theme/app_text_styles.dart` | Escala tipográfica (Sora + Inter). |
| `core/theme/app_theme.dart` | `AppTheme.dark`, aplicado em `MaterialApp`. |
| `core/components/app_buttons.dart` | `PrimaryButton` e variantes. |
| `core/components/app_card.dart` | Container padrão de conteúdo. |
| `core/components/app_snackbar.dart` | Feedback padronizado (`SnackType.success/error/info`). |
| `core/components/status_pill.dart` | Pílula de status (`AppStatus` enum) para orçamento/OS. |
| `core/components/responsive_components.dart` | `ResponsiveDialog`, `ResponsiveLayout`, `ResponsiveWidget`, `ResponsiveCard`, `ResponsiveGridView`, etc. — ainda contém aliases de cor legados (ver Seção 5). |
| `core/components/*_dialog.dart`, `*_form_dialog.dart`, `*_actions.dart` | Diálogos/forms/ações por entidade (cliente, orçamento, transação, veículo, cancelamento). |
| `core/widgets/stat_card.dart`, `skeletons.dart`, `app_logo.dart`, `pdf_preview_dialog.dart`, `update_gate.dart` | Widgets utilitários de nível de app. |

## 4. Estado da migração Supabase

O comentário do `pubspec.yaml` ("Fase 3: só o cliente, sem auth/dados ainda") está **desatualizado** — o código vai muito além disso hoje:

| Fase (conforme contexto original) | Estado real encontrado |
|---|---|
| 1. Camada única de repositório | ✅ Feito. `AppProvider` é o único ponto de acesso a dados para as telas; `DBService`/`SyncService` não vazam para `screens/`. |
| 2. Schema Supabase com `oficina_id` + RLS | ⚠️ Parcialmente verificável. Código assume tabelas remotas `oficinas`, `perfis` (com `oficina_id`, `role`), `empresa`, `clientes`, `veiculos`, `orcamentos`, `transacoes`, `notas`, `marcas_modelos_custom`, `pecas_custom`, `servicos_custom`, todas filtradas por `oficina_id` nas leituras (`sync_service.dart`). **Não há nenhum arquivo `.sql`, pasta `supabase/` ou migration versionada no repositório** — o schema remoto não é rastreável a partir do código-fonte (ver Seção 9). RLS não pode ser confirmada por este repo. |
| 3. Auth migrada para Supabase Auth | ✅ Feito e mais avançado que "cliente" descreve: `AuthProvider` fala 100% com `Supabase.instance.client.auth` (login, registro, reset de senha, listener de `onAuthStateChange`), sessão persistida via `flutter_secure_storage` (`SupabaseSecureLocalStorage`). Fluxo de onboarding (`OnboardingGate` em `main.dart`) cria oficina/perfil no primeiro login e resolve convites via RPC `aceitar_convite`. Deep link de confirmação de e-mail existe (commit `a52189e`). |
| 4. Motor de sync (fila offline + reconciliação) | ✅ Implementado para **todas as entidades principais**, não só Cliente: `sincronizar()` (escrita com fallback para fila `operacoes_pendentes` em erro de conectividade) e `buscarXRemoto`/`aplicarXRemoto` (leitura online-first + reconciliação) cobrem `clientes`, `veiculos`, `orcamentos`, `transacoes`, `notas`, `marcas_modelos_custom`, `pecas_custom`, `servicos_custom` — confirmado por grep de `entidade:` em `app_provider.dart` (32 ocorrências, 8 entidades distintas) e pela leitura de `_reloadForActiveUser`. Testado por `test/services/db_service_espelho_remoto_test.dart` (reconciliação de deleção, proteção de pendência). |
| 5. Migração de dados locais existentes no primeiro login | Não encontrada rotina explícita de "migrar SQLite pré-Supabase → Supabase" no primeiro login (distinto da migração de catálogo legado de veículo do SharedPreferences, que é outra coisa — ver `_migrateLegacyVehicleCatalogFromPrefs`). Não confirmável como concluída. |
| 6. Backup/restore, `empresa_service.dart` órfão, anexos | `empresa_service.dart` confirmado como dead code (Seção 3). `backup_manifest.dart` existe com teste próprio, mas não foi localizado o fluxo de restore ponta-a-ponta nesta investigação (fora do escopo desta leitura). Anexos (`attachment_service*.dart`) estão implementados e em uso via `attachment_widgets.dart`. |

**Atualização (17/09):** o schema de produção foi versionado via `supabase db pull` e vive em `supabase/migrations/`: `20260917221401_remote_schema.sql` (placeholder de baseline, 0 bytes), `20260917221842_remote_schema.sql` (dump completo, 1120 linhas), e `20260917223819_fix_perfis_insert_policy_oficina_isolation.sql`. Esta última corrige uma vulnerabilidade real de escalação de privilégio encontrada durante a auditoria: a policy de INSERT em `perfis` validava apenas `id = auth.uid()`, sem checar `oficina_id`, permitindo que qualquer usuário autenticado se auto-inserisse como admin em qualquer oficina existente via chamada direta à API REST (bypassando o app). A correção só permite o INSERT quando a oficina de destino ainda não tem nenhum perfil, fechando a brecha sem afetar o onboarding legítimo. Já aplicada e validada em produção (commit cf573cb).

## 5. Design system e padrões de UI

**Tokens:** `AppColors`, `AppSpacing`, `AppText` (em `core/theme/`), unificados por `AppTheme.dark`.

**Aliases de compatibilidade encontrados em `app_colors.dart`** (seção explicitamente comentada como "telas pré-Sprint 0"):
```dart
primaryYellow, primaryDark, secondaryGray, surface2, lightGray, white, border, warning, error
```
Uso real por arquivo (grep):
| Alias | Ainda usado em |
|---|---|
| `primaryYellow` | `empresa_screen.dart`, `register_screen.dart`, `equipe_screen.dart`, `convidar_colaborador_screen.dart`, `app_logo.dart`, `responsive_components.dart`, + arquivos em `archive/` |
| `primaryDark` | `register_screen.dart`, `app_logo.dart` |
| `secondaryGray` | `orcamentos_screen.dart`, `stat_card.dart` |
| `surface2` | `responsive_components.dart` |
| `lightGray` | `stat_card.dart`, `skeletons.dart`, `responsive_components.dart` |
| `AppColors.white` | `register_screen.dart`, `orcamentos_screen.dart`, `clientes_screen.dart`, `stat_card.dart`, `responsive_components.dart`, `common_widgets.dart` |
| `AppColors.border` | `convidar_colaborador_screen.dart`, `equipe_screen.dart`, `orcamentos_screen.dart`, `splash_screen.dart`, `clientes_screen.dart`, `responsive_components.dart` |
| `AppColors.warning` | `orcamento_detail_dialog.dart`, `orcamento_form_dialog.dart` |
| `AppColors.error` | `stat_card.dart`, `app_feedback.dart`, `responsive_components.dart`, `orcamento_form_dialog.dart` |

**Telas sem nenhum alias (candidatas a já totalmente migradas para os tokens novos):** `auth_wrapper.dart`, `dashboard_screen.dart`, `financeiro_screen.dart`, `home_screen.dart`, `login_screen.dart`, `relatorio_financeiro_screen.dart`.

**Telas ainda com aliases pendentes (por volume, maior primeiro):** `orcamentos_screen.dart` (9), `equipe_screen.dart` (4), `register_screen.dart` (3), `clientes_screen.dart` (3), `convidar_colaborador_screen.dart` (2), `empresa_screen.dart` (1), `splash_screen.dart` (1). `responsive_components.dart` e `stat_card.dart` (componentes compartilhados, não telas) também carregam aliases e bloqueiam a remoção total até serem migrados.

**Padrão de diálogo/form:** `ResponsiveDialog` em `core/components/responsive_components.dart` é o componente estabelecido, usado pelos `*_form_dialog.dart`/`*_detail_dialog.dart` em `core/components/` (cliente, orçamento, transação). Não foi encontrado um padrão separado de "full-screen Scaffold mobile vs. dialog desktop" como dois componentes distintos — `ResponsiveDialog`/`ResponsiveLayout` parecem encapsular essa responsividade internamente (não confirmado a fundo célula-a-célula; recomenda-se checar `responsive_components.dart` linha 1235+ antes de assumir o comportamento exato em telas novas).

## 6. Padrões de erro, logging e segurança

**Tratamento de exceções:** padrão consistente em `AppProvider` — cada método de escrita (`addCliente`, `updateOrcamento`, etc.) segue `try { ... } catch (e) { _recordError('...: $e'); rethrow; }`. Não existe um handler central de exceção de UI (cada tela decide como mostrar o erro), mas existe `core/utils/error_translator.dart` (`traduzirErro`) para traduzir exceções técnicas em mensagens amigáveis, usado em `main.dart`/`OnboardingGate`.

**Sync vs. erro real:** `SyncService.sincronizar` distingue explicitamente: `PostgrestException`/`AuthException` sempre propagam (erro real, deve ser mostrado); qualquer outra exceção é tratada como falha de conectividade e cai silenciosamente na fila `operacoes_pendentes`.

**Sentry:** inicializado em `main.dart` com DSN de produção, `tracesSampleRate: 1.0`, `environment` condicional a `kReleaseMode`. **Atualização (commit 400eeba):** `sendDefaultPii = false`, `beforeBreadcrumb` (remove `request_body`/`response_body`/`body` de breadcrumbs HTTP) e `beforeSend` (reduz `request`/`contexts.response` a método/url/status) estão implementados em `lib/main.dart`. Segue sem nenhuma chamada manual a `Sentry.captureException`/`captureMessage` em todo o `lib/` — apenas a inicialização em `main.dart`.

**Logging local:** `AppLogger` (arquivo em `OficinaAppLogs/app_YYYY-MM-DD.log`), chamado extensivamente em `AppProvider` (`info`/`warning`) para auditoria de ações (cliente adicionado, orçamento aprovado, etc.), best-effort e silencioso em falha.

**Segredos/tokens:**
- Não há arquivo `.env` no repositório (`find -iname "*.env*"` vazio).
- URL e chave `publishableKey` (anon key) do Supabase estão **hardcoded em `lib/main.dart`** — é a chave pública/anônima do Supabase (protegida por RLS no backend), não uma service key; ainda assim, é uma prática que vale confirmar com o responsável se é intencional para este projeto.
- Sessão de autenticação: `flutter_secure_storage` via `SupabaseSecureLocalStorage`. **Atualização (commit 400eeba):** o fallback silencioso foi removido. `SecureStorageService.write/read/delete` delegam exclusivamente ao `flutter_secure_storage` e propagam exceção em falha. `clearLegacyFallback(key)` existe só para limpar resíduo em texto plano de versões anteriores do app (best-effort, nunca escreve). Em `SupabaseSecureLocalStorage`, falha do storage degrada para "sem sessão" (retorna null/false) e loga via `AppLogger.instance.warning('...: ${e.runtimeType}')` — nunca o valor da sessão nem o erro completo. Testado em `test/services/secure_storage_service_test.dart` e `test/services/supabase_local_storage_test.dart` (commit 6e1a59f).

## 7. Testes existentes e comando de validação

`flutter analyze` → **7 issues, 0 erros** (baseline atual, rodado em 2026-09-16):
- 6x `info: deprecated_member_use` — API antiga do pacote `share_plus` (`Share`/`shareXFiles`) usada em `orcamento_detail_dialog.dart:296`, `responsive_components.dart:632`, `pdf_file_service.dart:34`. Pacote já está em `^12.0.2` no pubspec — a chamada não foi migrada para `SharePlus.instance.share()`.
- 1x `warning: unused_local_variable` — `pdf_file_service.dart:43` (variável `uri`).

**Testes (`test/`):**
| Arquivo | Tipo | Cobertura |
|---|---|---|
| `models/backup_manifest_test.dart`, `models/relatorio_financeiro_test.dart`, `models/user_test.dart` | Unitário | Serialização/desserialização de models. |
| `services/mappers/*_test.dart` (cliente, veiculo, orcamento, transacao, nota, catalogo_custom) | Unitário | Round-trip `paraSupabase`/`xFromSupabase`, defaults seguros em campos ausentes/nulos, tradução de enums snake_case. |
| `services/db_service_espelho_remoto_test.dart` + `db_service_test_utils.dart` | Unitário (SQLite em memória via `sqflite_common_ffi`) | Reconciliação online-first: upsert de registro remoto, proteção de registro com pendência local, reconciliação de deleção. |
| `services/auth_service_test.dart` | Unitário | Validação de formulário de registro. |
| `services/secure_storage_service_test.dart` | Unitário | Propagação de exceção em write/read/delete; comportamento de `clearLegacyFallback`. |
| `services/supabase_local_storage_test.dart` | Unitário | Degradação segura (null/false, sem propagar) quando o secure storage falha. |
| `providers/app_provider_test.dart` | Unitário | Agregações financeiras (`totalEntradas`, `saldo`, `resumoPorPeriodo`, `resumoPorCategoria`, `percentageChange`) via seams `debugSetTransacoes`/`debugSetVeiculos`. |
| `core/components/cliente_form_dialog_test.dart`, `veiculo_form_fields_test.dart` | Widget | Formulários. |
| `core/utils/text_normalize_test.dart` | Unitário | Normalização de texto (acentos, case). |
| `screens/financeiro_screen_test.dart` | Widget | Tela financeira. |
| `widget_test.dart` | Widget (smoke) | Padrão gerado pelo `flutter create`. |

**Comando de validação padrão:** `flutter analyze` (baseline: 7 issues) + `flutter test` → 83/83 passando (confirmado em 17/09).

## 8. Regras de comportamento para qualquer agente Claude que for atuar neste projeto

1. **Nunca criar uma segunda implementação de algo já listado na Seção 3** sem antes rodar `grep` para confirmar que não existe — em especial: não criar um novo service de acesso a dados sem verificar se `AppProvider`/`DBService`/`SyncService` já resolve; não criar um novo mapper sem checar `services/mappers/`.
2. **Nunca alterar regra de negócio, schema de banco (local ou Supabase), fluxo de auth/onboarding ou UX sem confirmação explícita do responsável** — isso inclui mexer em `_onCreate`/`_onUpgrade` de `db_service_io.dart`, em `OnboardingGate` (`main.dart`), ou em qualquer chamada RPC ao Supabase.
3. **Seguir o padrão confirmado na Seção 2: Provider + ChangeNotifier.** Não introduzir Riverpod, Bloc, GetX ou qualquer outro gerenciador de estado.
4. **Antes de adicionar uma dependência ao `pubspec.yaml`, checar a lista da Seção 1 e perguntar ao responsável** antes de adicionar uma nova — não duplicar funcionalidade já coberta (ex.: já há `share_plus`, `pdf`, `fl_chart`, `flutter_secure_storage`).
5. **Mudanças pequenas e mecânicas** (import, typo, lint, migrar `Share`/`shareXFiles` deprecado para `SharePlus.instance.share()`) podem ser feitas diretamente. **Mudanças estruturais** (nova tela, novo fluxo de dados, alteração de schema, migração de mais telas do design system) seguem sempre: investigar → planejar → explicar → confirmar → implementar → testar → revisar.
6. **`flutter analyze` deve permanecer na baseline atual (7 issues, Seção 7) — nenhum warning/info novo antes de considerar a tarefa concluída.** Se uma mudança precisar tocar em código que já gera um dos 7 issues existentes, corrigir o issue é bem-vindo, mas não obrigatório fora do escopo pedido.
7. **Não modificar nada em `lib/archive/`** sem perguntar — é código antigo isolado (nenhum import de fora do próprio diretório), mas sua remoção é uma decisão do responsável, não do agente.
8. **Não assumir que `empresa_service.dart`, `models/ordem_servico.dart`, `models/nota_servico.dart` ou `models/servico_item.dart` estão em uso** — confirmado nesta investigação que são código morto ou órfão (Seção 3). Não construir nova funcionalidade em cima deles sem antes confirmar com o responsável se serão reaproveitados ou removidos.
9. **Tratar a paridade de aliases de cor (Seção 5) como trabalho em andamento, não como bug** — ao tocar em uma tela que ainda usa `AppColors.white`/`border`/`warning`/`error`/`primaryYellow`/etc., é uma boa oportunidade para migrar para os tokens novos, mas isso é uma mudança estrutural de UX/visual e segue a regra 5 (confirmar antes).

## 9. Divergências encontradas

Itens em que o contexto presumido no início desta tarefa não bateu com o que o código mostra:

1. **A migração Supabase está muito mais avançada do que "Fase 4, piloto do Cliente".** O comentário do próprio `pubspec.yaml` ("Fase 3: só o cliente, sem auth/dados ainda") também está desatualizado. Na prática: Auth 100% em Supabase, e o motor de sync (fila offline + leitura online-first + reconciliação) cobre **8 entidades** (clientes, veículos, orçamentos, transações, notas, e os 3 catálogos custom), não só Cliente. Isso é mais avançado do que a memória de projeto registrada ("só Cliente testado em device") sugeria — vale re-sincronizar essa memória com o responsável: é possível que o código esteja implementado além do que foi validado em dispositivo real.
2. **Não existe nenhum arquivo `.sql`, pasta `supabase/` ou migration versionada no repositório.** O schema remoto (tabelas `oficinas`, `perfis`, `empresa`, `clientes`, etc., com `oficina_id` e RLS) só pôde ser inferido pelo código cliente (`sync_service.dart`, `main.dart`), nunca confirmado diretamente. Se o schema Supabase vive só no painel do Supabase (não versionado), isso é um risco de deriva entre ambientes que vale registrar com o responsável — não uma correção deste documento, mas um ponto cego que ele deve saber que existe. **RESOLVIDO (17/09):** `supabase/migrations/` agora existe e está versionado, incluindo o dump completo do schema de produção. Ver Seção 4.
3. **A alegação de que o Sentry exclui deliberadamente dados pessoais e ruído da FIPE API não tem nenhuma evidência no código.** `Sentry.init` em `main.dart` não define `beforeSend`/`beforeBreadcrumb`, e não há nenhuma chamada manual a `Sentry.captureException`/`captureMessage` em todo o projeto. Ou seja, hoje o Sentry captura o que a integração automática do Flutter capturar, sem filtro customizado algum. Se essa exclusão é uma prioridade real, ela **ainda precisa ser implementada** — não é um comportamento já existente que este documento estivesse ocultando. **RESOLVIDO (17/09):** ver atualização na Seção 6.
4. **`empresa_service.dart` é dead code confirmado** (zero usos fora da própria definição) — isso já era suspeitado no contexto original e a investigação confirma.
5. **Cluster adicional de dead/orphan code não mencionado no contexto original:** `models/ordem_servico.dart`, `models/nota_servico.dart` e `models/servico_item.dart` só se referenciam entre si, sem nenhum import de `screens/`, `providers/` ou `services/` fora desse trio.
6. **Não existe pasta `repositories/`** — o padrão real é "camada de repositório único" implementado dentro de `providers/app_provider.dart`, e não em uma classe/pasta dedicada `Repository`. Isso não contradiz a intenção original ("consolidar acesso a DB via camada única"), mas o nome/local da camada é diferente do que o termo "repositório" normalmente sugere em Flutter — vale ter isso em mente para não procurar por `*_repository.dart` (não existe nenhum arquivo com esse sufixo no projeto).
7. **`flutter_secure_storage` tem fallback silencioso para `SharedPreferences`** (`SecureStorageService`) em caso de falha — incluindo a sessão do Supabase Auth (`SupabaseSecureLocalStorage`). Isso não estava no contexto original e é um detalhe de segurança que vale confirmar como intencional. **RESOLVIDO (17/09):** ver atualização na Seção 6.
