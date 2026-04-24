# Seca-Track

**Seca Track** é um sistema de previsão operacional de rios para planejamento de navegação fluvial durante períodos de estiagem. A aplicação é um arquivo HTML único, 100% client-side, sem dependências de servidor.

## Visão Geral

O sistema integra projeções de nível de rios com cálculo de capacidade da frota, permitindo que operadores de transporte fluvial planejem suas operações considerando diferentes cenários hidrológicos (seca, normal e cheia).

## Funcionalidades

### Nível dos Rios
- Importação de dados históricos via Excel/CSV (SheetJS)
- Entrada manual de medições por rio e data
- Projeção estatística com três cenários padrão:
  - **Otimista** — média + 1 desvio padrão
  - **Médio** — média histórica com tendência linear
  - **Pessimista** — média − 1 desvio padrão
- Cenários customizados (desvio, percentual ou nível fixo por mês)
- Variáveis de navegação configuráveis: **Ábaco** (padrão 1,03) e **FAQ** (padrão 0,50)
- Fórmula: `Calado Operacional = Nível do Rio + Ábaco − FAQ`
- Avaliação de aderência: comparação de projeções do ano anterior vs. valores reais observados (MAE, MAPE)

### Ativos (Frota)
- **Barcaças:** cadastro de tipos com calado mínimo/máximo, capacidade de carga e quantidade disponível
- **Empurradores:** cadastro com potência, faixa de calado operacional e número máximo de barcaças por comboio
- Ativação/desativação individual de ativos

### Rotas & Metas
- Configuração de rotas com rio associado, tempos de viagem, taxas de carga/descarga e espera
- Metas mensais de transporte (12 meses)
- Alocação de empurradores com composição de comboio por rota
- Validação automática da composição versus capacidade do empurrador

### Dashboard
- Cards de KPI com capacidade remanescente no ano (3 cenários)
- Gráfico de barras empilhadas: capacidade pessimista / delta médio / delta otimista vs. meta
- Tabela rota × mês com status (OK / ALERTA / DÉFICIT)
- Drill-down por viagem: cálculo por empurrador, calado por barcaça, volume por viagem e ciclo em horas

## Tecnologias

| Biblioteca | Uso |
|---|---|
| [Tailwind CSS](https://tailwindcss.com) | Estilização e layout responsivo |
| [Chart.js](https://www.chartjs.org) | Gráficos de séries temporais e barras |
| [SheetJS (XLSX)](https://sheetjs.com) | Leitura de planilhas Excel/CSV |
| [Lucide](https://lucide.dev) | Ícones SVG |

Sem frameworks JavaScript — apenas HTML, CSS e JS vanilla.

## Como Usar

1. Abra `seca-track.html` diretamente no navegador (Chrome ou Edge recomendado para suporte completo à File System Access API).
2. Nenhuma instalação ou servidor necessário.

### Fluxo básico

```
1. Nível dos Rios  → Importe ou insira dados históricos de nível
2. Ativos          → Cadastre barcaças e empurradores
3. Rotas & Metas   → Configure rotas, metas e composição de comboios
4. Dashboard       → Analise a capacidade vs. meta por cenário
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

**Projeção de nível (`calcularProjecaoRio`)**
- Agrega dados históricos por mês
- Calcula média e desvio padrão
- Aplica regressão linear no período selecionado (padrão: 3 anos)
- Projeta os valores com ajuste por cenário

**Capacidade por rota/mês (`calcularCapacidadeRotaMes`)**
- Para cada empurrador alocado na rota:
  - Verifica se o calado operacional ≥ calado mínimo do empurrador
  - Interpola capacidade de carga das barcaças pelo calado disponível
  - Calcula tempo de ciclo: carga + viagem + descarga + espera
  - Deriva viagens/mês = (24 h/dia × dias do mês) ÷ ciclo
  - Volume/mês = viagens × volume do comboio

## Licença

Consulte o repositório para informações de licença.
