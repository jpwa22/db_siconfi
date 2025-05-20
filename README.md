# 📊 db_siconfi

Este repositório contém scripts em **Python** e **R** para acessar e extrair dados diretamente da API do Tesouro Nacional (SICONFI), com foco na coleta de informações dos relatórios RREO (Relatório Resumido de Execução Orçamentária) e RGF (Relatório de Gestão Fiscal).

---

## 📌 Objetivo

Facilitar o acesso aos dados fiscais de estados e municípios brasileiros, permitindo:

- Baixar dados atualizados por ano, período e UF;
- Estruturar os dados em formato `.csv` para posterior análise;
- Automatizar parte da coleta de dados de finanças públicas.

---

## 📁 Estrutura dos Scripts

- `baixar_dados_tesouro_rreo.py`: Faz a requisição à API do Tesouro para baixar os dados de RREO em Python.
- `extrator_siconfi.R`: Script em R para extrair os mesmos dados via API.

---

## ⚙️ Pré-requisitos

### Para Python

- Python 3.8+
- Instalar bibliotecas:

```bash
pip install pandas requests
```

### Para R

Instale os seguintes pacotes:

```r
install.packages(c("httr", "jsonlite", "dplyr", "readr"))
```

---

## 🚀 Como usar

### Usando Python

1. Clone o repositório:

```bash
git clone https://github.com/jpwa22/db_siconfi.git
cd db_siconfi
```

2. Edite o script `baixar_dados_tesouro_rreo.py` com os parâmetros desejados:

```python
ano = 2023
bimestre = 6  # de 1 a 6
uf = 26        # código IBGE do estado (ex: 26 para PE)
```

3. Execute o script:

```bash
python baixar_dados_tesouro_rreo.py
```

Os dados serão salvos em um arquivo `.csv` no diretório `dados/`.

---

### Usando R

1. Abra o R ou RStudio.

2. Carregue o script:

```r
source("extrator_siconfi.R")
```

3. Execute a função principal:

```r
baixar_dados_tesouro_rreo(ano = 2024, bimestre = 2, uf = 26)
```

Os dados serão automaticamente salvos como `.csv` no diretório `dados/`.

---

## 📂 Exemplo de código em ambos

### Python

```python
from baixar_dados_tesouro_rreo import baixar_dados_tesouro_rreo

baixar_dados_tesouro_rreo(ano=2024, bimestre=3, uf=26)
```

### R

```r
baixar_dados_tesouro_rreo(ano = 2023, bimestre = 6, uf = 35)  # São Paulo
```

---

## 🗂️ Fonte dos dados

- [API SICONFI - Tesouro Nacional](https://apidatalake.tesouro.gov.br/ords/siconfi/)

---

## 📄 Licença

Este projeto está sob a licença MIT.