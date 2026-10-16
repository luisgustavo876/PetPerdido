# PetPerdido — Progresso da finalização (TCC)

> Arquivo de acompanhamento. Para continuar numa sessão nova: "leia o PROGRESSO.md e continue".

Branch: `refactor/modulo-0-limpeza` (sem push, sem merge). Prazo: 28/10/2026.
Última atualização: 16/10/2026.

## Estado atual (resumo)

**Todo o código das 7 fases está pronto e commitado.** `flutter analyze` sem avisos, 131 testes
Flutter + 9 testes da Cloud Function passando, `flutter build apk --debug` compilando. Regras do
Firestore e do Storage publicadas e validadas por REST.

| Fase | Módulo | Situação |
|---|---|---|
| — | 0 Limpeza · 1 Regras · 2 Login/Cadastro · 3 Criar Post | ✅ Feito |
| 1 | 4 Mapa · 5 Feed · 6 Detalhe | ✅ Feito |
| 2 | IA (Gemini) | ✅ Código pronto · ⏸️ **você** ativa o AI Logic no console |
| 3 | Geofencing + Push | ✅ Código pronto · ⏸️ deploy da Function **espera sua autorização** |
| 4 | 7 Pontos e recompensas | ✅ Feito |
| 5 | 8 Chat | ✅ Feito · ⏸️ **você** cria a política TTL |
| 6 | 9 Configurações, perfil e LGPD | ✅ Feito |
| 7 | Fechamento (limpeza, regras, README, docs/SUBSIDIOS_TG.md) | ✅ Feito |

### O que falta

1. **Deploy da Cloud Function** (`firebase deploy --only functions`) — só com sua autorização,
   porque ativa APIs no Google Cloud. Depois dele: teste com 2 usuários de teste (um perto, um longe)
   e limpeza. **Para retomar:** autorize o deploy; eu publico, testo e registro aqui.
2. Os passos manuais abaixo (console do Firebase/Google e Git).
3. Seu teste no celular Android (roteiro no fim).

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
  filtros (tipo, espécie, porte, cor, favoritos, resolvidos) e ordem "Mais recentes" / "Mais perto
  de mim"; cards com "há 2 h · a 1,2 km"; estados vazio/erro. "Possíveis correspondências" na
  revisão do criar post (`Similaridade`, função pura testada).
- **Módulo 6** — detalhe com "Eu vi este pet" real (bairro automático, observações, foto opcional) em
  `posts/{id}/sightings/{uid}` + contadores no mesmo batch; linha do tempo real; favoritar
  (`users/{uid}.favorites`); compartilhar (share_plus); autor marca como resolvido e exclui
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
  **Falta:** deploy da Function (precisa da sua autorização) e o teste ponta a ponta.
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
- **Módulo 9** — Configurações com dados reais (nome editável, e-mail, CPF mascarado `***.456.789-**`,
  pontos), alterar senha (e-mail de redefinição), alertas (ligar/desligar e raio 1/3/5/10 km), "Meus
  posts" (resolver/excluir) e "Favoritos", Termos de Uso e Política de Privacidade (também linkados
  no cadastro), sair e "Excluir minha conta" com reautenticação. Sequência de exclusão validada por
  REST (33/33) e conferida com o MCP do Firebase (nenhum dado de teste sobrou em `chats`).

- **Fechamento** — sem código morto (nenhum arquivo, constante ou método sem uso), regras revisadas
  (autor não pode trocar o dono do post; validado 11/11), `cors.json` restrito a leitura, README
  reescrito e `docs/SUBSIDIOS_TG.md` criado.

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
- Favoritos no feed são lidos uma vez (e de novo ao voltar do Detalhe), para manter um só stream na tela.
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
- **IA — pacote:** `firebase_ai` 2.3.0, a versão compatível com os pacotes Firebase atuais
  (`firebase_core` 3.15). A versão mais nova (5.0.0, publicada em 15/10/2026) exigiria atualizar todos
  os pacotes Firebase em duas versões principais a poucos dias da entrega; fica como melhoria futura.
- **IA — modelo:** `gemini-3.5-flash` (constante `AppConstants.geminiModel`). Pela documentação do
  Firebase AI Logic (consultada em 16/10/2026), os Flash 3.6/3.7/3.8 são estáveis porém de
  "disponibilidade de curto prazo"; o 3.5 Flash tem disponibilidade garantida até pelo menos 05/2027.
  Para trocar, basta mudar a constante.
- **IA — dados:** a foto é reduzida (máx. 1024 px, JPEG 80) antes de enviar. O prompt manda ignorar
  pessoas e responder "Indefinido" sem cão/gato. A resposta só é aceita com valores das listas do app
  (espécie, porte, até 2 cores, características); raça limitada a 40 caracteres.
- O pacote `firebase_ai` só exporta a classe base de erro; o tipo (cota, API desativada) é reconhecido
  pela mensagem em `AIService.mensagemDeErro` (testada).
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
  política TTL apagar do banco. (O INSTRUCTIONS fala em "15 dias de inatividade"; segui o roteiro:
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

### 1. Autorizar o deploy da Cloud Function dos alertas
O código está em `functions/` e testado localmente (`npm test`). O primeiro
`firebase deploy --only functions` ativa no Google Cloud as APIs necessárias (Cloud Functions,
Cloud Build, Artifact Registry, Eventarc, Cloud Run, Pub/Sub). O plano Blaze já está ativo.
Responda "pode fazer o deploy" que eu publico, testo com 2 usuários de teste e apago tudo.

### 2. Ativar o Firebase AI Logic (necessário para "Preencher com IA")
Hoje a API responde 403 "Firebase AI Logic API has not been used ... or it is disabled".
1. Abra https://console.firebase.google.com/project/petperdido-ff844 e entre com a conta do projeto.
2. No menu da esquerda, abra **AI Logic** (fica em "Criar" / "Build", às vezes listado como "AI").
3. Clique em **Começar** ("Get started").
4. Escolha **Gemini Developer API** (não a "Vertex AI Gemini API") e confirme em **Ativar API**
   ("Enable API"). O console cria e gerencia a chave sozinho — não coloque chave nenhuma no app.
5. Se aparecer a sugestão de ativar o App Check, pode pular por enquanto (recomendado só em produção).
6. Espere uns 5 minutos e teste: Criar postagem → foto de cão ou gato → **Preencher com IA**.

### 3. Criar a política TTL das mensagens do chat
1. Abra https://console.cloud.google.com/firestore/databases/-default-/ttl?project=petperdido-ff844
   (ou, no console do Firebase, Firestore → aba **TTL**, se aparecer).
2. Clique em **Criar política** ("Create policy").
3. Em **Grupo de coleções** digite `messages`.
4. Em **Campo de carimbo de data/hora** digite `expireAt`.
5. Clique em **Criar**. Leva alguns minutos para ficar "Ativa"; o Firestore apaga as mensagens
   vencidas sozinho (até 24 h depois da data).

### 4. Restringir a chave do Google Maps
A chave `AIzaSyC9iSb...` está no `AndroidManifest.xml`, no `AppDelegate.swift` e no `web/index.html`.
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

### 5. CORS do Storage (só se as fotos não aparecerem no Chrome)
O `cors.json` (só leitura: GET/HEAD) está no repositório. Para aplicar, abra o **Cloud Shell**
(ícone `>_` no topo do console do Google Cloud), envie o arquivo e rode:
`gcloud storage buckets update gs://petperdido-ff844.firebasestorage.app --cors-file=cors.json`

### 6. Limpeza de dados e do repositório
- Apagar no console do Firebase (Firestore → `posts`) os posts antigos de teste, criados antes do
  Módulo 3 (têm `createdAt` em texto e coordenadas aleatórias).
- Remover a pasta `windows/` (não é usada; o Firebase não suporta Windows desktop):
  `git rm -r -q windows` e depois um commit.

## Como testar cada módulo no celular Android

Preparação: celular com **Depuração USB** ativada, conectado ao PC → `flutter run`
(ou instale `build/app/outputs/flutter-apk/app-debug.apk`). Use 2 contas (a sua e uma segunda,
no Chrome em `flutter run -d web-server --web-port 8080`).

1. **Cadastro (Módulo 2):** crie uma conta com CPF inválido (`11111111111`) → "CPF inválido";
   data de nascimento de menos de 16 anos → bloqueia; dados válidos → entra direto no app.
2. **Alertas (Geofencing):** no aviso "Alertas de pets perto de você" toque em **Ativar alertas** e
   permita notificações e localização. *(Só depois do deploy da Function:)* com a outra conta, crie um
   post a menos de 3 km → chega "Pet perdido perto de você"; tocar abre o post; com o app aberto
   aparece um banner; o sino mostra o alerta.
3. **Criar post (Módulo 3 + IA):** Mapa → Criar postagem → "Perdi" → foto (câmera ou galeria) →
   **Preencher com IA** (após ativar o AI Logic) → confira o selo "Sugerido pela IA" → marque o ponto
   no mapa (o bairro aparece sozinho) → revisão com "Possíveis correspondências" → Publicar.
4. **Mapa (Módulo 4):** marcadores por cor; toque → resumo → "Ver detalhes"; Filtros (tipo, espécie,
   período, resolvidos); botão satélite; "Minha localização".
5. **Feed (Módulo 5):** digite na busca (não perde o texto); filtros; "Mais perto de mim" mostra
   "a X km"; favoritos.
6. **Detalhe (Módulo 6):** com a outra conta, "Eu vi este pet" (bairro automático, foto opcional) → a
   linha do tempo atualiza e o botão vira "Já registrado"; favoritar; compartilhar (WhatsApp etc.);
   como autor: "Marcar como resolvido" e "Excluir".
7. **Pontos (Módulo 7):** depois de um "Achei" (+30) e de um "Eu vi" (+15), a aba Pontos mostra o
   saldo e o histórico; resgate uma recompensa → código do voucher em "Meus resgates".
8. **Chat (Módulo 8):** no post da outra conta, "Entrar em contato" → mande texto (teste um palavrão:
   vira `***`) e uma foto; a outra conta vê a conversa com "não lidas".
9. **Configurações (Módulo 9):** ícone de pessoa → nome, CPF mascarado, pontos; editar nome; alertas
   (desligar/ligar, raio); Meus posts; Favoritos; Termos e Privacidade; **Excluir minha conta** com
   uma conta de teste (pede a senha; tudo some).

## Como rodar as verificações

- `flutter analyze` · `flutter test` · `flutter build apk --debug`
- `cd functions && npm test`
- Web no seu Chrome: `flutter run -d web-server --web-port 8080` → http://localhost:8080
