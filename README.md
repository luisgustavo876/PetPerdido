# PetPerdido

Aplicativo mobile para busca e localização de animais de estimação perdidos —
projeto de TCC de Engenharia de Software (Flutter + Firebase).

Usuários publicam que **perderam**, **acharam** ou **avistaram** um pet; os posts
aparecem em um **mapa** e em um **feed**, e outros usuários podem registrar
avistamentos e conversar com o autor.

## Stack

- Flutter (Dart) — Android, iOS e Web (Chrome)
- Firebase Auth, Cloud Firestore e Firebase Storage
- Google Maps (`google_maps_flutter`)

> O app não roda em Windows/macOS desktop: o Firebase não está configurado
> para essas plataformas.

## Como rodar

```bash
flutter pub get
flutter run            # celular/emulador conectado
flutter run -d chrome  # navegador
```

## Estrutura

```
lib/
├── core/       → tema, cores, constantes, rotas, estilos por tipo de post
├── models/     → PostModel (+ enum PostType)
├── services/   → AuthService, PostService, StorageService (Firebase)
├── widgets/    → CustomButton, CustomTextField, PetPostCard, PetImage
├── screens/
│   ├── auth/     → Login, Cadastro
│   ├── map/      → Mapa com marcadores
│   ├── feed/     → Feed e Detalhe do post
│   ├── post/     → Criar postagem
│   ├── chat/     → Lista de conversas e Chat
│   └── profile/  → Pontos e Configurações
└── main.dart   → inicializa o Firebase e escolhe Login ou tela principal
```

## Testes

```bash
flutter analyze
flutter test
```
