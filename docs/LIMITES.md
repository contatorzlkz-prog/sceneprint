# Limites técnicos e publicação

## Por que não converter qualquer script?

Um script de animação pode construir movimentos de várias maneiras: alterar Motor6D.Transform, aplicar tweens, calcular trajetórias em loops, reagir a eventos ou depender de variáveis externas. O texto não descreve necessariamente uma lista fixa de poses. Tentar executar e observar um script arbitrário também seria inseguro e não daria um resultado reproduzível.

O Posecode trabalha com uma representação declarativa: cada quadro tem um tempo e cada junta tem uma transformação local. O plugin extrai apenas o bloco de dados e **nunca executa o script colado**.

## O que vira keyframe

O importador cria uma KeyframeSequence. Cada Keyframe guarda um conjunto hierárquico de Pose; os nomes das poses correspondem às peças controladas pelas juntas do rig. Posição é um offset local em studs; rotação é informada em graus e convertida para CFrame.

O esqueleto é lido do rig selecionado. O importador exige uma hierarquia conectada de Motor6D, nomes de peças sem duplicação e correspondência com o tipo R6/R15 declarado no bloco.

## Prévia

Para reproduzir uma sequência ainda não publicada, o plugin registra a KeyframeSequence no AnimationClipProvider e usa o ID temporário retornado para tocar uma animação no rig selecionado. Esse ID serve para prévia local no Studio; não é um asset publicado e não funciona fora dele.

## Salvamento e publicação

O botão **Salvar keyframes no Studio** armazena a KeyframeSequence em ServerStorage e cria/atualiza a referência AnimSaves no rig para manter os dados locais organizados.

A publicação final permanece no fluxo do próprio Editor de Animação: selecione o rig, abra a sequência salva, confira o movimento e use **Publicar no Roblox**. O plugin não exibe um botão próprio de upload porque a API pública documentada de AssetService:CreateAssetAsync() não lista Animation/KeyframeSequence entre os tipos aceitos. Não seria correto prometer um upload direto que a interface pública não oferece.

## Fora da v1

- Converter código arbitrário, TweenService ou lógica condicionada.
- Movimento de raiz e deslocamento global do personagem.
- Markers, eventos e curvas avançadas.
- Edição independente de cada track ou de cada keyframe dentro do plugin.
- Upload direto para o catálogo de animações.
- Compatibilidade garantida com rigs customizados fora da estrutura R6/R15.

A primeira prioridade é validar importação, hierarquia das poses, prévia e salvamento no Studio antes de ampliar o formato.