# Decisões de projeto

## O problema

Em mapas Roblox, pequenos detalhes podem ficar escondidos no Explorer: uma peça física que deveria estar ancorada, uma colisão invisível que bloqueia uma passagem ou um efeito com emissão muito alta. O desenvolvedor normalmente percebe isso enquanto testa o jogo, ou quando outra pessoa encontra o problema.

Sceneprint tenta encurtar esse caminho. Ele faz uma leitura rápida de propriedades que podem merecer atenção e mantém cada observação ligada ao objeto original.

## Por que não corrigir automaticamente?

A mesma configuração pode ser certa em um jogo e errada em outro. Uma parede invisível pode ser necessária. Um objeto sem ancoragem pode ser uma porta física. Um ParticleEmitter intenso pode fazer parte de uma habilidade que quase nunca é usada.

Alterar essas propriedades sem conhecer a intenção do jogo seria mais perigoso do que útil. Por isso, Sceneprint só observa e seleciona.

## Por que não dar uma nota ao mapa?

Uma pontuação única esconderia contexto. Dez alertas pequenos não significam necessariamente que uma cena é pior do que outra com um único problema importante. O painel mostra verificações separadas e explica cada uma.

## Escopo de leitura

- **Workspace:** foco no conteúdo do mapa.
- **Place inteiro:** percorre os descendentes do DataModel para incluir estruturas fora do Workspace.

O escopo completo pode demorar mais em experiências grandes. A leitura pode ser cancelada.

## Interface

O painel usa uma hierarquia curta: identidade, ação principal, resumo, filtros e resultados. A cor roxa identifica a ação e a identidade do produto; âmbar marca itens para revisão e cinza-azulado marca notas.

Cada resultado mantém o código da regra visível. Isso permite procurar a mesma regra na documentação sem depender da cor.

## Limites técnicos

Sceneprint é uma primeira versão focada em leitura de propriedades. Não lê o código de scripts, não calcula FPS e não substitui o MicroProfiler, os testes de dispositivo ou a revisão manual. A análise também não observa mudanças futuras feitas por scripts durante o jogo.

## Próximos passos possíveis

- Exportar relatório Markdown para compartilhar uma revisão.
- Permitir regras personalizadas por experiência.
- Adicionar exclusões persistentes para objetos intencionais.
- Comparar duas leituras e destacar mudanças.
- Criar testes automatizados para cada regra.

Esses itens são ideias futuras, não recursos presentes na versão 0.1.0.
