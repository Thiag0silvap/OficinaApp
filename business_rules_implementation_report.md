# Implementação das Regras de Negócio — Relatório

> Executado a partir da revisão de `business_rules_report.md`. Cada parte foi implementada, validada (`flutter analyze` + `flutter build linux --debug` + `flutter test` quando aplicável) e commitada isoladamente, nesta ordem, sem nenhuma quebra de build no caminho.

**Baseline antes de começar:** `flutter analyze` com 9 issues pré-existentes (nenhum deles tocado por este trabalho, exceto um que desapareceu incidentalmente na Parte 3 ao remover código morto duplicado). `git status` limpo — nenhum commit de baseline extra foi necessário.

**Estado final:** `flutter analyze` com 8 issues — todos pré-existentes e não relacionados a este trabalho (ver seção "Analyze" de cada parte). `flutter test` com todos os testes passando em todas as partes. `flutter build linux --debug` bem-sucedido em todas as partes.

---

## Parte 1 — Schema: soft delete, motivo de cancelamento, catálogo por conta

**O que mudou:** `schemaVersion` 2 → 3 em `db_service_io.dart`, seguindo o padrão existente (`_ensureTableExists`/`_ensureColumnExists` dentro de `_ensureLatestSchema`, sem quebrar bancos já existentes):
- Coluna `ativo INTEGER DEFAULT 1` em `clientes` e `veiculos`.
- Coluna `motivoCancelamento TEXT` (nullable) em `orcamentos`.
- Nova tabela `marcas_modelos_custom(id TEXT PRIMARY KEY, marca TEXT, modelo TEXT)`.
- Models `Cliente`/`Veiculo` ganharam `ativo` (bool, default `true`); `Orcamento` ganhou `motivoCancelamento` (`String?`). `toMap`/`fromMap`/`copyWith` atualizados nos três.

**Arquivos tocados:** `lib/services/db_service_io.dart`, `lib/models/cliente.dart`, `lib/models/veiculo.dart`, `lib/models/orcamento.dart`.

**Analyze:** 0 issues nos arquivos alterados (limpo). **Test:** todos passaram (incluindo `backup_manifest_test.dart`, que testa round-trip de serialização — não quebrou com os novos campos). **Build:** ok.

**Commit:** `5e57722`.

---

## Parte 2 — Catálogo de marca/modelo isolado por conta

**O que mudou:**
- `db_service_io.dart`: `insertMarcaModeloCustom({marca, modelo})` e `getMarcasModelosCustom()`, operando na tabela por conta (cada usuário já tem seu próprio arquivo `.db`, então isolar por conta é automático).
- `app_provider.dart`: `addMarcaModeloCustom` passou a gravar no banco (via `_db.insertMarcaModeloCustom`) em vez de `SharedPreferences`. `_reloadForActiveUser` agora também carrega o catálogo da conta ativa (`_fetchVehicleCatalogFromDb`), junto com clientes/veículos/orçamentos/transações — inclusive respeitando a mesma trava de corrida (só aplica o resultado se a conta ativa não mudou durante o `await`).
- **Migração de dados:** na primeira vez que a tabela `marcas_modelos_custom` da conta estiver vazia, `_migrateLegacyVehicleCatalogFromPrefs()` lê o catálogo antigo do `SharedPreferences` (se existir) e grava cada entrada no banco da conta atual. Não apaga o `SharedPreferences` (não é necessário — cada conta só migra uma vez, pois depois a tabela deixa de estar vazia), mas nunca mais grava nele.
- `syncAuthUser` agora também limpa `_customMarcas`/`_customModelosPorMarca` ao trocar de conta (antes ficavam vazando entre contas na mesma sessão do app).

**Arquivos tocados:** `lib/services/db_service_io.dart`, `lib/services/db_service_web.dart`, `lib/providers/app_provider.dart`.

**Analyze:** 0 issues novos (9 pré-existentes, iguais ao baseline). **Build:** ok. **Test:** todos passaram.

**Como testar manualmente:** logar com uma conta, cadastrar um veículo com marca "Outra... (digitar)" preenchendo um valor novo, fechar e reabrir o app (ou trocar de conta e voltar) — a marca deve continuar aparecendo na lista só para aquela conta. Logar com uma segunda conta e confirmar que a marca customizada da primeira conta **não** aparece (a menos que o `SharedPreferences` compartilhado já tivesse esse valor antes da migração, caso em que ambas as contas herdam o mesmo snapshot inicial — ver decisão documentada abaixo).

**Commit:** `1d722c4`.

---

## Parte 3 — Soft delete de cliente/veículo + edição/exclusão isolada de veículo

**O que mudou:**
- `app_provider.dart`: `deleteCliente` e `deleteVeiculo` agora fazem soft delete (`ativo = false` via `updateCliente`/`updateVeiculo`), com cascata de cliente → veículos. **Orçamentos e transações não são mais tocados** em nenhum dos dois casos — ficam intactos, com `clienteId`/`veiculoId` originais preservados. Adicionados `reativarCliente`/`reativarVeiculo` (não usados por nenhuma tela ainda, prontos para uso futuro).
- `db_service_io.dart`: `getClientes()`/`getVeiculos()` agora filtram `ativo IS NULL OR ativo = 1` direto na query SQL. Os métodos de delete físico (`deleteCliente`/`deleteVeiculo`) foram removidos por ficarem sem nenhum chamador (nenhuma outra parte do app os usava).
- Novo widget reutilizável `lib/core/components/veiculo_form_fields.dart`: `VeiculoFormController` (estado/lógica de marca-modelo-cor-placa-ano-observações, incluindo "Outra... digitar") + `VeiculoFormFields` (a UI). Pode ser criado vazio ou a partir de um veículo existente (`VeiculoFormController.fromVeiculo`).
- `cliente_form_dialog.dart` (passo do primeiro veículo) e `clientes_screen.dart` (`_showAddVeiculoDialog`) foram refatorados para usar o widget compartilhado, eliminando a duplicação de ~250 linhas de campos idênticos.
- `clientes_screen.dart`: novo diálogo unificado `_showVeiculoFormDialog` (add/edit) e `_showDeleteVeiculoDialog` (soft delete isolado, com contagem de orçamentos vinculados). No modal de detalhe do cliente (`_showClienteDetails`), cada veículo listado ganhou ações de editar/excluir.
- `_showDeleteClienteDialog`: agora busca a contagem real de veículos/orçamentos vinculados e mostra o texto pedido ("...vai ocultar N veículos e M orçamentos da lista ativa. Nada é apagado..."). Botão trocado de "Excluir" (vermelho) para "Ocultar" (cor neutra/amarela do app) — nome da função mantido.

**Arquivos tocados:** `lib/providers/app_provider.dart`, `lib/services/db_service_io.dart`, `lib/services/db_service_web.dart`, `lib/core/components/cliente_form_dialog.dart`, `lib/core/components/veiculo_form_fields.dart` (novo), `lib/screens/clientes_screen.dart`.

**Analyze:** 8 issues (1 a menos que o baseline — um lint pré-existente em `clientes_screen.dart` desapareceu porque o trecho de código onde ele vivia foi removido na refatoração). **Test:** todos passaram. **Build:** ok.

**Commit:** `eba7df4`.

---

## Parte 4 — Atalho de cadastro de veículo no orçamento

**O que mudou:** em `orcamento_form_dialog.dart`, no passo "Veículo" do assistente, foi adicionado um botão "Cadastrar veículo" que abre `VeiculoFormFields` (Parte 3) dentro de um `AlertDialog` simples. Ao salvar, o veículo novo é automaticamente selecionado como veículo do orçamento em andamento (`setState(() => _selectedVeiculo = veiculo)`), sem exigir seleção manual adicional.

**Arquivos tocados:** `lib/core/components/orcamento_form_dialog.dart`.

**Analyze:** 8 issues (igual ao estado pós-Parte-3). **Build:** ok.

**Commit:** `1c79b50`.

---

## Parte 5 — Cancelamento de orçamento expandido

**O que mudou:**
- `app_provider.dart`: `cancelarOrcamento(id, {String? motivo})` agora valida status no núcleo (não só na tela): aceita cancelar a partir de Pendente/Aprovado/Em andamento; lança `StateError` (erro tratável, mesmo padrão de `_validateCliente`/`_validateVeiculo` etc.) se já Concluído ou já Cancelado. Se o status atual for Em andamento, `motivo` vazio/nulo também lança erro — obrigatoriedade condicional vive no provider, não na tela.
- Novo `lib/core/components/cancelar_orcamento_dialog.dart`: diálogo compartilhado que pede motivo (obrigatório só quando `motivoObrigatorio: true`) e uma função `collectMotivoAndCancelarOrcamento` que orquestra diálogo + chamada ao provider — reutilizada pelas duas telas para não duplicar a lógica de coleta de motivo.
- `orcamentos_screen.dart`: ação "Cancelar" agora visível também para Aprovado/Em andamento (menu do card mobile e pills do card desktop), passando pelo diálogo compartilhado.
- `order_detail_screen.dart`: botão "Cancelar" agora aparece também nos blocos de Aprovado e Em andamento (antes só em Pendente), usando o mesmo diálogo.

**Arquivos tocados:** `lib/providers/app_provider.dart`, `lib/core/components/cancelar_orcamento_dialog.dart` (novo), `lib/screens/orcamentos_screen.dart`, `lib/screens/order_detail_screen.dart`.

**Analyze:** 8 issues (mesmos da Parte 3/4). **Test:** todos passaram. **Build:** ok.

**Commit:** `3d9577e`.

---

## Parte 6 — Campo "papel" no cadastro de usuário

**Resultado: nenhuma alteração de código foi necessária.** Investigação confirmou que `lib/screens/register_screen.dart` **já não expõe** nenhum seletor de papel/role hoje — o formulário de cadastro só pede usuário e senha. `lib/services/auth_service.dart:97` já grava sempre `role: UserRole.user` no registro. Não há nenhum outro ponto na UI (grep por `papel`/`Admin`/`UserRole` em `lib/`) que colete esse valor do usuário. O relato no `business_rules_report.md` parece refletir uma versão anterior do código (possivelmente já corrigida em um sprint anterior, antes deste trabalho). Nenhum commit foi criado para esta parte por não haver mudança de código.

---

## Parte 7 — Histórico de Serviços a partir da tabela "notas"

**O que mudou:**
- `app_provider.dart` / `concluirOrcamento`: a gravação da nota **já tinha `await`** (não reproduzia o bug de "salvar sem esperar" corrigido no sprint anterior para orçamentos). O que faltava era não deixar o erro passar em silêncio: trocado o `catch (_) {}` vazio por um log via `AppLogger.instance.error(...)`, mantendo o comportamento de não bloquear a conclusão do orçamento se a nota falhar (nota é registro auxiliar).
- `db_service_io.dart`: novo `getNotasByCliente(clienteId)` (a `getNotas()` existente não filtrava por cliente).
- `app_provider.dart`: novo `getNotasByCliente(clienteId)` (assíncrono — notas não ficam em cache no provider como clientes/veículos/orçamentos, são lidas direto do banco a cada chamada).
- `clientes_screen.dart` (`_showClienteDetails`): nova terceira seção "Histórico de Serviços", abaixo de Veículos e Orçamentos, mostrando data de emissão, veículo e valor total de cada nota; "Nenhum serviço concluído ainda" quando vazia. O método virou `async` para poder buscar as notas antes de abrir o diálogo.

**Arquivos tocados:** `lib/providers/app_provider.dart`, `lib/services/db_service_io.dart`, `lib/services/db_service_web.dart`, `lib/screens/clientes_screen.dart`.

**Analyze:** 8 issues (mesmos de sempre). **Build:** ok.

**Commit:** `d1504d1`.

---

## Decisões tomadas por ambiguidade (para revisão)

1. **Texto da confirmação de exclusão de cliente (Parte 3.2).** O texto pedido foi usado literalmente: "...vai ocultar N veículos **e M orçamentos** da lista ativa." Só que, por definição do próprio código (Parte 3.1), os orçamentos **não são ocultados** — continuam 100% visíveis, só o cliente/veículos ficam inativos. Implementei o texto exatamente como especificado (é uma cópia de produto, não uma regra técnica), mas ele pode ler como se os orçamentos também saíssem da lista ativa, o que não é o caso. Vale revisar a redação — ex. trocar para "...M orçamentos vinculados a ele continuam no histórico" — se isso não for a intenção.
2. **Placa em maiúsculas.** O cadastro de veículo dentro do assistente de cliente (`cliente_form_dialog.dart`) já uppercase-ava a placa (`toUpperCase()`); o cadastro avulso em `clientes_screen.dart` não fazia isso. Ao unificar os dois num único `VeiculoFormController`, padronizei para sempre uppercase — pareceu a escolha mais correta e resolve uma inconsistência pré-existente, mas é uma mudança de comportamento no fluxo que antes não fazia uppercase.
3. **Perda do "pular para o campo com erro" ao extrair `VeiculoFormFields`.** Antes, `cliente_form_dialog.dart` tinha lógica manual de mover o foco para o primeiro campo inválido ao falhar a validação do primeiro veículo. Como os `FocusNode`s agora vivem encapsulados dentro do controller/widget compartilhado, essa navegação manual de foco entre arquivos diferentes deixou de ser prática de preservar; a validação em si continua funcionando normalmente (mensagens de erro inline via `Form.validate()`), só não pula mais automaticamente o foco para o campo errado. UX ligeiramente mais simples, não uma regressão funcional.
4. **Migração do catálogo de marca/modelo (Parte 2) não é exclusiva por conta.** Conforme a própria instrução permitia ("não precisa se preocupar com dados de outras contas"), se duas contas diferentes nunca tiverem usado a tabela `marcas_modelos_custom` antes desta atualização, **ambas** herdam o mesmo snapshot do catálogo compartilhado antigo (`SharedPreferences`) na primeira vez que cada uma carregar após o update — não há deduplicação entre contas nesse instante inicial. Depois disso, cada conta evolui seu catálogo de forma independente.
5. **Reativação de cliente/veículo (Parte 3) exige o objeto completo, não só o `id`.** Como clientes/veículos inativos saem da lista em memória do provider, `reativarCliente`/`reativarVeiculo` recebem a entidade completa (não um `id`) — quem for construir a futura tela de "itens ocultos" precisará buscar essas entidades inativas via uma consulta direta ao banco (nenhum método de "listar inativos" foi criado, por não ter sido pedido).
6. **Motivo de cancelamento não é exibido em nenhuma tela ainda.** O texto do motivo é coletado e persistido em `motivoCancelamento` (Partes 1 e 5), mas nenhuma tela hoje mostra esse valor de volta ao usuário (nem no banner "Orçamento cancelado" do `order_detail_screen.dart`). Não foi pedido explicitamente exibir — só coletar e gravar — mas fica registrado como um histórico "morto" no mesmo espírito do ponto cego #8 do `business_rules_report.md` original (a tabela `notas`), até que uma tela venha a consumi-lo.
7. **Parte 6 sem commit.** Como não houve alteração de código (campo já não existia na UI), nenhum commit "chore: remove campo de papel..." foi criado — criar um commit vazio ou cosmético pareceu pior que documentar a constatação aqui.

## Áreas explicitamente fora de escopo (conforme solicitado)

Nenhuma mudança foi feita em: geração de PDF, integração com WhatsApp, fluxo de backup/restore, ou fluxo de pagamento/reversão de pagamento (já corrigidos em sprints anteriores).
