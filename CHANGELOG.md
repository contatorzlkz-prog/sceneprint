# Changelog

## 1.2 · Clips, curva e controles de prévia

- Gera KeyframeSequence para rigs somente com Motor6D.
- Gera CurveAnimation para rigs com AnimationConstraint, com canais Position e Rotation.
- Adiciona navegação por arraste na linha do tempo e leitura do tempo atual.
- Adiciona pausa/retomada, parada e velocidades 0.5×, 1×, 1.5× e 2×.
- Adiciona navegação para o quadro anterior e seguinte.
- Adiciona botão para carregar um exemplo com base no rig selecionado e botão para limpar.
- Padroniza rotações locais em ordem XYZ.
- Calcula tangentes para segmentos cúbicos das CurveAnimations.
- Atualiza a interface para distinguir clips de keyframes e de curvas.
- Identifica a saída CurveAnimation para AnimationConstraint como experimental, pois a documentação pública descreve claramente os canais para Motor6D e Bone.
- Restaura somente Transform, sem tentar escrever CurrentAngle.
- Atualiza a documentação do formato e os limites de interpolação.

## 1.1 · Correções e melhorias

- Prévia com avanço explícito do Animator no modo de edição e restauração da pose ao parar.
- Salvamento seguindo ServerStorage.RBX_ANIMSAVES e o ObjectValue AnimSaves do rig.
- Compatibilidade com referências AnimSaves antigas em formato Folder.
- Quadros alinhados ao FPS declarado, com início e fim garantidos.
- Transformações de juntas mantidas entre keyframes esparsos.
- Easing Linear, Constant, CubicV2, Elastic e Bounce.
- Prioridades Core, Idle, Movement e Action até Action4.
- Identificação de rigs com AnimationConstraint e Motor6D.
- Extração de JSON bruto, cercas de Markdown e string longa POSECODE.
- Limite de entrada de 256 KB e validação de arrays sem lacunas.

## 0.1.0 · Nova direção: Posecode

- Projeto reorientado de escultura de terreno para importação de animações geradas por IA.
- Formato declarativo POSECODE v1 com tempos e transformações por junta.
- Validação de rig, duração, keyframes e nomes das juntas.
- Conversão para KeyframeSequence e hierarquia de Pose.
- Prévia local usando AnimationClipProvider.
- Salvamento local em ServerStorage com referência AnimSaves.
- Documentação dos limites de conversão e do fluxo de publicação do Roblox.

> Protótipo em desenvolvimento.