# Regras de análise

Sceneprint usa verificações estáticas simples. Ele observa propriedades e relações entre instâncias, não tenta adivinhar a intenção de quem construiu o mapa.

## Como interpretar os níveis

- **Revisar:** a configuração pode ser válida, mas merece uma conferida.
- **Nota:** informação de organização que pode ou não exigir ação.

Nenhum resultado é tratado como erro garantido. Os limites abaixo destacam casos que costumam justificar uma olhada, não padrões universais.

## PHY-01 · Conjunto físico não ancorado

**Detecção:** considera a raiz de cada assembly que não está ancorada e que não pertence a um Model com Humanoid.

**Motivo:** objetos da cena que deveriam ficar parados podem cair, deslizar ou reagir a colisões.

**Falso positivo possível:** portas, veículos, mecanismos, props físicos e objetos que devem ser empurrados.

## COL-01 · Colisão em peça invisível

**Detecção:** **Transparency >= 0.98** junto com **CanCollide == true**.

**Motivo:** uma peça quase invisível pode bloquear o personagem sem deixar isso claro visualmente.

**Falso positivo possível:** paredes invisíveis, limites do mapa, gatilhos com colisão ou estruturas de gameplay. O plugin não altera CanCollide.

## FX-01 · Emissão intensa de partículas

**Detecção:** **ParticleEmitter.Rate > 180**.

**Motivo:** taxas elevadas podem aumentar o trabalho de renderização, principalmente quando vários emissores estão ativos ao mesmo tempo.

**Falso positivo possível:** efeitos curtos, controlados por script, que raramente aparecem juntos. A taxa sozinha não representa o custo completo de um efeito.

## LGT-01 · Luz com alcance amplo

**Detecção:** **Brightness >= 5** e **Range >= 48** para PointLight, SpotLight e SurfaceLight.

**Motivo:** muitas luzes com alcance amplo podem aumentar o custo visual e dificultar o controle da iluminação.

**Falso positivo possível:** cenas noturnas, fachadas, holofotes e cenários que dependem desse alcance.

## AUD-01 · Áudio com alcance longo

**Detecção:** **Sound.RollOffMaxDistance >= 350**.

**Motivo:** sons distantes podem ser ouvidos em áreas maiores do que o necessário.

**Falso positivo possível:** música ambiente, alarmes e sons globais intencionais.

## GEO-01 · Colisão precisa em MeshPart

**Detecção:** **CollisionFidelity == PreciseConvexDecomposition**.

**Motivo:** colisões detalhadas podem custar mais do que alternativas simplificadas, dependendo da malha e da quantidade de objetos.

**Falso positivo possível:** modelos cuja forma de colisão precisa acompanhar detalhes importantes. Compare com Hull e Box antes de mudar.

## UX-01 · Prompt com alcance elevado

**Detecção:** **ProximityPrompt.MaxActivationDistance > 30**.

**Motivo:** o jogador pode ativar a interação de uma distância maior do que a esperada pela composição visual.

**Falso positivo possível:** interações feitas para serem acessíveis de longe ou acionadas em áreas abertas.

## ORG-01 · Pasta vazia

**Detecção:** Folder sem filhos.

**Motivo:** pode ser uma estrutura provisória esquecida durante a organização.

**Falso positivo possível:** pastas reservadas para uso futuro ou preenchidas por scripts durante a execução.

## STR-01 · Workspace grande sem streaming

**Detecção:** a análise está no escopo Workspace, foram encontradas ao menos 2.500 BaseParts e **Workspace.StreamingEnabled** está desativado.

**Motivo:** mapas grandes podem se beneficiar de uma estratégia de carregamento adequada.

**Falso positivo possível:** experiências pequenas em área, mapas compactos com muitas peças ou projetos que já têm outra estratégia de otimização. Ativar streaming muda o comportamento de carregamento e deve ser testado no contexto do jogo.

## Limitações conhecidas

- A análise percorre instâncias descendentes do escopo escolhido.
- O conteúdo dos scripts não é lido.
- A ferramenta não calcula FPS, memória, draw calls ou custo real de rede.
- Não existe correção automática.
- O resultado depende das propriedades disponíveis no momento da leitura.
- Scripts podem criar e modificar objetos durante ou depois da análise.

Para validar desempenho, teste a experiência em dispositivos e condições de rede semelhantes às do público esperado.
