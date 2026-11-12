# Formato POSECODE v1

Este formato é usado pelo plugin POSECODE 1.8. O campo JSON `version` continua sendo 1: ele identifica a estrutura dos dados, não a versão do plugin.

O plugin não executa o código colado. Ele extrai o JSON de uma variável `POSECODE` ou aceita JSON diretamente. A caixa de importação aceita até 256 KB.

## Estrutura

```lua
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
```

Também é aceito JSON puro ou JSON cercado por um bloco Markdown. Para a forma Luau, o nome da variável precisa ser `POSECODE`; o delimitador longo pode usar qualquer quantidade de sinais de igualdade.

## Campos principais

| Campo | Tipo | Regra |
|---|---|---|
| format | string | Sempre `POSECODE` |
| version | number | Sempre `1` |
| name | string | Nome do clip |
| rig | string | `R6`, `R15` ou `CUSTOM` |
| fps | number | Inteiro de 1 a 60 |
| duration | number | Maior que 0 e até 15 segundos |
| looped | boolean | `true` ou `false` |
| priority | string | Core, Idle, Movement, Action, Action2, Action3 ou Action4 |
| easingStyle | string | Padrão: Linear |
| easingDirection | string | Padrão: InOut |
| frames | array | De 1 a 120 quadros após normalização |

Use `R6` ou `R15` quando o Model tiver um Humanoid. Para rigs sem Humanoid, use `CUSTOM`. Quando há Humanoid, o plugin confere se o perfil informado corresponde ao `RigType` real.

## Quadros e juntas

Cada quadro contém:

- `time`: tempo em segundos.
- `joints`: objeto com os canais que mudam naquele quadro.
- `easingStyle`: opcional; substitui o estilo global naquele quadro.
- `easingDirection`: opcional; substitui a direção global naquele quadro.
- `markers`: opcional; eventos disparados quando o quadro é alcançado.

O campo dentro de `joints` usa o nome do alvo animado:

- **Motor6D:** nome da peça em `Part1`.
- **AnimationConstraint:** nome da `BasePart` que é Parent de `Attachment1`.
- **Bone:** nome da instância `Bone`.

Cada nome usado como canal precisa ser único dentro do Model selecionado. Renomeie os alvos quando houver duas juntas ou Bones com o mesmo nome.

Cada junta aceita:

- `position`: deslocamento local `[x, y, z]`, em studs.
- `rotation`: rotação local `[x, y, z]`, em graus.

Os dois campos podem ser omitidos; o campo omitido assume zero. As rotações usam ordem XYZ. As transformações são esparsas: quando um canal não aparece em um quadro, ele mantém o último valor informado. Um canal nunca informado permanece neutro.

## Seleção de saída

A rota é escolhida pelo conteúdo do rig:

- **Somente Motor6D:** gera uma `KeyframeSequence` com uma árvore hierárquica de `Pose`.
- **Bone:** gera uma `CurveAnimation` com pastas hierárquicas e canais `Position` (`Vector3Curve`) e `Rotation` (`EulerRotationCurve`). Essa é a estrutura documentada pelo Roblox para Bones.
- **Motor6D + Bone:** usa `CurveAnimation` para manter a hierarquia de ambos no mesmo clip.
- **AnimationConstraint:** usa a rota `CurveAnimation` experimental. O Roblox documenta `CurveAnimation` explicitamente para Motor6D e Bone, mas não garante todas as configurações de AnimationConstraint. Confira a prévia antes de usar o clip.

Veja a referência oficial de [CurveAnimation](https://create.roblox.com/docs/reference/engine/classes/CurveAnimation), [Bone](https://create.roblox.com/docs/reference/engine/classes/Bone) e [AnimationConstraint](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint).

## Eventos de animação

Um quadro pode conter uma lista opcional de eventos:

```json
"markers": [
  { "name": "Footstep", "value": "left" },
  { "name": "Sound", "value": "land" }
]
```

Cada evento possui:

- `name`: identificador entre 1 e 64 caracteres.
- `value`: texto opcional de até 256 caracteres; quando omitido, fica vazio.

O limite é de 8 eventos por quadro e 128 por animação. Eles são convertidos em `KeyframeMarker` dentro da `KeyframeSequence`. Durante a prévia, os eventos aparecem na timeline e o status mostra o nome e o valor ao serem alcançados.

A conversão deste plugin não inclui markers na saída `CurveAnimation`. O importador rejeita markers quando o rig possui Bones ou AnimationConstraint, em vez de descartá-los silenciosamente.

Em uma animação publicada, scripts podem escutar um evento com `AnimationTrack:GetMarkerReachedSignal("Footstep")`. O parâmetro recebido corresponde ao campo `value`. Veja [eventos de animação](https://create.roblox.com/docs/animation/events).

## Tempo e normalização

Os tempos são arredondados para o quadro mais próximo segundo o FPS. Dois quadros que caiam no mesmo instante depois do arredondamento são rejeitados.

Se não existir um quadro em 0, o plugin cria um quadro inicial neutro. Se o último quadro ocorrer antes de `duration`, ele cria um quadro final que mantém a última pose. Os quadros automáticos também contam no limite de 120.

## Easing

Para `KeyframeSequence`, são aceitos Linear, Constant, CubicV2, Elastic e Bounce, com direções In, Out ou InOut.

Para `CurveAnimation`, são aceitos Linear, Constant e CubicV2 com direção InOut. Elastic e Bounce não possuem correspondência direta nesse formato e são recusados. CubicV2 é convertido para interpolação cúbica com tangentes calculadas a partir dos quadros vizinhos.

## Prompt de geração

> Crie uma animação de [descreva o movimento] para um rig Roblox. Gere somente POSECODE v1 em JSON dentro da variável Luau `POSECODE`. Informe name, rig (R6, R15 ou CUSTOM), fps, duration, looped, priority, easingStyle e easingDirection. Para cada quadro, informe time e somente os canais joints que mudaram. Use nomes exatos e únicos de Part1, Attachment1.Parent ou Bone, conforme o tipo de rig. Rotation usa graus locais em ordem XYZ; position usa offsets locais em studs. Use de 8 a 24 quadros distribuídos pelo movimento. Inclua markers somente para rigs que gerem KeyframeSequence. Não use TweenService, não execute código e não invente nomes de canais.

## Validação

O importador rejeita perfil incompatível, rig sem hierarquia válida, nomes de canal ausentes ou duplicados, arrays com lacunas, tempos repetidos após normalização, valores fora dos limites, easing incompatível, markers inválidos e clips acima de 15 segundos ou 120 quadros normalizados.
