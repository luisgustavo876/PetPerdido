# PetPerdido — Progresso da finalização (TCC)

> Arquivo de acompanhamento. Para continuar numa sessão nova: "leia o PROGRESSO.md e continue".

Branch: `refactor/modulo-0-limpeza` (enviada ao GitHub, sem merge). Prazo: 28/10/2026.
Última atualização: 16/10/2026 (pacote de correções de UX e bugs).

## Estado atual (resumo)

**Todo o código das 7 fases está pronto e commitado.** `flutter analyze` sem avisos, 166 testes
Flutter + 9 testes da Cloud Function passando, `flutter build apk --debug` compilando. Regras do
Firestore e do Storage publicadas e validadas por REST (inclusive a de avistamento não vazio).

| Fase | Módulo | Situação |
|---|---|---|
| — | 0 Limpeza · 1 Regras · 2 Login/Cadastro · 3 Criar Post | ✅ Feito |
| 1 | 4 Mapa · 5 Feed · 6 Detalhe | ✅ Feito |
| 2 | IA (Gemini) | ✅ Código pronto (Function `analisarPet`) · ⏸️ chave gratuita + deploy da Function |
| 3 | Geofencing + Push | ✅ Function publicada (16/10) e testada ponta a ponta |
| 4 | 7 Pontos e recompensas | ✅ Feito |
| 5 | 8 Chat | ✅ Feito (TTL publicado por código) |
| 6 | 9 Configurações, perfil e LGPD | ✅ Feito |
| 7 | Fechamento (limpeza, regras, README, docs/SUBSIDIOS_TG.md) | ✅ Feito |

**Versão Web publicada (23/10/2026):** https://petperdido-ff844.web.app (Firebase Hosting, seção
`hosting` no `firebase.json` servindo `build/web`). Conferido no domínio publicado: login, mapa e feed
com fotos. Domínio já autorizado no Firebase Auth. Para atualizar: `flutter build web --release` e
`firebase deploy --only hosting`.

### O que falta

1. ~~Deploy da Cloud Function~~ — **feito em 16/10/2026** e testado ponta a ponta (22/22): só o usuário
   a ~0,6 km recebeu o alerta; o de ~12 km e o autor não. Falta só decidir a política de limpeza
   do Artifact Registry (item 1 dos passos manuais).
2. ~~Publicar a regra de avistamento não vazio~~ — **publicada em 16/10/2026** (ruleset ativo igual
   ao `firestore.rules`; validada no projeto real 5/5, dados de teste apagados).
3. Os passos manuais abaixo (console do Firebase/Google e Git).
4. Seu teste no celular Android (roteiro no fim).

## Feito

- **Módulo 0** — limpeza de código morto, widgets `PetImage` e `PostTypeStyle`, README.
- **Módulo 1** — `firestore.rules` e `storage.rules` publicadas e validadas por REST.
- **Módulo 2** — CPF (módulo 11), idade mínima 16, cadastro sem travar, app em pt-BR.
- **Módulo 3** — criar post em 5 etapas, mapa com marcador, bairro automático (geocoding nativo + Nominatim), cor, data do ocorrido, coordenadas arredondadas (~100 m), geohash.
- **Módulo 4** — mapa com stream único, marcadores por tipo (resolvidos ocultos por padrão,
  semitransparentes quando incluídos), filtros reais (tipo, espécie, período, incluir resolvidos)
  num painel compartilhado (`FiltrosSheet`), camada satélite, "Minha localização" e câmera inicial
  na posição do usuário (só se ele já tiver dado permissão). Build Android corrigido.
- **Módulo 5** — feed com stream único, busca que não perde o texto (sem acentos, várias palavras),
  filtros (tipo, espécie, porte, cor, resolvidos) e ordem "Mais recentes" / "Mais perto
  de mim"; cards com "há 2 h · a 1,2 km"; estados vazio/erro. "Possíveis correspondências" na
  revisão do criar post (`Similaridade`, função pura testada).
- **Módulo 6** — detalhe com "Eu vi este pet" real (bairro automático, observações, foto opcional) em
  `posts/{id}/sightings/{uid}` + contadores no mesmo batch; linha do tempo real;
  compartilhar (share_plus); autor marca como resolvido e exclui
  (post + avistamentos + fotos). Regras publicadas e validadas por REST (28/28, tudo limpo).
- **Módulo IA** — "Preencher com IA" na etapa Foto (foto reduzida para 1024 px, JSON estruturado com
  `responseSchema`) e "Preencher a partir da descrição" para Avistei sem foto. Sugestões com selo
  "Sugerido pela IA" na etapa Pet, sempre editáveis. Erros tratados (offline, cota, API desativada,
  resposta inválida, "não é um pet"). Conversor puro `SugestaoIA.converter` com testes.
- **Módulo Geofencing** — app: `firebase_messaging`, permissão POST_NOTIFICATIONS, canal
  `alertas_pets` (criado na `MainActivity`), aviso de LGPD antes de pedir a localização, gravação de
  `lastLocation` (arredondada, com geohash) e `fcmToken` ao abrir e ao voltar do segundo plano,
  toque na notificação abre o post, banner dentro do app, sino com contador e tela "Alertas".
  Cloud Function `alertarProximos` em `functions/` (Node 22, southamerica-east1) com lógica pura
  testada (`npm test`, 9 testes). Regras de `users/{uid}/notifications` publicadas e validadas (13/13).
  **Deploy feito em 16/10/2026** (southamerica-east1) e teste ponta a ponta 22/22: com 3 usuários de
  teste (autor, um a ~0,6 km e um a ~12 km, raio 3 km), só o de perto recebeu o alerta ("Pet perdido
  perto de você" · "Cão caramelo · Vila Barth, Itapetininga"); a Function apagou o token falso
  (push inválido) e o log registrou "1 avisados". Tudo apagado e conferido pelo MCP.
- **Módulo 7** — pontos reais em `users/{uid}.points` (stream): Achei +30, Avistei +10, "Eu vi" +15
  (uma vez por post), sempre em transação com registro em `pointsLog`; nível com barra de progresso;
  "Como ganhar pontos"; histórico; catálogo de recompensas de exemplo ("Exemplo de parceria", sem
  marcas); resgate em transação que confere o saldo e gera o código do voucher; "Meus resgates".
  `DadosGlobais` não guarda mais pontos. Regras validadas por REST (18/18).
- **Módulo 8** — chat real: "Entrar em contato" no Detalhe abre/cria a conversa com id
  determinístico (`postId_uidA_uidB`), sem conversar consigo mesmo; lista de conversas em tempo real
  (mais recentes primeiro, última mensagem, não lidas); chat com texto e foto (Storage
  `chats/{chatId}/`, até 5 MB); filtro de palavrões (ao enviar e ao exibir); mensagens com mais de
  15 dias escondidas e com `expireAt` para o TTL; só o nome do outro aparece. `DadosGlobais` foi
  apagado. Regras do Firestore e do Storage validadas por REST com 3 usuários (35/35).
- **Módulo 9** — Configurações com dados reais (nome editável, CPF mascarado `***.456.789-**`,
  pontos), alterar senha (e-mail de redefinição), alertas (ligar/desligar e raio 1/3/5/10 km), "Meus
  posts" (resolver/excluir), Termos de Uso e Política de Privacidade (também linkados
  no cadastro), sair e "Excluir minha conta" com reautenticação. Sequência de exclusão validada por
  REST (33/33) e conferida com o MCP do Firebase (nenhum dado de teste sobrou em `chats`).

- **Fechamento** — sem código morto (nenhum arquivo, constante ou método sem uso), regras revisadas
  (autor não pode trocar o dono do post; validado 11/11), `cors.json` restrito a leitura, README
  reescrito e `docs/SUBSIDIOS_TG.md` criado.

- **Pacote de correções de UX e bugs (16/10)** — um commit por item:
  1. Fotos na Web: o `photoUrl` estava certo; o bucket não manda CORS e o Flutter Web escondia o
     erro. `PetImage` usa `WebHtmlElementStrategy.fallback` (desenha como `<img>` se o CORS bloquear)
     e loga o erro em modo debug. O `cors.json` continua valendo (passo manual 5).
  2. CPF com máscara `000.000.000-00` (`MascaraInputFormatter`, sem dependência); grava só os dígitos.
  3. Data de nascimento digitada (`29062006` → `29/06/2006`) com calendário opcional; valida data
     real, futuro e 16 anos, com mensagens claras.
  4. Usuário sempre pelo nome (`Formatters.nomeUsuario`): sem nome ou com "@" vira "Usuário". O
     cartão do perfil não mostra mais o e-mail. O chat também não copia mais o `userName` do post
     sem filtrar. **Dados corrigidos (16/10):** 2 posts (`userName`) e 1 chat
     (`participantNames`) guardavam o e-mail de uma conta sem nome no perfil; viraram "Usuário".
     Varredura de posts, sightings, chats, messages e notifications: 0 e-mails.
  5. "Eu vi" exige bairro e descrição (mín. 10 caracteres), botão desabilitado e aviso do que falta;
     regra equivalente em `sightings` (emulador 14/14; publicada e conferida no projeto real 5/5).
  6. Fotos sem corte: inteira na criação, inteira sobre fundo desfocado no card, proporção original
     e zoom em tela cheia no detalhe; upload até 1600 px / qualidade 85, mantendo a proporção.
  7. 22 características prontas (agrupadas) + até 5 próprias ("+ Adicionar", 2 a 24 caracteres, sem
     duplicar, com filtro de palavrões).
  8. "Favoritos" removido (coração, item do perfil, filtro, serviço). Eram um array `favorites` em
     `users/{uid}`, sem regra própria; o campo pode sobrar em documentos antigos, sem uso.

## Decisões de implementação

- Coordenadas sempre arredondadas para 3 casas (`LocationService.arredondar`, ~100 m) antes de gravar.
- Endereço público = só "Bairro, Cidade" (nunca rua com número).
- Consultas sem índice composto: últimos 100 posts por `createdAt` e filtros no app.
- **Build Android:** o projeto estava com Android Gradle Plugin 8.3.2, mas as bibliotecas AndroidX
  atuais exigem 8.9.1+. Atualizado para AGP 8.11.1 + Kotlin 2.2.20 (combinação do Flutter 3.41).
- Filtro de período usa a data do ocorrido (`eventAt`), não a data da publicação.
- "Satélite" = `MapType.hybrid` (satélite com nomes de ruas).
- Na Web o ponto azul nativo não existe: a posição do usuário vira um marcador azul.
- `PostOptions` virou `PetOptions` em `lib/core/pet_options.dart` (usado no app todo).
- **Posts semelhantes** (`lib/core/similaridade.dart`): obrigatório tipos opostos (Perdi x Achei/Avistei),
  mesma espécie, nenhum resolvido, até 3 km e até 7 dias entre os ocorridos; além disso, cor em comum
  ou mesmo porte (se os dois informaram cores, precisa haver ao menos uma em comum). A nota ordena
  a lista (cor 0,4 + porte 0,3 + proximidade 0,3). Mostra até 5.
- O botão "Conversar" saiu do card até o chat real existir (Fase 5).
- O `PetPostCard` não usa mais `GoogleFonts` direto (a fonte vem do tema) — assim dá para testá-lo.
- **Avistamentos:** o id do documento é o uid de quem viu → no máximo 1 por pessoa por post (as regras
  negam o segundo). Um não-autor só altera `sightingsCount`/`helpersCount`, exatamente +1, e só no mesmo
  batch em que cria o próprio avistamento (`existsAfter`). O autor do post pode apagar avistamentos
  (necessário para "Excluir post"). Coordenadas do avistamento arredondadas; se o bairro digitado não
  for encontrado, o avistamento é salvo sem coordenadas.
- Fotos de avistamento ficam em `posts/{postId}/avistamento_{uid}.jpg` (mesma regra do Storage dos posts).
- Regras: publico com `firebase deploy --only firestore:rules` (após `--dry-run`) e valido logo em
  seguida por REST com 2 usuários de teste; tudo é apagado no fim.
- Build Android: se aparecer `mergeExtDexDebug` falhando, rodar de novo (erro passageiro do Gradle).
- **IA — de AI Logic para Cloud Function (23/10/2026):** o projeto está no Blaze (exigido pela
  Function de alertas), então a Gemini API dele saiu do nível gratuito e passou a usar créditos
  pré-pagos, que acabaram (erro 429 "prepayment credits are depleted"). O nível gratuito só vale para
  projetos sem faturamento. Solução sem custo: chave criada no AI Studio num **projeto separado, sem
  faturamento**, guardada no segredo `GEMINI_API_KEY` do Firebase; a Function `analisarPet` (HTTPS,
  só usuário logado, CORS só dos domínios do app) chama o Gemini. O app saiu do `firebase_ai` e
  chama a Function com o pacote `http` (sem biblioteca Android nova).
- **IA — modelos:** lista em `functions/ia.js` (`gemini-3.6-flash`, `3.8-flash`, `3.5-flash-lite`,
  `2.5-flash`); em 429 (limite gratuito daquele modelo) ou 404 tenta o próximo. As listas de valores
  permitidos vão do app para a Function (uma fonte só: `PetOptions`).
- **IA — nível gratuito:** tem limite diário por modelo e o Google pode usar o conteúdo enviado para
  melhorar os produtos; avisado na tela e na Política de Privacidade.
- **IA — dados:** a foto é reduzida (máx. 1024 px, JPEG 80) antes de enviar. O prompt manda ignorar
  pessoas e responder "Indefinido" sem cão/gato. A resposta só é aceita com valores das listas do app
  (espécie, porte, até 2 cores, características); raça limitada a 40 caracteres.
- Erros da IA: `AIService.mensagemDoStatus` (401, 429, 400, outros) e `mensagemDeErro` (tempo,
  internet), testadas.
- **Geofencing — consentimento:** `alertsEnabled` só é gravado depois do aviso de LGPD (aceitou = true,
  "Agora não" = false). Sem resposta (campo ausente) o app pergunta ao abrir. Assim ninguém recebe
  alertas nem tem a localização guardada sem ter concordado. O raio padrão é 3 km.
- **Geofencing — quando atualiza:** ao abrir o app e ao voltar do segundo plano (no máximo a cada
  15 min). Nunca rastreamento contínuo. A localização é a última conhecida.
- **Geofencing — Function:** busca por faixas de geohash com o maior raio (10 km) em
  `users.lastLocation.geohash` (índice simples, automático), filtra pela distância exata ≤ raio de cada
  usuário, exclui o autor e quem desligou. Grava `users/{uid}/notifications` e envia push com
  `sendEachForMulticast` (lotes de 500), apagando tokens inválidos. Região southamerica-east1 = mesma
  do Firestore. `firebase-functions` 7.4, `firebase-admin` 14.5, `geofire-common` 6.0, Node 22 (o mais
  novo na lista de runtimes do Cloud Functions em 16/10/2026).
- **Notificações:** só a Function cria (Admin SDK); o dono lê, apaga e muda apenas o campo `read`.
- **Push na Web e no iOS:** fora do escopo. Na Web o serviço de alertas não roda (precisaria de chave
  VAPID e service worker); no iOS o push exige chave APNs (conta Apple Developer).
- Ao sair da conta, o `fcmToken` é apagado do `users/{uid}` (o aparelho para de receber os alertas
  daquela conta).
- **Pontos — "uma vez só":** cada ganho usa um id fixo no `pointsLog` (`post_<id>`, `euvi_<id>`); a
  transação não soma de novo se o lançamento já existe, e as regras não deixam recriar nem editar
  lançamentos. Publicar "Perdi" não dá pontos (só contribuições para os outros).
- **Pontos — limitação:** a pontuação é gravada pelo próprio app (o dono pode escrever em
  `users/{uid}`). Num produto real ela iria para uma Cloud Function. Registrado para o TG.
- **Recompensas:** catálogo fixo em `lib/core/recompensas.dart` (5 itens genéricos). Código do voucher
  `PET-XXXX-XXXX` sem caracteres que confundem (0/O, 1/I). É demonstração, sem validação no parceiro.
- **Níveis:** Vizinho atento (0), Ajudante da rua (50), Protetor do bairro (150), Herói dos pets (300).
- **Chat — id e regras:** o id é `postId_uidA_uidB` com os uids em ordem; as regras conferem esse
  formato na criação e que são 2 pessoas diferentes. Depois de criada, só mudam `lastMessage`,
  `lastMessageAt` e `unread`. Mensagens: só participantes leem; cada um cria em nome próprio.
  Lista de conversas: `participants array-contains` e ordenação no app (sem índice composto).
- **Chat — só com o autor do post (fix 16/10):** a criação exige que o post de `postId` exista, que o
  autor dele seja um dos 2 participantes e que quem cria NÃO seja o autor (no app quem chama é quem
  quer ajudar; o autor só responde). Toda mensagem precisa de `expireAt` do tipo timestamp.
  Validado por REST (21/21) e conferido pelo MCP (nada sobrou em `chats`).
- **Chat — Storage sem IAM:** a regra de `chats/{chatId}/` verifica se o uid de quem pede está dentro
  do `chatId` (que já foi validado no Firestore). Assim não precisa da regra cruzada Storage→Firestore,
  que exigiria liberar permissão no IAM.
- **Chat — link da foto:** como em todo o Firebase Storage, quem tiver a URL de download (com token)
  consegue abrir a foto. A URL só fica gravada nas mensagens, que só os participantes leem.
- **Palavrões:** lista em `lib/core/filtro_palavroes.dart`, comparação por palavra inteira, sem acento
  e sem diferenciar maiúsculas; palavras ambíguas do dia a dia ("pau", "rola", "pinto") ficam de fora.
- **15 dias:** o app esconde mensagens com mais de 15 dias e grava `expireAt` = envio + 15 dias para a
  política TTL apagar do banco (política definida em `firestore.indexes.json`). (O INSTRUCTIONS fala em "15 dias de inatividade"; segui o roteiro:
  15 dias por mensagem.)
- O banner do chat orienta a combinar a entrega em local público e a não enviar endereço/CPF.
- **Excluir conta — ordem:** reautentica com a senha → apaga posts do usuário (com avistamentos e
  fotos) → avistamentos feitos em posts de outros (achados pelo histórico de pontos `euvi_<postId>`,
  sem consulta de grupo de coleções, que exigiria índice) → mensagens próprias (e fotos) e as
  conversas → `notifications`, `pointsLog`, `redemptions` → `users/{uid}` → usuário do Auth.
  As mensagens da outra pessoa ficam inacessíveis sem o documento da conversa e o TTL as apaga.
- **Desligar alertas** apaga `lastLocation` e `fcmToken` (minimização de dados, LGPD). Ligar de novo
  pede as permissões e grava de novo.
- **Trocar o nome** atualiza `users/{uid}` e o Auth; posts e conversas antigos guardam o nome da época
  (cópia no documento, comum em Firestore).
- Termos e Política: textos de protótipo, em linguagem simples, sem contato pessoal; devem ser
  revisados antes de um uso real. O alerta, a Web e o raio aparecem desabilitados na Web (sem push).

## Passos manuais pendentes (dependem de você)

### 1. (Opcional, envolve custo) Política de limpeza das imagens das Functions
O deploy funcionou, mas o CLI avisou que não configurou a política que apaga imagens antigas de
build no Artifact Registry (região southamerica-east1). Sem ela, cada novo deploy guarda uma imagem
(custo pequeno de armazenamento). Para configurar (apaga imagens com mais de 1 dia):
`firebase functions:artifacts:setpolicy --location southamerica-east1`
(ou, no próximo deploy, `firebase deploy --only functions --force`).

### 2. Chave gratuita da IA (necessária para "Preencher com IA")
1. Em https://aistudio.google.com/apikey → **Criar chave de API** → num **projeto novo** (ex.:
   "PetPerdido IA"), **sem faturamento** (plano "Free"). Nunca no `petperdido-ff844`.
2. No terminal, na pasta do projeto: `firebase functions:secrets:set GEMINI_API_KEY` e cole a chave
   (se pedir para ativar o Secret Manager, responda Y).
3. Deploy da Function: `firebase deploy --only functions` (pedir autorização antes).
4. Teste: Criar postagem → foto de cão ou gato → **Preencher com IA**.

### 3. ~~Criar a política TTL das mensagens do chat~~ — feito por código (16/10/2026)
`firestore.indexes.json` tem um `fieldOverrides` com `ttl: true` em `messages.expireAt` (mantendo os
índices simples padrão do campo). Publicado com `firebase deploy --only firestore:indexes`; logo após
o deploy a política estava `CREATING` e passa a `ACTIVE` em alguns minutos. Para conferir:
`firebase firestore:indexes` (mostra `ttl: true`) ou a aba TTL do Firestore no console do Google Cloud.

### 4. Restringir a chave do Google Maps
**Android: feito em 16/10** — o `AndroidManifest.xml` usa uma chave nova, restrita por pacote e SHA-1.
A chave antiga `AIzaSyC9iSb...` continua no `AppDelegate.swift` e no `web/index.html` (não apague nem
restrinja só para Android, senão o mapa da Web para). Falta fazer o mesmo para a Web (e o iOS):
1. Abra https://console.cloud.google.com/apis/credentials?project=petperdido-ff844 e clique na chave
   do Maps.
2. **Restrições de aplicativo:** como ela é usada em mais de uma plataforma, o mais simples é criar
   **uma chave para cada uma**:
   - Android: "Apps Android" → adicionar pacote `com.luisg.petperdido` + **SHA-1** do certificado.
     Para o debug: `cd android && .\gradlew signingReport` e copie o SHA1 da variante `debug`.
   - Web: "Referenciadores HTTP" → `http://localhost:8080/*` (e o domínio, se publicar o site).
   - Troque a chave em cada arquivo pela chave da plataforma.
3. **Restrições de API:** marque só "Maps SDK for Android", "Maps SDK for iOS" e "Maps JavaScript API".
4. Salve e teste o mapa no celular e no Chrome (pode levar alguns minutos para valer).

### 5. CORS do Storage (recomendado)
Confirmado em 16/10: o bucket não devolve `Access-Control-Allow-Origin`. O app já contorna isso na
Web (desenha a foto como `<img>`), mas com o CORS aplicado as fotos carregam pelo caminho normal
(e o fundo desfocado dos cards funciona). O `cors.json` (só leitura: GET/HEAD) está no repositório.
No **Cloud Shell** (ícone `>_` no topo do console do Google Cloud) rode:
`gsutil cors set cors.json gs://petperdido-ff844.firebasestorage.app`
(o comando que cria o arquivo no Cloud Shell está no relatório da sessão de 16/10).

### 6. Limpeza de dados e do repositório
- Apagar no console do Firebase (Firestore → `posts`) os posts antigos de teste, criados antes do
  Módulo 3 (têm `createdAt` em texto e coordenadas aleatórias).
- Remover a pasta `windows/` (não é usada; o Firebase não suporta Windows desktop):
  `git rm -r -q windows` e depois um commit.

## Como testar cada módulo no celular Android

Preparação: celular com **Depuração USB** ativada, conectado ao PC → `flutter run`
(ou instale `build/app/outputs/flutter-apk/app-debug.apk`). Use 2 contas (a sua e uma segunda,
no Chrome em `flutter run -d web-server --web-port 8080`).

1. **Cadastro (Módulo 2):** digite só números no CPF (vira `000.000.000-00`); CPF inválido
   (`11111111111`) → "CPF inválido"; data digitada só com números (`29062006` → `29/06/2006`) ou pelo
   ícone do calendário; `31/02/2006` → "Data inválida"; menos de 16 anos → bloqueia; dados válidos →
   entra direto no app.
2. **Alertas (Geofencing):** no aviso "Alertas de pets perto de você" toque em **Ativar alertas** e
   permita notificações e localização. Com a outra conta, crie um post a menos de 3 km → chega "Pet perdido perto de você"; tocar abre o post; com o app aberto
   aparece um banner; o sino mostra o alerta.
3. **Criar post (Módulo 3 + IA):** Mapa → Criar postagem → "Perdi" → foto (câmera ou galeria) →
   **Preencher com IA** (após a chave gratuita e o deploy da Function) → confira o selo "Sugerido pela IA" → marque o ponto
   no mapa (o bairro aparece sozinho) → revisão com "Possíveis correspondências" → Publicar.
4. **Mapa (Módulo 4):** marcadores por cor; toque → resumo → "Ver detalhes"; Filtros (tipo, espécie,
   período, resolvidos); botão satélite; "Minha localização".
5. **Feed (Módulo 5):** digite na busca (não perde o texto); filtros; "Mais perto de mim" mostra
   "a X km"; fotos inteiras (sem corte) nos cards.
6. **Detalhe (Módulo 6):** toque na foto → tela cheia com zoom; com a outra conta, "Eu vi este pet"
   (bairro automático, descrição obrigatória, foto opcional) → a linha do tempo atualiza e o botão
   vira "Já registrado"; compartilhar (WhatsApp etc.); como autor: "Marcar como resolvido" e "Excluir".
7. **Pontos (Módulo 7):** depois de um "Achei" (+30) e de um "Eu vi" (+15), a aba Pontos mostra o
   saldo e o histórico; resgate uma recompensa → código do voucher em "Meus resgates".
8. **Chat (Módulo 8):** no post da outra conta, "Entrar em contato" → mande texto (teste um palavrão:
   vira `***`) e uma foto; a outra conta vê a conversa com "não lidas".
9. **Configurações (Módulo 9):** ícone de pessoa → nome, CPF mascarado, pontos; editar nome; alertas
   (desligar/ligar, raio); Meus posts; Termos e Privacidade; **Excluir minha conta** com
   uma conta de teste (pede a senha; tudo some).

## Como rodar as verificações

- `flutter analyze` · `flutter test` · `flutter build apk --debug`
- `cd functions && npm test`
- Web no seu Chrome: `flutter run -d web-server --web-port 8080` → http://localhost:8080
