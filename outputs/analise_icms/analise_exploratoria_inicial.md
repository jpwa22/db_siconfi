# Analise exploratoria inicial do ICMS

Arquivo analisado: `./icms.rds`.
Cobertura: 2022B1 a 2026B2, com 27 UFs.

## Leitura principal

- Periodo mais recente: **2026B2**.
- PE arrecadou R$ 28,1 bilhoes no total acumulado em 12 meses.
- Crescimento de PE contra o mesmo bimestre do ano anterior: **4,9%**.
- Crescimento do agregado Brasil: **5,8%**.
- Crescimento mediano entre UFs: **6,3%**.
- Diferenca PE - Brasil: **-0,9 p.p.**.
- Ranking de PE entre UFs no crescimento anual recente: **19 de 27**.

## Interpretacao inicial

- PE se move proximo ao agregado nacional no periodo mais recente.
- A comparacao usa a linha de total acumulado em 12 meses do RREO, pois ela evita duplicar as 12 linhas mensais existentes em cada bimestre informado.
- Para a comparacao regional, foi gerada uma serie historica do crescimento anual do valor do bimestre para MA, PI, CE, RN, PB, PE, AL, SE e BA.
- Na comparacao regional mais recente, PE cresceu **7,9%** no valor do bimestre e ficou na posicao **7 de 9** entre os estados do Nordeste.
- Os graficos e tabelas gerados nesta pasta permitem verificar se a diferenca de PE e persistente ou concentrada no periodo mais recente.

## Arquivos gerados

- `cobertura_periodos.csv`
- `total_12m_uf_periodo.csv`
- `valor_bimestre_uf_periodo.csv`
- `crescimento_yoy_uf.csv`
- `crescimento_bimestre_yoy_uf.csv`
- `crescimento_bimestre_yoy_nordeste.csv`
- `comparacao_recente_ufs.csv`
- `comparacao_recente_nordeste.csv`
- `resumo_pe_vs_brasil.csv`
- `serie_indice_pe_brasil_mediana.png`
- `crescimento_recente_ufs.png`
- `serie_yoy_nordeste.png`
- `crescimento_recente_nordeste.png`
