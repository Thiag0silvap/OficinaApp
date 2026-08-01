# Instruções para Adicionar a Logo GRAU CAR

## Passos para adicionar a logo real:

### 1. Salvar a imagem da logo
- Salve a imagem da logo GRAU CAR que você enviou como `grau_car_logo.png`
- Coloque o arquivo na pasta: `/home/thiago/Documentos/app_funilaria/assets/images/grau_car_logo.png`

### 2. Atualizar o widget da logo
No arquivo `/home/thiago/Documentos/app_funilaria/lib/core/widgets/app_logo.dart`, descomente as linhas da imagem real e comente o container placeholder.

### 3. Rodar flutter pub get
Execute: `cd /home/thiago/Documentos/app_funilaria && flutter pub get`

### 4. Fazer hot reload
Se o app estiver rodando, faça hot reload pressionando 'r' no terminal.

## O que já está configurado:

✅ **Nome do app**: Mudou de "GRAU CAR" para "OficinaApp" (nome genérico para venda)
✅ **Estrutura de assets**: Pasta assets/images/ já configurada
✅ **Widget responsivo**: Logo se adapta para mobile, tablet e desktop  
✅ **Cores**: Usando as cores da logo (amarelo dourado e preto)
✅ **Posicionamento**: Logo aparece no desktop sidebar e pode ser usada em outros locais

## Funcionalidades do sistema:

### 📱 **Layout Responsivo**
- **Mobile**: Bottom navigation bar
- **Tablet**: Side navigation rail  
- **Desktop**: Sidebar completo com logo

### 🔧 **Funcionalidades Principais**
- Dashboard com estatísticas
- Gestão de clientes
- Criação de orçamentos
- Controle financeiro (entradas/saídas)
- Sistema de status para orçamentos

### 💰 **Gestão Financeira**
- Saldo total e do mês
- Registrar entradas (pagamentos)
- Registrar saídas (despesas)
- Relatórios por categorias

### 🚗 **Gestão de Serviços**
Os serviços da GRAU CAR já estão configurados:
- Funilaria
- Pintura  
- Polimento especializado
- Cristalização e recuperação de farol
- Higienização interna

## Próximos passos recomendados:

1. **Adicionar a logo real** (instruções acima)
2. **Testar em diferentes tamanhos de tela**
3. **Personalizar cores se necessário**
4. **Adicionar mais funcionalidades conforme necessário**

O app está pronto para ser usado como **OficinaApp** - um produto genérico que pode ser vendido para outras oficinas, mas mantém toda a qualidade e funcionalidades específicas da GRAU CAR!