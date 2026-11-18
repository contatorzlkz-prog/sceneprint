# POSECODE 3.2 — guia do gerador

O POSECODE recebe uma descrição curta e extrai quatro grupos de intenção: ação principal, gesto secundário opcional, atitude e modificadores direcionais. O motor usa esses parâmetros para gerar poses diretamente para o Mesh Rig 2016.

## 1. Ações principais

| Movimento | Termos reconhecidos |
|---|---|
| Walk | `walk`, `walking`, `andar`, `andando`, `caminhar`, `caminhada`, `passo natural` |
| Run | `run`, `running`, `jog`, `jogging`, `correr`, `correndo`, `corrida`, `trotar`, `trote` |
| Sprint | `sprint`, `sprinting`, `sprintar`, `corrida rápida`, `correr rápido`, `disparar correndo` |
| Sneak | `sneak`, `stealth`, `agachar`, `agachado`, `furtivo`, `esgueirar`, `andar sem fazer barulho` |
| Tiptoe | `tiptoe`, `na ponta`, `ponta dos pés`, `andar na ponta dos pés` |
| March | `march`, `marchar`, `marcha`, `passo militar`, `desfilar` |
| Limp | `limp`, `limping`, `mancar`, `mancando`, `andar mancando` |
| Idle | `idle`, `standing idle`, `still`, `stand`, `parado`, `respirando`, `em pé`, `ficar parado` |
| Wave | `wave`, `waving`, `acenar`, `aceno`, `tchau`, `dar tchau`, `acenar com a mão` |
| Salute | `salute`, `saluting`, `continência`, `prestar continência`, `saudação militar` |
| Jump | `jump`, `jumping`, `pular`, `pulando`, `salto`, `saltando` |
| Bow | `bow`, `bowing`, `reverência`, `reverenciar`, `curvar o corpo` |
| Point | `point`, `pointing`, `apontar`, `apontando`, `aponta` |
| Clap | `clap`, `clapping`, `bater palmas`, `aplaudir`, `palmas` |
| Dance | `dance`, `dancing`, `dançar`, `dançando`, `dança` |
| Crawl | `crawl`, `crawling`, `rastejar`, `rastejando`, `engatinhar` |
| Strafe | `strafe`, `side step`, `sideways walk`, `andar de lado`, `passo lateral` |
| Backpedal | `backpedal`, `walk backwards`, `andar de costas`, `andar para trás`, `recuar andando` |
| Stretch | `stretch`, `stretching`, `alongar`, `alongando`, `espreguiçar` |
| Shrug | `shrug`, `shrugging`, `dar de ombros`, `encolher os ombros` |

O interpretador prioriza uma ação de locomoção quando ela aparece junto de um gesto. Quando não existe locomoção, usa o primeiro gesto identificado como ação principal.

## 2. Combinar movimentos

Use duas ações na mesma descrição: uma principal e um gesto secundário. O motor mantém a cadência da ação principal e aplica o gesto em uma camada separada.

| Descrição | Resultado pretendido |
|---|---|
| `walk + wave` | Caminha enquanto acena |
| `walk and wave with left arm` | Caminha e acena com o braço esquerdo |
| `run + point` | Corre enquanto aponta |
| `sneak + wave` | Move-se furtivamente enquanto acena |
| `walk + clap` | Caminha e bate palmas |
| `wave + point` | Combina dois gestos sem ciclo de locomoção |
| `idle + shrug` | Fica parado e dá de ombros |

No máximo um gesto secundário é aplicado. Descrições como “andar, acenar, bater palmas e depois apontar” não viram uma sequência de quatro etapas; escolha duas ações ou gere cada etapa separadamente.

## 3. Atitudes

O motor tem 21 perfis de atitude e um estado neutro:

- **Cansado:** `cansado`, `exausto`, `tired`
- **Feliz:** `feliz`, `alegre`, `animado`, `happy`, `friendly`, `energetic`
- **Confiante:** `confiante`, `seguro`, `confident`
- **Irritado:** `bravo`, `irritado`, `furioso`, `angry`, `aggressive`
- **Pesado:** `pesado`, `heavy`
- **Triste:** `triste`, `abatido`, `sad`
- **Robótico:** `robótico`, `mecânico`, `robotic`, `mechanical`
- **Exagerado:** `exagerado`, `over the top`
- **Casual:** `casual`, `natural`, `normal`
- **Sonolento:** `sonolento`, `com sono`, `sleepy`
- **Nervoso:** `nervoso`, `ansioso`, `nervous`, `anxious`
- **Orgulhoso:** `orgulhoso`, `peito estufado`, `proud`
- **Curioso:** `curioso`, `intrigado`, `curious`
- **Brincalhão:** `brincalhão`, `divertido`, `playful`
- **Sério:** `sério`, `formal`, `serious`
- **Relaxado:** `relaxado`, `tranquilo`, `calmo`, `relaxed`
- **Assustado:** `assustado`, `com medo`, `scared`, `fearful`
- **Tímido:** `tímido`, `envergonhado`, `shy`
- **Determinado:** `determinado`, `decidido`, `determined`
- **Arrogante:** `arrogante`, `convencido`, `arrogant`
- **Confuso:** `confuso`, `perdido`, `sem entender`, `confused`

Exemplos: `walk cansado`, `run confiante`, `sneak nervoso`, `wave friendly`, `dance brincalhão`, `walk assustado`.

## 4. Modificadores

### Ritmo e amplitude
- **Velocidade:** `muito devagar`, `devagar`, `rápido`, `muito rápido`.
- **Intensidade:** `sutil`, `leve`, `forte`, `intenso`, `extremo`.
- **Passada:** `passos muito curtos`, `passos curtos`, `passo longo`, `passada larga`.
- **Braços:** `braços soltos`, `braços suaves`, `braços fortes`, `braços amplos`.
- **Postura:** `postura ereta`, `postura neutra`, `inclinado`, `muito curvado`.
- **Balanço:** `sem quicar`, `pouco quique`, `saltitante`.

### Direção e partes do corpo
- **Braço do gesto:** `braço esquerdo`, `braço direito`, `ambos os braços`.
- **Cabeça:** `olhar para esquerda`, `olhar para direita`, `olhar para cima`, `olhar para baixo`.
- **Cabeça em movimento:** `balançar a cabeça` (não) ou `fazer que sim` / `nod` (sim).
- **Travar partes:** `braços parados` / `arms still`; `cabeça parada` / `head still`.
- **Assimetria:** `perna esquerda` ou `perna direita` para o movimento `limp`.
- **Espelhar:** `espelhado`, `mirror` ou `invertido`.
- **Interpolação:** `robótico` / `linear`, `travado` / `constant`, `suave` / `smooth`.
- **Direção de marcha:** `de costas`, `para trás`, `backwards` ou `recuando`.

Exemplos completos:

```text
walk cansado, passos curtos, braços soltos
run determinado, passos largos, olhando para frente
walk + wave com o braço esquerdo, cabeça parada
sneak assustado, olhando para direita, sem quicar
limp com a perna direita, lento e muito curvado
idle confuso, balançar a cabeça
```

## 5. Como o motor trabalha

1. **Normalização:** remove diferenças de caixa, acentos e pontuação para comparar sinônimos.
2. **Interpretação:** localiza as ações e escolhe uma ação principal; quando possível, identifica um gesto adicional.
3. **Camadas de estilo:** aplica atitude, velocidade, intensidade, passada, postura e controles direcionais.
4. **Síntese:** calcula os canais das 15 juntas em cada quadro.
5. **Validação e saída:** valida o documento e cria o clip apropriado para o tipo de junta reconhecido no Mesh Rig 2016.

O interpretador é local e baseado em regras. Ele não chama um LLM nem uma API, por isso não entende qualquer frase possível. Use pelo menos um nome de ação reconhecido e termos do vocabulário deste guia.

## 6. Variações e biblioteca

**Outra variação** altera a semente para produzir uma nova realização do mesmo pedido. Depois de conferir a prévia, **Guardar referência** salva a receita localmente. A biblioteca mantém até 48 receitas e pode reutilizar parâmetros de uma referência com a mesma ação e atitude quando o novo pedido não define explicitamente determinado modificador.

As referências ficam nas configurações locais do plugin do Studio. Não são enviadas ao GitHub nem compartilhadas com outros usuários.

## 7. Instalação e atualização

Habilite **Plugin Debugging Enabled**, salve o Script como Local Plugin e edite a cópia dentro de `PluginDebugService`. Para aplicar uma alteração, use **Save and Reload Plugin** no menu de contexto dessa cópia. Não continue editando o Script de instalação em `ServerStorage`: ele não é a instância que está sendo executada pelo Studio.

## 8. Limites

- Exclusivo do Mesh Rig 2016 R15 validado estruturalmente.
- Uma ação principal mais, no máximo, um gesto secundário.
- Não há sequenciamento temporal livre em uma única descrição.
- Dedos individuais não possuem canais independentes.
- A geração e a prévia precisam ser conferidas no Roblox Studio antes de publicar.
