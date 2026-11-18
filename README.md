<div align="center">
  <img src="assets/posecode-mark.svg" width="42" alt="POSECODE" />
  <h1>POSECODE</h1>
  <p>Gerador procedural de animações para Roblox Studio.</p>
  <p><sub>ruancr · v3.1 · MESH RIG 2016</sub></p>
</div>

![Interface do POSECODE 3.1](assets/posecode-preview.svg)

## O que é

O POSECODE é um gerador procedural de animações. Você descreve o movimento que deseja — por exemplo, `walk cansado`, `backpedal confiante`, `wave friendly` ou `dance playful` — e o motor constrói uma sequência de poses para as 15 juntas do Mesh Rig 2016.

Ele não é um transcritor de scripts, não pede JSON e não executa código colado. A animação nasce de perfis de movimento, parâmetros de locomoção, camadas de atitude e variações determinísticas.

## Motor procedural

- **20 movimentos-base:** walk, run, sprint, sneak, tiptoe, march, limp, idle, wave, salute, jump, bow, point, clap, dance, crawl, strafe, backpedal, stretch e shrug.
- **17 perfis de atitude:** 16 atitudes reconhecidas mais o estado neutro.
- **16,32 milhões de combinações paramétricas teóricas:** combinações de movimento, velocidade, intensidade, passada, braços, postura, balanço, direção, interpolação e atitude. Não são arquivos prontos nem uma promessa de 16,32 milhões de movimentos visualmente únicos.
- **Geração local:** não depende de API externa, chave, modelo de linguagem ou conexão com a internet.
- **Variações:** muda a semente mantendo a descrição e os parâmetros principais.
- **Biblioteca local:** guarda até 48 receitas aprovadas para servirem como referência em gerações semelhantes.

## Interface

O fluxo é único e compacto:

1. Selecione o Mesh Rig 2016 no Explorer.
2. Escreva uma descrição ou escolha uma sugestão rápida.
3. Clique em **Gerar animação**. O plugin valida o rig, sintetiza as poses e inicia a prévia.
4. Ajuste a reprodução, peça outra variação ou guarde uma referência aprovada.
5. Use **Salvar no Studio** para guardar o clip em AnimSaves.

A barra visual MOTION → BLEND → POSE representa as etapas internas: padrão-base, combinação de modificadores e saída nas juntas. É uma referência de organização de grafos de animação, não um editor de nós independente.

## Instalação

1. Abra o Roblox Studio e habilite **Plugin Debugging Enabled** nas configurações.
2. Crie um Script em `ServerStorage` e cole o conteúdo de [Posecode.plugin.lua](src/Posecode.plugin.lua).
3. Selecione o Script no Explorer e use **Plugins → Save as Local Plugin**.
4. Remova o Script de instalação de `ServerStorage` e abra o plugin salvo em **Plugins → POSECODE**.

O plugin foi direcionado exclusivamente ao perfil estrutural Mesh Rig 2016 (R15). O rig precisa estar selecionado e dentro de `Workspace` para gerar e pré-visualizar.

## Escopo e limites

- A geração é procedural e baseada em vocabulário conhecido; não é um modelo de IA que entende qualquer frase livre.
- O plugin reconhece 20 movimentos-base e modificadores documentados no [guia do gerador](docs/GERADOR.md).
- R6, rigs genéricos, rigs de Bone, modelos incompletos e hierarquias diferentes do Mesh Rig 2016 são recusados.
- Gestos de mão usam as juntas existentes; não há animação independente de dedos.
- A prévia é local ao Studio. Para publicar, use o Editor de Animação do Roblox.
- A aparência depende do rig e da orientação local de suas juntas. Sempre confira a prévia antes de publicar.

## Arquivos

- [Código do plugin](src/Posecode.plugin.lua)
- [Guia de movimentos e vocabulário](docs/GERADOR.md)
- [Histórico de versões](CHANGELOG.md)
