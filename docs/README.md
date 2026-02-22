# GitHub Pages (Update Manifest)

Este diretório é publicado pelo GitHub Pages.

## Arquivos

- `update_manifest.json`: usado pelo app para checar se existe versão mais nova.

## Como usar

1) Ative GitHub Pages em **Settings → Pages**
- Source: *Deploy from a branch*
- Branch: `main`
- Folder: `/docs`

2) Ajuste o link do manifest no app
- Em [lib/core/constants/app_constants.dart](../lib/core/constants/app_constants.dart) configure `AppConstants.updateManifestUrl` com a URL do Pages:
  - `https://thiag0silvap.github.io/OficinaApp/update_manifest.json`

3) A cada release
- Gere o zip: `bash tool/release_linux.sh build`
- Publique o zip (ex.: GitHub Releases)
- Atualize `docs/update_manifest.json` apontando `downloadUrl` para o zip.
