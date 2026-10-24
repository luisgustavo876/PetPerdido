# Subsídios técnicos para o TG — PetPerdido

Material de apoio para atualizar o texto do Trabalho de Graduação com o que foi **de fato
implementado** (outubro de 2026). Cada seção pode ser adaptada para o capítulo correspondente
(Desenvolvimento, Arquitetura, Segurança, Testes, Considerações finais).

---

## 1. Arquitetura real

```
┌──────────────────────── App Flutter (Android · Web · iOS) ───────────────────────┐
│ screens/  (telas: StatefulWidget + StreamBuilder, um stream por tela)            │
│     │                                                                            │
│ services/ (classes com métodos static — sem gerenciador de estado)              │
│   AuthService · PostService · StorageService · UserService · LocationService     │
│   AIService · AlertaService · PontosService · ChatService · ContaService         │
│     │                                                                            │
│ core/ + models/ (regras puras e testáveis: Haversine, similaridade, filtro de     │
│   palavrões, conversor da resposta da IA, máscara de CPF, PostModel...)          │
└──────┬──────────────┬─────────────┬──────────────┬──────────────┬────────────────┘
       │              │             │              │              │
  Firebase Auth   Firestore     Storage      Firebase AI      Nominatim /
  (e-mail/senha)  (dados +      (fotos)      Logic → Gemini   geocoding nativo
                  regras)                    (sem chave no    (bairro ↔ coordenada)
                     │                         app)
                     │ onDocumentCreated(posts/{id})
                     ▼
            Cloud Function "alertarProximos" (Node 22, southamerica-east1)
                     │ geohash + distância → destinatários
                     ▼
            Firebase Cloud Messaging (push) + users/{uid}/notifications
```

- **Cliente:** Flutter 3.41 / Dart 3.11, um único código para Android, Web e iOS.
- **Backend sem servidor próprio:** Firebase (Auth, Firestore, Storage, FCM, Functions, Hosting) e
  Gemini API (chamada pela Cloud Function `analisarPet`).
- **Padrão de código:** camadas `screens → services → Firebase`; regras de negócio em funções puras
  (testadas sem Firebase). Sem gerenciador de estado, para manter o código acessível ao time.
- **Consultas sem índice composto:** a lista principal lê os 100 posts mais recentes por `createdAt`
  e aplica os filtros no aparelho; a lista de conversas usa só `array-contains` e ordena no app.

## 2. Modelo de dados (Cloud Firestore)

| Caminho | Campos principais | Observações |
|---|---|---|
| `users/{uid}` | id, name, email, cpf (só os 11 dígitos), birthDate, points, createdAt, alertsEnabled, alertRadiusKm, fcmToken, lastLocation{lat, lng, geohash, updatedAt} | Só o dono lê e escreve (protege CPF, e-mail e localização). |
| `users/{uid}/notifications/{id}` | title, body, postId, type, read, createdAt | Criadas só pela Cloud Function. |
| `users/{uid}/pointsLog/{id}` | reason, delta, postId?, createdAt | Id fixo por ganho (`post_<id>`, `euvi_<id>`) evita pontuar duas vezes. |
| `users/{uid}/redemptions/{id}` | rewardId, title, cost, code, createdAt | Resgates de recompensas (demonstração). |
| `posts/{id}` | userId, userName, type (perdi/achei/avistei), petName, description, species, breed, size, sex, colors[], traits[], tags[], lastSeenAddress (bairro), latitude, longitude (arredondadas), geohash, photoUrl, createdAt, eventAt, isResolved, sightingsCount, helpersCount | Leitura pública; só o autor altera. |
| `posts/{id}/sightings/{uid}` | userId, userName, address (bairro), lat, lng (arredondadas), notes (descrição, mín. 10 caracteres), photoUrl?, createdAt | Id = uid de quem viu → no máximo 1 por pessoa. |
| `chats/{postId_uidA_uidB}` | participants[2], participantNames{uid: nome}, postId, postTitle, lastMessage, lastMessageAt, unread{uid: n} | Id determinístico (uids em ordem alfabética). |
| `chats/{id}/messages/{id}` | senderId, text, photoUrl?, createdAt, expireAt | `expireAt` = envio + 15 dias. A política TTL do Firestore (definida em código, `firestore.indexes.json`) apaga a mensagem depois dessa data. |

**Storage:** `posts/{postId}/foto.jpg`, `posts/{postId}/avistamento_{uid}.jpg` e
`chats/{chatId}/{mensagemId}.jpg` (imagens de até 5 MB).

## 3. Regras de segurança (resumo)

- **Posts:** leitura pública; criação só com `userId` igual ao usuário logado; edição e exclusão só
  pelo autor, que não pode trocar o dono. Outros usuários só somam **exatamente +1** em
  `sightingsCount`/`helpersCount`, e **somente no mesmo lote (batch)** em que criam o próprio
  avistamento (`existsAfter`).
- **Avistamentos:** leitura pública; criação só no id do próprio usuário e nunca vazia (bairro e
  descrição com pelo menos 10 caracteres, a mesma regra da tela); remoção por quem registrou ou pelo
  autor do post.
- **Users e subcoleções:** só o dono. Notificações: o dono só pode alterar o campo `read`; ninguém as
  cria pelo app. Pontos e resgates: criar e apagar, nunca editar.
- **Chats:** só os 2 participantes leem e escrevem; a criação confere o formato do id
  (`postId_uidA_uidB`), que são duas pessoas diferentes, que o post existe e que o **autor do post**
  é um dos participantes — e quem abre a conversa é quem quer ajudar, nunca o autor (assim ninguém
  inicia conversa com um estranho). Depois só mudam a última mensagem e as não lidas. Cada mensagem
  é criada em nome do próprio remetente e precisa ter `expireAt` (data de expiração do TTL).
- **Storage:** fotos de posts com leitura pública e envio só por usuário logado (imagem ≤ 5 MB); fotos
  do chat só para participantes (o uid precisa estar no id da conversa); o resto do bucket é bloqueado.
- Todas as regras foram **publicadas e validadas por API REST** com usuários de teste (ver seção 8).

## 4. Fluxo do alerta por proximidade (geofencing + FCM)

1. **Consentimento (LGPD):** na primeira vez, o app explica em linguagem simples o que é guardado
   (localização aproximada e código do aparelho) e pede autorização. Só então pede as permissões
   de localização e de notificação.
2. **Atualização da localização:** ao abrir o app e ao voltar do segundo plano (no máximo a cada
   15 min) — **sem rastreamento contínuo**. A posição é arredondada para 3 casas decimais
   (~100 m) e gravada em `users/{uid}.lastLocation` com o **geohash**, junto com o `fcmToken`.
3. **Novo post:** o gatilho `onDocumentCreated(posts/{id})` da Cloud Function calcula as faixas de
   geohash que cobrem um círculo de **10 km** (maior raio possível) com `geohashQueryBounds` e
   consulta `users` por `lastLocation.geohash` (índice simples). A consulta lê **só** os campos dos
   alertas (`select`: token, localização, preferências) — nunca CPF, e-mail ou nome.
4. **Filtro exato:** para cada candidato, calcula a distância (Haversine) e mantém só quem está
   dentro do **próprio raio** (1, 3, 5 ou 10 km), excluindo o autor e quem desligou os alertas.
5. **Envio:** grava `users/{uid}/notifications` (sino do app, com a foto) e envia um push por pessoa
   com `sendEach` (lotes de 500), já com a distância de cada um. Tokens inválidos são apagados.
6. **No aparelho:** com o app fechado, a notificação aparece na barra (canal `alertas_pets`, prioridade
   alta) com a **foto do pet**, e o toque abre o post; com o app aberto, aparece um banner interno.
   No navegador (Chrome/Edge/Firefox), o service worker `firebase-messaging-sw.js` mostra a
   notificação com a foto e o toque abre o site já no post (`?post=<id>`).

**Notificação rica** — para a pessoa saber se pode ajudar sem abrir o app (só dados públicos do post):
- título: tipo, nome (se for "Perdi") e espécie com cor — "🚨 PERDIDO: Pipoca · cão caramelo";
- 1ª linha: bairro, quando (horário de Brasília, "hoje/ontem") e distância — "📍 Vila Barth ·
  sumiu hoje às 09:00 · a 1,2 km de você";
- 2ª linha: porte, raça e até 3 características; 3ª linha: começo da descrição (até 100 caracteres);
- imagem: a foto do post.

**Modo de teste** (`functions/.env`, `ALERTAS_PARA_TODOS=true`): todo post novo avisa **todos** os
usuários, inclusive o autor, sem olhar a distância — usado para testar a notificação. Em produção,
`false` volta ao geofencing.

## 5. Fluxo da IA (extração de metadados com Gemini)

1. Na etapa Foto do cadastro do post, o usuário toca em **"Preencher com IA"** (ou, em "Avistei" sem
   foto, em "Preencher a partir da descrição").
2. A foto é **reduzida para no máximo 1024 px** (JPEG) no aparelho.
3. O app chama a **Cloud Function `analisarPet`** (HTTPS) com o token do usuário logado e as listas de
   valores permitidos. A Function confere o login e o tamanho da foto e chama a **Gemini API** (modelos
   Flash, no nível gratuito de um projeto separado e sem faturamento). A chave do Gemini fica num
   **segredo do Firebase** (Secret Manager), **nunca no app**. Se um modelo atingir o limite gratuito
   (429), a Function tenta o próximo da lista.
4. A resposta é **JSON estruturado** (`responseSchema`) com valores restritos às listas do app:
   espécie (Cão/Gato/Indefinido), porte, até 2 cores, raça curta e características.
5. O prompt manda **ignorar pessoas** e responder "Indefinido" se não houver cão ou gato.
6. Um conversor puro (`SugestaoIA.converter`) valida a resposta e descarta qualquer valor fora das listas.
7. Os valores entram como **sugestões editáveis** com o selo "Sugerido pela IA". Falhas (sem internet,
   cota esgotada, API desativada, resposta inválida, "não é um pet") geram mensagens claras.

**Por que a IA:** descrições manuais são subjetivas ("marrom", "caramelo", "doce de leite"); a IA
padroniza os atributos e melhora a busca, os filtros e o aviso de posts semelhantes.

## 6. Decisões de privacidade

- **Coordenadas arredondadas** para 3 casas decimais (~100 m) antes de gravar: posts, avistamentos e
  a última localização dos alertas.
- **Endereço público = só "Bairro, Cidade"** (nunca rua com número); o mapa usa a área aproximada.
- **CPF** validado pelos dígitos verificadores, guardado só em `users/{uid}` (acesso do dono) e
  exibido mascarado (`***.456.789-**`).
- **Chat** mostra apenas o nome do outro usuário; orienta encontro em local público; mensagens
  expiram em 15 dias.
- **Alertas** só com consentimento; desligar apaga a localização e o token guardados.
- **Exclusão de conta** apaga posts, fotos, avistamentos, mensagens, pontos, resgates, o cadastro e o
  usuário do Auth (exige a senha de novo).
- Termos de Uso e Política de Privacidade dentro do app (e no cadastro).

## 7. Limitações conhecidas

- **Idade mínima** verificada só no app (as regras do banco não conferem a data de nascimento).
- **Pontos gravados pelo cliente:** o próprio usuário consegue escrever no seu documento; num produto
  real a pontuação iria para uma Cloud Function.
- **Push validado só no Android.** No iOS o FCM exige chave APNs (conta Apple Developer); na Web,
  chave VAPID e service worker.
- **Localização dos alertas é a última conhecida** (atualizada ao abrir o app), não em tempo real.
- **Nominatim** (OpenStreetMap) tem política de no máximo 1 requisição por segundo; o app respeita, mas
  em escala seria preciso um serviço próprio ou pago de geocodificação.
- **Exclusão de fotos no Storage é permissiva** para usuários logados em `posts/` (a regra do Storage
  não conhece o dono do post sem regra cruzada com o Firestore).
- **Recompensas** e parceiros são exemplos (expansão futura).
- Consulta limitada aos **100 posts mais recentes** (adequado ao piloto em uma cidade).

## 8. Roteiro de testes executados

**Testes automatizados (Flutter, `flutter test`): 131 testes**, entre eles:
CPF (dígitos verificadores, repetidos, máscara) · idade (inclusive 29/02) · PostModel (Timestamp,
geohash, posts antigos) · arredondamento de coordenadas · leitura das respostas do Nominatim ·
Haversine · filtros e busca sem acento · similaridade de posts · formatação de tempo e distância ·
conversor da resposta da IA e redução da foto · pontuação, código de voucher e níveis · filtro de
palavrões e chat · telas (criar post etapas 1–3, card do post, telas legais).

**Testes da Cloud Function (`npm test`): 9 testes** — distância, raio por usuário, escolha de
destinatários (perto/longe, autor, alertas desligados, sem localização, sem token) e texto da mensagem.

**Validação das regras por API REST, com usuários de teste (e-mail e CPF fictícios), apagando tudo
no fim e confirmando a exclusão:**

| Módulo | Verificações | O que foi provado |
|---|---|---|
| 1 — Regras base | 22 | Criar post com foto; bloqueio de editar/apagar post alheio, de post em nome de outro, de upload fora de `posts/` e de arquivo que não é imagem. |
| 2 — Cadastro | 12 | `users/{uid}` com `birthDate` (Timestamp) e pontos iniciais; documento protegido sem login. |
| 6 — Avistamentos | 28 | "Eu vi" com +1 nos contadores; bloqueio de 2º registro, de contador sem avistamento, de +2 e de avistamento em nome de outro. |
| Geofencing | 13 | Localização/token só pelo dono; notificações não podem ser criadas pelo app. |
| 7 — Pontos | 18 | Ganho em transação, ganho duplicado recusado, lançamentos não editáveis, resgate com débito. |
| 8 — Chat | 35 | Id determinístico, sem conversa consigo mesmo, terceiro bloqueado no Firestore e no Storage. |
| 9 — Excluir conta | 33 | A sequência completa de exclusão passa pelas regras e não deixa dados. |
| Fechamento | 11 | Autor não troca o dono do post; resolvido e "Eu vi" seguem funcionando. |
| Chat × autor | 21 | Conversa só com o autor de um post existente; estranho e post inexistente bloqueados; mensagem sem `expireAt` bloqueada. |
| Avistamento não vazio (emulador local do Firestore) | 14 | Descrição vazia, só espaços, curta ou ausente e bairro vazio são negados (o batch inteiro, com os contadores); avistamento completo segue funcionando. |
| Alertas (ponta a ponta, Function publicada) | 22 | Autor publica post; usuário a ~0,6 km (raio 3 km) recebe o alerta "Pet perdido perto de você — Cão caramelo · Vila Barth, Itapetininga"; usuário a ~12 km e o autor não recebem; token inválido é removido. |

**Validação manual (roteiro no PROGRESSO.md):** fluxo completo no Chrome e no celular Android
(cadastro, criar post com IA, mapa, feed, detalhe, chat, alertas push, pontos, configurações).
