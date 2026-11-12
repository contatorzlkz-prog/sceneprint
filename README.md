<div align="center">
  <img src="assets/sceneprint-mark.svg" width="54" alt="Marca do Sceneprint" />
  <h1>sceneprint</h1>
  <p>Escultura de terreno com Parts para Roblox Studio.</p>
  <p><sub>ruancr · EM DESENVOLVIMENTO</sub></p>
  <img src="assets/sceneprint-progress.svg" width="220" alt="" />
</div>

![Prévia do Sceneprint](assets/sceneprint-preview.svg)

## A ideia

Um terreno que você consegue esculpir como em um editor 3D, mas construído com **Parts** comuns do Roblox.

A proposta é criar uma base de blocos e trabalhar a altura diretamente na viewport. Sem usar o objeto Terrain do Roblox e sem precisar montar cada peça manualmente.

## O que está em estudo

- **Criar base:** gerar uma área inicial de 16 × 16 tiles sobre uma peça existente.
- **Subir e baixar:** alterar a altura dos tiles com queda gradual ao redor do pincel.
- **Suavizar:** aproximar a altura dos tiles vizinhos para reduzir degraus.
- **Raio do pincel:** controlar quantos tiles recebem cada alteração.
- **Desfazer e refazer:** registrar as alterações na própria história do Studio.

## Estado

**Protótipo em desenvolvimento**

A prioridade é acertar a sensação do pincel, a organização dos blocos e o custo de gerar terreno com Parts antes de adicionar mais ferramentas.

Ainda não é uma versão pronta para produção. O comportamento precisa ser testado no Roblox Studio, principalmente em mapas maiores.

## Arquivos

- [Código do plugin](src/Sceneprint.plugin.lua)
- [Estudo das ferramentas](docs/ESTUDO.md)
- [Decisões de implementação](docs/DECISOES.md)
