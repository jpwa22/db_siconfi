# db_siconfi

Scripts em R e Python para extrair, transformar, armazenar e analisar dados fiscais de estados brasileiros via API do SICONFI (Tesouro Nacional), com foco em ICMS e em bases brutas RREO/RGF consultáveis em DuckDB.

---

## Pipeline

```
API SICONFI
    ↓
[1] extracao/extracao.R / extracao/extracao.ipynb   → extracao/csv/rreo/*.csv + extracao/csv/rgf/*.csv
    ↓
[2] build_duckdb.R                                   → data/siconfi.duckdb
    ↓
[3] etl.R                                            → data/icms.rds + data/csv/icms.csv
    ↓
[4] analise/analise_icms.R                           → outputs/analise_icms/
    ↓
[5] app/app.R                                        → Dashboard Shiny interativo
```

O módulo DuckDB é uma camada de armazenamento local para consulta dos CSVs brutos de RREO e RGF. Ele não substitui o `etl.R`, que continua sendo o tratamento específico para a análise de ICMS.

---

## Estrutura de pastas

```
db_siconfi/
├── extracao/
│   ├── extracao.R          # [1] Baixa RREO/RGF da API — destinado a repo próprio
│   ├── extracao.ipynb      # [1] Idem, em Python
│   └── csv/
│       ├── rreo/           # CSVs brutos de RREO (gitignored)
│       └── rgf/            # CSVs brutos de RGF (gitignored)
├── data/
│   ├── siconfi.duckdb      # Banco DuckDB com RREO/RGF brutos (gerado — gitignored)
│   ├── icms.rds            # Dado consolidado de ICMS (gerado por etl.R — gitignored)
│   └── csv/
│       └── icms.csv        # Dado consolidado de ICMS em CSV (gitignored)
├── build_duckdb.R          # [2] Constrói data/siconfi.duckdb a partir dos CSVs brutos
├── etl.R                   # [3] Transforma CSVs brutos em data/icms.rds
├── analise/
│   └── analise_icms.R      # [4] Análise exploratória (PE vs Brasil/Nordeste)
├── app/
│   └── app.R               # [5] Dashboard Shiny interativo
├── outputs/
│   └── analise_icms/       # CSVs de resultado, PNGs e relatório .md
└── README.md
```

> **Nota:** `data/` e os CSVs brutos são gitignored — os arquivos são gerados, não versionados.
> Para rodar o pipeline a partir do zero, execute os scripts na ordem [1] → [5].

---

## Módulo DuckDB

O script `build_duckdb.R` cria o arquivo `data/siconfi.duckdb` lendo diretamente os CSVs de `extracao/csv/rreo/` e `extracao/csv/rgf/`.

O banco criado contém quatro tabelas principais:

| Tabela | Conteúdo |
| --- | --- |
| `rreo` | Dados brutos consolidados dos arquivos `extracao/csv/rreo/*.csv` |
| `rgf` | Dados brutos consolidados dos arquivos `extracao/csv/rgf/*.csv` |
| `arquivos_csv` | Inventário dos arquivos importados, com caminho, tamanho e data de modificação |
| `resumo_importacao` | Contagem de linhas e arquivos importados por relatório |

A importação usa `read_csv()` do DuckDB com separador `;`, cabeçalho, união de colunas por nome e inclusão da coluna `filename`, que preserva o arquivo de origem de cada linha. O script também cria índices simples para consultas frequentes por `exercicio`, `uf`, `periodo` e `anexo`.

Na última execução validada, o banco foi criado com:

| Relatório | Linhas | Arquivos |
| --- | ---: | ---: |
| `rgf` | 306.876 | 917 |
| `rreo` | 203.326 | 63 |

---

## Como executar

Todos os scripts devem ser rodados com o **diretório de trabalho na raiz do projeto**.
No RStudio, abra o arquivo `db_siconfi.Rproj` para garantir isso automaticamente.

### Pré-requisitos (R)

```r
install.packages(c("httr", "jsonlite", "fs", "tidyverse", "data.table",
                   "DBI", "duckdb",
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
# Parâmetros ajustáveis no final do script: anos, bimestres, quadrimestres e UFs
```

**2. Banco DuckDB** — consolida RREO e RGF em um banco local consultável:

```r
source("build_duckdb.R")
# Gera data/siconfi.duckdb
```

Exemplo de consulta:

```r
library(DBI)
library(duckdb)

con <- dbConnect(duckdb(), "data/siconfi.duckdb", read_only = TRUE)

DBI::dbGetQuery(con, "
  SELECT exercicio, uf, periodo, anexo, COUNT(*) AS linhas
  FROM rreo
  GROUP BY exercicio, uf, periodo, anexo
  ORDER BY exercicio, uf, periodo, anexo
  LIMIT 10
")

dbDisconnect(con, shutdown = TRUE)
```

**3. ETL de ICMS** — consolida os CSVs em um único objeto R:

```r
source("etl.R")
# Gera data/icms.rds e data/csv/icms.csv
```

**4. Análise** — gera tabelas, gráficos e relatório:

```r
source("analise/analise_icms.R")
# Saídas em outputs/analise_icms/
```

**5. Dashboard** — sobe o app Shiny:

```r
shiny::runApp("app/app.R")
```

---

## Fonte dos dados

- [API SICONFI — Tesouro Nacional](https://apidatalake.tesouro.gov.br/docs/siconfi/)
- Relatórios: RREO (Relatório Resumido de Execução Orçamentária) e RGF (Relatório de Gestão Fiscal)
- Cobertura local atual: conforme arquivos disponíveis em `extracao/csv/rreo/` e `extracao/csv/rgf/`

---

## Próximos passos de organização

- **`extracao/`** deve virar um repositório separado (`extrator-siconfi`) — é uma ferramenta genérica reutilizável, independente desta análise específica.
- Avaliar se o `etl.R` deve passar a ler diretamente de `data/siconfi.duckdb`, em vez de ler os CSVs brutos novamente.
- A pasta `scripts/` (se ainda existir vazia) pode ser deletada manualmente.

---

## Licença

MIT