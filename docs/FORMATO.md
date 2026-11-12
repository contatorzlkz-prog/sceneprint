# Formato Posecode · v1

O plugin não executa o código colado. Ele procura uma variável POSECODE com um bloco de texto JSON e converte esse conteúdo em uma sequência de keyframes.

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
      "frames": [
        {
          "time": 0,
          "joints": {
            "RightUpperArm": {
              "position": [0, 0, 0],
              "rotation": [0, 0, -15]
            },
            "RightLowerArm": {
              "position": [0, 0, 0],
              "rotation": [0, 0, -20]
            }
          }
        },
        {
          "time": 0.4,
          "joints": {
            "RightUpperArm": {
              "position": [0, 0, 0],
              "rotation": [0, 0, 45]
            },
            "RightLowerArm": {
              "position": [0, 0, 0],
              "rotation": [0, 0, 70]
            }
          }
        },
        {
          "time": 0.8,
          "joints": {
            "RightUpperArm": {
              "position": [0, 0, 0],
              "rotation": [0, 0, -15]
            },
            "RightLowerArm": {
              "position": [0, 0, 0],
              "rotation": [0, 0, -20]
            }
          }
        }
      ]
    }
    ]==]

    return POSECODE

O nome da variável precisa ser exatamente POSECODE. O delimitador longo pode usar qualquer quantidade de sinais =; o exemplo usa [==[ ... ]==].

## Campos

| Campo | Tipo | Regra |
|---|---|---|
| format | string | Sempre POSECODE |
| version | number | Sempre 1 |
| name | string | Nome curto da animação |
| rig | string | R6 ou R15 |
| fps | number | Inteiro de 1 a 60; referência para a IA |
| duration | number | Duração total em segundos, máximo 15 |
| looped | boolean | true ou false |
| priority | string | Core, Idle, Movement ou Action |
| frames | array | De 1 a 120 quadros |

Cada quadro tem time em segundos e joints, um objeto cujas chaves são os nomes das peças controladas por Motor6D.

Cada junta aceita:

- position: deslocamento local [x, y, z], em studs. Pode ser omitido.
- rotation: rotação local [x, y, z], em graus. Pode ser omitida.

Uma transformação omitida equivale à identidade. A hierarquia de poses é montada a partir das juntas do próprio rig selecionado.

## Prompt para gerar uma animação

Peça à IA algo semelhante a:

> Crie uma animação de [descreva o movimento] para um rig R15 no Roblox. Gere somente um script Luau no formato POSECODE v1: uma variável POSECODE contendo JSON em uma string longa [==[ ... ]==], seguida de return POSECODE. Inclua tempos em segundos, duração, loop, prioridade e rotações locais em graus para as juntas R15. Use entre 8 e 24 keyframes, distribua o movimento de forma suave e mantenha a pose inicial/final coerente com o tipo de animação. Não use TweenService, não escreva código de playback e não invente nomes de juntas.

Troque R15 por R6 quando estiver usando um rig R6.

## Regras de validação

O importador rejeita versões diferentes de v1, rig incompatível, juntas desconhecidas, tempos repetidos, valores fora dos limites e animações acima de 15 segundos ou 120 keyframes. Isso evita transformar dados inválidos em objetos difíceis de depurar.