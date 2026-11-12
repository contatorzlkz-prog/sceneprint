# Changelog

## 1.7 · Compatibilidade de rigs e organização

- Adiciona suporte a hierarquias **Bone** e malhas skinned usando `CurveAnimation`.
- Permite perfis `CUSTOM` para Models sem `Humanoid`.
- Organiza a geração de curvas em uma árvore que acompanha a hierarquia dos nós animados.
- Permite combinar canais `Motor6D` e `Bone` na mesma saída `CurveAnimation`.
- Adiciona **Analisar rig** para conferir perfil, quantidade de elementos e tipo de saída antes da importação.
- Diferencia a rota documentada de `Bone` da conversão experimental de `AnimationConstraint`.
- Atualiza os exemplos, a validação e a documentação sem alterar o formato POSECODE v1.

## 1.6 · Eventos e robustez técnica

- Adiciona **event markers** opcionais em `KeyframeSequence`, com nome e valor por quadro.
- Exibe os eventos na timeline e informa quando um marker é alcançado durante a prévia.
- Adiciona controle de repetição independente para a prévia.
- Protege toda a inicialização da prévia, incluindo `Animator`, captura de pose e registro temporário.
- Desconecta os listeners de eventos ao parar ou reiniciar a prévia.
- Faz pré-verificação do volume de saída: 18.000 poses ou 24.000 chaves de curva.
- Mantém o formato POSECODE v1 e a interface clássica da versão anterior.

## 1.5 · Ajustes técnicos e experiência de uso

- Reorganiza a interface para um painel clássico, discreto e consistente.
- Adiciona estados contextuais aos controles e evita ações antes de haver um clip importado.
- Valida juntas incompletas, limita o tamanho do esqueleto e escolhe a raiz de forma determinística.
- Atualiza a seleção do rig somente quando a seleção muda, sem reexaminar o modelo a cada caractere digitado.
- Reduz as atualizações visuais da timeline durante a prévia sem reduzir a avaliação da animação.
- Mantém o formato POSECODE v1.

## 1.4 · Ícones vetoriais e robustez da prévia

- Cria um conjunto enxuto de ícones SVG em `assets/icons/posecode-icons.svg`.
- Desenha os ícones dentro do plugin com elementos nativos da GUI do Roblox, sem depender de uploads de imagens ou IDs externos.
- Atualiza os títulos de seção e os botões de importar, exemplo, limpar, reproduzir, pausar, parar, navegar e salvar.
- Centraliza os ícones dos controles compactos e evita sobreposição entre o título da timeline e o resumo do clip.
- Corrige a exibição do tempo total quando a timeline é limpa.
- Protege a criação de `KeyframeSequence` e `CurveAnimation`, destruindo o objeto parcialmente criado quando ocorre uma falha.
- Registra `Animation` e `AnimationTrack` durante a criação para que a limpeza também funcione se `LoadAnimation` ou `Play` falhar.
- Encerra e restaura a prévia quando o rig sai do `Workspace` ou quando o painel é ocultado.
- Mantém POSECODE v1 compatível; a versão 1.4 é a versão do plugin.

## 1.3 · Interface compacta e conversão eficiente

- Reorganiza a janela em cabeçalho fixo e conteúdo com rolagem, com tamanho mínimo menor.
- Reduz a altura do editor de entrada e elimina painéis grandes desnecessários.
- Substitui rótulos longos nos controles de prévia por símbolos de reprodução, pausa e parada.
- Adiciona identidade visual mais clara, estado do plugin por indicador de cor e hover discreto nos botões.
- Calcula cada transformação local uma vez por junta/quadro e reutiliza o cache na geração dos clips.
- Calcula Euler XYZ uma vez por junta/quadro nas curvas, em vez de decompor a rotação novamente para cada eixo.
- Valida os três componentes dos vetores sem criar tabelas temporárias.
- Mantém o formato de dados POSECODE v1 compatível; a versão 1.3 é a versão do plugin, não do JSON.

## 1.2 · Clips, curva e controles de prévia

- Gera `KeyframeSequence` para rigs somente com `Motor6D`.
- Gera `CurveAnimation` para rigs com `AnimationConstraint`, com canais Position e Rotation.
- Adiciona navegação por arraste na linha do tempo e leitura do tempo atual.
- Adiciona pausa/retomada, parada e velocidades 0.5×, 1×, 1.5× e 2×.
- Adiciona navegação para o quadro anterior e seguinte.
- Adiciona botão para carregar um exemplo com base no rig selecionado e botão para limpar.
- Padroniza rotações locais em ordem XYZ.
- Calcula tangentes para segmentos cúbicos das `CurveAnimation`.
- Atualiza a interface para distinguir clips de keyframes e de curvas.
- Atualiza a documentação do formato e os limites de interpolação.

## 1.1 · Correções e melhorias

- Faz a prévia avançar explicitamente a avaliação do `Animator` no Studio.
- Restaura `Transform` e `CurrentAngle` das juntas ao encerrar a prévia.
- Usa `RegisterActiveAnimationClip` para criar o ID temporário.
- Identifica a raiz pela `AssemblyRootPart` e valida a árvore `Motor6D`/`AnimationConstraint`.
- Reconhece `AnimationConstraint` em rigs novos e continua aceitando `Motor6D` em rigs anteriores.
- Alinha os tempos ao FPS declarado e rejeita colisões após o arredondamento.
- Insere um quadro neutro no início e mantém a última pose até a duração final.
- Suporta transformações esparsas e easing global ou por keyframe.
- Amplia as prioridades até `Action4`.
- Salva em `ServerStorage.RBX_ANIMSAVES`, referenciado por `AnimSaves`.
- Mantém compatibilidade com a pasta `AnimSaves` antiga e restaura referências se o salvamento falhar.
- Melhora a extração do conteúdo JSON.
- Limita a entrada a 256 KB e rejeita arrays incompletos ou com índices inválidos.

## 0.1.0 · Nova direção: POSECODE

- Reorienta o projeto de escultura de terreno para importação de animações geradas por IA.
- Introduz o formato declarativo POSECODE v1, com tempos e transformações por junta.
- Valida rig, duração, keyframes e nomes das juntas.
- Converte os dados para `KeyframeSequence` e hierarquia de `Pose`.
- Adiciona prévia local usando `AnimationClipProvider`.
- Adiciona salvamento local em `ServerStorage`, com referência `AnimSaves`.
- Documenta os limites de conversão e o fluxo de publicação do Roblox.
