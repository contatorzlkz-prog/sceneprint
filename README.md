<div align="center">
  <img src="assets/sceneprint-mark.svg" width="54" alt="Símbolo do Sceneprint" />
  <h1>Sceneprint</h1>
  <p>Uma revisão rápida da sua seleção no Roblox Studio.</p>
  <p><sub>Criado por <strong>Ruan Carlos</strong> · <a href="https://github.com/contatorzlkz-prog">ruancr</a></sub></p>
  <img src="assets/sceneprint-scan.svg" width="180" alt="" />
</div>

![Prévia do Sceneprint](assets/sceneprint-preview.svg)

## Por que fiz isso

Quando a gente monta um mapa, algumas coisas parecem normais no Explorer, mas podem atrapalhar durante o jogo. Uma peça quase invisível pode bloquear o caminho. Um conjunto físico pode ficar solto quando deveria permanecer no lugar.

O Sceneprint procura só esses dois casos. Você escolhe um Model ou algumas peças, faz a leitura e clica no resultado para encontrar o objeto no Explorer.

Não tem nota para o mapa, correção automática ou uma lista enorme de métricas. É uma ferramenta pequena para uma revisão específica.

## O que ele confere

**Colisão escondida**  
Uma peça quase invisível que continua com colisão ligada. Nomes como Hitbox, Trigger e Collider são tratados como intencionais e ignorados.

**Peça sem ancoragem**  
Um conjunto físico que pode se mover. O plugin mostra um aviso por conjunto, ignora personagens e nomes que sugerem mecanismos ou objetos móveis.

Essas verificações são pistas, não erros garantidos. Uma colisão invisível ou uma peça solta pode fazer parte do seu jogo.

## Usar no Studio

1. Abra [src/Sceneprint.plugin.lua](src/Sceneprint.plugin.lua) e copie o código.
2. No Studio, ative **Plugin Debugging Enabled** nas configurações.
3. Crie um Script temporário em ServerStorage e cole o código.
4. Com esse Script selecionado, use **Save as Local Plugin** no menu Plugins.
5. Apague o Script temporário e use a versão criada em PluginDebugService.

Depois, selecione um Model ou algumas peças no Explorer e clique em Sceneprint na barra Plugins.

[Instruções oficiais para criar plugins](https://create.roblox.com/docs/studio/plugins)

## Feito por

**Ruan Carlos · ruancr**

Este é meu primeiro projeto publicado como ferramenta para Roblox Studio. Estou desenvolvendo o Sceneprint para aprender mais sobre plugins, Luau e ferramentas que realmente ajudam durante a criação de jogos.

Versão 0.2.0 · Ainda em testes no Studio.
