<div align="center">
  <img src="assets/posecode-mark.svg" width="42" alt="POSECODE" />
  <h1>POSECODE</h1>
  <p>Importador de animações estruturadas para Roblox Studio.</p>
  <p><sub>ruancr · v1.5 · EM DESENVOLVIMENTO</sub></p>
</div>

![Interface do POSECODE v1.5](assets/posecode-preview.svg)

## Sobre

O POSECODE transforma dados de animação no formato POSECODE v1 em clips editáveis no Roblox Studio. Ele valida os quadros, verifica as juntas do rig e permite conferir o movimento antes de salvar.

O conteúdo colado nunca é executado. O plugin aceita somente JSON estruturado, inclusive quando está dentro de uma variável `POSECODE`.

## Como usar

1. Selecione um rig R6 ou R15 no Studio.
2. Gere os dados no [formato POSECODE v1](docs/FORMATO.md).
3. Cole o conteúdo e selecione **Importar clip**.
4. Confira a animação na prévia e use a timeline para navegar.
5. Salve o clip no Studio e publique pelo Editor de Animação.

## Instalação

1. Habilite **Plugin Debugging Enabled** nas configurações do Roblox Studio.
2. Crie um Script em `ServerStorage` e cole o conteúdo de [Posecode.plugin.lua](src/Posecode.plugin.lua).
3. Com o Script selecionado no Explorer, use **Plugins → Save as Local Plugin**.
4. Depois de salvar, remova o Script original de `ServerStorage` e use a cópia do plugin em `PluginDebugService`.

Veja a documentação oficial de [Studio plugins](https://create.roblox.com/docs/studio/plugins).

## v1.5

Revisão técnica e de experiência de uso: interface mais clássica, controles contextuais, validação mais rigorosa dos rigs e atualização mais leve da timeline durante a prévia. O formato de dados continua POSECODE v1.

## Saída por tipo de rig

- **Motor6D:** gera uma `KeyframeSequence`.
- **AnimationConstraint:** tenta gerar uma `CurveAnimation`. Essa rota permanece experimental e a compatibilidade precisa ser conferida no Studio.

## Limites

- Não interpreta scripts Luau arbitrários, TweenService ou lógica condicionada.
- Entrada máxima de 256 KB, até 120 quadros normalizados, duração máxima de 15 segundos e 256 juntas.
- Movimento global da raiz, markers/eventos e edição individual de tracks ainda não fazem parte do plugin.
- A prévia usa um ID temporário válido apenas no Studio. A publicação continua pelo Editor de Animação.

## Documentação

- [Formato POSECODE v1](docs/FORMATO.md)
- [Limites técnicos e publicação](docs/LIMITES.md)
- [Código do plugin](src/Posecode.plugin.lua)
- [Histórico de versões](CHANGELOG.md)
