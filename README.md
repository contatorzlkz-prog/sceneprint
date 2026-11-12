<div align="center">
  <img src="assets/posecode-mark.svg" width="48" alt="Posecode" />
  <h1>POSECODE</h1>
  <p>Do movimento descrito por IA para keyframes editáveis no Roblox Studio.</p>
  <p><sub>ruancr · EM DESENVOLVIMENTO</sub></p>
</div>

![Interface do Posecode](assets/posecode-preview.svg)

## A proposta

Você pede uma animação para uma IA, recebe um script no formato Posecode e cola no plugin. O Posecode lê os dados do movimento, monta uma KeyframeSequence e permite reproduzir no rig selecionado.

A ideia não é tentar interpretar qualquer código Luau. Scripts comuns podem ter loops, condições, cálculos e chamadas de TweenService; não existe uma forma confiável de reconstruir todos os estados pretendidos apenas olhando o texto. Por isso, a IA gera um bloco de dados com tempos e transformações definidos.

## Fluxo

1. Selecione um rig R6 ou R15 no Studio.
2. Peça à IA uma animação no formato Posecode.
3. Cole o script no campo de importação.
4. Gere os keyframes, confira a linha do tempo e reproduza a prévia.
5. Salve a sequência local e publique pelo Editor de Animação do Studio.

## Instalar para testar

1. No Roblox Studio, habilite **Plugin Debugging Enabled** nas configurações do Studio.
2. Crie um Script dentro de ServerStorage e cole o conteúdo de [Posecode.plugin.lua](src/Posecode.plugin.lua).
3. Com o Script selecionado no Explorer, use **Plugins → Save as Local Plugin**.
4. Depois de salvar, remova o Script original de ServerStorage e use a cópia do plugin no PluginDebugService.

A documentação oficial do Roblox explica esse fluxo em [Studio plugins](https://create.roblox.com/docs/studio/plugins).

## O que a primeira versão faz

- Importa o bloco estruturado dentro de um script Luau.
- Valida versão, rig, duração, quantidade de keyframes e nomes das juntas.
- Converte posição e rotação de juntas em objetos Pose.
- Gera uma KeyframeSequence com loop e prioridade.
- Reproduz uma prévia local usando o ID temporário do AnimationClipProvider.
- Salva a sequência local em ServerStorage, com referência AnimSaves no rig.

## Limites atuais

- Não converte automaticamente scripts Luau arbitrários.
- Não executa o texto colado.
- A versão inicial usa rigs com juntas Motor6D e formatos R6/R15.
- Movimento da raiz, eventos, markers, curvas avançadas e edição individual de tracks ainda não fazem parte do protótipo.
- A publicação na nuvem continua pelo fluxo oficial do Editor de Animação do Roblox. O ID temporário da prévia só funciona localmente no Studio.

## Documentação

- [Formato aceito e exemplo](docs/FORMATO.md)
- [Limites e publicação](docs/LIMITES.md)
- [Código do plugin](src/Posecode.plugin.lua)

## Estado

**Protótipo em desenvolvimento.** O código está versionado, mas ainda precisa ser instalado e validado no Roblox Studio.