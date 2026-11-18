# Changelog

## 3.2 · Abertura corrigida e interpretação em camadas

- Conecta o clique da barra Plugins ao estado visível da janela POSECODE e sincroniza o indicador ativo do botão.
- Corrige a ausência do handler de abertura que fazia o botão da barra não apresentar o painel.
- Troca a escolha única de movimento por interpretação semântica de uma ação principal e um gesto secundário.
- Permite combinações como caminhar enquanto acena, correr enquanto aponta e caminhar enquanto bate palmas.
- Adiciona seleção de braço para gestos, controles de cabeça, travas de braços/cabeça, lado da marcha mancando e espelhamento.
- Adiciona cinco perfis de atitude: assustado, tímido, determinado, arrogante e confuso.
- Normaliza sinônimos com acentos antes da comparação e escolhe aliases por posição e especificidade.
- Sincroniza a fase do gesto secundário com a ação principal para manter continuidade.
- Melhora as sugestões rápidas com composições que exercitam os novos recursos.
- Documenta a diferença entre interpretação semântica local e geração por modelo de linguagem externo.

## 3.1 · Gerador procedural exclusivo

- Substitui a interface em abas por um painel único, compacto e centrado na geração.
- Remove os caminhos de colar JSON, importar clipes, migrar V1 e carregar exemplos.
- O fluxo de usuário passa a ser: rig selecionado → descrição → geração → prévia → salvar/aprovar referência.
- Adiciona uma faixa visual MOTION → BLEND → POSE para mostrar a composição procedural.
- Expande o catálogo para 20 bases, incluindo crawl, strafe, backpedal, stretch e shrug.
- Expande o vocabulário de atitudes e reforça a recusa de descrições sem movimento-base reconhecido.
- Amplia a biblioteca local para 48 referências aprovadas.
- Melhora as fases de backpedal e strafe e mantém a geração limitada ao Mesh Rig 2016 selecionado.
- Continua usando internamente o pipeline validado de poses, prévia e salvamento do Studio.

