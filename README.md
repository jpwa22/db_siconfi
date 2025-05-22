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

- `extracao.ipynb`: Faz a requisição à API do Tesouro para baixar os dados de RREO e RGF em Python.
- `extracao.R`: Script em R para extrair os mesmos dados via API.

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

2. Edite o script `extracao.ipynb` com os parâmetros desejados:

```python
ano = 2023 # Informe o ano ou intervalo.
bimestre = 6  # de 1 a 6
uf = [11, 12, 13, 14, 15, 16, 17, 21, 22, 23, 24, 25, 26, 27, 28, 29, 31, 32, 33, 35, 41, 42, 43, 50, 51, 52, 53]  # código IBGE dos estados (ex: 26 para PE)
```
#### Em Python, intervalos são definidos usando a função range(início, fim, passo) ou ao trabalhar com fatias (slices). O ponto de atenção é que o valor final (fim) não é incluído. Ou seja, o intervalo vai até, mas não inclui, o valor final. Por exemplo: range(2015,2026). Lembrando que em python o final é exclusivo, tal como quando utilizamos < 2026 para definir um intervalo até 2025.

3. Execute todas as células do notebook.



---

### Usando R

1. Abra o R ou RStudio.

2. Edite o script `extracao.R` com os parâmetros desejados:

```r
ufs <- c(11:17, 21:29, 31:35, 41:43, 50:53)  # Códigos IBGE dos estados
anos <- 2015:2027  # Intervalo de anos
quadrimestres <- 1:3   # Intervalo de quadrimestres (1 a 3) no caso do RGF
bimestres <- 1:6 # Intervalo de bimestres (1 a 6) no caso do RREO
```

3. Execute todo script:

```r
source("extracao.R")
```
#### Se estiver utilizando o RStudio é possível executar o script linha a linha.


### Os dados serão salvos em um arquivo `.csv` no diretório `csv/rgf` ou `csv/rreo`.

---

## 🗂️ Fonte dos dados

- [API SICONFI - Tesouro Nacional](https://apidatalake.tesouro.gov.br/ords/siconfi/)

---

### Agora é só carregar os arquivos csv na sua ferramenta preferida e analisar os dados.


## 📄 Licença

Este projeto está sob a licença MIT.