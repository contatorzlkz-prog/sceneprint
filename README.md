<div align="center">
  <img src="assets/posecode-mark.svg" width="42" alt="POSECODE" />
  <h1>POSECODE</h1>
  <p>Gerador procedural e importador de animações para Roblox Studio.</p>
  <p><sub>ruancr · v3.0 · MESH RIG 2016</sub></p>
</div>

![Interface do POSECODE v3.0](assets/posecode-preview.svg)

## Sobre

O POSECODE 3.0 é um gerador procedural de animações para o Mesh Rig 2016. Você descreve o movimento em texto — por exemplo, **"walk cansado"** ou **"run confiante"** — e o motor combina padrões de movimento, ritmo, intensidade, passada, braços, postura, balanço e interpolação para criar um clip.

A animação gerada é convertida internamente para POSECODE V2 e passa pelo mesmo validador, prévia e salvamento do importador. A ferramenta também continua aceitando documentos POSECODE V2 e V1 existentes. Texto de usuário é tratado como descrição: o plugin não executa código colado.

O motor possui 15 movimentos-base e 720.000 combinações paramétricas discretas. Isso não significa 720 mil arquivos pré-gravados: cada clip é calculado no momento da geração. Você pode aprovar uma geração e guardá-la como referência; a biblioteca local persiste entre sessões do Studio e é consultada em gerações futuras com o mesmo tipo de movimento.

## Destaques da v3.0

- **Gerador por descrição:** interpreta pedidos como `walk cansado`, `run confiante`, `sneak lento`, `wave`, `jump`, `salute` e `dance`.
- **Quinze movimentos-base:** walk, run, sprint, sneak, tiptoe, march, limp, idle, wave, salute, jump, bow, point, clap e dance.
- **720.000 combinações paramétricas:** cruza ritmo, intensidade, passada, braços, postura, balanço, direção e interpolação; são receitas sintetizadas, não arquivos pré-gravados.
- **Variações instantâneas:** gera outra versão com uma nova semente sem perder a intenção e o estilo do pedido.
- **Biblioteca local:** guarda referências aprovadas e reutiliza os parâmetros em futuras gerações semelhantes.
- **POSECODE V2 como saída:** cada animação é construída em tracks tipadas e segue pelo pipeline existente de validação e conversão.
- **Importação legada:** mantém suporte a V2 externo e a migração de V1 para V2.
- **Mesh Rig 2016:** valida R15, as 15 MeshParts corporais, HumanoidRootPart e as 15 juntas.
- **Prévia e salvamento:** mantém a timeline e a gravação local de clips no Studio.

## Formatos

- **POSECODE V2:** formato recomendado. Estrutura com \`metadata\`, \`rig\`, \`timeline\`, \`tracks\` e \`events\`.
- **POSECODE V1:** formato legado, aceito para compatibilidade e com migração assistida.

Documentação: [guia do gerador](docs/GERADOR.md) · [guia V2](docs/FORMATO_V2.md) · [JSON Schema](schemas/posecode-v2.schema.json) · [referência V1](docs/FORMATO.md).

## Compatibilidade

O POSECODE 3.0 é direcionado ao **perfil estrutural do Mesh Rig 2016**: Humanoid R15, 15 MeshParts corporais com nomes padronizados, HumanoidRootPart e uma árvore corporal de 15 juntas.

- **15 AnimationConstraint:** gera CurveAnimation, usada pela prévia local.
- **15 Motor6D:** gera KeyframeSequence.
- **Juntas mistas, rig R6, rigs genéricos, rigs de Bone e modelos incompletos:** recusados antes da importação.

A validação reconhece a estrutura do rig; ela não consegue provar qual opção histórica do Rig Builder originou um Model estruturalmente idêntico. A estrutura corporal validada segue a especificação R15 do Roblox.

timeline.rotationSpace pode ser joint (padrão, eixos locais da junta) ou character (eixos alinhados ao HumanoidRootPart). A posição continua sendo expressa localmente.

AnimationConstraint é reconhecido como o tipo de junta usado pelo Avatar Joint Upgrade. A prévia local deve ser conferida no Studio antes de publicar o clip.

POSECODE V1 continua disponível para documentos antigos, mas agora também exige o perfil de rig aceito pelo POSECODE 3.0.

## Como usar

1. Insira e selecione um Mesh Rig 2016 no Studio.
2. Abra **Rig** e use **Analisar estrutura do rig** para conferir as 15 MeshParts e as 15 juntas.
3. Abra **Gerar** e descreva o movimento, por exemplo: `walk cansado`, `run confiante`, `sneak lento` ou `march robotico`.
4. Clique em **Gerar animação**. O plugin monta o documento V2, valida a estrutura e abre a **Prévia** automaticamente.
5. Confira o clip no rig. Use **Outra variação** para trocar a semente e criar uma versão próxima, mas não idêntica.
6. Depois de aprovar, volte à aba **Gerar** e clique em **Guardar referência**. As receitas aprovadas podem orientar novas gerações parecidas.
7. Salve o clip em **Prévia** e publique pelo Editor de Animação.

Para importar um JSON externo, use **Importar**. Para projetos V1, use **Converter V1 para V2** e revise o documento convertido antes de importar.

## Instalação

1. Habilite **Plugin Debugging Enabled** nas configurações do Roblox Studio.
2. Crie um Script em \`ServerStorage\` e cole o conteúdo de [Posecode.plugin.lua](src/Posecode.plugin.lua).
3. Com o Script selecionado no Explorer, use **Plugins → Save as Local Plugin**.
4. Depois de salvar, remova o Script original de \`ServerStorage\` e use a cópia do plugin em \`PluginDebugService\`.

Veja a documentação oficial de [Studio plugins](https://create.roblox.com/docs/studio/plugins).

## Limites

- O gerador está direcionado ao perfil estrutural Mesh Rig 2016 (R15); não é um conversor de código Luau arbitrário.
- A biblioteca local guarda receitas aprovadas, não dezenas de milhares de clips pré-renderizados.
- Entrada máxima de 256 KB.
- Até 15 tracks/alvos e 120 instantes de keyframe normalizados.
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
