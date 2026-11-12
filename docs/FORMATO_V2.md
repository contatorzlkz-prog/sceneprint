# Formato POSECODE V2

O **POSECODE V2** é o formato recomendado para novas animações. Ele separa metadados, perfil do rig, timeline, tracks e eventos. Cada track representa um alvo animado e contém sua própria sequência de keyframes.

O plugin POSECODE v1.8 importa V2 e continua aceitando documentos V1. O campo \`version\` identifica a versão do formato dos dados, não a versão do plugin.

## Exemplo completo

Este exemplo usa nomes de alvo ilustrativos. Troque-os pelos nomes exatos existentes no rig selecionado.

\`\`\`json
{
  "format": "POSECODE",
  "version": 2,
  "metadata": {
    "name": "Walk_Cycle",
    "author": "ruancr",
    "description": "Ciclo simples de caminhada"
  },
  "rig": {
    "profile": "R15"
  },
  "timeline": {
    "fps": 30,
    "duration": 0.8,
    "looped": true,
    "priority": "Movement",
    "defaultEasing": {
      "style": "CubicV2",
      "direction": "InOut"
    }
  },
  "tracks": [
    {
      "target": {
        "type": "Motor6D",
        "name": "RightUpperArm"
      },
      "keys": [
        {
          "time": 0,
          "transform": {
            "position": [0, 0, 0],
            "rotation": [0, 0, -15]
          }
        },
        {
          "time": 0.4,
          "transform": {
            "position": [0, 0, 0],
            "rotation": [0, 0, 25]
          }
        },
        {
          "time": 0.8,
          "transform": {
            "position": [0, 0, 0],
            "rotation": [0, 0, -15]
          }
        }
      ]
    },
    {
      "target": {
        "type": "Motor6D",
        "name": "LeftUpperArm"
      },
      "keys": [
        {
          "time": 0,
          "transform": {
            "position": [0, 0, 0],
            "rotation": [0, 0, 25]
          }
        },
        {
          "time": 0.4,
          "transform": {
            "position": [0, 0, 0],
            "rotation": [0, 0, -15]
          }
        },
        {
          "time": 0.8,
          "transform": {
            "position": [0, 0, 0],
            "rotation": [0, 0, 25]
          }
        }
      ]
    }
  ],
  "events": [
    {
      "time": 0.4,
      "name": "Footstep",
      "value": "left"
    }
  ]
}
\`\`\`

## Estrutura

| Campo | Obrigatório | Descrição |
|---|---|---|
| \`format\` | Sim | Sempre \`POSECODE\`. |
| \`version\` | Sim | Sempre o número \`2\`. |
| \`metadata\` | Sim | Identificação do clip. |
| \`rig\` | Sim | Perfil do rig de destino. |
| \`timeline\` | Sim | Configuração global de tempo e reprodução. |
| \`tracks\` | Sim | Lista de canais animados. |
| \`events\` | Não | Eventos de animação associados ao tempo. Ausência equivale a uma lista vazia. |

## Metadata

\`metadata.name\` é obrigatório e deve ter de 1 a 64 caracteres.

\`metadata.author\` é opcional e aceita até 64 caracteres. \`metadata.description\` também é opcional e aceita até 256 caracteres. Esses campos são descritivos; não alteram a conversão da animação.

## Rig

\`rig.profile\` aceita:

- \`R6\`
- \`R15\`
- \`CUSTOM\`, para Models sem Humanoid.

Quando o Model selecionado possui um Humanoid, o plugin confere se o perfil corresponde ao RigType real.

### Alvos tipados

Cada track declara o tipo de alvo, evitando depender apenas de um nome sem contexto:

| \`target.type\` | Como \`target.name\` é resolvido |
|---|---|
| \`Motor6D\` | Nome da BasePart conectada em \`Part1\`. |
| \`AnimationConstraint\` | Nome da BasePart que é Parent de \`Attachment1\`. A saída continua experimental. |
| \`Bone\` | Nome da instância \`Bone\`. |

Os nomes precisam existir no Model selecionado e ser únicos dentro dos canais reconhecidos pelo plugin. O valor de \`target.type\` precisa corresponder ao tipo real detectado. Não use o nome do objeto Motor6D no lugar do nome de sua peça \`Part1\`.

## Timeline

| Campo | Regra |
|---|---|
| \`fps\` | Obrigatório. Inteiro de 1 a 60. |
| \`duration\` | Obrigatório. Maior que zero e até 15 segundos. |
| \`looped\` | Opcional. Booleano; padrão \`false\`. |
| \`priority\` | Opcional. Padrão \`Action\`. |
| \`defaultEasing\` | Opcional. Padrão Linear / InOut. |

Prioridades aceitas: \`Core\`, \`Idle\`, \`Movement\`, \`Action\`, \`Action2\`, \`Action3\` e \`Action4\`.

\`defaultEasing\` contém \`style\` e \`direction\`. Os estilos aceitos são \`Linear\`, \`Constant\`, \`CubicV2\`, \`Elastic\` e \`Bounce\`; as direções são \`In\`, \`Out\` e \`InOut\`. A rota CurveAnimation aceita Linear, Constant ou CubicV2 com InOut. Elastic e Bounce não têm correspondência direta e são recusados nessa rota.

## Tracks e keyframes

Cada item de \`tracks\` possui:

- \`target\`: objeto com \`type\` e \`name\`.
- \`keys\`: array de keyframes daquele alvo.

Uma track precisa ter ao menos um keyframe. Um mesmo alvo não pode aparecer em duas tracks. O limite é de 256 tracks.

Cada keyframe contém:

- \`time\`: posição em segundos dentro da duração.
- \`transform\`: objeto com \`position\` e/ou \`rotation\`.
- \`easing\`: opcional; substitui o easing global daquele keyframe.

\`position\` é um vetor local em studs: \`[x, y, z]\`. \`rotation\` é um vetor de ângulos locais em graus, na ordem XYZ. Se um dos campos não aparecer, seu valor será zero naquele keyframe. Cada componente de posição tem limite de 5 studs e cada componente de rotação tem limite de 720 graus.

O objeto \`easing\`, quando informado, precisa conter os dois campos:

\`\`\`json
"easing": {
  "style": "CubicV2",
  "direction": "InOut"
}
\`\`\`

Keyframes de tracks diferentes podem compartilhar o mesmo tempo e serão combinados em um único instante da timeline. Como o sistema de saída atual aplica easing no nível do keyframe global, todos os canais que caem no mesmo instante precisam usar o mesmo par \`style\` / \`direction\`. O importador rejeita conflitos, em vez de escolher um easing silenciosamente.

## Eventos

\`events\` é uma lista opcional. Cada item contém:

- \`time\`: tempo em segundos.
- \`name\`: identificador de 1 a 64 caracteres.
- \`value\`: texto opcional de até 256 caracteres; padrão vazio.

São aceitos até 128 eventos no total e 8 eventos por quadro normalizado. Os eventos são convertidos em \`KeyframeMarker\` e, por isso, estão disponíveis somente na saída \`KeyframeSequence\`. Se o rig usar Bone ou AnimationConstraint e o documento tiver eventos, o importador recusa a conversão para evitar perda silenciosa.

## Tempo, combinação e normalização

Os tempos são ajustados para o quadro mais próximo de acordo com \`fps\`. Keyframes de tracks diferentes que resultem no mesmo quadro são combinados. Dois keyframes da mesma track que resultem no mesmo quadro são recusados. Eventos também são associados ao quadro normalizado correspondente.

Se o primeiro instante estiver depois de zero, o plugin insere um quadro neutro no início. Se o último keyframe estiver antes do fim, a última pose é mantida até \`duration\`. Quadros automáticos também contam no limite de 120 instantes normalizados.

## Limites de segurança

- JSON de até 256 KB.
- Até 256 tracks/alvos.
- Até 120 keyframes por track e 120 instantes após combinar e normalizar.
- Duração máxima de 15 segundos e FPS de 1 a 60.
- Posição local de até 5 studs por componente.
- Rotação local de até 720 graus por componente.
- Até 128 eventos e 8 eventos por quadro.

O plugin valida a entrada como JSON estruturado. Não executa scripts Luau, chamadas, funções ou código incluído no documento.

## Compatibilidade com V1

O V1 continua aceito para projetos existentes. O V2 é recomendado para novos documentos porque separa metadados, rig, timeline e canais, declara o tipo de cada alvo e permite escrever keyframes por track. O plugin normaliza V2 internamente para o mesmo pipeline validado usado para criar clips; isso preserva as rotas atuais de saída sem manter dois conversores de animação independentes.

Veja também [Formato POSECODE V1 (legado)](FORMATO.md), [limites técnicos](LIMITES.md) e a documentação oficial de [CurveAnimation](https://create.roblox.com/docs/reference/engine/classes/CurveAnimation), [Bone](https://create.roblox.com/docs/reference/engine/classes/Bone) e [AnimationConstraint](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint).
