# Limites técnicos e publicação

## Por que não converter qualquer script?

Um script de animação pode construir movimentos de várias maneiras: alterar Motor6D.Transform ou AnimationConstraint.Transform, aplicar tweens, calcular trajetórias em loops, reagir a eventos ou depender de variáveis externas. O texto não descreve necessariamente uma lista fixa de poses. Tentar executar e observar um script arbitrário não seria seguro nem reproduzível.

O Posecode trabalha com uma representação declarativa: cada quadro tem um tempo e cada junta tem uma transformação local. O plugin extrai apenas o bloco de dados e **nunca executa o script colado**.

## Hierarquia dos keyframes

O importador cria uma KeyframeSequence. Cada Keyframe contém uma hierarquia de Pose baseada nas conexões de juntas do rig. A Pose nomeada pela peça conectada é colocada como filha da Pose da peça que a controla; sua CFrame é aplicada à junta correspondente.

A v1.1 aceita Motor6D e AnimationConstraint. Para Motor6D, a conexão usa Part0 e Part1. Para AnimationConstraint, usa Attachment0.Parent e Attachment1.Parent. A raiz é identificada pela AssemblyRootPart do rig selecionado. O importador exige uma hierarquia conectada, nomes de peças sem duplicação e correspondência com o tipo R6/R15 declarado no bloco.

As transformações são esparsas: uma junta mantém o último valor definido nos keyframes seguintes até receber uma nova transformação. Juntas que nunca aparecem permanecem neutras.

## Tempo e interpolação

Os tempos são arredondados para o quadro mais próximo de acordo com fps. O plugin rejeita dois keyframes que colidam após esse arredondamento.

Para que o clip tenha exatamente a duração declarada, é criado um quadro neutro inicial quando necessário e uma cópia da última pose no fim, caso o último quadro seja anterior à duração. O limite de 120 quadros considera esses quadros automáticos.

O easing pode ser definido globalmente ou em cada quadro, usando Linear, Constant, CubicV2, Elastic ou Bounce, com direção In, Out ou InOut.

## Prévia

O plugin registra a KeyframeSequence usando AnimationClipProvider:RegisterActiveAnimationClip e carrega o ID temporário em um Animator. Durante a prévia, ele avança a avaliação com Animator:StepAnimations no Heartbeat do Studio. Ao parar ou terminar, encerra a track e restaura os valores originais de Transform das juntas e CurrentAngle quando a junta é Motor6D.

O ID temporário serve apenas para teste local no Studio; não é um asset publicado e não funciona fora dele.

## Salvamento e publicação

O botão de salvar preserva a KeyframeSequence no local de animações do Roblox: ServerStorage.RBX_ANIMSAVES, com uma subpasta para o rig e um ObjectValue chamado AnimSaves no rig apontando para essa pasta. Em rigs que ainda usam uma pasta AnimSaves antiga, o plugin salva nela sem apagar os dados existentes.

A documentação e os anúncios do Roblox descrevem esse modelo de referência: o ObjectValue AnimSaves aponta para a pasta do rig em ServerStorage.RBX_ANIMSAVES. A referência deve ser usada para acessar as animações locais, em vez de depender do nome da pasta. Consulte [Animation Editor](https://create.roblox.com/docs/animation/editor) e [a mudança de estrutura AnimSaves](https://devforum.roblox.com/t/important-changes-for-the-animation-clip-editor-animsaves-folder/2732912).

A publicação continua pelo Editor de Animação: abra a sequência salva, confira o movimento e use Publish to Roblox. O plugin não exibe um botão próprio de upload porque a API pública documentada de AssetService:CreateAssetAsync() lista atualmente Model e Plugin como tipos suportados, não Animation ou KeyframeSequence. Não seria correto prometer um upload direto que a interface pública não oferece. Consulte [AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService).

## Limites da v0.1.1

- Não converte código arbitrário, TweenService ou lógica condicionada.
- Não anima a raiz do personagem nem deslocamento global.
- Não inclui markers/eventos de animação.
- Não tem edição independente de cada track ou keyframe dentro do plugin.
- Não faz upload direto para o catálogo de animações.
- Foca rigs R6/R15 com hierarquia conectada de Motor6D ou AnimationConstraint; rigs customizados podem exigir ajustes.

A v0.1.1 foi revisada estaticamente. Ainda precisa ser executada no Roblox Studio para validar a compatibilidade do preview e a abertura das sequências salvas pelo Editor de Animação.