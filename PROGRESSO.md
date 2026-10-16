# PetPerdido — Progresso da finalização (TCC)

> Arquivo de acompanhamento. Atualizado ao fim de cada módulo.
> Para continuar numa sessão nova: "leia o PROGRESSO.md e continue".

Branch: `refactor/modulo-0-limpeza` (sem push, sem merge). Prazo: 28/10/2026.

## Estado atual

| Fase | Módulo | Situação |
|---|---|---|
| — | 0 Limpeza · 1 Regras · 2 Login/Cadastro · 3 Criar Post | ✅ Feito |
| 1 | 4 Mapa | ✅ Feito |
| 1 | 5 Feed | ✅ Feito |
| 1 | 6 Detalhe | ✅ Feito |
| 2 | IA (Gemini) | ✅ Feito (falta você ativar o AI Logic no console) |
| 3 | Geofencing + Push | ⏳ Em andamento |
| 4 | 7 Pontos e recompensas | Pendente |
| 5 | 8 Chat | Pendente |
| 6 | 9 Configurações, perfil e LGPD | Pendente |
| 7 | Fechamento | Pendente |

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

## Passos manuais pendentes (dependem de você)

### Ativar o Firebase AI Logic (necessário para "Preencher com IA")
Hoje a API responde 403 "Firebase AI Logic API has not been used ... or it is disabled".
1. Abra https://console.firebase.google.com/project/petperdido-ff844 e entre com a conta do projeto.
2. No menu da esquerda, abra **AI Logic** (fica em "Criar" / "Build", às vezes listado como
   "Gemini" ou "AI").
3. Clique em **Começar** ("Get started").
4. Escolha **Gemini Developer API** (não a "Vertex AI Gemini API") e confirme em **Ativar API**
   ("Enable API"). O console cria e gerencia a chave sozinho — não coloque chave nenhuma no app.
5. Se aparecer a sugestão de ativar o App Check, pode pular por enquanto (recomendado só em produção).
6. Espere uns 5 minutos e teste: Criar postagem → escolha uma foto de cão ou gato → **Preencher com IA**.
   A etapa "Sobre o pet" deve vir com o selo "Sugerido pela IA" nos campos.

- Apagar no console do Firebase os posts antigos de teste (com `createdAt` em texto).
- `git rm -r windows/` (a pasta não é usada; o Firebase não suporta Windows desktop).

## Como testar

- `flutter analyze` · `flutter test` · `flutter build apk --debug`
- Web: `flutter run -d web-server --web-port 8080` e abrir http://localhost:8080 no Chrome.
