<div align="center">
  <img src="assets/posecode-mark.svg" width="42" alt="POSECODE" />
  <h1>POSECODE</h1>
  <p>Importador de animações estruturadas para Roblox Studio.</p>
  <p><sub>ruancr · v1.6 · EM DESENVOLVIMENTO</sub></p>
</div>

![Interface do POSECODE v1.6](assets/posecode-preview.svg)

## Sobre

O POSECODE transforma dados no formato POSECODE v1 em clips editáveis no Roblox Studio. O importador valida os quadros e as juntas do rig, organiza a timeline e permite conferir o movimento antes de salvar.

O conteúdo colado nunca é executado: o plugin aceita apenas JSON estruturado, inclusive dentro de uma variável `POSECODE`.

## Como usar

1. Selecione um rig R6 ou R15 no Studio.
2. Gere os dados no [formato POSECODE v1](docs/FORMATO.md).
3. Cole o conteúdo e selecione **Importar clip**.
4. Confira a prévia, navegue pela timeline e use os eventos quando existirem.
5. Salve o clip no Studio e publique pelo Editor de Animação.

## Instalação

1. Habilite **Plugin Debugging Enabled** nas configurações do Roblox Studio.
2. Crie um Script em `ServerStorage` e cole o conteúdo de [Posecode.plugin.lua](src/Posecode.plugin.lua).
3. Com o Script selecionado no Explorer, use **Plugins → Save as Local Plugin**.
4. Depois de salvar, remova o Script original de `ServerStorage` e use a cópia do plugin em `PluginDebugService`.

Veja a documentação oficial de [Studio plugins](https://create.roblox.com/docs/studio/plugins).

## v1.6

Adiciona eventos de animação em clips Motor6D, repetição independente na prévia e uma revisão técnica de limites de processamento, inicialização da prévia e limpeza de conexões. A interface mantém o visual clássico da v1.5.

## Saída por tipo de rig

- **Motor6D:** gera uma `KeyframeSequence`, incluindo event markers opcionais.
- **AnimationConstraint:** tenta gerar uma `CurveAnimation`. Essa rota permanece experimental e não aceita markers.

## Limites

- Não interpreta scripts Luau arbitrários, TweenService ou lógica condicionada.
- Entrada máxima de 256 KB, até 120 quadros normalizados, duração máxima de 15 segundos e 256 juntas.
- Eventos: até 8 por quadro e 128 por animação.
- Orçamento de saída: 18.000 poses ou 24.000 chaves de curva, conforme o formato.
- Movimento global da raiz e edição individual de tracks ainda não fazem parte do plugin.
- A prévia usa um ID temporário válido apenas no Studio. A publicação continua pelo Editor de Animação.

## Documentação

- [Formato POSECODE v1](docs/FORMATO.md)
- [Limites técnicos e publicação](docs/LIMITES.md)
- [Código do plugin](src/Posecode.plugin.lua)
- [Histórico de versões](CHANGELOG.md)
