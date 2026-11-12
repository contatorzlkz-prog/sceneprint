# Changelog

## 1.1 · Correções e melhorias

- Prévia agora avança a avaliação do Animator no Studio.
- Restaura Transform e CurrentAngle das juntas ao encerrar a prévia.
- Usa RegisterActiveAnimationClip para criar o ID temporário.
- Identifica a raiz pela AssemblyRootPart e valida a árvore Motor6D/AnimationConstraint.
- Reconhece AnimationConstraint em rigs novos e continua aceitando Motor6D em rigs anteriores.
- Alinha tempos ao FPS declarado e rejeita colisões após o arredondamento.
- Insere quadro neutro no início e mantém a última pose até a duração final.
- Suporta transformações esparsas e easing global ou por keyframe.
- Amplia as prioridades até Action4.
- Salva em ServerStorage.RBX_ANIMSAVES, referenciado por AnimSaves.
- Mantém compatibilidade com a pasta AnimSaves antiga e restaura referências se o salvamento falhar.
- Melhora a extração do conteúdo JSON.
- Limita a entrada a 256 KB e rejeita arrays incompletos ou com índices inválidos.
- A versão do plugin passa a ser identificada como 1.1.

## 0.1.0 · Nova direção: Posecode

- Projeto reorientado de escultura de terreno para importação de animações geradas por IA.
- Formato declarativo POSECODE v1 com tempos e transformações por junta.
- Validação de rig, duração, keyframes e nomes das juntas.
- Conversão para KeyframeSequence e hierarquia de Pose.
- Prévia local usando AnimationClipProvider.
- Salvamento local em ServerStorage com referência AnimSaves.
- Documentação dos limites de conversão e do fluxo de publicação do Roblox.

> Protótipo em desenvolvimento; ainda precisa ser validado no Roblox Studio.