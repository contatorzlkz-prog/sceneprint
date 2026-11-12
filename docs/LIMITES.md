# Limites técnicos e publicação

## Importação segura

O plugin não tenta interpretar a lógica de scripts Luau arbitrários. Um script pode conter loops, cálculos, condições, TweenService e eventos, sem uma lista fixa de poses. Executá-lo para tentar reconstruir os movimentos seria imprevisível.

O Posecode extrai somente o JSON estruturado de POSECODE v1. Não usa loadstring e não executa o conteúdo colado. A entrada tem limite de 256 KB e validação de arrays, tempos, juntas e transformações.

## Formatos de saída

### Rigs com Motor6D

Gera uma KeyframeSequence. Cada Keyframe contém uma árvore hierárquica de Pose, na qual o nome da Pose corresponde à peça conectada pela junta. O CFrame local da Pose é aplicado ao Motor6D correspondente.

### Rigs com AnimationConstraint

A v1.6 gera uma CurveAnimation como saída experimental. A estrutura usa pastas hierárquicas com Position (Vector3Curve) e Rotation (EulerRotationCurve) para as peças conectadas pelas constraints, usando Attachment0.Parent e Attachment1.Parent. A hierarquia começa no HumanoidRootPart ou PrimaryPart do rig, sem substituir essa raiz pela raiz física da montagem.

**Compatibilidade não garantida:** a referência oficial de CurveAnimation descreve os canais Position/Rotation explicitamente para Motor6D e Bone. AnimationConstraint é a substituição de Motor6D nos rigs de avatar atualizados e possui sua própria propriedade Transform controlada pelo sistema de animação, mas a documentação pública não confirma de forma explícita que a hierarquia CurveAnimation gerada pelo Posecode será aplicada a todas as configurações de AnimationConstraint. Por isso, o plugin marca essa saída como experimental e o resultado precisa ser conferido no Studio. Consulte [CurveAnimation](https://create.roblox.com/docs/reference/engine/classes/CurveAnimation), [AnimationConstraint](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint) e [a migração de Avatar Joint Upgrade](https://devforum.roblox.com/t/avatar-joint-upgrade-aju-phase-2-rollout-updated-migration-recommendations/4656414).

## Rotações e tempo

As rotações de POSECODE são expressas em graus locais na ordem XYZ e convertidas para CFrame/curvas Euler XYZ.

Os tempos são arredondados para o quadro mais próximo segundo fps. O importador rejeita colisões depois do arredondamento. Um quadro neutro é acrescentado em 0 quando necessário e o último quadro é prolongado até duration. O limite de 120 inclui quadros criados automaticamente; a duração máxima é 15 segundos.

A saída KeyframeSequence aceita Linear, Constant, CubicV2, Elastic e Bounce com direções In, Out ou InOut. A saída CurveAnimation usa Linear, Constant ou Cubic; CubicV2 é convertido para segmentos cúbicos com tangentes estimadas entre os quadros vizinhos e direção InOut. Elastic e Bounce não possuem correspondência direta no modelo de interpolação das curvas e são recusados nesse caminho.

## Eventos de animação

Na saída `KeyframeSequence`, o campo opcional `markers` de cada quadro é convertido para instâncias `KeyframeMarker`. A prévia registra `AnimationTrack:GetMarkerReachedSignal()` para os nomes presentes no clip e mostra o último evento recebido no status. A timeline diferencia os pontos de evento dos keyframes comuns.

A saída experimental `CurveAnimation` não recebe esses marcadores; a importação é recusada quando um rig de curvas contém eventos. Os limites são 8 eventos por quadro, 128 por animação, nomes de até 64 caracteres e valores de até 256 caracteres. Consulte [Keyframe](https://create.roblox.com/docs/reference/engine/classes/Keyframe), [KeyframeMarker](https://create.roblox.com/docs/reference/engine/classes/KeyframeMarker) e [AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack).

## Prévia e navegação

O plugin registra o clip temporariamente com AnimationClipProvider:RegisterActiveAnimationClip e carrega o ID local em um Animator. O ID temporário não é um asset publicado e não funciona fora do Studio.

Durante a prévia, Animator:StepAnimations avança a avaliação. O plugin permite pausar/retomar, parar, alterar a velocidade (0.5×, 1×, 1.5× ou 2×), ativar repetição independente do valor salvo, arrastar o cursor e saltar para o quadro anterior ou seguinte. A posição é atualizada por AnimationTrack.TimePosition, que só pode ser alterada enquanto a track está tocando. Ao parar, o plugin encerra a track e restaura os valores originais de Transform das juntas.

Consulte [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator), [AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack) e [AnimationClipProvider](https://create.roblox.com/docs/reference/engine/classes/AnimationClipProvider).

## Eficiência interna

A validação calcula cada transformação local uma vez por junta em cada quadro e armazena o resultado para reutilização na geração do clip. Na saída CurveAnimation, a decomposição Euler XYZ também é feita uma vez por junta/quadro, em vez de ser repetida separadamente para cada eixo. A validação dos vetores não cria tabelas temporárias para conferir os três componentes.

## Limites de processamento

Antes de criar instâncias, o importador estima o tamanho da saída. A geração de KeyframeSequence é limitada a 18.000 instâncias Pose estimadas; a geração de CurveAnimation é limitada a 24.000 chaves de curva estimadas. O esqueleto continua limitado a 256 juntas e cada animação a 120 quadros normalizados. Esses limites evitam que uma combinação de rig e quadros produza uma quantidade excessiva de objetos no Studio.

A inicialização completa da prévia é protegida por tratamento de erros, incluindo a busca/criação de Animator, a captura da pose original, o registro temporário do clip e a conexão dos eventos. Ao encerrar, o plugin desconecta os listeners de markers e restaura a pose capturada.

## Salvamento

O botão **Salvar Clip no Studio** armazena o clip em ServerStorage.RBX_ANIMSAVES, com uma subpasta para o rig e um ObjectValue AnimSaves no próprio rig apontando para essa pasta. Rigs que já possuem uma pasta AnimSaves local continuam sendo aceitos.

O Editor de Animação salva KeyframeSequence e CurveAnimation localmente em ServerStorage e usa a referência AnimSaves no rig para acessar esse trabalho. Consulte [Animation Editor](https://create.roblox.com/docs/animation/editor).

## Publicação

O plugin não faz upload próprio. Para publicar, abra o clip salvo no Editor de Animação e use **Publish to Roblox**. A publicação do clip continua no fluxo do Studio, e o ID temporário da prévia não substitui um ID de asset.

## Limites da v1.6

- Não converte código arbitrário, TweenService ou lógica condicionada.
- Não anima deslocamento global da raiz do personagem.
- Eventos são aceitos apenas no caminho KeyframeSequence para rigs Motor6D; CurveAnimation experimental não aceita markers.
- Não inclui edição independente de tracks ou keyframes dentro do plugin.
- Rigs customizados podem exigir ajuste na hierarquia e nos nomes de partes/juntas.
- A saída CurveAnimation para AnimationConstraint é experimental e precisa ser verificada; a saída KeyframeSequence é voltada a rigs Motor6D.
- O esqueleto é limitado a 256 juntas; a saída também respeita os orçamentos de 18.000 poses ou 24.000 chaves de curva.
- A interface usa um painel compacto com controles contextuais; ações de prévia e salvamento permanecem indisponíveis até que um clip seja importado.
