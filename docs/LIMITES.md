# Limites técnicos e compatibilidade

## Importação segura

O plugin não interpreta a lógica de scripts Luau arbitrários. Scripts podem conter loops, cálculos, condições, TweenService e eventos sem uma lista fixa de poses; executá-los para reconstruir movimentos seria imprevisível.

O POSECODE extrai somente JSON estruturado. Não usa `loadstring` e não executa o conteúdo colado. A entrada tem limite de 256 KB.

## Formatos POSECODE

O importador aceita duas estruturas de dados:

- **V2 (recomendado):** organiza o documento em `metadata`, `rig`, `timeline`, `tracks` e `events`. Cada track declara seu alvo e seus próprios keyframes. Keyframes de tracks diferentes são reunidos em uma timeline comum.
- **V1 (legado):** mantém a estrutura anterior de `rig`, `fps`, `duration` e `frames`, com `joints` por quadro.

O V2 declara o tipo de cada alvo (`Motor6D`, `AnimationConstraint` ou `Bone`) e o plugin confere o tipo com a estrutura real do rig. Os tempos são arredondados para o quadro mais próximo conforme o FPS. Colisões dentro de uma mesma track são recusadas; keyframes de tracks diferentes podem compartilhar o mesmo instante.

No V2, o easing é aplicado por instante global. Se várias tracks tiverem keyframes no mesmo instante, todas precisam usar o mesmo `style` e `direction`. Isso evita resultados ambíguos no pipeline de saída atual.

Veja o [guia completo do POSECODE V2](FORMATO_V2.md) e a [referência V1](FORMATO.md).

## Compatibilidade de rigs

### Motor6D

Rigs que usam apenas `Motor6D` geram uma `KeyframeSequence` com uma árvore de `Pose`. Cada Pose corresponde à peça conectada pela junta.

### Bone e malhas skinned

Rigs com `Bone` geram `CurveAnimation`. A estrutura de pastas acompanha a hierarquia dos Bones, com canais locais `Position` e `Rotation`. Rigs que misturam Motor6D e Bone também seguem a rota de curvas para preservar os dois tipos de canal.

O perfil `CUSTOM` permite importar Models sem Humanoid. Cada nome usado em `joints` precisa ser único dentro do Model selecionado.

A estrutura segue a referência de [CurveAnimation](https://create.roblox.com/docs/reference/engine/classes/CurveAnimation) e [Bone](https://create.roblox.com/docs/reference/engine/classes/Bone), que documenta curvas para canais de Motor6D e Bones.

### AnimationConstraint

A v1.7 mantém a rota experimental para rigs com `AnimationConstraint`, lendo os alvos por `Attachment0` e `Attachment1`. O Roblox usa AnimationConstraint como substituto de Motor6D em novos rigs de avatar, mas a documentação de CurveAnimation não garante explicitamente essa configuração. Por isso, a prévia precisa ser conferida no Studio e o plugin mantém essa saída identificada como experimental.

Não altere os CFrames dos RigAttachments para corrigir o resultado. A documentação de migração recomenda usar as propriedades de Transform e os Attachments conforme o sistema de avatar. Consulte [AnimationConstraint](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint) e a [documentação do Avatar Joint Upgrade](https://devforum.roblox.com/t/avatar-joint-upgrade-aju-phase-2-rollout-updated-migration-recommendations/4656414).

## Rotações e tempo

As rotações POSECODE são expressas em graus locais na ordem XYZ e convertidas para CFrame ou curvas Euler XYZ.

Os tempos são arredondados para o quadro mais próximo segundo FPS. O importador rejeita colisões após o arredondamento. Um quadro neutro é acrescentado em 0 quando necessário e o último quadro é prolongado até duration. O limite de 120 inclui os quadros automáticos; a duração máxima é 15 segundos.

A saída KeyframeSequence aceita Linear, Constant, CubicV2, Elastic e Bounce com direções In, Out ou InOut. A saída CurveAnimation usa Linear, Constant ou CubicV2 com direção InOut. Elastic e Bounce não têm correspondência direta no modelo de curvas e são recusados.

## Eventos de animação

Na saída `KeyframeSequence`, o campo `markers` é convertido para `KeyframeMarker`. A prévia registra `AnimationTrack:GetMarkerReachedSignal()` para cada nome presente e mostra o evento alcançado. Os limites são 8 eventos por quadro, 128 por animação, nomes de até 64 caracteres e valores de até 256 caracteres.

A rota CurveAnimation não recebe markers neste plugin. A importação é recusada quando o rig contém Bone ou AnimationConstraint e o JSON inclui eventos, para evitar perda silenciosa.

Consulte [KeyframeMarker](https://create.roblox.com/docs/reference/engine/classes/KeyframeMarker), [AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack) e [eventos de animação](https://create.roblox.com/docs/animation/events).

## Prévia no Studio

A prévia registra o clip temporariamente com `AnimationClipProvider:RegisterActiveAnimationClip` e usa o ID temporário em um objeto `Animation`. Esse ID serve apenas para teste local no Studio; não é um asset publicado.

O plugin usa `Animator:LoadAnimation()`, não os métodos de carregamento depreciados de Humanoid/AnimationController. Se necessário, cria temporariamente um AnimationController e Animator no Model e remove os objetos temporários ao encerrar. O Animator precisa estar no Workspace antes do carregamento.

Durante a prévia, `Animator:StepAnimations()` avança a avaliação no contexto de plugin. O usuário pode pausar, retomar, parar, alterar a velocidade (0.5×, 1×, 1.5× ou 2×), controlar a repetição, arrastar o cursor e navegar entre quadros. Ao encerrar, o plugin restaura os valores de Transform capturados, inclusive para Bones.

Consulte [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator), [AnimationController](https://create.roblox.com/docs/reference/engine/classes/AnimationController) e [AnimationClipProvider](https://create.roblox.com/docs/reference/engine/classes/AnimationClipProvider).

## Interface v1.8

A janela separa as ações em três abas: **Importar**, **Prévia** e **Rig**. A aba Importar concentra o JSON e a conversão; Prévia contém a timeline e os controles do clip; Rig contém a análise estrutural. O status permanece no rodapé durante a navegação. Os ícones são desenhados com elementos GUI nativos e não exigem IDs de imagem.

## Análise do rig

O botão **Analisar estrutura do rig**, na aba **Rig**, verifica a hierarquia antes da importação e informa o perfil detectado, a quantidade de juntas/Bones e a rota de saída prevista. A validação rejeita raízes ambíguas, ciclos, partes fora do Model selecionado, alvos sem conexão e nomes de canal duplicados.

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

## Limites da v1.8

- Não converte código arbitrário, TweenService ou lógica condicionada.
- Não implementa movimento global da raiz como um canal independente.
- Não oferece edição independente de tracks/keyframes dentro do plugin.
- Markers só são gerados na saída KeyframeSequence.
- A saída CurveAnimation para AnimationConstraint continua experimental.
- Rigs customizados precisam ter uma hierarquia conectada e nomes de canal únicos.
