# db_siconfi

Scripts em R e Python para extrair, transformar e analisar dados fiscais de estados brasileiros via API do SICONFI (Tesouro Nacional), com foco em ICMS.

---

## Pipeline

```
API SICONFI
    ↓
[1] extracao/extracao.R / extracao/extracao.ipynb   → data/csv/rreo/*.csv
    ↓
[2] etl.R                                            → data/icms.rds + data/csv/icms.csv
    ↓
[3] analise/analise_icms.R                           → outputs/analise_icms/
    ↓
[4] app/app.R                                        → Dashboard Shiny interativo
```

---

## Estrutura de pastas

```
db_siconfi/
├── extracao/
│   ├── extracao.R          # [1] Baixa RREO/RGF da API — destinado a repo próprio
│   └── extracao.ipynb      # [1] Idem, em Python
├── data/
│   ├── icms.rds            # Dado consolidado (gerado por etl.R — gitignored)
│   └── csv/
│       ├── rreo/           # CSVs brutos (~1.800 arquivos — gitignored)
│       └── icms.csv        # Dado consolidado em CSV (gitignored)
├── etl.R                   # [2] Transforma CSVs brutos em data/icms.rds
├── analise/
│   └── analise_icms.R      # [3] Análise exploratória (PE vs Brasil/Nordeste)
├── app/
│   └── app.R               # [4] Dashboard Shiny interativo
├── outputs/
│   └── analise_icms/       # CSVs de resultado, PNGs e relatório .md
└── README.md
```

> **Nota:** `data/` é gitignored — os arquivos são gerados, não versionados.
> Para rodar o pipeline a partir do zero, execute os scripts na ordem [1] → [4].

---

## Como executar

Todos os scripts devem ser rodados com o **diretório de trabalho na raiz do projeto**.
No RStudio, abra o arquivo `db_siconfi.Rproj` para garantir isso automaticamente.

### Pré-requisitos (R)

```r
install.packages(c("httr", "jsonlite", "fs", "tidyverse", "data.table",
                   "shiny", "bslib", "plotly", "DT", "scales"))
```

### Pré-requisitos (Python)

```bash
pip install pandas requests
```

### Passo a passo

**1. Extração** — baixa os dados brutos da API:

```r
source("extracao/extracao.R")
# Parâmetros ajustáveis no final do script: anos, bimestres, UFs
```

**2. ETL** — consolida os CSVs em um único objeto R:

```r
source("etl.R")
# Gera data/icms.rds e data/csv/icms.csv
```

**3. Análise** — gera tabelas, gráficos e relatório:

```r
source("analise/analise_icms.R")
# Saídas em outputs/analise_icms/
```

**4. Dashboard** — sobe o app Shiny:

```r
shiny::runApp("app/app.R")
```

---

## Fonte dos dados

- [API SICONFI — Tesouro Nacional](https://apidatalake.tesouro.gov.br/docs/siconfi/)
- Relatório: RREO (Relatório Resumido de Execução Orçamentária), Anexo 03
- Cobertura: 2015–2026, bimestral, todas as UFs

---

## Próximos passos de organização

- **`extracao/`** deve virar um repositório separado (`extrator-siconfi`) — é uma ferramenta genérica reutilizável, independente desta análise específica.
- A pasta `scripts/` (se ainda existir vazia) pode ser deletada manualmente.

---

## Licença

MIT
