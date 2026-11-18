# Gerador de animações POSECODE

O gerador recebe uma descrição curta, interpreta o tipo de movimento e compõe uma animação procedural para o Mesh Rig 2016. Ele não converte código Luau em poses: cria keyframes diretamente e gera um documento POSECODE V2.

## Movimentos reconhecidos

| Movimento | Exemplos de descrição |
|---|---|
| Walk | `walk`, `walking`, `andar`, `caminhar` |
| Run | `run`, `running`, `correr`, `jogging` |
| Sprint | `sprint`, `sprinting`, `correr rapido` |
| Sneak | `sneak`, `sneaking`, `furtivo`, `agachado` |
| Tiptoe | `tiptoe`, `na ponta dos pes` |
| March | `march`, `marching`, `marchar` |
| Limp | `limp`, `mancar`, `mancando` |
| Idle | `idle`, `parado`, `respirando` |
| Wave | `wave`, `waving`, `acenar`, `tchau` |
| Salute | `salute`, `continencia`, `saudacao militar` |
| Jump | `jump`, `jumping`, `pular`, `salto` |
| Bow | `bow`, `bowing`, `reverencia` |
| Point | `point`, `pointing`, `apontar` |
| Clap | `clap`, `bater palmas`, `aplaudir` |
| Dance | `dance`, `dancing`, `dancar`, `dancando` |

## Modificadores entendidos

O gerador reconhece descritores de velocidade (`lento`, `rapido`, `muito rapido`), atitude (`cansado`, `feliz`, `confiante`, `triste`, `robotico`, `pesado`, `exagerado`), passada (`passos curtos`, `passos largos`), braços (`bracos soltos`, `bracos fortes`), postura (`ereto`, `inclinado`), balanço (`sem quicar`, `saltitante`), direção (`de costas`) e interpolação (`linear`, `travado`, `suave`).

Exemplos:

- `walk cansado e lento`
- `run confiante com passos largos`
- `sneak furtivo sem quicar`
- `wave`
- `jump exagerado`
- `salute robotico`
- `dance feliz`

O parser combina os descritores reconhecidos. Termos que ainda não fazem parte do vocabulário não são interpretados como instruções arbitrárias; o sistema usa o movimento-base encontrado e mantém os parâmetros padrão.

## Como as combinações são criadas

O motor cruza 15 movimentos-base com parâmetros discretos de velocidade, intensidade, passada, braços, postura, balanço, direção e easing. Isso representa 720.000 combinações paramétricas possíveis. Não são 720 mil clips pré-gravados: os 15 canais são calculados sob demanda, com 13 amostras por ciclo antes da otimização do formato V2.

## Biblioteca de referências

A biblioteca guarda até 24 receitas aprovadas pelo usuário. Depois de gerar, confira a prévia e use **Guardar referência** para registrar a receita. Gerações futuras com o mesmo movimento-base e atitude podem usar esses parâmetros como referência, desde que o pedido novo não especifique aquele modificador diretamente.

As referências ficam nas configurações locais do plugin no Roblox Studio. Não são enviadas automaticamente ao GitHub nem compartilhadas com outros usuários. Essa escolha mantém a biblioteca limpa: uma geração só vira referência depois de você aprová-la.

## Limites da primeira versão

- Direcionado exclusivamente ao Mesh Rig 2016 R15 validado pelo plugin.
- Não usa um modelo de linguagem, API externa, rede ou biblioteca pública de animações.
- Não interpreta código Lua arbitrário.
- A qualidade visual depende do rig e dos parâmetros; sempre confira a prévia e ajuste o clip antes de publicar.
- Gestos de braço são rotações das juntas existentes; dedos individuais ou deslocamentos complexos de mãos não fazem parte do esqueleto de 15 juntas.
