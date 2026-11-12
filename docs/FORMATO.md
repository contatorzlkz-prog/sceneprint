# Formato Posecode v1

Este formato é usado pelo plugin Posecode 0.1.1. O campo version dentro do JSON continua sendo 1; ele identifica a estrutura dos dados, não a versão do plugin.

O plugin não executa o código colado. Ele extrai apenas o JSON de uma variável POSECODE ou aceita o JSON diretamente.

## Estrutura do script

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
            },
            "RightLowerArm": {
              "rotation": [0, 0, -20]
            }
          }
        },
        {
          "time": 0.4,
          "joints": {
            "RightUpperArm": {
              "rotation": [0, 0, 45]
            },
            "RightLowerArm": {
              "rotation": [0, 0, 70]
            }
          },
          "easingStyle": "CubicV2",
          "easingDirection": "InOut"
        },
        {
          "time": 0.8,
          "joints": {
            "RightUpperArm": {
              "rotation": [0, 0, -15]
            },
            "RightLowerArm": {
              "rotation": [0, 0, -20]
            }
          }
        }
      ]
    }
    ]==]

    return POSECODE

O nome da variável precisa ser POSECODE. O delimitador longo pode usar qualquer quantidade de sinais de igualdade; o exemplo usa [==[ ... ]==]. O plugin também aceita JSON puro ou JSON cercado por um bloco de Markdown.

## Campos principais

| Campo | Tipo | Regra |
|---|---|---|
| format | string | Sempre POSECODE |
| version | number | Sempre 1 |
| name | string | Nome da animação |
| rig | string | R6 ou R15 |
| fps | number | Inteiro entre 1 e 60 |
| duration | number | Duração em segundos, até 15 |
| looped | boolean | true ou false |
| priority | string | Core, Idle, Movement, Action, Action2, Action3 ou Action4 |
| easingStyle | string | Padrão opcional: Linear |
| easingDirection | string | Padrão opcional: InOut |
| frames | array | De 1 a 120 quadros após normalização |

## Campos de cada quadro

Cada quadro contém:

- time: tempo em segundos.
- joints: objeto cujas chaves são os nomes das peças ligadas à junta. Em Motor6D, use o nome de Part1. Em AnimationConstraint, use o nome da BasePart que é Parent de Attachment1.
- easingStyle: opcional; substitui o easingStyle global naquele quadro.
- easingDirection: opcional; substitui o easingDirection global naquele quadro.

Cada junta aceita position, um deslocamento local [x, y, z] em studs, e rotation, uma rotação local [x, y, z] em graus. Ambos podem ser omitidos.

As transformações são esparsas: quando uma junta não aparece em um quadro, ela mantém a última transformação informada. Uma junta nunca informada permanece na pose neutra.

## Tempo e normalização

Os tempos são ajustados ao quadro mais próximo de acordo com fps. Dois keyframes que caiam no mesmo quadro depois do ajuste são rejeitados.

Se não houver um quadro em 0, o plugin adiciona um quadro inicial neutro. Se o último quadro ocorrer antes de duration, o plugin duplica a última pose até o final para preservar a duração declarada. Essas adições também contam no limite de 120 quadros.

## Easing aceito

- Linear
- Constant
- CubicV2
- Elastic
- Bounce

Direções aceitas: In, Out e InOut.

## Prompt para gerar uma animação

Peça à IA algo semelhante a:

> Crie uma animação de [descreva o movimento] para um rig R15 no Roblox. Gere somente um script Luau POSECODE v1: variável POSECODE contendo JSON dentro de uma string longa [==[ ... ]==], seguida de return POSECODE. Informe fps, duration, looped, priority, easingStyle e easingDirection. Para cada keyframe, informe time em segundos e somente as juntas que mudaram, usando nomes exatos das peças conectadas por Motor6D ou AnimationConstraint. Rotation deve usar graus locais [x, y, z] e position deve usar offsets locais em studs. Use de 8 a 24 quadros distribuídos pelo movimento. Não use TweenService, não execute código, não invente nomes de juntas.

Troque R15 por R6 quando estiver usando um rig R6.

## Regras de validação

O importador rejeita versões diferentes de v1, rig incompatível, juntas desconhecidas, tempos inválidos ou repetidos após o ajuste, transformações fora dos limites, estilos de easing desconhecidos e animações acima de 15 segundos ou 120 quadros após normalização.