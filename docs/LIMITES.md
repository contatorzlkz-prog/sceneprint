# Limites técnicos e publicação

## Importação segura

O plugin não tenta interpretar a lógica de scripts Luau arbitrários. Um script pode conter loops, cálculos, condições, TweenService e eventos, sem uma lista fixa de poses. Executá-lo para tentar reconstruir os movimentos seria imprevisível.

O Posecode extrai somente o JSON estruturado de POSECODE v1. Não usa loadstring e não executa o conteúdo colado. A entrada tem limite de 256 KB e validação de arrays, tempos, juntas e transformações.

## Formatos de saída

### Rigs com Motor6D

Gera uma KeyframeSequence. Cada Keyframe contém uma árvore hierárquica de Pose, na qual o nome da Pose corresponde à peça conectada pela junta. O CFrame local da Pose é aplicado à junta correspondente.

### Rigs com AnimationConstraint

Gera uma CurveAnimation. A estrutura é composta por pastas hierárquicas e canais de animação: Position usa Vector3Curve e Rotation usa EulerRotationCurve em ordem XYZ. As curvas são organizadas pela hierarquia de partes obtida de Attachment0.Parent e Attachment1.Parent.

O formato CurveAnimation usa interpolação Linear, Constant ou Cubic. CubicV2 é mapeado para Cubic com tangentes estimadas dos quadros vizinhos e direção InOut. Elastic e Bounce são recusados nesse caminho porque não possuem correspondência direta no modelo de interpolação das curvas.

A documentação de CurveAnimation descreve curvas de posição e rotação organizadas pela hierarquia de juntas e consumidas pelo sistema de animação. A compatibilidade de rigs específicos pode depender da estrutura de juntas e nomes presentes no modelo. Consulte [CurveAnimation](https://create.roblox.com/docs/reference/engine/classes/CurveAnimation) e [AnimationConstraint](https://create.roblox.com/docs/physics/constraints/animation).

## Rotações e tempo

As rotações de POSECODE são expressas em graus locais na ordem XYZ e convertidas para CFrame/curvas Euler XYZ.

Os tempos são arredondados para o quadro mais próximo segundo fps. O importador rejeita colisões depois do arredondamento. Um quadro neutro é acrescentado em 0 quando necessário e o último quadro é prolongado até duration. O limite de 120 inclui quadros criados automaticamente; a duração máxima é 15 segundos.

## Prévia e navegação

O plugin registra o clip temporariamente com AnimationClipProvider:RegisterActiveAnimationClip e carrega o ID local em um Animator. O ID temporário não é um asset publicado e não funciona fora do Studio.

Durante a prévia, Animator:StepAnimations avança a avaliação. O plugin permite pausar/retomar, parar, alterar a velocidade (0.5×, 1×, 1.5× ou 2×), arrastar o cursor e saltar para o quadro anterior ou seguinte. A posição é atualizada por AnimationTrack.TimePosition, que só pode ser alterada enquanto a track está tocando. Ao parar, o plugin restaura Transform e CurrentAngle quando aplicável.

Consulte [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator), [AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack) e [AnimationClipProvider](https://create.roblox.com/docs/reference/engine/classes/AnimationClipProvider).

## Salvamento

O botão **Salvar Clip no Studio** armazena o clip em ServerStorage.RBX_ANIMSAVES, com uma subpasta para o rig e um ObjectValue AnimSaves no próprio rig apontando para essa pasta. Rigs que já possuem uma pasta AnimSaves local continuam sendo aceitos.

O Editor de Animação salva KeyframeSequence e CurveAnimation localmente em ServerStorage, e usa a referência AnimSaves no rig para acessar esse trabalho. Consulte [Animation Editor](https://create.roblox.com/docs/animation/editor).

## Publicação

O plugin não faz upload próprio. Para publicar, abra o clip salvo no Editor de Animação e use **Publish to Roblox**. A publicação do clip continua no fluxo do Studio, e o ID temporário da prévia não substitui um ID de asset.

## Limites da v1.2

- Não converte código arbitrário, TweenService ou lógica condicionada.
- Não anima deslocamento global da raiz do personagem.
- Não cria markers/eventos de animação.
- Não inclui edição independente de tracks ou keyframes dentro do plugin.
- Rigs customizados podem exigir ajuste na hierarquia e nos nomes de partes/juntas.
- A saída CurveAnimation usa somente Linear, Constant e CubicV2/InOut; Elastic e Bounce ficam disponíveis apenas no caminho KeyframeSequence.