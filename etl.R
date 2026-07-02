library(DBI)
library(duckdb)
library(tidyverse)

db_path <- file.path("data", "siconfi.duckdb")

if (!file.exists(db_path)) {
  stop(
    "Banco DuckDB não encontrado em ", db_path, ". ",
    "Execute source('build_duckdb.R') antes do ETL."
  )
}

con <- dbConnect(duckdb(), dbdir = db_path, read_only = TRUE)
on.exit({
  dbDisconnect(con, shutdown = TRUE)
}, add = TRUE)

icms <- dbGetQuery(con, "
  SELECT
    *,
    CASE coluna
      WHEN '<MR-11>' THEN 5
      WHEN '<MR-10>' THEN 6
      WHEN '<MR-9>' THEN 7
      WHEN '<MR-8>' THEN 8
      WHEN '<MR-7>' THEN 9
      WHEN '<MR-6>' THEN 10
      WHEN '<MR-5>' THEN 11
      WHEN '<MR-4>' THEN 12
      WHEN '<MR-3>' THEN 1
      WHEN '<MR-2>' THEN 2
      WHEN '<MR-1>' THEN 3
      WHEN '<MR>' THEN 4
    END AS mes
  FROM rreo
  WHERE anexo = 'RREO-Anexo 03'
    AND cod_conta = 'ICMSLiquidoExcetoTransferenciasEFUNDEB'
") |>
  as_tibble()

glimpse(icms)

dir.create(file.path("data", "csv"), recursive = TRUE, showWarnings = FALSE)

saveRDS(icms, file.path("data", "icms.rds"))
readr::write_excel_csv2(icms, file.path("data", "csv", "icms.csv"))
