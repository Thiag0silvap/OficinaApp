# OficinaApp — Regras de Negócio e Funcionamento

> Documento de leitura para discussão de produto — sem jargão técnico. Cada regra cita entre parênteses o arquivo/função de onde foi extraída, para quem quiser conferir no código depois. Não é uma lista de bugs nem de sugestões — é um retrato fiel do que o sistema faz hoje.

---

## 1. Visão geral

O OficinaApp é um sistema de gestão para oficinas de funilaria/pintura que roda no computador ou celular do dono da oficina, guardando tudo localmente no próprio aparelho (não é um sistema em nuvem — não existe servidor central nem sincronização entre aparelhos). Ele cobre quatro áreas: cadastro de clientes e seus veículos, criação e acompanhamento de orçamentos/ordens de serviço do início ao pagamento, um controle financeiro simples de entradas e saídas, e geração de PDF (orçamento ou nota de serviço) para enviar ao cliente por WhatsApp. Cada pessoa que faz login no aplicativo tem sua própria "oficina" isolada dentro do mesmo aparelho — dados de clientes e orçamentos não se misturam entre contas diferentes, mas alguns cadastros auxiliares (como marcas/modelos de veículo digitados manualmente) são compartilhados entre todas as contas do mesmo aparelho, como detalhado abaixo.

---

## 2. Autenticação e usuários

**Login e cadastro.** O acesso é por usuário (nome de login) e senha, sem e-mail. Para criar conta, o nome precisa ter pelo menos 3 caracteres e só pode usar letras, números, ponto, underline ou hífen; a senha precisa ter pelo menos 6 caracteres e conter ao menos uma letra e um número (`services/auth_service.dart: validateRegistration`). Não existe recuperação de senha — se o usuário esquecer a senha, não há "esqueci minha senha" em lugar nenhum do app.

**Bloqueio por tentativas.** Depois de 5 tentativas de login erradas seguidas para o mesmo nome de usuário, o sistema bloqueia novas tentativas por 5 minutos (`services/auth_service.dart: maxFailedAttempts`, `lockoutDuration`). O contador zera assim que um login correto é feito.

**Sessão.** Depois de logado, se o app for fechado e reaberto em até 10 minutos, o usuário continua logado automaticamente; passado esse tempo, precisa fazer login de novo (`providers/auth_provider.dart: _restoreSession`). A opção "Lembrar usuário" só guarda o nome de usuário para preencher automaticamente na próxima vez — a senha nunca é lembrada, mesmo com a caixa marcada (`providers/auth_provider.dart: _saveCredentials` sempre grava senha vazia).

**Existe mais de um perfil de acesso?** Sim, no cadastro existe um campo "papel" com dois valores possíveis, Admin e Usuário (`models/user.dart: UserRole`). Na prática, **hoje esse papel não muda absolutamente nada no que a pessoa pode ver ou fazer** — não há nenhuma tela, botão ou ação no aplicativo que seja liberada para um e escondida para o outro. É um rótulo que existe no cadastro, mas sem efeito. Além disso, a conta "admin" só é criada automaticamente em versões de desenvolvimento do app (usuário `admin`, senha `123456`) — na versão que chega ao usuário final, essa conta não existe a menos que alguém se cadastre manualmente (`providers/auth_provider.dart: _init`, só roda em modo debug).

**Isolamento de dados entre contas.** Cada conta de usuário tem seu próprio banco de dados local, guardado em um arquivo separado no aparelho (`oficina_<idDoUsuario>.db`). Isso significa que clientes, veículos, orçamentos, transações financeiras e até os dados cadastrais da própria oficina (nome, telefone, endereço, CNPJ usados no PDF) **são completamente isolados por conta de login** — logar com um usuário diferente no mesmo celular/computador mostra uma oficina "vazia", sem nenhum dado da outra conta (`services/db_service_io.dart`, `providers/app_provider.dart: syncAuthUser/_ensureUserDbSelected`).

Isso **não** é verdade para tudo, porém: a lista de contas cadastradas no aparelho, o nome de usuário lembrado para autopreenchimento, e o catálogo de marcas/modelos de veículo digitados manualmente por qualquer usuário (ver seção 4) ficam guardados de forma compartilhada no aparelho, não dentro do banco de dados de cada conta — ou seja, se uma pessoa digitar uma marca de carro nova numa conta, essa marca aparece na lista de opções de todas as outras contas que usarem aquele mesmo aparelho (`services/auth_service.dart`, `providers/app_provider.dart: _customMarcas`, ambos gravados em SharedPreferences do aparelho, não no banco por usuário).

---

## 3. Clientes

**Tipos de cliente.** Existem quatro: Cliente Particular, Seguradora, Oficina Parceira e Frota Empresarial (`models/cliente.dart: TipoCliente`). Na prática, **só o tipo "Seguradora" muda alguma coisa no formulário**: ele libera três campos extras — Nome da Seguradora (obrigatório só nesse caso), CNPJ da Seguradora (opcional) e Pessoa de Contato (opcional) (`core/components/cliente_form_dialog.dart: _buildClientFields`). Os outros três tipos (Particular, Oficina Parceira, Frota) usam exatamente o mesmo formulário, sem nenhum campo a mais — a única diferença visual entre eles é a cor da bolinha/etiqueta na listagem de clientes (`screens/clientes_screen.dart: _getTipoClienteColor`).

**Campos obrigatórios vs opcionais.** Para qualquer cliente: Nome e Telefone são obrigatórios; Endereço e Observações são sempre opcionais (`providers/app_provider.dart: _validateCliente`). Se o tipo for Seguradora, o Nome da Seguradora também vira obrigatório (validado só na tela, não no provedor de dados — ver seção 8).

**Cliente sem veículo.** No cadastro de um cliente novo pela tela "Novo Cliente", **não é permitido salvar sem pelo menos um veículo** — o formulário é um assistente de 2 passos (dados do cliente → primeiro veículo) e recusa terminar o cadastro se nenhum veículo tiver sido preenchido (`core/components/cliente_form_dialog.dart: _submitAdd`, mensagem "Adicione pelo menos um veículo para concluir o cadastro do cliente"). Dito isso, depois de criado, um cliente **pode ficar sem nenhum veículo** — não existe hoje nenhuma tela para excluir um veículo isoladamente (ver seção 4), então isso só aconteceria se o cliente inteiro for apagado e recriado, ou por alteração direta no banco.

**Veículo sem cliente.** Não é permitido — toda tentativa de salvar um veículo sem um cliente válido associado é bloqueada pelo sistema (`providers/app_provider.dart: _validateVeiculo`, rejeita explicitamente o identificador temporário usado durante o assistente de cadastro).

**Excluir um cliente com orçamentos/veículos vinculados.** É permitido, e a exclusão **arrasta tudo junto silenciosamente**: todos os veículos daquele cliente, todos os orçamentos daquele cliente (em qualquer status) e qualquer lançamento financeiro que tenha nascido de um desses orçamentos são apagados na mesma operação (`providers/app_provider.dart: deleteCliente`). A caixa de confirmação que aparece para o usuário, porém, só avisa "Tem certeza que deseja excluir o cliente [nome]? Esta ação não pode ser desfeita" — **não menciona** que veículos, orçamentos e lançamentos financeiros ligados a ele também serão apagados (`screens/clientes_screen.dart: _showDeleteClienteDialog`).

---

## 4. Veículos

**Dados guardados por veículo.** Marca, modelo, cor, placa, ano (opcional) e observações (opcional) (`models/veiculo.dart`). Não existe campo de chassi, quilometragem ou histórico de manutenção.

**Catálogo de marcas/modelos.** A lista inicial é fixa no código — 8 marcas (Chevrolet, Fiat, Ford, Volkswagen, Honda, Toyota, Hyundai, Renault) com 4 a 5 modelos cada (`core/constants/app_constants.dart: marcas`, `modelosPorMarca`). Mas em qualquer formulário de veículo o usuário pode escolher "Outra... (digitar)" para marca ou modelo e digitar um valor livre; a partir daí esse valor fica salvo e passa a aparecer como opção normal na lista dali em diante (`providers/app_provider.dart: addMarcaModeloCustom`). Como descrito na seção 2, essas marcas/modelos digitados manualmente ficam guardados no aparelho de forma compartilhada entre todas as contas de usuário que usarem aquele aparelho — não são exclusivos da conta que os cadastrou.

**Um veículo pode ter mais de um dono ao longo do tempo?** Não existe essa funcionalidade. Cada veículo pertence a exatamente um cliente (`models/veiculo.dart: clienteId`), e **não há nenhuma tela para editar um veículo depois de criado** — nem para trocar o dono, nem para corrigir a placa ou a cor. As únicas ações disponíveis para um veículo já existente são: aparecer nas listas do cliente e no formulário de orçamento, e ser apagado em bloco junto com o cliente se o cliente for excluído. Não existe tela de "excluir veículo" isolada nem tela de "editar veículo" — apesar de o sistema internamente ter as funções prontas para atualizar e apagar um veículo individualmente, nenhuma tela chama essas funções (`providers/app_provider.dart: updateVeiculo`/`deleteVeiculo` existem mas não são usadas por nenhuma tela).

---

## 5. Orçamentos / Ordens de Serviço

**Ciclo de vida.** Um orçamento passa pelos status, nessa ordem obrigatória: **Pendente → Aprovado → Em andamento → Concluído**, com o pagamento sendo controlado à parte (ver abaixo). Existe também o status **Cancelado**, que é um desvio possível a partir de Pendente (`models/orcamento.dart: OrcamentoStatus`).

**O que é exigido em cada transição** (`providers/app_provider.dart`):
- **Pendente → Aprovado** (`aprovarOrcamento`): só funciona se o orçamento estiver, no momento do clique, exatamente com status Pendente. Registra a data de aprovação.
- **Aprovado → Em andamento** (`iniciarServico`): só funciona se estiver exatamente Aprovado.
- **Em andamento → Concluído** (`concluirOrcamento`): só funciona se estiver exatamente Em andamento e ainda não tiver data de conclusão registrada. Ao concluir, o sistema também grava automaticamente uma cópia dos dados do orçamento numa tabela interna de "notas" — mas essa cópia não aparece em nenhuma tela do app hoje (ver seção 8).
- **Não é possível pular etapas**: não existe um botão "Concluir" disponível em um orçamento Pendente, nem "Aprovar" num orçamento já Em andamento — cada tela só mostra o botão da próxima etapa válida (`screens/order_detail_screen.dart: _ActionsCard`, `screens/orcamentos_screen.dart: _resolvePrimary`).

**Cancelamento.** Nas telas do aplicativo, **cancelar só é oferecido enquanto o orçamento está Pendente** — não existe botão de cancelar para um orçamento Aprovado, Em andamento ou Concluído em nenhuma das duas telas onde orçamentos são gerenciados (`screens/orcamentos_screen.dart`, `screens/order_detail_screen.dart: _ActionsCard`). Uma vez cancelado, o orçamento fica travado — a tela de detalhe mostra "Orçamento cancelado. Nenhuma ação disponível." e nenhuma ação (nem reabrir, nem editar) é oferecida (`screens/order_detail_screen.dart`).

**Cálculo do valor total.** O orçamento é montado por itens de serviço (cada item tem um serviço, opcionalmente uma peça, uma descrição e um valor em reais digitado à mão — não há tabela de preço de peças, só uma lista de sugestão de preço por tipo de serviço que preenche o campo automaticamente e pode ser editado). O valor total do orçamento é a soma dos itens, menos um desconto opcional em reais (não em porcentagem) que o usuário pode digitar na última etapa; o desconto não pode ultrapassar o valor da soma dos itens (`core/components/orcamento_form_dialog.dart: _adicionarItem`, `_buildDescontoSection`, `_salvarOrcamento`). Não existe cálculo automático de mão de obra separado de peças, nem imposto, nem taxa de cartão.

**"Pago" e "Concluído" são independentes.** Concluir o serviço (mudar para status Concluído) e registrar o pagamento são duas ações separadas, cada uma com seu próprio botão, e uma não obriga a outra: um orçamento pode ficar Concluído e sem pagamento por tempo indefinido, mostrando um aviso "Serviço concluído, mas o pagamento ainda não foi registrado" (`screens/order_detail_screen.dart`). Só é possível registrar pagamento depois de o orçamento estar Concluído — não dá para receber pagamento de um orçamento Pendente/Aprovado/Em andamento (`providers/app_provider.dart: registrarPagamento`, exige status Concluído e ainda não pago).

**Efeito no financeiro.** A única ação de um orçamento que gera um lançamento financeiro automático é **registrar o pagamento**: nesse momento o sistema cria uma entrada de Entrada no financeiro, com valor igual ao valor total do orçamento, categoria "Serviço" e descrição "Pagamento serviço - [nome do cliente]" (`providers/app_provider.dart: registrarPagamento`). Aprovar, iniciar ou concluir o serviço **não** geram nenhum lançamento financeiro — só o pagamento gera.

**Edição depois de aprovado/em andamento.** As telas de listagem só oferecem o botão "Editar" quando o orçamento está Pendente — depois de aprovado, não há mais opção de editar em nenhuma das telas (`screens/orcamentos_screen.dart`, `screens/order_detail_screen.dart`, o botão de editar só aparece com `if (status == OrcamentoStatus.pendente)`). Além disso, mesmo no fluxo de edição de um orçamento Pendente, o cliente e o veículo escolhidos ficam travados (não é possível trocá-los durante a edição, só na criação) — só os itens, o desconto e as observações podem mudar (`core/components/orcamento_form_dialog.dart`, os campos de cliente/veículo ficam desabilitados quando `isEdit` é verdadeiro).

**Geração de PDF.** "Orçamento" e "Nota de Serviço" **são o mesmo documento, gerado pela mesma função**, mudando apenas o título impresso e um aviso de rodapé: se o orçamento ainda não está Concluído, o título é "Orçamento" e aparece o aviso "Este orçamento é válido por 30 dias"; se já está Concluído, o título vira "Nota de Serviço" e esse aviso de validade desaparece (`services/pdf_service.dart: generateOrcamentoPdf`). O PDF sempre traz os dados da oficina (nome, telefone, endereço, CNPJ) cadastrados em "Dados da Oficina" — que, como descrito na seção 2, são específicos de cada conta de usuário.

---

## 6. Financeiro

**O que conta como entrada/saída.** O sistema não impõe nenhuma categoria fixa de entrada ou saída — é o usuário quem escolhe manualmente "Entrada" ou "Saída" ao lançar cada transação, e digita livremente a categoria (Material, Ferramentas, Aluguel etc. são só sugestões pré-cadastradas, mas qualquer texto pode ser digitado) (`screens/financeiro_screen.dart: _NovaTransacaoDialog`, `core/constants/app_constants.dart: categoriasDespesas`).

**Transações automáticas vs manuais.** As duas coisas coexistem. Além do lançamento automático de Entrada criado ao registrar pagamento de um orçamento (seção 5), o usuário pode lançar qualquer transação manualmente pela tela Financeiro — de entrada ou saída, com descrição, valor, categoria e data livres (`screens/financeiro_screen.dart: _NovaTransacaoDialog`). Não existe nenhuma trava que impeça lançar uma "Entrada" avulsa que pareça um pagamento de serviço, nem que vincule automaticamente uma transação manual a um orçamento.

**Cálculos.** Saldo = soma de todas as entradas menos soma de todas as saídas, de todo o histórico (não só do mês) (`providers/app_provider.dart: saldo`). Faturamento mensal (mostrado no Dashboard) considera só as entradas do mês corrente; a comparação com o mês anterior é feita em porcentagem — se o mês anterior teve 0 e o atual tem algo, mostra "Novo" em vez de uma porcentagem (`providers/app_provider.dart: entradasMesAtual`, `entradasMesAnterior`, `percentageChange`).

**Editar ou excluir uma transação.** Não existe edição de transação depois de criada — só exclusão (`screens/financeiro_screen.dart: _confirmDelete`). A exclusão é permitida para **qualquer** transação, inclusive as que nasceram automaticamente de um pagamento de orçamento, sem nenhum aviso especial diferenciando esse caso de um lançamento manual qualquer. **O que acontece com o orçamento vinculado ao excluir sua transação de pagamento: nada.** O orçamento continua marcado como "Pago", com sua data de pagamento preservada — só o registro financeiro desaparece do extrato (`providers/app_provider.dart: deleteTransacao`, que apaga a transação mas não toca no orçamento). Isso é detalhado como ponto de atenção na seção 8.

---

## 7. Backup e dados

**O que é salvo no backup.** O backup copia o arquivo inteiro do banco de dados daquele usuário (todas as tabelas: clientes, veículos, orçamentos, transações, notas e dados da oficina) e grava também um arquivo de "manifesto" com metadados (data de criação, versão do app, versão do formato do banco, tamanho do arquivo, e o identificador do usuário dono daquele backup) (`services/db_service_io.dart: exportBackupToUserDocuments`). Não é um backup seletivo — é tudo ou nada, do usuário logado no momento.

**Restaurar backup de outro usuário/oficina por engano.** Existem duas formas de restaurar no app, com proteções diferentes:
- Pelo fluxo guiado interno (a partir da lista de backups já feitos naquele aparelho), o sistema **confere se o backup pertence ao usuário atualmente logado** e recusa restaurar se o identificador do usuário salvo no manifesto do backup for diferente do usuário logado, mostrando um erro (`services/db_service_io.dart: _validateBackupManifest`, "Este backup pertence ao usuário [x] e não ao usuário atual").
- Já pelo botão "Restaurar backup" do menu principal, o usuário escolhe **qualquer arquivo `.db`** solto no aparelho pelo seletor de arquivos do sistema operacional — esse caminho **não faz nenhuma verificação de dono**: qualquer arquivo `.db` válido (mesmo de outra oficina, outro usuário, ou salvo por outra pessoa) é aceito e substitui o banco da conta atualmente logada, sem checar a quem pertence (`core/components/responsive_components.dart: _confirmAndRestoreBackup`, chama `restoreBackupFromFilePath`, que não passa pela validação de usuário do outro caminho). Antes de sobrescrever, o sistema guarda uma cópia de segurança do banco atual (arquivo "_antes_restauracao"), então a operação anterior não é definitivamente perdida — mas o usuário não recebe nenhum aviso de que está prestes a importar dados de uma oficina diferente da que está logada.

---

## 8. Regras implícitas e pontos cegos

Esta seção lista comportamentos reais do sistema que não estão declarados em lugar nenhum para o usuário, mas que existem no código e afetam o funcionamento.

1. **Salvar/editar um orçamento não espera confirmação antes de dizer "sucesso".** Ao clicar em "Gerar Orçamento" ou "Salvar" no formulário de orçamento, o aplicativo chama a gravação no banco, mas **não espera essa gravação terminar** antes de mostrar "Orçamento salvo com sucesso!" e fechar a tela (`core/components/orcamento_form_dialog.dart: _salvarOrcamento`, as chamadas `appProvider.addOrcamento(...)`/`updateOrcamento(...)` não têm `await`). Na prática isso quase sempre funciona porque a gravação é rápida, mas significa que, se por qualquer motivo a gravação falhar (por exemplo, desconto igual ao valor total zerando o orçamento, que é rejeitado pela validação interna do sistema com "o valor total deve ser maior que zero"), **o usuário mesmo assim vê a mensagem de sucesso e a tela fecha como se tivesse dado certo** — o erro acontece "nos bastidores" e não chega a aparecer na tela.

2. **Excluir a transação de um pagamento não desfaz o "pago" do orçamento.** Como descrito na seção 6, apagar no Financeiro a transação que nasceu de um pagamento de orçamento não muda o status "Pago" daquele orçamento nem sua data de pagamento — o dinheiro some do extrato, mas o orçamento continua dizendo que foi pago. Não existe hoje um caminho para "estornar" um pagamento de dentro da tela do orçamento.

3. **O campo "Responsável" registra sempre quem editou por último, não quem criou.** Toda vez que um orçamento é salvo ou editado, o sistema apaga qualquer linha anterior que comece com "Responsável:" nas observações e escreve uma nova com o nome de quem está logado no momento daquele salvamento (`core/components/orcamento_form_dialog.dart: _salvarOrcamento`). Ou seja, se a pessoa A cria o orçamento e a pessoa B o edita depois, o campo passa a mostrar "Responsável: B" — não existe histórico de quem fez o quê, só o nome da última pessoa que salvou.

4. **A palavra "cor" é obrigatória na tela, mas não é cobrada pelo sistema por trás.** O formulário de veículo (tanto dentro do cadastro de cliente quanto no "Adicionar veículo" avulso) marca "Cor" com asterisco e recusa avançar sem preencher. Só que a validação central de veículos do sistema (`providers/app_provider.dart: _validateVeiculo`) não exige cor — só marca, modelo, placa e um cliente válido. Isso não muda nada hoje porque as duas telas de cadastro de veículo forçam o preenchimento, mas é uma regra que existe só na tela, não no núcleo do sistema.

5. **A validação de "Nome da Seguradora obrigatório" também só existe na tela, não no núcleo.** `providers/app_provider.dart: _validateCliente` só exige nome e telefone para qualquer tipo de cliente — a obrigatoriedade do nome da seguradora quando o tipo é Seguradora é imposta apenas pelo formulário (`core/components/cliente_form_dialog.dart`), não pela camada que efetivamente grava o cliente.

6. **Cancelar um orçamento não tem trava por status no núcleo do sistema, só na tela.** A função que cancela um orçamento (`providers/app_provider.dart: cancelarOrcamento`) só recusa cancelar se ele já estiver cancelado — tecnicamente aceitaria cancelar um orçamento Aprovado, Em andamento ou até Concluído. O que impede isso hoje é só o fato de nenhuma tela mostrar o botão de cancelar fora do status Pendente (seção 5). Não é uma trava do sistema, é uma trava de interface.

7. **O catálogo de marca/modelo de veículo digitado manualmente é compartilhado entre todas as contas do mesmo aparelho**, enquanto clientes, veículos e orçamentos são isolados por conta (detalhado nas seções 2 e 4). Isso pode ser surpreendente: um dono de oficina que empresta o aparelho para um funcionário logar com a própria conta vai ver, na lista de marcas, qualquer marca "digitada manualmente" que o funcionário tiver cadastrado — mesmo sem nunca ter tido acesso aos clientes dele.

8. **Existe uma tabela de "notas" gerada automaticamente que nunca aparece em tela nenhuma.** Toda vez que um orçamento é concluído, o sistema grava uma cópia dos dados daquele orçamento numa tabela chamada "notas" no banco (`providers/app_provider.dart: concluirOrcamento`, `models/nota.dart`). Essa tabela é gravada, mas **nenhuma tela do aplicativo lê ou mostra esse conteúdo** — a função para consultá-la existe no sistema (`services/db_service_io.dart: getNotas`) mas não é chamada por nenhuma tela. Na prática é um histórico "morto", invisível para quem usa o app; o PDF de "Nota de Serviço" que o usuário realmente vê e envia é gerado direto a partir do orçamento, não a partir dessa tabela.

9. **Não existe tela para editar ou excluir um veículo isoladamente**, embora as funções para isso existam no sistema (`providers/app_provider.dart: updateVeiculo`, `deleteVeiculo`) — nenhuma tela chama nenhuma das duas (detalhado na seção 4). Um erro de digitação numa placa, por exemplo, não tem como ser corrigido pelo aplicativo — só apagando o cliente inteiro (o que também apaga os orçamentos dele) e recadastrando tudo.

10. **Ao criar um orçamento, se o cliente escolhido não tiver nenhum veículo cadastrado, o formulário não oferece um jeito de cadastrar um ali mesmo** — o campo Veículo simplesmente fica vazio/sem opções, e é preciso sair do formulário de orçamento, ir até a tela de Clientes, adicionar um veículo por lá, e só depois voltar para criar o orçamento (`core/components/orcamento_form_dialog.dart`, o campo de veículo lista só `provider.getVeiculosByCliente(...)`, sem atalho de cadastro).

11. **"Excluir cliente" não avisa sobre o que mais vai junto.** Já citado na seção 3: a caixa de confirmação de exclusão de cliente fala só do cliente, mas a ação real apaga em cascata veículos, orçamentos e lançamentos financeiros vinculados — sem listar quantos itens serão afetados nem pedir confirmação extra para isso.

---

## 9. Funcionalidades ausentes

Com base no que existe hoje no código, o que **não foi encontrado** em nenhuma tela ou regra do sistema (sem julgar se deveria existir ou não):

- Agenda/agendamento real de horários ou datas de atendimento (existe um campo de "data prevista de entrega" dentro de um orçamento, mas não há uma agenda/calendário de compromissos).
- Controle de estoque de peças (o sistema tem uma lista fixa de nomes de peças para descrever o item do orçamento, mas não controla quantidade em estoque, entrada/saída de peças ou fornecedores).
- Diferença real de permissões entre perfis de usuário (o campo "papel" existe mas não tem efeito, como descrito na seção 2).
- Histórico de alterações/auditoria (não existe registro de quem alterou o quê e quando em nenhuma entidade — o único vestígio parecido é o campo "Responsável" sobrescrito a cada edição de orçamento, sem histórico).
- Notificação automática ao cliente (o envio de PDF por WhatsApp é sempre uma ação manual da pessoa da oficina — não existe lembrete automático, aviso de orçamento pronto, ou aviso de veículo pronto para retirada).
- Edição de veículo já cadastrado (só existe adicionar e, indiretamente, apagar em cascata junto com o cliente — seção 4/8).
- Edição ou estorno de uma transação financeira já lançada (só existe criar e excluir).
- Reabertura de um orçamento cancelado, ou qualquer forma de "desfazer" uma mudança de status.
- Múltiplos veículos vinculados a um mesmo orçamento (cada orçamento tem exatamente um veículo).
- Anexos de fotos do veículo/dano vinculados a um cliente, veículo ou orçamento visíveis em alguma tela (existe um modelo de dados para anexos e componentes de interface prontos para isso no código, mas não estão conectados a nenhuma tela do fluxo de cliente, veículo ou orçamento hoje).
- Qualquer tipo de sincronização entre aparelhos ou backup automático na nuvem (o backup é sempre manual e local, como descrito na seção 7).
- Relatórios financeiros além dos totais simples de entradas/saídas/saldo (não há relatório por categoria, por cliente, por período customizado, exportação em planilha, etc.).
- Recuperação de senha esquecida.
