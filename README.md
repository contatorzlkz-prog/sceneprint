<div align="center">
  <img src="assets/posecode-mark.svg" width="42" alt="POSECODE" />
  <h1>POSECODE</h1>
  <p>Importador e conversor de animações para Roblox Studio.</p>
  <p><sub>ruancr · v2.0 · EM DESENVOLVIMENTO</sub></p>
</div>

![Interface do POSECODE v2.0](assets/posecode-preview.svg)

## Sobre

O POSECODE transforma documentos POSECODE V2 ou V1 em clips editáveis no Roblox Studio. O V2 é o formato principal, organizado por tracks; o V1 continua disponível para projetos existentes.

A entrada é validada como JSON estruturado. O conteúdo colado nunca é executado.

## Destaques da v2.0

- **POSECODE V2 nativo:** tracks tipadas, timeline comum, metadados e eventos.
- **Migração V1 → V2:** converte documentos antigos e devolve o JSON V2 na caixa de entrada para revisão antes da importação.
- **Otimização conservadora:** remove apenas keyframes intermediários em sequências de três ou mais transformações consecutivas idênticas, mantendo o primeiro e o último.
- **Diagnóstico de rig:** discrimina contagens de Motor6D, AnimationConstraint e Bone, além da rota de saída.
- **JSON Schema:** especificação formal para validar documentos V2 em ferramentas externas.
- **Interface por etapas:** Importar, Prévia e Rig, com os controles separados.

## Formatos

- **POSECODE V2:** formato recomendado. Estrutura com \`metadata\`, \`rig\`, \`timeline\`, \`tracks\` e \`events\`.
- **POSECODE V1:** formato legado, aceito para compatibilidade e com migração assistida.

Documentação: [guia V2](docs/FORMATO_V2.md) · [JSON Schema](schemas/posecode-v2.schema.json) · [referência V1](docs/FORMATO.md).

## Compatibilidade

- **Motor6D:** gera \`KeyframeSequence\`.
- **Bone:** gera \`CurveAnimation\`, incluindo esqueletos de malhas skinned.
- **Motor6D + Bone:** usa a hierarquia de curvas para manter os dois tipos no mesmo clip.
- **AnimationConstraint:** possui uma rota \`CurveAnimation\` experimental; confira o resultado no Studio.
- **CUSTOM:** permite descrever rigs sem \`Humanoid\`.

## Como usar

1. Selecione o Model do rig no Studio.
2. Abra **Rig** e use **Analisar estrutura do rig**.
3. Abra **Importar** e cole um documento POSECODE V2.
4. Use **Importar clip** para validar e converter.
5. O painel abre **Prévia** após uma importação bem-sucedida.
6. Revise a timeline, teste a animação e salve o clip no Studio.
7. Publique pelo Editor de Animação.

Para projetos V1, cole o documento antigo e use **Converter V1 para V2**. O texto convertido aparece na caixa para que você confira e importe quando estiver pronto.

## Instalação

1. Habilite **Plugin Debugging Enabled** nas configurações do Roblox Studio.
2. Crie um Script em \`ServerStorage\` e cole o conteúdo de [Posecode.plugin.lua](src/Posecode.plugin.lua).
3. Com o Script selecionado no Explorer, use **Plugins → Save as Local Plugin**.
4. Depois de salvar, remova o Script original de \`ServerStorage\` e use a cópia do plugin em \`PluginDebugService\`.

Veja a documentação oficial de [Studio plugins](https://create.roblox.com/docs/studio/plugins).

## Limites

- Entrada máxima de 256 KB.
- Até 256 tracks/alvos e 120 instantes de keyframe normalizados.
- Duração máxima de 15 segundos, FPS de 1 a 60.
- Até 128 eventos e 8 por quadro; eventos disponíveis apenas em \`KeyframeSequence\`.
- Posição local de até 5 studs por componente e rotação de até 720 graus por componente.
- Orçamento de saída: 18.000 poses ou 24.000 chaves de curva.
- O nome de cada alvo usado nas tracks precisa ser único dentro do rig.
- Movimento global da raiz e edição independente de tracks ainda não fazem parte do plugin.
- A prévia usa um ID temporário válido apenas no Studio. A publicação continua pelo Editor de Animação.

## Arquivos

- [Código do plugin](src/Posecode.plugin.lua)
- [Formato POSECODE V2](docs/FORMATO_V2.md)
- [JSON Schema V2](schemas/posecode-v2.schema.json)
- [Formato POSECODE V1 (legado)](docs/FORMATO.md)
- [Limites técnicos](docs/LIMITES.md)
- [Histórico de versões](CHANGELOG.md)
