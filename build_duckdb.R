library(DBI)
library(duckdb)

csv_root <- file.path("extracao", "csv")
db_path <- file.path("data", "siconfi.duckdb")

rreo_glob <- file.path(csv_root, "rreo", "*.csv")
rgf_glob <- file.path(csv_root, "rgf", "*.csv")

dir.create(dirname(db_path), recursive = TRUE, showWarnings = FALSE)

if (file.exists(db_path)) {
  invisible(file.remove(db_path))
}

con <- dbConnect(duckdb(), dbdir = db_path, read_only = FALSE)
on.exit({
  dbDisconnect(con, shutdown = TRUE)
}, add = TRUE)

read_csv_sql <- function(glob) {
  sprintf(
    "read_csv(%s, delim=';', header=true, union_by_name=true, filename=true, all_varchar=false)",
    dbQuoteString(con, glob)
  )
}

invisible(dbExecute(con, sprintf("
  CREATE TABLE rreo AS
  SELECT *
  FROM %s
", read_csv_sql(rreo_glob))))

invisible(dbExecute(con, sprintf("
  CREATE TABLE rgf AS
  SELECT *
  FROM %s
", read_csv_sql(rgf_glob))))

rreo_files <- list.files(file.path(csv_root, "rreo"), pattern = "\\.csv$", full.names = TRUE)
rgf_files <- list.files(file.path(csv_root, "rgf"), pattern = "\\.csv$", full.names = TRUE)

arquivos <- data.frame(
  relatorio = c(rep("rreo", length(rreo_files)), rep("rgf", length(rgf_files))),
  caminho = normalizePath(c(rreo_files, rgf_files), winslash = "/", mustWork = FALSE),
  stringsAsFactors = FALSE
)

if (nrow(arquivos) > 0) {
  info <- file.info(arquivos$caminho)
  arquivos$tamanho_bytes <- as.numeric(info$size)
  arquivos$modificado_em <- as.POSIXct(info$mtime)
}

invisible(dbWriteTable(con, "arquivos_csv", arquivos, overwrite = TRUE))

invisible(dbExecute(con, "
  CREATE TABLE resumo_importacao AS
  SELECT 'rreo' AS relatorio, COUNT(*) AS linhas, COUNT(DISTINCT filename) AS arquivos
  FROM rreo
  UNION ALL
  SELECT 'rgf' AS relatorio, COUNT(*) AS linhas, COUNT(DISTINCT filename) AS arquivos
  FROM rgf
"))

invisible(dbExecute(con, "CREATE INDEX idx_rreo_ano_uf_periodo ON rreo(exercicio, uf, periodo)"))
invisible(dbExecute(con, "CREATE INDEX idx_rreo_anexo ON rreo(anexo)"))
invisible(dbExecute(con, "CREATE INDEX idx_rgf_ano_uf_periodo ON rgf(exercicio, uf, periodo)"))
invisible(dbExecute(con, "CREATE INDEX idx_rgf_anexo ON rgf(anexo)"))

invisible(dbExecute(con, "CHECKPOINT"))

print(dbGetQuery(con, "SELECT * FROM resumo_importacao ORDER BY relatorio"))
message("Banco DuckDB criado em: ", normalizePath(db_path, winslash = "/", mustWork = FALSE))