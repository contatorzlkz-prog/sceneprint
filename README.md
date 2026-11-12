<div align="center">
  <img src="assets/posecode-mark.svg" width="42" alt="POSECODE" />
  <h1>POSECODE</h1>
  <p>Importador de animações estruturadas para Roblox Studio.</p>
  <p><sub>ruancr · v1.8 · EM DESENVOLVIMENTO</sub></p>
</div>

![Interface do POSECODE v1.8](assets/posecode-preview.svg)

## Sobre

O POSECODE converte dados no formato POSECODE v1 em clips editáveis no Roblox Studio. O importador valida a hierarquia do rig, converte keyframes, oferece prévia local e salva o resultado no fluxo de animação do Studio.

O conteúdo colado nunca é executado. A entrada é JSON estruturado, diretamente ou dentro de uma variável `POSECODE`.

## Interface v1.8

A janela foi dividida em três áreas de navegação:

- **Importar:** editor JSON, importação, exemplo e limpeza.
- **Prévia:** timeline, reprodução, pausa, velocidade, repetição, navegação por quadros e salvamento.
- **Rig:** análise isolada da estrutura e da rota de saída.

Ao importar um clip com sucesso, o painel abre automaticamente **Prévia**. Os ícones de navegação são desenhados com elementos GUI nativos do plugin; não dependem de IDs de imagem ou uploads externos. O SVG de referência está em [posecode-icons.svg](assets/icons/posecode-icons.svg).

## Compatibilidade

- **Motor6D:** gera `KeyframeSequence`.
- **Bone:** gera `CurveAnimation`, incluindo esqueletos de malhas skinned.
- **Motor6D + Bone:** usa a hierarquia de curvas para manter os dois tipos no mesmo clip.
- **AnimationConstraint:** possui uma rota `CurveAnimation` experimental; confira o resultado no Studio.
- **CUSTOM:** permite descrever rigs sem `Humanoid`.

## Como usar

1. Selecione o Model do rig no Studio.
2. Abra **Rig** e use **Analisar estrutura do rig** para conferir a estrutura e a rota de saída.
3. Abra **Importar**, gere os dados no [formato POSECODE v1](docs/FORMATO.md) e cole o JSON.
4. Selecione **Importar clip**. Após a conversão, o POSECODE abre **Prévia** automaticamente.
5. Confira a timeline e a animação; use os controles de reprodução e salve o clip no Studio.
6. Publique pelo Editor de Animação.

## Instalação

1. Habilite **Plugin Debugging Enabled** nas configurações do Roblox Studio.
2. Crie um Script em `ServerStorage` e cole o conteúdo de [Posecode.plugin.lua](src/Posecode.plugin.lua).
3. Com o Script selecionado no Explorer, use **Plugins → Save as Local Plugin**.
4. Depois de salvar, remova o Script original de `ServerStorage` e use a cópia do plugin em `PluginDebugService`.

Veja a documentação oficial de [Studio plugins](https://create.roblox.com/docs/studio/plugins).

## Limites

- Não interpreta scripts Luau arbitrários, TweenService ou lógica condicionada.
- Entrada máxima de 256 KB, até 120 quadros normalizados, duração máxima de 15 segundos e 256 juntas/Bones.
- Eventos: até 8 por quadro e 128 por animação; disponíveis apenas na saída `KeyframeSequence`.
- Orçamento de saída: 18.000 poses ou 24.000 chaves de curva.
- O nome de cada junta ou Bone usado no JSON precisa ser único dentro do rig.
- Movimento global da raiz e edição independente de tracks ainda não fazem parte do plugin.
- A prévia usa um ID temporário válido apenas no Studio. A publicação continua pelo Editor de Animação.

## Documentação

- [Formato POSECODE v1](docs/FORMATO.md)
- [Limites técnicos e publicação](docs/LIMITES.md)
- [Código do plugin](src/Posecode.plugin.lua)
- [Histórico de versões](CHANGELOG.md)
