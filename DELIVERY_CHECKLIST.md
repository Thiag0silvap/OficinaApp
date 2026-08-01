# Checklist de entrega — App Funilaria

Este app é **offline-first** (dados ficam no dispositivo). Como você vai entregar para **notebook/PC (desktop)** agora e deixar **mobile para depois**, o foco é build desktop + smoke test + backup.

## 1) Build e execução (Desktop)

### Linux
- Gerar bundle release:
  - `flutter build linux --release`
  - Saída: `build/linux/x64/release/bundle/`
- Rodar no mesmo PC:
  - Executável: `build/linux/x64/release/bundle/app_funilaria`

### Windows (se você for entregar para Windows)
- `flutter build windows --release`
- Saída típica: `build/windows/x64/runner/Release/`

### macOS (se você for entregar para macOS)
- `flutter build macos --release`
- Saída típica: `build/macos/Build/Products/Release/`

## 1.1) Versionamento (quando você fizer mudanças)

- Subir a versão/build automaticamente:
  - `dart run tool/bump_version.dart build` (incrementa só o `+build`)
  - `dart run tool/bump_version.dart patch` (incrementa patch e o build)
- Depois gerar o bundle novamente (ex.: Linux):
  - `flutter build linux --release`

## 2) O que entregar para o cliente (Desktop)

- O cliente precisa receber a pasta do bundle (não só o executável).
  - Linux: entregue a pasta `build/linux/x64/release/bundle/` inteira.
- Forma prática de entrega:
  - Compactar a pasta (zip) e enviar.

## 3) Smoke test (5–10 min)

## 2) Smoke test (5–10 min)
No celular do cliente (ou um aparelho equivalente):

- Abrir o app e navegar entre telas principais.
- Criar 1 cliente.
- Adicionar 1 veículo (testar marca/modelo existentes e “Outra/Outro (digitar)”).
- Criar 1 orçamento com 1–2 itens.
- Gerar/visualizar PDF (orçamento e, se aplicável, nota de serviço).
- Marcar como pago/pendente (se o fluxo existir na tela).
- Fazer **Backup (manual)** e confirmar mensagem de sucesso.

## 4) Backup/Restore (obrigatório antes de uso real)

- Fazer 1 backup.
- Confirmar onde o arquivo foi salvo:
  - Desktop: tenta `~/Documents` e faz fallback para pasta do app.
- Rodar “Restaurar backup” (se disponível) e confirmar que os dados voltam.

## 5) Expectativas do cliente

- Sem internet: o app continua funcionando (os dados ficam locais).
- Troca de computador: precisa **restaurar backup** no novo PC.

## 6) Itens recomendados para segunda-feira

- Definir uma rotina simples:
  - “Todo dia no fim do expediente: fazer backup.”
- Combinar com o cliente onde guardar os backups (Drive/WhatsApp/computador).

## 7) Se você for levar para mobile depois

- Android: quando decidir ir para celular, aí sim vale:
  - Definir keystore de release (`key.properties`) para atualizações futuras.
  - Testar permissões/armazenamento para backup no dispositivo.

## 8) Se você for publicar ou manter atualizações

- Gerar keystore de release e criar `android/key.properties`.
- Fazer build release assinado e manter a mesma keystore para as próximas versões.

## 9) Update automático (desktop)

O app tem um “check” simples de atualização ao abrir:

- Você mantém um arquivo JSON público (manifest) com a última versão + link.
- O app lê esse JSON, compara com a versão instalada e, se tiver mais nova, mostra um diálogo com botão **Baixar atualização**.

Como configurar:
- Publique um JSON seguindo o exemplo em `tool/update_manifest_example.json`.
- Coloque a URL dele em `AppConstants.updateManifestUrl`.
