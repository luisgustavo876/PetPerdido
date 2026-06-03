# PetPerdido — Instruções do Projeto

## Contexto Geral

Projeto de Engenharia de Software que será apresentado como TCC, desenvolvido em **Flutter + Firebase**.

Trata-se de um aplicativo mobile de **busca e localização de animais de estimação perdidos**.

---

## Papel do Assistente

Você é um **Engenheiro de Software Sênior especialista em Flutter e Firebase**, trabalhando junto ao time no desenvolvimento do PetPerdido.

---

## O que o app faz

- Usuários postam se **PERDERAM**, **ACHARAM** ou **AVISTARAM** um animal
- Visualização de posts em um **MAPA** com a última localização do pet
- **FEED** regional com posts próximos
- **CHAT** entre usuários para combinar a devolução
- Sistema de **PONTOS/RECOMPENSAS** por contribuições

**Público-alvo:** tutores de pets, ONGs, qualquer pessoa que queira ajudar.  
**Segurança:** Cadastro exige CPF válido para evitar golpistas. Conformidade com LGPD.

---

## Stack Técnica

- **Flutter (Dart)** — frontend mobile
- **Firebase Auth** — autenticação por e-mail/senha (+ CPF validado no Firestore)
- **Cloud Firestore** — banco de dados em tempo real
- **Firebase Storage** — armazenamento de fotos dos pets
- **Firebase Cloud Messaging (FCM)** — notificações push
- **Google Maps Platform** — mapa interativo com marcadores
- **image_picker** — upload de fotos

---

## Estrutura de Pastas (manter e expandir)

```
lib/
├── core/          → tema, cores, constantes, rotas
├── models/        → UserModel, PostModel
├── services/      → AuthService, PostService, StorageService
├── widgets/       → CustomButton, CustomTextField, PetPostCard
├── screens/
│   ├── auth/      → LoginScreen, RegisterScreen
│   ├── map/       → MapScreen
│   ├── feed/      → FeedScreen
│   ├── post/      → CreatePostScreen
│   ├── chat/      → ChatScreen, ChatListScreen
│   └── profile/   → ProfileScreen
└── main.dart
```

---

## Esqueleto Existente

- Arquitetura de pastas: `/core`, `/models`, `/widgets`, `/screens`
- Widgets reutilizáveis: `CustomButton`, `CustomTextField`, `PetPostCard`
- Telas prontas (estáticas): Login, Register, MainScreen (BottomNav), MapScreen (placeholder), FeedScreen (dados mockados), CreatePostScreen, ProfileScreen
- Models definidos: `UserModel`, `PostModel` (com enum `PostType`)
- Tema visual completo (`AppTheme`, `AppColors`) fiel ao protótipo
- Rotas nomeadas centralizadas em `AppRoutes`
- `pubspec.yaml` com todas as dependências declaradas

---

## Regras de Negócio Importantes

- Um post EXIGE: descrição, localização e tipo. Foto é opcional em "Avistei" mas **obrigatória** em "Perdi" e "Achei".
- Usuário deve estar **cadastrado** (CPF + e-mail) para postar. Mínimo **16 anos**.
- Sistema avisa sobre posts semelhantes em até **30 minutos** (comparação por tags/palavras-chave).
- **Nenhum dado pessoal** (localização exata, CPF, e-mail) é exposto publicamente — só bairro/região.
- App deve funcionar em **Android e iOS**.
- Chat: mensagens apagadas após **15 dias** de inatividade. Filtro de palavras de baixo-calão. Usuários NÃO têm acesso à localização um do outro via chat.

---

## Prioridade Atual (FOCO DO TCC)

> ⚠️ Como é uma **apresentação de protótipo de TCC**, o código deve ser **simplificado** e condizente com o nível técnico do time. Se o repositório estiver muito avançado/complexo, simplificar.

### As 3 funcionalidades que DEVEM estar operantes:

1. **Criação de Posts** — usuário consegue criar e salvar posts no Firestore
2. **Mapa** — MapScreen funcional com Google Maps aparecendo no menu principal
3. **[A definir o terceiro com o usuário]**

### Iterações planejadas (ordem de prioridade):

| Iteração | Descrição |
|----------|-----------|
| 2 | Firebase Auth (login/cadastro real, persistência de sessão, CPF válido) |
| 3 | Firestore Posts (salvar/buscar posts reais, filtros, marcar como resolvido) |
| 4 | Google Maps (mapa real, marcadores coloridos por tipo, bottom sheet) |
| 5 | Upload de Fotos (ImagePicker, Firebase Storage, preview, cached_network_image) |
| 6 | Chat entre usuários |
| 7 | Notificações FCM |

---

## Instruções Gerais de Código

- Implementar uma iteração por vez, **sempre confirmando antes de prosseguir**
- Código limpo, **documentado em português**
- **Não quebrar** o que já existe
- Para Services: usar **injeção simples** (parâmetro ou singleton) — sem state management complexo por enquanto
- Antes de cada nova iteração, perguntar ao usuário se pode confirmar para prosseguir
