# Limites técnicos e publicação

## Importação segura

O plugin não tenta interpretar a lógica de scripts Luau arbitrários. Um script pode conter loops, cálculos, condições, TweenService e eventos, sem uma lista fixa de poses. Executá-lo para tentar reconstruir os movimentos seria imprevisível.

O Posecode extrai somente o JSON estruturado de POSECODE v1. Não usa loadstring e não executa o conteúdo colado. A entrada tem limite de 256 KB e validação de arrays, tempos, juntas e transformações.

## Formatos de saída

### Rigs com Motor6D

Gera uma KeyframeSequence. Cada Keyframe contém uma árvore hierárquica de Pose, na qual o nome da Pose corresponde à peça conectada pela junta. O CFrame local da Pose é aplicado ao Motor6D correspondente.

### Rigs com AnimationConstraint

A v1.3 gera uma CurveAnimation como saída experimental. A estrutura usa pastas hierárquicas com Position (Vector3Curve) e Rotation (EulerRotationCurve) para as peças conectadas pelas constraints, usando Attachment0.Parent e Attachment1.Parent.

**Compatibilidade não garantida:** a referência oficial de CurveAnimation descreve os canais Position/Rotation explicitamente para Motor6D e Bone. AnimationConstraint é a substituição de Motor6D nos rigs de avatar atualizados e possui sua própria propriedade Transform controlada pelo sistema de animação, mas a documentação pública não confirma de forma explícita que a hierarquia CurveAnimation gerada pelo Posecode será aplicada a todas as configurações de AnimationConstraint. Por isso, o plugin marca essa saída como experimental e o resultado precisa ser conferido no Studio. Consulte [CurveAnimation](https://create.roblox.com/docs/reference/engine/classes/CurveAnimation), [AnimationConstraint](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint) e [a migração de Avatar Joint Upgrade](https://devforum.roblox.com/t/avatar-joint-upgrade-aju-phase-2-rollout-updated-migration-recommendations/4656414).

## Rotações e tempo

As rotações de POSECODE são expressas em graus locais na ordem XYZ e convertidas para CFrame/curvas Euler XYZ.

Os tempos são arredondados para o quadro mais próximo segundo fps. O importador rejeita colisões depois do arredondamento. Um quadro neutro é acrescentado em 0 quando necessário e o último quadro é prolongado até duration. O limite de 120 inclui quadros criados automaticamente; a duração máxima é 15 segundos.

A saída KeyframeSequence aceita Linear, Constant, CubicV2, Elastic e Bounce com direções In, Out ou InOut. A saída CurveAnimation usa Linear, Constant ou Cubic; CubicV2 é convertido para segmentos cúbicos com tangentes estimadas entre os quadros vizinhos e direção InOut. Elastic e Bounce não possuem correspondência direta no modelo de interpolação das curvas e são recusados nesse caminho.

## Prévia e navegação

O plugin registra o clip temporariamente com AnimationClipProvider:RegisterActiveAnimationClip e carrega o ID local em um Animator. O ID temporário não é um asset publicado e não funciona fora do Studio.

Durante a prévia, Animator:StepAnimations avança a avaliação. O plugin permite pausar/retomar, parar, alterar a velocidade (0.5×, 1×, 1.5× ou 2×), arrastar o cursor e saltar para o quadro anterior ou seguinte. A posição é atualizada por AnimationTrack.TimePosition, que só pode ser alterada enquanto a track está tocando. Ao parar, o plugin encerra a track e restaura os valores originais de Transform das juntas.

Consulte [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator), [AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack) e [AnimationClipProvider](https://create.roblox.com/docs/reference/engine/classes/AnimationClipProvider).

## Eficiência interna

A validação calcula cada transformação local uma vez por junta em cada quadro e armazena o resultado para reutilização na geração do clip. Na saída CurveAnimation, a decomposição Euler XYZ também é feita uma vez por junta/quadro, em vez de ser repetida separadamente para cada eixo. A validação dos vetores não cria tabelas temporárias para conferir os três componentes.

## Salvamento

O botão **Salvar Clip no Studio** armazena o clip em ServerStorage.RBX_ANIMSAVES, com uma subpasta para o rig e um ObjectValue AnimSaves no próprio rig apontando para essa pasta. Rigs que já possuem uma pasta AnimSaves local continuam sendo aceitos.

O Editor de Animação salva KeyframeSequence e CurveAnimation localmente em ServerStorage e usa a referência AnimSaves no rig para acessar esse trabalho. Consulte [Animation Editor](https://create.roblox.com/docs/animation/editor).

## Publicação

O plugin não faz upload próprio. Para publicar, abra o clip salvo no Editor de Animação e use **Publish to Roblox**. A publicação do clip continua no fluxo do Studio, e o ID temporário da prévia não substitui um ID de asset.

## Limites da v1.3

- Não converte código arbitrário, TweenService ou lógica condicionada.
- Não anima deslocamento global da raiz do personagem.
- Não cria markers/eventos de animação.
- Não inclui edição independente de tracks ou keyframes dentro do plugin.
- Rigs customizados podem exigir ajuste na hierarquia e nos nomes de partes/juntas.
- A saída CurveAnimation para AnimationConstraint é experimental e precisa ser verificada; a saída KeyframeSequence é voltada a rigs Motor6D.
- A janela do plugin usa rolagem vertical para caber em docks menores; o cabeçalho permanece visível.
