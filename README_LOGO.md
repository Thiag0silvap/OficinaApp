# Instruções para adicionar a logo do GRAU CAR

## Como adicionar a logo real:

1. **Salve a imagem da logo** que você enviou como `logo_grau_car.png` na pasta:
   ```
   /home/thiago/Documentos/app_funilaria/assets/images/
   ```

2. **Formatos recomendados:**
   - PNG com fundo transparente (preferível)
   - Resolução mínima: 512x512 pixels
   - Para melhor qualidade, crie versões em diferentes resoluções:
     - `logo_grau_car.png` (512x512)
     - `logo_grau_car@2x.png` (1024x1024)
     - `logo_grau_car@3x.png` (1536x1536)

## O que foi implementado:

✅ **Nome genérico do app**: "OficinaApp" - pode ser vendido para outras oficinas
✅ **Sistema responsivo**: Funciona em mobile, tablet, desktop e web  
✅ **Logo responsiva**: Se adapta a diferentes tamanhos de tela
✅ **Fallback inteligente**: Usa ícone de carro se a logo não estiver disponível
✅ **Branding consistente**: Logo aparece em:
   - Header do mobile
   - AppBar do tablet
   - Menu lateral do desktop
   - Splash screen (futuro)

## Alterações feitas:

- **Nome do app**: GRAU CAR → OficinaApp
- **Slogan**: "O grau que o seu carro precisa" → "Gestão completa para sua oficina"
- **Logo sistema**: Widget `AppLogo` criado com variações para diferentes contextos
- **Layout responsivo**: Diferentes layouts para mobile/tablet/desktop
- **Assets configurados**: pubspec.yaml atualizado para incluir imagens

## Próximos passos:

1. Substitua o arquivo placeholder pela logo real
2. Teste o app em diferentes tamanhos de tela
3. Se quiser mudar o nome do app, edite `AppConstants.appName`
4. Para personalizar para cada oficina, crie um sistema de configuração

---

**Dica**: O sistema já está preparado para ser um produto vendável, pois usa um nome genérico e permite fácil customização da logo e branding por oficina.