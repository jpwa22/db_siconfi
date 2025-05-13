# Carregar bibliotecas
library(RPostgres)
library(data.table)
library(DBI)
library(dplyr)

# Configuração do banco de dados PostgreSQL
db_host <- "localhost"    # Substitua pelo host do PostgreSQL
db_port <- 5432           # Porta padrão
db_name <- "compara_estados"    # Nome do banco de dados
db_user <- "postgres"  # Nome do usuário
db_password <- "1234"  # Senha do usuário





# Função para juntar os csvs e salvar em objetos

salvar_csvs <- function(caminho_pasta,tabela) {
  # Listar todos os arquivos CSV na pasta
  arquivos_csv <- list.files(caminho_pasta, pattern = "\\.csv$", full.names = TRUE)
  
  # Ler e combinar todos os arquivos CSV em um único objeto
  # Usando data.table::fread para eficiência
  dados_combinados <- rbindlist(lapply(arquivos_csv, fread), fill = TRUE)
  
  # Converter para tibble (opcional, se você preferir usar o dplyr)
  # Atribuir o data frame a um objeto com o nome especificado
   dados_combinados <- as_tibble(dados_combinados)
   
   assign(tabela, dados_combinados, envir = .GlobalEnv)
   
   # Conectar ao banco de dados
   con <- dbConnect(
     RPostgres::Postgres(),
     dbname = db_name,
     host = db_host,
     port = db_port,
     user = db_user,
     password = db_password
   )
   
   # Importar para o banco de dados
   dbWriteTable(
     con,
     name = tabela,
     value = dados_combinados,
     row.names = FALSE,
     overwrite = TRUE  # Substituir a tabela se ela já existir
   )
   
   cat(sprintf("Tabela '%s' criada com sucesso \n", tabela))
   
   # Fechar conexão com o banco de dados
   dbDisconnect(con)
   
   openxlsx::write.xlsx(dados_combinados,
                        paste0("excel/",tabela,".xlsx")
                        
                        )
}

# Salvando as tabelas
salvar_csvs( "H:\\Meu Drive\\IGPE\\compara_estados\\bases\\rgf6","rgf6")

salvar_csvs( "H:\\Meu Drive\\IGPE\\compara_estados\\bases\\rreo1","rreo1")

salvar_csvs( "H:\\Meu Drive\\IGPE\\compara_estados\\bases\\rreo3","rreo3")
