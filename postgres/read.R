# Instale os pacotes necessários, se ainda não tiver
if (!requireNamespace("RPostgres", quietly = TRUE)) install.packages("RPostgres")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("dbplyr", quietly = TRUE)) install.packages("dbplyr")
if (!requireNamespace("DBI", quietly = TRUE)) install.packages("DBI")

# Carregar bibliotecas
library(RPostgres)
library(dplyr)
library(dbplyr)
library(DBI)

# Configuração do banco de dados PostgreSQL
db_host <- "localhost"    # Substitua pelo host do PostgreSQL
db_port <- 5432           # Porta padrão
db_name <- "compara_estados"    # Nome do banco de dados
db_user <- "postgres"  # Nome do usuário
db_password <- "1234"  # Senha do usuário

# Conectar ao banco de dados
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = db_name,
  host = db_host,
  port = db_port,
  user = db_user,
  password = db_password
)



# Nome da tabela no banco de dados que você deseja carregar
nome_tabela <- "rgf6"


# Ler as tabelas
rgf6 <- as_tibble(tbl(con, "rgf6"))
rreo1 <- as_tibble(tbl(con, "rreo1"))
rreo3 <- as_tibble(tbl(con, "rreo3"))

# Encerrar conexão ao banco de dados
dbDisconnect(con)


# Data Cleanning ----------------------------------------------------------

# power bi --------------------------------------------------------------------

df1 <- rreo1 |> select("exercicio", "periodo", "periodicidade", "cod_ibge", "uf", "populacao", 
                      "anexo", "coluna", "cod_conta", "conta", "valor")|> 
              filter(coluna == "No Bimestre (b)" | coluna == "DESPESAS LIQUIDADAS NO BIMESTRE") |> 
              mutate(quadrimestre =  if_else(periodo <=2,1,if_else(periodo <= 4,2,3)),
                     fonte = "rre01"
                     )
               
df2 <-   rreo3 |>  select("exercicio", "periodo", "periodicidade", "cod_ibge", "uf", "populacao", 
                   "anexo", "coluna", "cod_conta", "conta", "valor")|>
  filter((coluna == "<MR-1>" | coluna == "<MR>") & (conta == "RECEITA CORRENTE LÍQUIDA AJUSTADA PARA CÁLCULO DOS LIMITES DA DESPESA COM PESSOAL (IX) = (V - VI - VII - VIII)" 
         | conta == "RECEITA CORRENTE LÍQUIDA AJUSTADA PARA CÁLCULO DOS LIMITES DA DESPESA COM PESSOAL (VII) = (V - VI)" | conta == "RECEITA CORRENTE LÍQUIDA (III) = (I - II)" |
           conta == "RECEITA CORRENTE LÍQUIDA AJUSTADA PARA CÁLCULO DOS LIMITES DE ENDIVIDAMENTO (V) = (III - IV)"
         )) |> mutate(coluna = "No Bimestre",
                      quadrimestre =  if_else(periodo <=2,1,if_else(periodo <= 4,2,3)),
                      fonte = "rreo3"
                      )
df3 <-  rgf6 |> select("exercicio", "periodo", "periodicidade", "cod_ibge", "uf", "populacao", 
                       "anexo", "coluna", "cod_conta", "conta", "valor")|> 
                mutate(quadrimestre = as.numeric(periodo),
                       fonte = "rgf6"
                       )

df <- rbind(df1,df2,df3)

saveRDS(df,"compara_estados.rds")
openxlsx::write.xlsx(df,"excel/compara_estados.xlsx")













# FULL --------------------------------------------------------------------

df1 <- rreo1 |> select("exercicio", "periodo", "periodicidade", "cod_ibge", "uf", "populacao", 
                       "anexo", "coluna", "cod_conta", "conta", "valor")|> 
  mutate(quadrimestre =  if_else(periodo <=2,1,if_else(periodo <= 4,2,3)),
         fonte = "rre01"
  )

df2 <-   rreo3 |>  select("exercicio", "periodo", "periodicidade", "cod_ibge", "uf", "populacao", 
                          "anexo", "coluna", "cod_conta", "conta", "valor")|>
                   mutate(coluna = "No Bimestre",
               quadrimestre =  if_else(periodo <=2,1,if_else(periodo <= 4,2,3)),
               fonte = "rreo3"
  )
df3 <-  rgf6 |> select("exercicio", "periodo", "periodicidade", "cod_ibge", "uf", "populacao", 
                       "anexo", "coluna", "cod_conta", "conta", "valor")|> 
  mutate(quadrimestre = as.numeric(periodo),
         fonte = "rgf6"
  )

df <- rbind(df1,df2,df3)

saveRDS(df,"compara_estados_full.rds")
openxlsx::write.xlsx(df,"excel/compara_estados_full.xlsx")





# Tabelão com as colunas comuns -----------------------------------------------------------------



# Salvando o tabelão e salvando no Excel
# df <- rbind(
#             rgf6,-which(colnames(rgf6) == "co_poder"),
#             rreo1,-which(colnames(rreo1) == "demonstrativo")
#           )
# df <- rbind(df,
#             rreo3,-which(colnames(rreo3) == "demonstrativo")
#             )


