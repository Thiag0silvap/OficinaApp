# OficinaApp — Manual do Usuário (Passo a Passo)

## 1) Visão geral
O **OficinaApp** é um sistema de gestão para oficina (funilaria/pintura) com foco em:
- Cadastro de clientes (particular/seguradora/frota/oficina parceira)
- Cadastro de veículos por cliente
- Gestão de orçamentos/ordens de serviço (status, pagamento, PDF e impressão)
- Controle financeiro (entradas/saídas)
- Backup manual do banco de dados

> Observação: este app usa **banco local (SQLite)** no computador. Nesta versão, **Flutter Web não é suportado**.

## 2) Primeiro acesso (criar usuário)
1. Abra o app.
2. Na tela **Acesse sua conta**, clique em **Criar conta**.
3. Preencha:
   - **Usuário**
   - **Senha**
4. (Opcional) Marque **Lembrar credenciais neste computador**.
5. Clique em **Criar conta**.
6. Você volta para a tela de login.

### 2.1) Sobre “Lembrar usuário/credenciais”
- No **Login**, a opção é **Lembrar usuário neste computador**.
- A tela pode preencher automaticamente o **nome do usuário**.
- Por segurança, a **senha não é salva** e **não fica preenchida** automaticamente.

### 2.2) Dados separados por usuário
- Cada usuário cadastrado no app possui **dados separados** (banco de dados por usuário) no mesmo computador.
- Isso evita que um usuário veja informações de outro.

## 3) Login e navegação
1. Informe **Usuário** e **Senha**.
2. Clique em **Entrar**.
3. Você será direcionado para a tela principal (**Home**).

### 3.1) Menu lateral (módulos)
O menu lateral permite acessar:
- **Dashboard**
- **Clientes**
- **Orçamentos**
- **Financeiro**

Ações disponíveis no menu:
- **Configurações** (atalho sem ação nesta versão)
- **Backup (manual)** (gera uma cópia do banco)
- **Ajuda** (atalho sem ação nesta versão)
- **Sair** (encerra a sessão)

## 4) Dashboard (visão rápida)
O **Dashboard** exibe:
- Indicadores do mês (ex.: **Faturamento Mensal** e tendência)
- Contadores (ex.: **Ordens Ativas**, **Concluídos Hoje**, **Pendentes**)
- Insight com gráfico de evolução (últimos meses) e **Resumo Diário**
- Listas rápidas:
  - **Ordens Recentes** (últimos itens)
  - **Próximos Agendamentos** (pendentes)

### 4.1) Atalhos do Dashboard
No card **Resumo Diário**, você pode:
- Abrir **Financeiro** clicando em **Entradas hoje / Saídas hoje / Saldo do dia**
- Criar um orçamento pelo botão **Novo Orçamento**
- Abrir rapidamente **Clientes** e **Financeiro**

## 5) Clientes
A tela **Clientes** permite cadastrar e gerenciar pessoas/empresas.

### 5.1) Buscar, filtrar e ordenar
- **Busca**: por nome, telefone ou seguradora.
- **Filtro** (Tipo): Todos, Particular, Seguradora, Frota, Oficina parceira.
- **Ordenação**: A–Z ou Recentes.

### 5.2) Cadastrar novo cliente (passo a passo)
1. Clique em **Novo Cliente**.
2. Selecione o **Tipo de Cliente**.
3. Preencha os campos obrigatórios:
   - **Nome**
   - **Telefone**
4. Campos opcionais:
   - Endereço
   - Observações
5. Se o tipo for **Seguradora**, preencha também:
   - **Nome da Seguradora** (obrigatório)
   - CNPJ da Seguradora (opcional)
   - Pessoa de contato (opcional)
6. Clique em **Salvar**.

Dicas:
- O formulário aceita atalhos: **Ctrl+Enter** para salvar e **Esc** para fechar.

### 5.3) Ações em um cliente
Em cada cliente existe um menu de ações (⋮), com:
- **Editar**
- **Add Veículo**
- **Novo Orçamento**
- **Excluir**

Ao clicar no cliente, abre-se o **detalhe** com seções de veículos e orçamentos associados.

### 5.4) Cadastrar veículo para um cliente
1. Na lista de clientes, clique no menu (⋮) do cliente.
2. Selecione **Add Veículo**.
3. Preencha os campos obrigatórios:
   - **Marca** (pode escolher “Outra... (digitar)”)
   - **Modelo** (pode escolher “Outro... (digitar)”)
   - **Cor**
   - **Placa**
4. Campos opcionais:
   - **Ano**
   - Observações
5. Clique em **Salvar**.

## 6) Orçamentos (Ordens de Serviço)
A tela **Orçamentos** é organizada por abas:
- **Pendentes**
- **Aprovados**
- **Em Andamento**
- **Concluídos**

### 6.1) Buscar e ordenar
- **Busca**: por cliente, veículo ou ID.
- **Ordenação**: Recentes, Maior valor, Menor valor, Nome A–Z.

### 6.2) Fluxo recomendado (do orçamento ao pagamento)
1. Crie um orçamento (por **Novo Orçamento** ou a partir de um cliente).
2. Ele entrará como **Pendente**.
3. Quando aprovado, use **Aprovar**.
4. Ao iniciar o serviço, use **Iniciar**.
5. Ao finalizar, use **Concluir**.
6. Após concluir, registre o pagamento com **Receber** (se ainda não estiver pago).

### 6.2.1) Criar um orçamento (passo a passo)
Você pode criar um orçamento pelo Dashboard (**Novo Orçamento**) ou pelo menu do cliente (**Novo Orçamento**).

1. Abra **Orçamentos** e clique em **Novo Orçamento** (ou crie a partir de um cliente).
2. Selecione:
   - **Cliente** (obrigatório)
   - **Veículo** (obrigatório)
3. Em **Itens do Serviço**, adicione pelo menos 1 item:
   - Escolha o **Tipo**: **Serviço** ou **Peça**
   - Selecione o item (Serviço/Peça)
   - Informe/ajuste **Valor**
   - Preencha **Detalhes do item**
   - Clique no botão **+** para adicionar (ou **salvar** quando estiver editando um item)
4. (Opcional) Marque **Aplicar desconto** e informe o valor.
5. (Opcional) Preencha **Observações do Orçamento**.
6. Confira o **Valor Total** (e “Total com desconto”, se aplicável).
7. Clique em **Gerar Orçamento**.

Dicas:
- Se não houver itens, o sistema avisa: “Adicione pelo menos um item ao orçamento”.
- O campo de observações adiciona automaticamente a linha **Responsável: <usuário>**.
- O formulário aceita atalhos: **Ctrl+Enter** para gerar/salvar e **Esc** para fechar.

### 6.3) Ações disponíveis por status
- **Pendente**: Editar, Aprovar, Cancelar
- **Aprovado**: Iniciar
- **Em Andamento**: Concluir
- **Concluído**: Receber (se ainda não estiver pago)

### 6.4) PDF e impressão
Em qualquer orçamento você pode:
- **Enviar PDF**: gera e compartilha um PDF (em orçamento concluído, vira “nota de serviço”).
- **Imprimir**: abre uma pré-visualização e permite imprimir.

Também existe a ação:
- **Excluir**: remove o orçamento (irreversível).

## 7) Financeiro
A tela **Financeiro** controla transações de **Entrada** e **Saída**.

### 7.1) Recursos
- Indicadores: **Entradas**, **Saídas** e **Saldo**
- Busca e filtros:
  - Buscar por descrição, categoria ou valor
  - Filtrar por tipo: todos / entradas / saídas
  - Ordenar: recentes / maior valor / menor valor
- Lista de transações com opção de **Excluir**

### 7.2) Criar nova transação (passo a passo)
1. Clique em **Nova Transação**.
2. Selecione:
   - **Tipo**: Entrada ou Saída
   - **Data** (clicar para escolher no calendário)
3. Preencha:
   - **Descrição** (obrigatória)
   - **Valor** (obrigatório)
   - **Categoria** (opcional; se vazio, o sistema usa “Geral”)
4. Clique em **Salvar**.

## 8) Backup (manual)
O backup é feito pelo menu lateral em **Backup (manual)**.

### 8.1) Como gerar o backup
1. Abra o menu lateral.
2. Clique em **Backup (manual)**.
3. Aguarde a mensagem “Iniciando backup...”.
4. Ao concluir, o sistema mostrará uma mensagem com o caminho do arquivo.

### 8.2) Onde o backup fica salvo (Linux)
No Linux, o app tenta salvar em:
- `~/Documents/backups_app_funilaria/`

O backup inclui:
- Um arquivo `.db` (banco SQLite)
- Um arquivo `.json` (exportação de tabelas)
- Um arquivo `.manifest.json` (hash SHA-256 e tamanho para verificação)

## 9) Atualizações
Ao abrir o app, ele pode checar automaticamente se existe nova versão.
- Se houver, aparece a janela **Atualização disponível**.
- Clique em **Baixar atualização** para abrir o link no navegador.

## 10) Perguntas rápidas (FAQ)
**1) Posso usar o app em mais de um computador?**
- Sim, mas os dados são locais. Para levar os dados, gere um **Backup (manual)** e peça suporte para restaurar no outro computador.

**2) O que acontece se faltar internet?**
- O app funciona normalmente (banco é local). Apenas a checagem de atualização pode não aparecer.

**3) “Configurações” e “Ajuda” não fazem nada. Está com problema?**
- Não. Nesta versão, são atalhos reservados para futuras melhorias.

## 11) Suporte / Restauração de backup (procedimento técnico)
Nesta versão, a restauração não possui botão na interface.
Se precisar restaurar um backup:
- Feche o app.
- Envie o arquivo `.db` do backup para o suporte.
- O suporte fará a substituição do arquivo do banco local do usuário (procedimento interno).

---
Documento para entrega ao cliente.
