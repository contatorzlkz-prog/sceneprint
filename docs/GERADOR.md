# Guia do gerador procedural

O POSECODE recebe uma descrição curta e converte a intenção reconhecida em parâmetros de movimento. O motor gera as poses diretamente para o Mesh Rig 2016; o usuário não precisa escrever código ou colar JSON.

## Movimentos-base

| Movimento | Vocabulário reconhecido |
|---|---|
| Walk | `walk`, `walking`, `andar`, `andando`, `caminhar`, `caminhada` |
| Run | `run`, `running`, `jog`, `jogging`, `correr`, `correndo`, `corrida` |
| Sprint | `sprint`, `sprinting`, `sprintar`, `corrida rápida`, `correr rápido` |
| Sneak | `sneak`, `sneaking`, `stealth`, `agachar`, `agachado`, `furtivo`, `esgueirar` |
| Tiptoe | `tiptoe`, `tiptoeing`, `na ponta`, `ponta dos pés` |
| March | `march`, `marching`, `marchar`, `marcha` |
| Limp | `limp`, `limping`, `mancar`, `mancando`, `manco` |
| Idle | `idle`, `standing idle`, `still`, `parado`, `respirando`, `em pé` |
| Wave | `wave`, `waving`, `acenar`, `aceno`, `tchau` |
| Salute | `salute`, `saluting`, `continência`, `saudação militar` |
| Jump | `jump`, `jumping`, `pular`, `pulando`, `salto` |
| Bow | `bow`, `bowing`, `reverência`, `reverenciar` |
| Point | `point`, `pointing`, `apontar`, `apontando` |
| Clap | `clap`, `clapping`, `bater palmas`, `aplaudir` |
| Dance | `dance`, `dancing`, `dançar`, `dançando`, `dança` |
| Crawl | `crawl`, `crawling`, `rastejar`, `rastejando`, `engatinhar` |
| Strafe | `strafe`, `strafing`, `side step`, `sideways walk`, `andar de lado`, `passo lateral` |
| Backpedal | `backpedal`, `backpedaling`, `walk backwards`, `andar de costas`, `recuar andando` |
| Stretch | `stretch`, `stretching`, `alongar`, `espreguiçar` |
| Shrug | `shrug`, `shrugging`, `dar de ombros`, `encolher os ombros` |

## Atitudes

O motor dispõe de 16 perfis de atitude e um estado neutro: cansado, feliz, confiante, intenso/irritado, pesado, triste, robótico, exagerado, casual, sonolento, nervoso, orgulhoso, curioso, brincalhão, sério e relaxado.

Exemplos: `walk cansado`, `run confiante`, `sneak nervoso`, `wave friendly`, `jump energetic`, `dance brincalhão`.

## Modificadores

A descrição também pode especificar:

- **Ritmo:** muito devagar, devagar, rápido, muito rápido.
- **Intensidade:** sutil, suave, leve, forte, intenso, exagerado.
- **Passada:** curta, muito curta, longa ou larga.
- **Braços:** soltos, relaxados, leves ou fortes.
- **Postura:** ereta, neutra, inclinada ou curvada.
- **Balanço:** sem quicar, pouco quique ou saltitante.
- **Direção:** de costas / para trás.
- **Interpolação:** linear/robótica, travada ou suave/fluida.

O parser usa apenas os termos reconhecidos. Uma frase sem movimento-base reconhecido recebe uma mensagem explicando que o tipo de movimento precisa ser informado, em vez de gerar uma caminhada por padrão.

## Como o motor compõe a animação

A geração combina:

1. **Motion:** o padrão biomecânico ou gesto-base.
2. **Blend:** atitude e parâmetros de velocidade, intensidade, passada, braços, postura, balanço, direção e easing.
3. **Pose:** as transformações calculadas para as 15 juntas do Mesh Rig 2016.

A interface mostra esse caminho como MOTION → BLEND → POSE. A composição é calculada localmente e não depende de uma API ou de um modelo de linguagem.

O espaço paramétrico contém 20 bases, 5 níveis de velocidade, 5 de intensidade, 5 de passada, 4 de braço, 4 de postura, 4 de balanço, 2 direções, 3 interpolações e 17 estados de atitude (16 perfis mais neutro): **16.320.000 combinações de parâmetros**. São configurações teóricas calculadas sob demanda, não 16,32 milhões de arquivos ou movimentos únicos garantidos.

## Variações e biblioteca

**Outra variação** altera a semente para produzir uma nova realização do mesmo pedido. Depois de conferir o resultado, **Guardar referência** salva a receita localmente. A biblioteca mantém até 48 receitas aprovadas e pode reutilizar os parâmetros de uma referência parecida quando o novo pedido não define explicitamente aquele modificador.

As referências ficam nas configurações locais do plugin no Roblox Studio. Não são enviadas ao GitHub nem compartilhadas com outros usuários.

## Fluxo recomendado

1. Selecione o Mesh Rig 2016 no Explorer.
2. Confira se o indicador de rig está verde.
3. Escreva uma descrição com um movimento-base e, quando necessário, atitude e modificadores.
4. Gere e veja a prévia no mesmo rig selecionado.
5. Peça uma variação ou guarde uma referência aprovada.
6. Salve o clip no Studio e revise-o no Editor de Animação antes de publicar.

## Limites atuais

- Exclusivo do Mesh Rig 2016 R15 validado estruturalmente.
- 15 canais de juntas; dedos individuais não são canais independentes.
- Vocabulário procedural conhecido, não linguagem livre ilimitada.
- A prévia precisa ser conferida no Roblox Studio; esta atualização não substitui um teste no rig real.
