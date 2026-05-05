# Seca-Track

**Seca Track** é um sistema de previsão operacional de rios para planejamento de navegação fluvial durante períodos de estiagem. A aplicação é um arquivo HTML único, 100% client-side, sem dependências de servidor.

## Visão Geral

O sistema integra projeções de nível de rios com cálculo de capacidade da frota e custo variável de combustível, permitindo que operadores de transporte fluvial planejem suas operações considerando diferentes cenários hidrológicos (seca, normal e cheia).

## Abas

| Aba | Descrição |
|---|---|
| **Nível dos Rios** | Importação de dados, projeções, aderência e tempo de parada |
| **Ativos** | Cadastro de empurradores, barcaças e combustíveis |
| **Rotas & Metas** | Configuração de rotas, cidades e cenários de rotas |
| **Capacidade Frota** | Dashboard de KPIs, gráficos e tabelas de capacidade vs. meta |
| **Custo Variável** | Cálculo automático de consumo de combustível e custo por rota |

## Funcionalidades

### Nível dos Rios

**Projeção de Nível**
- Importação de dados históricos via Excel/CSV (SheetJS) ou entrada manual
- Projeção estatística com três cenários padrão:
  - **Otimista** — média + 1 desvio padrão
  - **Médio** — média histórica com tendência linear
  - **Pessimista** — média − 1 desvio padrão
- Cenários customizados (desvio, percentual ou nível fixo por mês)
- Comparação com anos históricos via lista suspensa com seleção múltipla
- Exportação das projeções em CSV
- Variáveis de navegação configuráveis globalmente:
  - **Ábaco** (padrão 1,03) e **FAQ** (padrão 0,50)
  - Fórmula: `Nível mínimo navegável = Calado da embarcação − Ábaco + FAQ`
  - Período de tendência configurável de 1 a 20 anos (padrão: 3 anos)

**Aderência das Previsões**
- Comparação de projeções do ano anterior vs. valores reais observados
- Seleção de cenário (Otimista, Médio ou Pessimista) para análise
- Métricas por mês: nível projetado, nível real, erro (m), erro (%) e acurácia
- Indicadores globais: MAE e MAPE

**Tempo de Parada das Embarcações**
- Seleção de embarcações para visualização (individual ou todas)
- Gráfico de Gantt horizontal com períodos de restrição de navegação por cenário
- Tabela detalhada: cenário, tipo, embarcação, início da restrição, retomada e dias parados
- Interpolação diária para histórico e linear para projeções

### Ativos (Frota)

- **Empurradores:** potência (HP), faixa de calado operacional, número máximo de barcaças por comboio e consumo (L/H) por tipo de combustível
- **Tipos de Barcaças:** calado mínimo/máximo, capacidade de carga interpolada entre os extremos e quantidade disponível
- **Tipos de Combustível:** cadastro de itens com preço (R$/L) utilizado no cálculo automático do Custo Variável

### Rotas & Metas

- Configuração de rotas com rio associado, tempo de viagem, taxas de carga/descarga, tempo de espera e meses ativos
- Cadastro de cidades/origens-destino com tipo (origem, destino ou pulmão) e meta anual de transporte
- Cenários de rotas: agrupamento de rotas para comparação de capacidade no dashboard
- Cálculo de ciclo: `carga + viagem (ida e volta) + descarga + espera`; locais marcados como pulmão têm tempo de carga/descarga zero

### Capacidade Frota

- Cards de KPI: capacidade remanescente no ano para os 3 cenários e meta total do período
- Filtros: rota, cenário de rotas, período (restante do ano / ano inteiro) e ano
- Alternância de visualização: **Por Rota** ou **Por Mês (Total)**
- Gráfico de barras empilhadas com status por faixa: Seguro / Atenção / Alerta
- Gráfico de comparação entre cenários de rotas
- Tabela rota × mês com status (OK / ALERTA / DÉFICIT) e drill-down por viagem
- **Rastreamento de Pulmão:** monitoramento separado das localizações buffer com envio, consumo e saldo por cenário

### Custo Variável

- Cálculo automático de consumo de combustível baseado em: viagens planejadas × consumo (L/H) × horas de viagem por empurrador
- Filtros: ano, cenário de nível do rio, cenário de rotas e tipo de combustível
- Três modos de visualização:
  - **Litros Totais** — consumo absoluto mensal
  - **L/Ton** — eficiência de consumo por tonelada transportada
  - **R$/Ton** — custo de combustível por tonelada transportada
- Gráfico de barras de consumo médio mensal (12 meses)
- Três gráficos de pizza anuais: consumo por combustível, por empurrador e por rota
- Tabela de consumo por rota com linhas expansíveis (mês → detalhamento por rota/empurrador): litros totais, tonelagem, L/Ton, R$/Ton e custo total (R$)

## Tecnologias

| Biblioteca | Uso |
|---|---|
| [Tailwind CSS](https://tailwindcss.com) | Estilização e layout responsivo |
| [Chart.js](https://www.chartjs.org) | Gráficos de séries temporais, barras e pizza |
| [SheetJS (XLSX)](https://sheetjs.com) | Leitura de planilhas Excel/CSV |
| [Lucide](https://lucide.dev) | Ícones SVG |

Sem frameworks JavaScript — apenas HTML, CSS e JS vanilla.

## Como Usar

1. Abra `seca-track.html` diretamente no navegador (Chrome ou Edge recomendado para suporte completo à File System Access API).
2. Nenhuma instalação ou servidor necessário.

### Fluxo básico

```
1. Nível dos Rios  → Importe ou insira dados históricos de nível
2. Ativos          → Cadastre empurradores, barcaças e combustíveis
3. Rotas & Metas   → Configure rotas, cidades e cenários de rotas
4. Capacidade      → Analise capacidade vs. meta por cenário
5. Custo Variável  → Acompanhe consumo e custo de combustível por rota
```

## Persistência de Dados

| Mecanismo | Comportamento |
|---|---|
| **localStorage** | Persistência automática na sessão do navegador |
| **IndexedDB** | Armazena handles de arquivos entre sessões |
| **File System Access API** | Salva `seca-track-db.json` em pasta escolhida pelo usuário (Chrome/Edge) com auto-save de 700 ms |

### Exportação / Importação
- **JSON** — exporta/importa o banco de dados completo com timestamp e versão
- **CSV** — exporta projeções de nível dos rios para análise em planilhas

## Estrutura do Projeto

```
Seca-Track/
└── seca-track.html   # Aplicação completa (HTML + CSS + JS em arquivo único)
```

## Formato dos Dados de Nível

Para importação via planilha, o arquivo deve conter as colunas:

| Coluna | Formato | Exemplo |
|---|---|---|
| Data | DD/MM/AAAA | 15/03/2023 |
| Rio | Texto | Rio Madeira |
| Nível | Número (metros) | 7,88 |

## Cálculos Principais

**Projeção de nível**
- Agrega dados históricos por mês
- Calcula média e desvio padrão por mês do calendário
- Aplica regressão linear no período configurado (padrão: 3 anos)
- Projeta valores com ajuste por cenário (desvio padrão, percentual ou fixo)

**Capacidade por rota/mês**
- Para cada empurrador alocado na rota:
  - Verifica se o calado operacional ≥ calado mínimo do empurrador
  - Interpola capacidade de carga das barcaças pelo calado disponível
  - Calcula tempo de ciclo: carga + viagem (ida e volta) + descarga + espera
  - Viagens/mês = (24 h × dias do mês) ÷ ciclo
  - Volume/mês = viagens × volume do comboio

**Custo variável de combustível**
- Para cada rota e empurrador: viagens planejadas × consumo (L/H) × horas de viagem
- Aplicação do preço por tipo de combustível para obter R$/mês
- Divisão pela tonelagem transportada para métricas de eficiência (L/Ton e R$/Ton)

## Licença

Consulte o repositório para informações de licença.
