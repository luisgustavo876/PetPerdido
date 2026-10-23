# PetPerdido

Aplicativo para mapear e ajudar a resgatar animais de estimação perdidos — projeto de TCC
de Engenharia de Software, com recorte piloto em **Itapetininga-SP** (Flutter + Firebase).

Quem perdeu, quem achou e quem só viu um animal publica um post (**Perdi**, **Achei** ou
**Avistei**), que vira um marcador no mapa. Quem está perto recebe um **alerta por
proximidade** (inspirado no Amber Alert), e a **IA (Gemini)** padroniza espécie, porte e cor
a partir da foto.

## Funcionalidades

- **Cadastro e login** com CPF validado (dígitos verificadores, máscara 000.000.000-00) e data
  de nascimento digitada (DD/MM/AAAA) com idade mínima de 16 anos. O usuário aparece sempre
  pelo nome, nunca pelo e-mail.
- **Criar post em 5 etapas:** tipo, foto (obrigatória em Perdi/Achei), dados do pet (22
  características prontas e até 5 próprias), local no
  mapa (bairro preenchido sozinho) e data; revisão com **possíveis correspondências** (posts
  semelhantes de tipo oposto, até 3 km e 7 dias).
- **IA:** "Preencher com IA" a partir da foto (ou da descrição, em Avistei sem foto) — sugestões
  editáveis de espécie, porte, cores, raça e características.
- **Mapa** com marcadores por tipo, filtros (tipo, espécie, período, resolvidos), satélite e
  "Minha localização".
- **Feed** com busca, filtros (tipo, espécie, porte, cor), ordem por data ou
  distância, e "há 2 h · a 1,2 km" em cada card. Fotos inteiras, sem recorte.
- **Detalhe:** foto com zoom em tela cheia, "Eu vi este pet" (avistamentos com bairro e
  descrição, na linha do tempo), compartilhar, "Entrar em contato", e para o autor: marcar como
  resolvido e excluir.
- **Alertas por proximidade:** Cloud Function + FCM avisa quem está dentro do raio escolhido
  (1, 3, 5 ou 10 km). Sino com as notificações no app.
- **Chat** em tempo real com texto e foto, filtro de palavrões e mensagens que somem em 15 dias.
- **Pontos e recompensas** (demonstração): Achei +30, Avistei +10, "Eu vi" +15; resgate com
  código de voucher.
- **Configurações e LGPD:** perfil (nome, CPF mascarado e pontos), preferências de alerta,
  meus posts, Termos de Uso, Política de Privacidade e "Excluir minha conta".

## Stack

- **Flutter 3.41 / Dart 3.11** — Android (alvo principal), Web (Chrome) e iOS (sem push)
- **Firebase:** Authentication, Cloud Firestore, Storage, Cloud Messaging, Cloud Functions
  (Node 22, região `southamerica-east1`) e **AI Logic** (Gemini `gemini-3.5-flash`)
- **Mapas e localização:** Google Maps (`google_maps_flutter`), `geolocator`, `geocoding` e
  Nominatim/OpenStreetMap (fallback, inclusive na Web), geohash (`dart_geohash` / `geofire-common`)
- Sem gerenciador de estado: services com métodos `static`, `StatefulWidget` + `StreamBuilder`

## Como rodar

```bash
flutter pub get
flutter run                 # celular Android conectado (ou emulador)
flutter run -d chrome       # navegador (janela separada)

# No seu próprio Chrome:
flutter run -d web-server --web-port 8080
# e abra http://localhost:8080
```

### Versão Web publicada (Firebase Hosting)

O app está em **https://petperdido-ff844.web.app** (abre no navegador do celular; push só no app
Android). Para publicar de novo:

```bash
flutter build web --release
firebase deploy --only hosting
```

Build de teste do Android: `flutter build apk --debug`
(arquivo em `build/app/outputs/flutter-apk/app-debug.apk`).

### Cloud Functions

```bash
cd functions
npm install
npm test                                  # lógica pura dos alertas
firebase deploy --only functions          # publicar
```

### Regras de segurança e índices (inclui a política TTL do chat)

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Estrutura

```
lib/
├── core/       → tema, cores, constantes, rotas, geo (Haversine), formatação,
│                 similaridade, filtro de palavrões, opções do pet, recompensas
├── models/     → PostModel, SightingModel, ChatModel, NotificacaoModel, SugestaoIA, PostFilter
├── services/   → Auth, Post, Storage, User, Location, AI, Alerta, Pontos, Chat, Conta
├── widgets/    → PetPostCard, PetImage, FotoTelaCheia, FiltrosSheet, SeletorImagem, botões
│                 e campos
├── screens/
│   ├── auth/     → Login, Cadastro
│   ├── map/      → Mapa
│   ├── feed/     → Feed, Detalhe e "Eu vi"
│   ├── post/     → Criar postagem (5 etapas) e PostDraft
│   ├── chat/     → Conversas e Chat
│   ├── alerts/   → Alertas (notificações)
│   ├── profile/  → Pontos, histórico, resgates, Configurações, Meus posts
│   └── legal/    → Termos de Uso e Política de Privacidade
└── main.dart   → inicializa o Firebase e escolhe Login ou tela principal
functions/      → Cloud Function dos alertas (index.js) + lógica pura (alertas.js) e testes
firestore.rules / storage.rules → regras de segurança
firestore.indexes.json → configuração de campos (TTL de messages.expireAt)
docs/SUBSIDIOS_TG.md → material técnico para o texto do TG
PROGRESSO.md    → andamento, decisões e passos manuais
```

## Testes

```bash
flutter analyze
flutter test
cd functions && npm test
```

## Limitações conhecidas

- A idade mínima é verificada só no app (as regras do banco não conferem a data de nascimento).
- Os pontos são gravados pelo próprio app; num produto real iriam para uma Cloud Function.
- Push validado só no Android. No iOS exige chave APNs; na Web, chave VAPID e service worker.
- Os alertas usam a última localização conhecida (atualizada ao abrir o app), não rastreamento contínuo.
- O Nominatim (OpenStreetMap) tem limite de uso (1 requisição/s); o app respeita esse limite.
- No Storage, qualquer usuário logado pode apagar fotos em `posts/` (a regra não conhece o dono do post).
- Recompensas e parceiros são exemplos (expansão futura).
- O app não roda em Windows/macOS desktop (o Firebase não está configurado para essas plataformas).
