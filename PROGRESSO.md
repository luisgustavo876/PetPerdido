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
| 1 | 6 Detalhe | ⏳ Em andamento |
| 2 | IA (Gemini) | Pendente |
| 3 | Geofencing + Push | Pendente |
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

## Passos manuais pendentes (dependem de você)

- Apagar no console do Firebase os posts antigos de teste (com `createdAt` em texto).
- `git rm -r windows/` (a pasta não é usada; o Firebase não suporta Windows desktop).

## Como testar

- `flutter analyze` · `flutter test` · `flutter build apk --debug`
- Web: `flutter run -d web-server --web-port 8080` e abrir http://localhost:8080 no Chrome.
