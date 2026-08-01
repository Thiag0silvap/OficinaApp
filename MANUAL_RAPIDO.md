# OficinaApp — Manual Rápido (1 página)

## 1) Acesso
- **Entrar**: informe **Usuário** e **Senha** → **Entrar**.
- **Primeiro acesso**: **Criar conta** → informe usuário/senha → **Criar conta** → volte e faça login.
- **Lembrar usuário**: pode preencher o nome automaticamente; **a senha não é salva**.

## 2) Onde fica cada coisa (menu lateral)
- **Dashboard**: visão geral e atalhos.
- **Clientes**: cadastro de clientes e veículos.
- **Orçamentos**: do orçamento à ordem de serviço, PDF e impressão.
- **Financeiro**: entradas/saídas e saldo.
- **Backup (manual)**: gera cópia do banco.
- **Sair**: encerra a sessão.

## 3) Fluxo recomendado do dia a dia
1. Cadastre o **Cliente**.
2. Cadastre o **Veículo** do cliente.
3. Crie um **Orçamento** com itens (serviço/peça).
4. Atualize o status:
   - **Pendente** → **Aprovar** → **Iniciar** → **Concluir** → **Receber** (se ainda não pago)
5. Gere **PDF/Impressão** quando necessário.

## 4) Clientes (o essencial)
- **Novo Cliente** → escolha tipo → preencha **Nome** e **Telefone** → **Salvar**.
- Menu (⋮) no cliente:
  - **Editar**
  - **Add Veículo**
  - **Novo Orçamento**
  - **Excluir**

## 5) Veículos (o essencial)
- Cliente (⋮) → **Add Veículo** → preencher **Marca/Modelo/Cor/Placa** → **Salvar**.

## 6) Orçamentos (o essencial)
- **Novo Orçamento** → escolher **Cliente** e **Veículo**.
- Em **Itens do Serviço**: selecione **Serviço/Peça**, informe **Valor** e **Detalhes** → clique **+**.
- (Opcional) **Aplicar desconto**.
- Finalize em **Gerar Orçamento**.
- No card do orçamento, use:
  - Ações por status (**Aprovar / Iniciar / Concluir / Receber**)
  - **Enviar PDF** ou **Imprimir**

## 7) Financeiro (o essencial)
- **Nova Transação** → Tipo (**Entrada/Saída**) → Data → Descrição → Valor → Categoria (opcional) → **Salvar**.

## 8) Backup (manual) — muito importante
- Menu lateral → **Backup (manual)**.
- No Linux, o app tenta salvar em:
  - `~/Documents/backups_app_funilaria/`
- Guarde o arquivo `.db` em local seguro (ex.: pendrive ou nuvem).

## 9) Internet e atualizações
- O app funciona **sem internet** (banco é local).
- Se existir atualização, pode aparecer um aviso com botão **Baixar atualização**.

## 10) Suporte / restauração de backup
- Nesta versão, a restauração não tem botão na interface.
- Para restaurar: feche o app e envie o arquivo **.db** do backup para o suporte.
