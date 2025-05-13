# Extração de Dados Fiscais via API Siconfi

## 📊 Sobre o Siconfi

O **Siconfi (Sistema de Informações Contábeis e Fiscais do Setor Público Brasileiro)** é uma plataforma do Tesouro Nacional que reúne e divulga dados fiscais, contábeis e orçamentários de estados e municípios brasileiros. O sistema promove a transparência da gestão fiscal e é fundamental para o monitoramento da responsabilidade na administração pública.

Entre os principais relatórios disponíveis no Siconfi, destacam-se:

* **RREO (Relatório Resumido da Execução Orçamentária)**: apresenta a execução orçamentária bimestral dos entes federativos, com informações sobre receitas, despesas, resultado primário, entre outros indicadores fiscais exigidos pela Lei de Responsabilidade Fiscal (LRF).

* **RGF (Relatório de Gestão Fiscal)**: divulgado quadrimestralmente, traz informações sobre limites de despesa com pessoal, endividamento, concessão de garantias e outros dados que evidenciam o cumprimento das regras fiscais previstas na LRF.

## 🎯 Objetivo do Repositório

O objetivo principal deste repositório é **automatizar a extração de dados dos relatórios RGF e RREO utilizando a API pública do Siconfi**. Os scripts contidos aqui permitem acessar os dados de forma estruturada, facilitando análises comparativas, monitoramento de indicadores fiscais e elaboração de painéis e relatórios. A extração pode ser realizada em Python ou R.

## 🧰 Funcionalidades

* Consulta programática de dados do RGF e RREO por UF, ano e período
* Salvamento local dos dados em formato `.csv`

## 📁 Organização

```
📂/etl
   └── extracao.ipynb
   └── extracao.R
📂/etl/csv
   └── arquivos extraídos em CSV
README.md
requirements.txt
```

## 📌 Referências

* [Portal Siconfi](https://www.tesourotransparente.gov.br/temas/siconfi)
* [API Siconfi - Tesouro Nacional](https://apidatalake.tesouro.gov.br/swagger-ui.html)

