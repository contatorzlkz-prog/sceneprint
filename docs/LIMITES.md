# Limites técnicos e compatibilidade

## Importação segura

O plugin não interpreta a lógica de scripts Luau arbitrários. Scripts podem conter loops, cálculos, condições, TweenService e eventos sem uma lista fixa de poses; executá-los para reconstruir movimentos seria imprevisível.

O POSECODE extrai somente JSON estruturado. Não usa `loadstring` e não executa o conteúdo colado. A entrada tem limite de 256 KB.

## Formatos POSECODE

O importador aceita duas estruturas de dados:

- **V2 (recomendado):** organiza o documento em `metadata`, `rig`, `timeline`, `tracks` e `events`. Cada track declara seu alvo e seus próprios keyframes. Keyframes de tracks diferentes são reunidos em uma timeline comum.
- **V1 (legado):** mantém a estrutura anterior de `rig`, `fps`, `duration` e `frames`, com `joints` por quadro.

Na versão 2.0, o V2 também pode passar pelo otimizador conservador: somente keyframes intermediários de sequências de três ou mais transformações consecutivas idênticas são removidos; primeiro e último permanecem. A migração V1 → V2 valida o documento legado e o rig antes de gerar o JSON novo.

O V2 declara o tipo de cada alvo (`Motor6D`, `AnimationConstraint` ou `Bone`) e o plugin confere o tipo com a estrutura real do rig. Os tempos são arredondados para o quadro mais próximo conforme o FPS. Colisões dentro de uma mesma track são recusadas; keyframes de tracks diferentes podem compartilhar o mesmo instante.

No V2, o easing é aplicado por instante global. Se várias tracks tiverem keyframes no mesmo instante, todas precisam usar o mesmo `style` e `direction`. Isso evita resultados ambíguos no pipeline de saída atual.

Veja o [guia completo do POSECODE V2](FORMATO_V2.md) e a [referência V1](FORMATO.md).

## Compatibilidade de rigs

O POSECODE 2.1 aceita somente o perfil estrutural **Mesh Rig 2016 (R15)**. A validação exige:

- Um Humanoid com RigType = R15.
- As 15 MeshParts corporais: Head, UpperTorso, LowerTorso, braços, mãos, pernas e pés com os nomes padrão R15.
- HumanoidRootPart como raiz.
- As 15 juntas na hierarquia R15 esperada.
- Todas as juntas do mesmo tipo: 15 AnimationConstraint ou 15 Motor6D.

Rigs R6, rigs genéricos, rigs com Bone, hierarquias avançadas com juntas extras, juntas misturadas e modelos incompletos são recusados. A validação identifica a estrutura; não consegue comprovar a opção exata do Rig Builder que criou um Model com estrutura idêntica.

### AnimationConstraint

Quando o Mesh Rig 2016 usa AnimationConstraint, o plugin lê Attachment0 e Attachment1 para construir a hierarquia de juntas e gera uma CurveAnimation. O Roblox documenta AnimationConstraint.Transform como o transform usado durante a animação e equivalente ao comportamento de Motor6D.Transform quando IsKinematic = true.

A documentação de CurveAnimation descreve curvas em hierarquias de juntas Motor6D/Bone; o uso com AnimationConstraint depende da compatibilidade do pipeline de avatar atual. Por isso, a prévia local no Studio continua sendo a verificação necessária antes de publicar.

### Motor6D

Se a mesma estrutura Mesh Rig 2016 usar 15 Motor6D, o plugin gera uma KeyframeSequence com uma árvore de Pose. O plugin não aceita uma mistura de Motor6D e AnimationConstraint no mesmo rig.

## Rotações e tempo

As rotações POSECODE são expressas em graus na ordem XYZ. Por padrão, rotationSpace = joint usa os eixos locais da junta. Com rotationSpace = character, o plugin converte a rotação a partir dos eixos do HumanoidRootPart para a referência local de cada junta, calculada pelo Attachment0 ou C0. A posição continua local à junta.

Os tempos são arredondados para o quadro mais próximo segundo FPS. O importador rejeita colisões após o arredondamento. Um quadro neutro é acrescentado em 0 quando necessário e o último quadro é prolongado até duration. O limite de 120 inclui os quadros automáticos; a duração máxima é 15 segundos.

A saída KeyframeSequence aceita Linear, Constant, CubicV2, Elastic e Bounce com direções In, Out ou InOut. A saída CurveAnimation usa Linear, Constant ou CubicV2 com direção InOut. Elastic e Bounce não têm correspondência direta no modelo de curvas e são recusados.

## Eventos de animação

Na saída `KeyframeSequence`, o campo `markers` é convertido para `KeyframeMarker`. A prévia registra `AnimationTrack:GetMarkerReachedSignal()` para cada nome presente e mostra o evento alcançado. Os limites são 8 eventos por quadro, 128 por animação, nomes de até 64 caracteres e valores de até 256 caracteres.

A rota CurveAnimation não recebe markers neste plugin. A importação é recusada quando o rig contém Bone ou AnimationConstraint e o JSON inclui eventos, para evitar perda silenciosa.

Consulte [KeyframeMarker](https://create.roblox.com/docs/reference/engine/classes/KeyframeMarker), [AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack) e [eventos de animação](https://create.roblox.com/docs/animation/events).

## Prévia no Studio

A prévia registra o clip temporariamente com `AnimationClipProvider:RegisterAnimationClip` e usa o ID temporário em um objeto `Animation`. Esse ID serve apenas para teste local no Studio; não é um asset publicado.

O plugin usa `Animator:LoadAnimation()`, não os métodos de carregamento depreciados de Humanoid/AnimationController. Se necessário, cria temporariamente um AnimationController e Animator no Model e remove os objetos temporários ao encerrar. O Animator precisa estar no Workspace antes do carregamento.

Durante a prévia, `Animator:StepAnimations()` avança a avaliação no contexto de plugin. O usuário pode pausar, retomar, parar, alterar a velocidade (0.5×, 1×, 1.5× ou 2×), controlar a repetição, arrastar o cursor e navegar entre quadros. Ao encerrar, o plugin restaura os valores de Transform capturados, inclusive para Bones.

Consulte [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator), [AnimationController](https://create.roblox.com/docs/reference/engine/classes/AnimationController) e [AnimationClipProvider](https://create.roblox.com/docs/reference/engine/classes/AnimationClipProvider).

## Interface v2.0

A janela separa as ações em três abas: **Importar**, **Prévia** e **Rig**. A aba Importar concentra o JSON e a conversão; Prévia contém a timeline e os controles do clip; Rig contém a análise estrutural. O status permanece no rodapé durante a navegação. Os ícones são desenhados com elementos GUI nativos e não exigem IDs de imagem.

## Análise do rig

O botão **Analisar estrutura do rig**, na aba **Rig**, valida as 15 MeshParts e as 15 juntas do Mesh Rig 2016, confere a raiz e a árvore corporal e informa a rota de saída prevista. A validação rejeita raízes ambíguas, ciclos, partes fora do Model selecionado, alvos sem conexão e nomes de canal duplicados.

## Limites de processamento

- Entrada: 256 KB.
- Quadros normalizados: 120.
- Duração: 15 segundos.
- Juntas e Bones: 256 no total.
- Saída KeyframeSequence: até 18.000 instâncias Pose estimadas.
- Saída CurveAnimation: até 24.000 chaves de curva estimadas.
- Markers: até 8 por quadro e 128 por animação.

A estimativa do tamanho da saída é feita antes da criação das instâncias para evitar importar clips excessivamente grandes.

## Salvamento e publicação

O botão **Salvar clip no Studio** preserva o clip em `ServerStorage.RBX_ANIMSAVES`, com uma subpasta para o rig e um `ObjectValue` chamado `AnimSaves` apontando para ela. O plugin também reconhece rigs que já possuem uma pasta AnimSaves local.

Para publicar, abra o clip no Editor de Animação e use **Publish to Roblox**. O ID temporário da prévia não substitui um ID de asset.

## Limites da v2.1

- Não converte código arbitrário, TweenService ou lógica condicionada.
- Não implementa movimento global da raiz como um canal independente.
- Não oferece edição independente de tracks/keyframes dentro do plugin.
- Markers só são gerados na saída KeyframeSequence.
- A prévia com AnimationConstraint precisa ser conferida no Studio antes da publicação.
- O plugin não aceita rigs fora da assinatura estrutural do Mesh Rig 2016.
