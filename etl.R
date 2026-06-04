library(tidyverse)
library(data.table)

caminho_pasta <- "data/csv/rreo"

# Listar todos os arquivos CSV na pasta
arquivos_csv <- list.files(caminho_pasta, pattern = "\\.csv$", full.names = TRUE)

# Ler e combinar todos os arquivos CSV em um único objeto
# Usando data.table::fread para eficiência
dados_combinados <- rbindlist(lapply(arquivos_csv, fread), fill = TRUE)

# Converter para tibble (opcional, se você preferir usar o dplyr)
# Atribuir o data frame a um objeto com o nome especificado
dados_combinados <- as_tibble(dados_combinados)

glimpse(dados_combinados)


colunas_rreo_mensais <- c(
  "<MR-11>", "<MR-10>", "<MR-9>", "<MR-8>", "<MR-7>", "<MR-6>",
  "<MR-5>", "<MR-4>", "<MR-3>", "<MR-2>", "<MR-1>", "<MR>"
)

mes_rreo_mensal <- c(
  "<MR-11>" = 5,
  "<MR-10>" = 6,
  "<MR-9>" = 7,
  "<MR-8>" = 8,
  "<MR-7>" = 9,
  "<MR-6>" = 10,
  "<MR-5>" = 11,
  "<MR-4>" = 12,
  "<MR-3>" = 1,
  "<MR-2>" = 2,
  "<MR-1>" = 3,
  "<MR>" = 4
)

df <- dados_combinados |>
  filter(anexo == "RREO-Anexo 03", cod_conta == "ICMSLiquidoExcetoTransferenciasEFUNDEB") |>
  mutate(mes = unname(mes_rreo_mensal[coluna]))

saveRDS(df, "data/icms.rds")
icms <- readRDS("data/icms.rds")
readr::write_excel_csv2(icms, "data/csv/icms.csv")
