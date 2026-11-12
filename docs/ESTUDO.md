# Estudo do Sceneprint

## Objetivo

Investigar uma forma de criar superfícies de terreno usando Parts comuns, com uma experiência de edição inspirada em ferramentas de escultura 3D.

O projeto não pretende substituir um editor de malhas. A ideia é experimentar uma superfície em grade, formada por blocos ajustáveis, que possa ser editada direto na viewport do Studio.

## Perguntas que guiam o desenvolvimento

1. Qual o tamanho de tile que deixa o terreno maleável sem criar peças demais?
2. Como fazer o pincel parecer previsível ao subir, baixar e suavizar?
3. Como evitar degraus visuais muito fortes entre tiles vizinhos?
4. Quantas Parts uma área pode ter antes de ficar desconfortável de editar?
5. Como permitir desfazer cada pincelada de forma natural no Studio?

## Protótipo

O primeiro experimento usa uma grade de 16 × 16 Parts. Cada tile mantém uma altura própria, mas todos compartilham a mesma base vertical.

O pincel trabalha com queda gradual: o centro recebe a alteração maior e as bordas recebem menos. A ferramenta de suavização usa a média dos vizinhos próximos.

## Fora do escopo por enquanto

- Importar ou exportar malhas.
- Gerar Terrain nativo do Roblox.
- Pincéis de textura ou pintura.
- Sistemas de cavernas e saliências.
- Geração procedural avançada.
- Promessas de desempenho em mapas grandes.

Essas ideias só entram depois que a edição básica estiver estável.
