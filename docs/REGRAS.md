# O que o Sceneprint procura

A versão 0.2.0 tem duas verificações. O objetivo é manter a leitura curta e evitar avisos sem contexto.

## Colisão escondida

Aparece quando uma BasePart tem Transparency maior ou igual a 0.95 e CanCollide ativo.

O plugin ignora personagens e objetos cujo nome, ou o nome de um ancestral, contém termos comuns de uso intencional: Hitbox, Hurtbox, Trigger, Collider, Collision, Boundary, Bounds.

Isso reduz ruído, mas não entende a intenção do projeto. Uma peça chamada WallInvisible ainda pode ser legítima e aparecer na lista.

## Peça sem ancoragem

Aparece uma vez por conjunto físico quando a raiz do conjunto não está ancorada e tem CanCollide ativo.

Personagens são ignorados. Objetos com nomes que indicam mecanismos e partes móveis também são ignorados: Vehicle, Wheel, Door, Gate, Ragdoll, Projectile, Physics e Moving.

Uma porta física, veículo ou objeto empurrável pode ser totalmente intencional. O aviso serve para chamar sua atenção, não para mandar ancorar a peça.

## Escopo

O plugin só percorre BaseParts dentro dos objetos selecionados no Explorer. Selecionar um Model inclui suas peças descendentes. Selecionar vários objetos relacionados não duplica a leitura de peças.

O Workspace inteiro não é analisado automaticamente. A seleção é uma escolha deliberada para manter a ferramenta rápida e previsível.

## Limites

- Não lê o código de Scripts, LocalScripts ou ModuleScripts.
- Não mede FPS, memória ou desempenho real.
- Não muda propriedades nem oferece correção automática.
- Não substitui teste no jogo.
- A filtragem por nomes pode esconder uma peça que merecia revisão.

O desenvolvedor decide o que é intencional.
