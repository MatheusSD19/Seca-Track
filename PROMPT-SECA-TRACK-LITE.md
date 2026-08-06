# Prompt — Seca Track Lite

> Prompt pronto para colar em outra plataforma de geração de código.
> Copie tudo abaixo da linha.

---

## Objetivo

Construa um aplicativo web de **página única**, chamado **Seca Track Lite**, para planejamento de navegação fluvial em período de estiagem. O app projeta o nível de um rio ao longo do ano, cruza essa projeção com o calado das embarcações cadastradas e responde a duas perguntas operacionais:

1. **Quando cada embarcação para de navegar** (e quando volta a navegar);
2. **Qual o volume médio de carga por barcaça** em cada mês, dado o calado disponível.

## Stack obrigatória

- **Um único arquivo `seca-track-lite.html`**, 100% client-side, sem build, sem servidor, sem framework. Abrir o arquivo no navegador tem que funcionar.
- HTML + CSS + JavaScript vanilla.
- Bibliotecas por CDN, apenas estas:
  - [Tailwind CSS](https://cdn.tailwindcss.com) — estilo
  - [Chart.js](https://cdn.jsdelivr.net/npm/chart.js) — gráficos
  - [SheetJS / XLSX](https://cdn.sheetjs.com/xlsx-0.20.1/package/dist/xlsx.full.min.js) — leitura de `.xlsx` / `.csv`
- Persistência em **localStorage** (salvar automaticamente a cada alteração e recarregar ao abrir).
- Interface toda em **português do Brasil**. Números com vírgula decimal (`pt-BR`), datas em `DD/MM/AAAA`.

---

## Conceitos do domínio (leia com atenção — as fórmulas são o coração do app)

**Régua** = nível do rio medido, em metros. É o dado que vem da planilha.

**Calado** = profundidade que a embarcação ocupa na água, em metros. É atributo da embarcação.

Duas constantes globais convertem uma coisa na outra:

- **Ábaco** (padrão `1,03`)
- **FAQ** (padrão `0,50`)

Fórmulas oficiais, use exatamente estas:

```
Régua mínima navegável = calado da embarcação − Ábaco + FAQ
Calado operacional     = régua observada + Ábaco − FAQ
```

Ou seja: uma embarcação **para** quando a régua do rio cai abaixo da sua régua mínima navegável, e **retoma** no primeiro dia em que a régua volta a ficar igual ou acima dela.

**Barcaça** tem faixa de calado (`calado mín` → `calado máx`) e faixa de volume (`vol @mín` → `vol @máx`). O volume que ela consegue carregar num calado intermediário é **interpolado linearmente**:

```js
function calcularVolumeBarcaca(barcaca, caladoPossivel) {
    if (caladoPossivel < barcaca.caladoMin) return 0;              // não navega
    if (!barcaca.caladoMax || barcaca.caladoMax <= barcaca.caladoMin) return barcaca.volMin;
    const cal = Math.min(caladoPossivel, barcaca.caladoMax);       // trava no calado máximo
    const razao = (cal - barcaca.caladoMin) / (barcaca.caladoMax - barcaca.caladoMin);
    return barcaca.volMin + razao * (barcaca.volMax - barcaca.volMin);
}
```

Uma barcaça tem, portanto, **dois eventos**, e ambos importam:
- **redução de calado** — a régua cai abaixo de `caladoMax − Ábaco + FAQ`: ela ainda navega, mas carrega menos;
- **parada** — a régua cai abaixo de `caladoMin − Ábaco + FAQ`: ela não navega.

Empurrador tem só **parada** (usa o `caladoMin` dele).

---

## Módulo 1 — Importação de bases

Um card "Base de dados" com:

- Botão **Importar planilha** (`<input type="file" accept=".xlsx,.xls,.csv">`) que lê via SheetJS a **primeira aba** do arquivo. Colunas esperadas (aceite variações de caixa e acento; se não achar pelo nome, use a 1ª, 2ª e 3ª coluna nessa ordem):

  | Coluna | Formato | Exemplo |
  |---|---|---|
  | `Data` | `DD/MM/AAAA` | `15/03/2023` |
  | `Rio` (ou `Nome do Rio`) | texto | `Rio Madeira` |
  | `Nível` (ou `Nível do Rio`) | número em metros | `7,88` |

- A importação é um **upsert**: mesma data + mesmo rio atualiza o nível existente; data nova insere. Ao final, mostre um alerta com `X adicionados, Y atualizados, Z ignorados (formato inválido)`.
- **Cuidado com datas** (é onde a maioria das implementações erra):
  - Ler o workbook com `XLSX.read(uint8, { type:'array', raw:true })` e `sheet_to_json(sheet, { raw:true, defval:'' })` para receber o valor bruto da célula;
  - Célula numérica é **serial do Excel** → converter com `XLSX.SSF.parse_date_code(v)`, nunca com `new Date(numero)`;
  - String `DD/MM/AAAA` é **dia primeiro** (padrão brasileiro), nunca mês primeiro;
  - Rejeitar datas de calendário impossíveis (`31/02/2024`, `45/13/2026`) em vez de gravar lixo;
  - Nível pode vir como `7,88` (vírgula) — normalizar para ponto.
- Botão **Adicionar medição manual** (data, rio, nível) para quem não tem planilha.
- Botão **Exportar JSON** / **Importar JSON** do banco inteiro (rios + embarcações + barcaças + variáveis), com `versao` e `timestamp`.
- Botão **Limpar dados de rio** com confirmação.
- Uma tabela paginada (ou com as 50 medições mais recentes) mostrando `Data | Rio | Nível` com botão de excluir por linha.

**Importante:** o app deve abrir funcional mesmo sem nenhum dado — mostre estados vazios explicativos, nunca telas quebradas ou `NaN`.

---

## Módulo 2 — Página inicial (dashboard)

Tudo o que segue fica na **mesma página inicial**, um card abaixo do outro. Um seletor de **Rio** no topo (populado com os rios distintos da base) e um seletor de **Ano-base** (ano atual + 5 anos à frente) controlam todos os cards.

### 2.1 Gráfico de projeção de nível

Gráfico de linha (Chart.js), **eixo X diário** do ano-base inteiro (01/01 a 31/12, rótulos `DD/MM`), com estas séries:

| Série | Cor | Conteúdo |
|---|---|---|
| Histórico | cinza `#6b7280` | medições reais do ano-base (só nos dias com medição) |
| Otimista | verde `#10b981` | projeção |
| Médio | azul `#3b82f6` | projeção |
| Pessimista | vermelho `#ef4444` | projeção |
| Calado mínimo de cada ativo | linha tracejada | linha horizontal na `régua mínima navegável` de cada embarcação/barcaça ativa |

As três projeções só começam **depois da última medição real** — não desenhe projeção em cima do histórico já observado. Legenda clicável para ligar/desligar séries.

**Como calcular a projeção (base simulada):**

1. Agrupe todo o histórico do rio por **mês do calendário** (jan..dez, somando todos os anos da base). Calcule `média[m]` e `desvio-padrão[m]` de cada mês. Meses sem dado usam a média geral como fallback.
2. Calcule uma **tendência linear** (regressão simples, coeficiente angular) sobre os pontos dos últimos **N anos** (N configurável, padrão 3; se houver menos de 2 pontos no período, use toda a base).
3. Para cada mês `m` ainda não observado no ano-base:
   ```
   base   = média[m]
   ajuste = tendencia * max(1, m - mesAtual)
   medio      = max(0, base + ajuste)
   otimista   = max(0, medio + 1 * desvioPadrao[m])
   pessimista = max(0, medio - 1 * desvioPadrao[m])
   ```
   Piso em 0 sempre.
4. Para chegar na **série diária** (necessária para os cálculos de parada), monte âncoras e interpole linearmente entre elas:
   - cada medição real vira uma âncora na sua data;
   - cada mês futuro vira uma âncora no **dia 15** com o valor projetado daquele cenário;
   - **não** injete âncora mensal no mês que contém a última medição real (senão a curva "salta" da última régua real para a média do mês);
   - interpole dia a dia entre âncoras; antes da primeira/depois da última, repita o valor da ponta.
5. Gere a série diária para a janela `[anoBase, anoBase + 1]`. O ano extra existe **só** para resolver corretamente a data de retorno de paradas que atravessam 31/12 — restrições que começam no ano seguinte **não** entram nas tabelas.

Abaixo do gráfico, uma linha de texto informando a última régua observada, a data dela, e o intervalo histórico disponível.

### 2.2 Tabela — Paradas das embarcações

Título: **"Redução de calado e paradas"**. Para cada cenário (Pessimista, Médio, Otimista) e cada ativo ativo, encontre os **períodos contíguos** da série diária em que `nivel < réguaMínima`, e consolide em uma linha:

| Cenário | Embarcação | Tipo | Régua Mínima (m) | Régua Simulada (m) | Parada | Retorno | Dias Parado |
|---|---|---|---|---|---|---|---|

- **Parada** = início do primeiro período restrito que começa no ano-base.
- **Retorno** = fim do último período **+ 1 dia** (o primeiro dia navegável).
- **Dias Parado** = soma dos dias de todos os períodos.
- **Régua Simulada** = nível da série no dia da parada.
- **Tipo** é `Empurrador`, `Barcaça (redução)` ou `Barcaça (parada)` — cada barcaça gera até duas linhas, uma para cada limiar.
- Exiba **apenas os ativos que têm evento** no período. Se nenhum tiver, mostre a frase *"Nenhuma embarcação com redução de calado ou parada projetada para os cenários atuais."*
- Colora a linha por cenário (vermelho / azul / verde suaves) e permita filtrar por cenário e por embarcação.

Acima da tabela, um **parágrafo em linguagem natural gerado dinamicamente**, uma frase por cenário, no formato:

> No cenário **Pessimista**, a redução de calado das barcaças iniciaria por volta de **12/09/2026**, com parada de embarcações (Empurrador X, Barcaça Y) a partir de **04/10/2026** e retorno até **28/11/2026**.

Se um cenário não tiver evento nenhum, a frase vira *"No cenário **Otimista**, não há redução de calado nem parada de embarcações projetada para o período."*

### 2.3 Tabela — Calado operacional e volume médio por barcaça

Título: **"Calado operacional estimado"**. Use como **barcaça de referência** a barcaça ativa de maior `volMax`. Para cada cenário × mês (do mês atual até dezembro do ano-base):

| Mês | Cenário | Média Régua (m) | Média Calado (m) | **Vol. Médio (t)** | Menor Régua (m) | Menor Calado (m) | **Menor Vol. (t)** |
|---|---|---|---|---|---|---|---|

Onde, sobre os dias daquele mês na série diária do cenário:

```
mediaRegua  = média dos níveis diários do mês
menorRegua  = mínimo dos níveis diários do mês
mediaCalado = min(mediaRegua + Ábaco − FAQ, caladoMax da barcaça de referência)
menorCalado = min(menorRegua + Ábaco − FAQ, caladoMax da barcaça de referência)
volMedio    = calcularVolumeBarcaca(referencia, mediaCalado)
menorVol    = calcularVolumeBarcaca(referencia, menorCalado)
```

Volumes em toneladas, arredondados e formatados `pt-BR` (`1.234`). Réguas e calados com 2 casas decimais.

Feche o card com uma frase dinâmica do tipo:

> No cenário **Pessimista**, o menor calado operacional estimado é de cerca de **3,10 m**, equivalente a aproximadamente **1.850 t** por barcaça.

---

## Módulo 3 — Cadastro de embarcações e barcaças

Uma segunda aba/seção **"Ativos"**, com duas tabelas e modais de criar/editar/excluir. Todo salvamento persiste em localStorage e **recalcula o dashboard inteiro**.

### Empurradores

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `nome` | texto | sim | |
| `potencia` | número (HP) | não | |
| `caladoMin` | número (m) | sim | define a régua mínima navegável |
| `caladoMax` | número (m) | não | |
| `qtdBarcacas` | inteiro | sim | barcaças por comboio, padrão 4 |
| `ativo` | booleano | — | padrão `true`; inativo não entra em nenhum cálculo |

### Barcaças (tipos de barcaça)

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `nome` | texto | sim | |
| `quantidade` | inteiro > 0 | sim | quantas existem na frota |
| `caladoMin` | número (m) | sim | abaixo disso, para |
| `volMin` | número (t) | sim | volume no calado mínimo |
| `caladoMax` | número (m) | sim | deve ser **maior** que `caladoMin` |
| `volMax` | número (t) | sim | volume no calado máximo |
| `ativo` | booleano | — | padrão `true` |

Validações: campos obrigatórios preenchidos, `caladoMax > caladoMin`, `quantidade > 0`. Mensagem de erro clara, sem salvar registro inválido.

Cada linha das tabelas tem botões de **editar**, **excluir** (com confirmação) e um **toggle de ativo/inativo**.

---

## Configurações globais

Um card ou modal "Variáveis" com:

- **Ábaco** (padrão `1,03`)
- **FAQ** (padrão `0,50`)
- **Anos para tendência** (1 a 20, padrão `3`)
- Multiplicador de desvio-padrão de cada cenário (padrão `+1` otimista, `0` médio, `−1` pessimista)

Alterar qualquer um recalcula tudo na hora.

---

## Critérios de aceite

O app está pronto quando, partindo do arquivo HTML aberto no navegador:

1. Importo uma planilha com ~3 anos de medições diárias e o gráfico desenha histórico + 3 cenários sem erro no console.
2. Cadastro 1 empurrador (calado mín `2,50`) e 1 barcaça (`2,00`–`3,50` m / `1.500`–`3.000` t) e as linhas tracejadas de calado mínimo aparecem no gráfico.
3. A tabela de paradas mostra, por cenário, datas de parada e retorno coerentes com o cruzamento da curva com as linhas tracejadas — conferíveis a olho no gráfico.
4. Uma parada que começa em novembro e só terminaria em fevereiro do ano seguinte mostra a **data real de retorno**, não `01/01`.
5. A tabela de calado operacional mostra o volume médio por barcaça mês a mês, e o volume nunca ultrapassa o `volMax` da barcaça nem fica negativo.
6. Fecho e reabro o navegador: dados de rio, embarcações, barcaças e variáveis continuam lá.
7. Sem nenhum dado importado, o app abre com estados vazios explicativos — nada de `NaN`, `undefined` ou tela branca.

## Dados de exemplo

Inclua um botão **"Carregar dados de exemplo"** que popula a base com uma série sintética plausível (um rio amazônico, cheia em maio ~`15 m`, vazante até outubro ~`3 m`, 3 anos de histórico diário), 2 empurradores e 2 tipos de barcaça — para o app poder ser avaliado sem planilha nenhuma.

## Qualidade esperada

- Layout responsivo, limpo, com cards brancos, cantos arredondados e boa densidade de informação; cabeçalho fixo com as abas **Início** e **Ativos**.
- Nenhum erro no console em uso normal.
- Cálculos puros separados da renderização — funções como `gerarSerieDiariaRio`, `encontrarPeriodosRestricao`, `calcularVolumeBarcaca` devem ser testáveis isoladamente.
- Comentários curtos nos trechos de fórmula explicando **por quê**, não o quê.
