# Decisões de implementação

## Parts em vez de Terrain

Cada tile é uma Part ancorada. A altura é aplicada alterando Size.Y e mantendo sua base na mesma posição. Isso permite uma grade de terreno que continua editável no Explorer e no Studio.

## Grade pequena primeiro

O protótipo começa com 16 × 16 tiles de 4 studs. O tamanho é intencionalmente limitado enquanto o fluxo de escultura está sendo avaliado.

## Ferramentas

- **Subir:** aumenta a altura das Parts dentro do raio.
- **Baixar:** reduz a altura sem deixar o tile atravessar a base.
- **Suavizar:** aproxima a altura de cada tile à média de seus vizinhos.
- **Raio:** altera o alcance da pincelada.

A queda gradual do pincel evita que todos os tiles recebam o mesmo deslocamento.

## Undo e redo

Cada criação de base e cada pincelada usa ChangeHistoryService para registrar uma ação que o Studio pode desfazer ou refazer.

## Limites

Uma grade de Parts não tem a mesma continuidade de uma malha. Bordas entre tiles continuarão visíveis e áreas muito grandes podem gerar muitas instâncias. A prioridade é descobrir se essa abordagem tem uma boa sensação de edição antes de investir em recursos mais complexos.
