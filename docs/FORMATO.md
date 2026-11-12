# Formato POSECODE v1

Este formato é usado pelo plugin Posecode 1.2. O campo JSON version continua sendo 1; ele identifica a estrutura dos dados, não a versão do plugin.

O plugin não executa o código colado. Ele extrai o JSON de uma variável POSECODE ou aceita JSON diretamente. A caixa de importação aceita até 256 KB.

## Estrutura

    local POSECODE = [==[
    {
      "format": "POSECODE",
      "version": 1,
      "name": "Arm_Swing",
      "rig": "R15",
      "fps": 30,
      "duration": 0.8,
      "looped": false,
      "priority": "Action",
      "easingStyle": "CubicV2",
      "easingDirection": "InOut",
      "frames": [
        {
          "time": 0,
          "joints": {
            "RightUpperArm": {
              "position": [0, 0, 0],
              "rotation": [0, 0, -15]
            }
          }
        },
        {
          "time": 0.4,
          "joints": {
            "RightUpperArm": {
              "position": [0, 0, 0],
              "rotation": [0, 0, 45]
            }
          }
        },
        {
          "time": 0.8,
          "joints": {
            "RightUpperArm": {
              "position": [0, 0, 0],
              "rotation": [0, 0, -15]
            }
          }
        }
      ]
    }
    ]==]

    return POSECODE

O nome da variável precisa ser POSECODE. O delimitador longo pode usar qualquer quantidade de sinais de igualdade; o exemplo usa [==[ ... ]==]. Também é aceito JSON puro ou JSON cercado por um bloco Markdown.

## Campos principais

| Campo | Tipo | Regra |
|---|---|---|
| format | string | Sempre POSECODE |
| version | number | Sempre 1 |
| name | string | Nome da animação |
| rig | string | R6 ou R15 |
| fps | number | Inteiro de 1 a 60 |
| duration | number | Duração em segundos, até 15 |
| looped | boolean | true ou false |
| priority | string | Core, Idle, Movement, Action, Action2, Action3 ou Action4 |
| easingStyle | string | Padrão: Linear |
| easingDirection | string | Padrão: InOut |
| frames | array | De 1 a 120 quadros após normalização |

## Quadros e juntas

Cada quadro contém:

- time: tempo em segundos.
- joints: objeto com o nome de cada peça ligada a uma junta.
- easingStyle: opcional; substitui o easingStyle global nesse quadro.
- easingDirection: opcional; substitui o easingDirection global nesse quadro.

Em Motor6D, use o nome da peça em Part1. Em AnimationConstraint, use o nome da BasePart que é Parent de Attachment1.

Cada junta aceita:

- position: deslocamento local [x, y, z], em studs.
- rotation: rotação local [x, y, z], em graus.

Os dois campos podem ser omitidos; quando isso acontece, a parte omitida assume zero. As rotações usam ordem **XYZ**. Os valores são convertidos para CFrame no caminho KeyframeSequence e para curvas Euler XYZ no caminho CurveAnimation.

As transformações são esparsas: quando uma junta não aparece em um quadro, ela mantém o último valor informado. Uma junta nunca informada permanece na pose neutra.

## Como o formato de saída é escolhido

A seleção é automática:

- Se o rig usa apenas Motor6D, o plugin cria uma KeyframeSequence com poses hierárquicas. O gerador usa os valores padrão de peso das Pose, sem escrever propriedades depreciadas.
- Se o rig contém AnimationConstraint, o plugin tenta criar uma CurveAnimation com pastas hierárquicas e canais Position (Vector3Curve) e Rotation (EulerRotationCurve). Essa saída é experimental: a documentação pública do CurveAnimation descreve explicitamente os canais para Motor6D e Bone, sem garantir todas as configurações com AnimationConstraint. Confira a prévia no Studio antes de usar o clip.

## Tempo e normalização

Os tempos são arredondados para o quadro mais próximo de acordo com fps. Dois quadros que caiam no mesmo instante depois do arredondamento são rejeitados.

Se não existir um quadro em 0, o plugin cria um quadro inicial neutro. Se o último quadro ocorrer antes de duration, o plugin adiciona um quadro final que mantém a última pose. Os quadros automáticos também contam no limite de 120.

## Easing

Para KeyframeSequence, são aceitos Linear, Constant, CubicV2, Elastic e Bounce, com direções In, Out ou InOut.

Para CurveAnimation, o formato de curva aceita Linear, Constant e CubicV2 com direção InOut. Elastic e Bounce não possuem correspondência direta nesse formato e são recusados para evitar uma conversão enganosa. CubicV2 é convertido para interpolação cúbica com tangentes calculadas a partir dos quadros vizinhos.

## Prompt para a IA

> Crie uma animação de [descreva o movimento] para um rig R15 no Roblox. Gere somente um script Luau POSECODE v1: variável POSECODE contendo JSON dentro de uma string longa [==[ ... ]==], seguida de return POSECODE. Informe fps, duration, looped, priority, easingStyle e easingDirection. Para cada quadro, informe time em segundos e somente as juntas que mudaram. Use nomes exatos das peças conectadas por Motor6D ou AnimationConstraint. Rotation deve usar graus locais em ordem XYZ [x, y, z] e position deve usar offsets locais em studs. Use de 8 a 24 quadros distribuídos pelo movimento. Para rigs com AnimationConstraint, use somente Linear, Constant ou CubicV2 com direção InOut. Não use TweenService, não execute código e não invente nomes de juntas.

Troque R15 por R6 quando estiver usando um rig R6.

## Validação

O importador rejeita versão incompatível, rig diferente, arrays com lacunas ou índices inválidos, juntas desconhecidas, tempos repetidos depois da normalização, valores fora dos limites, estilos de easing incompatíveis e animações acima de 15 segundos ou 120 quadros normalizados.