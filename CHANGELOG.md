# Changelog

## 1.7 · Compatibilidade de rigs e organização

- Adiciona suporte a hierarquias Bone e malhas skinned usando CurveAnimation.
- Permite perfis CUSTOM para Models sem Humanoid.
- Organiza a geração de curvas em uma árvore que acompanha a hierarquia dos nós animados.
- Permite combinar canais Motor6D e Bone na mesma saída CurveAnimation.
- Adiciona **Analisar rig** para conferir perfil, quantidade de elementos e tipo de saída antes da importação.
- Diferencia a rota documentada de Bone da conversão experimental de AnimationConstraint.
- Atualiza os exemplos, a validação e a documentação sem alterar o formato POSECODE v1.

## 1.6 · Eventos e robustez técnica

- Adiciona event markers opcionais em KeyframeSequence, com nome e valor por quadro.
- Exibe os eventos na timeline e informa quando um marker é alcançado durante a prévia.
- Adiciona controle de repetição independente para a prévia.
- Protege toda a inicialização da prévia, incluindo Animator, captura de pose e registro temporário.
- Desconecta os listeners de eventos ao parar ou reiniciar a prévia.
- Faz pré-verificação do volume de saída: 18.000 poses ou 24.000 chaves de curva.
- Mantém o formato POSECODE v1 e a interface clássica da versão anterior.

## 1.5 · Ajustes técnicos e experiência de uso

- Reorganiza a interface para um painel clássico, discreto e consistente.
- Adiciona estados contextuais aos controles e evita ações antes de haver um clip importado.
- Valida juntas incompletas, limita o tamanho do esqueleto e escolhe a raiz de forma determinística.
- Atualiza a seleção do rig somente quando a seleção muda, sem reexaminar o modelo a cada caractere digitado.
- Reduz as atualizações visuais da timeline durante a prévia sem reduzir a avaliação da animação.

## 1.4 · Ajustes de interface e prévia

- Melhora a organização dos controles e a estabilidade da limpeza de clips e da prévia.

## 1.3 · Interface compacta e eficiência

- Reorganiza a janela e reduz trabalho repetido durante a conversão das animações.

## 1.2 · Linha do tempo e reprodução

- Adiciona navegação temporal, pausa, velocidade e navegação entre quadros.
- Inclui geração de KeyframeSequence para Motor6D e uma rota experimental de CurveAnimation.

## 1.1 · Correções do fluxo

- Melhora a prévia, a restauração de Transform, a validação e o salvamento local.

## 0.1.0 · Primeira versão do POSECODE

- Introduz o formato estruturado POSECODE v1 e a conversão inicial para clips do Roblox.
