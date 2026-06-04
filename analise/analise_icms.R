library(tidyverse)

arquivo_icms <- "data/icms.rds"
dir_saida <- "outputs/analise_icms"

dir.create(dir_saida, recursive = TRUE, showWarnings = FALSE)

icms <- readRDS(arquivo_icms) |>
  mutate(
    exercicio = as.integer(exercicio),
    periodo = as.integer(periodo),
    valor = as.numeric(valor),
    uf = as.character(uf),
    coluna = as.character(coluna)
  )

fmt_num <- function(x) format(round(x, 1), big.mark = ".", decimal.mark = ",", scientific = FALSE)
fmt_pct <- function(x) ifelse(is.na(x), NA_character_, paste0(format(round(100 * x, 1), decimal.mark = ","), "%"))

cobertura <- icms |>
  count(exercicio, periodo, uf, name = "linhas") |>
  summarise(
    ufs = n_distinct(uf),
    linhas_min = min(linhas),
    linhas_max = max(linhas),
    .by = c(exercicio, periodo)
  ) |>
  arrange(exercicio, periodo)

total_12m <- icms |>
  filter(str_detect(str_to_upper(coluna), "TOTAL")) |>
  transmute(
    exercicio,
    periodo,
    periodo_ref = paste0(exercicio, "B", periodo),
    uf,
    instituicao,
    cod_ibge,
    valor_12m = valor,
    valor_12m_bilhoes = valor / 1e9
  ) |>
  arrange(uf, exercicio, periodo)

if (nrow(total_12m) == 0) {
  stop("Nao foram encontradas linhas de total em icms.rds.")
}

valor_bimestre <- icms |>
  filter(coluna %in% c("<MR-1>", "<MR>")) |>
  summarise(
    valor_bimestre = sum(valor, na.rm = TRUE),
    valor_bimestre_bilhoes = valor_bimestre / 1e9,
    .by = c(exercicio, periodo, uf, instituicao, cod_ibge)
  ) |>
  mutate(periodo_ref = paste0(exercicio, "B", periodo)) |>
  arrange(uf, exercicio, periodo)

crescimento_bimestre_yoy_uf <- valor_bimestre |>
  left_join(
    valor_bimestre |>
      transmute(
        uf,
        exercicio = exercicio + 1L,
        periodo,
        valor_bimestre_ano_anterior = valor_bimestre
      ),
    by = c("uf", "exercicio", "periodo")
  ) |>
  mutate(
    crescimento_yoy = valor_bimestre / valor_bimestre_ano_anterior - 1,
    crescimento_yoy_pct = 100 * crescimento_yoy
  )

crescimento_yoy_uf <- total_12m |>
  left_join(
    total_12m |>
      transmute(
        uf,
        exercicio = exercicio + 1L,
        periodo,
        valor_12m_ano_anterior = valor_12m
      ),
    by = c("uf", "exercicio", "periodo")
  ) |>
  mutate(
    crescimento_yoy = valor_12m / valor_12m_ano_anterior - 1,
    crescimento_yoy_pct = 100 * crescimento_yoy
  )

brasil_12m <- total_12m |>
  summarise(
    valor_12m = sum(valor_12m, na.rm = TRUE),
    valor_12m_bilhoes = valor_12m / 1e9,
    .by = c(exercicio, periodo, periodo_ref)
  ) |>
  arrange(exercicio, periodo) |>
  left_join(
    total_12m |>
      summarise(
        valor_12m_ano_anterior = sum(valor_12m, na.rm = TRUE),
        .by = c(exercicio, periodo)
      ) |>
      mutate(exercicio = exercicio + 1L),
    by = c("exercicio", "periodo")
  ) |>
  mutate(crescimento_yoy = valor_12m / valor_12m_ano_anterior - 1)

mediana_ufs <- crescimento_yoy_uf |>
  summarise(
    mediana_valor_12m = median(valor_12m, na.rm = TRUE),
    mediana_crescimento_yoy = median(crescimento_yoy, na.rm = TRUE),
    .by = c(exercicio, periodo, periodo_ref)
  )

ufs_nordeste <- c("MA", "PI", "CE", "RN", "PB", "PE", "AL", "SE", "BA")

crescimento_yoy_nordeste <- crescimento_bimestre_yoy_uf |>
  filter(uf %in% ufs_nordeste, !is.na(crescimento_yoy)) |>
  mutate(
    regiao = "Nordeste",
    destaque = if_else(uf == "PE", "PE", "Demais estados do Nordeste")
  ) |>
  arrange(uf, exercicio, periodo)

periodo_recente <- total_12m |>
  distinct(exercicio, periodo, periodo_ref) |>
  arrange(desc(exercicio), desc(periodo)) |>
  slice(1)

comparacao_recente_ufs <- crescimento_yoy_uf |>
  semi_join(periodo_recente, by = c("exercicio", "periodo", "periodo_ref")) |>
  mutate(
    ranking_crescimento = min_rank(desc(crescimento_yoy)),
    destaque = if_else(uf == "PE", "PE", "Demais UFs")
  ) |>
  arrange(desc(crescimento_yoy))

pe_recente <- comparacao_recente_ufs |> filter(uf == "PE")
brasil_recente <- brasil_12m |> semi_join(periodo_recente, by = c("exercicio", "periodo", "periodo_ref"))
mediana_recente <- mediana_ufs |> semi_join(periodo_recente, by = c("exercicio", "periodo", "periodo_ref"))

resumo_pe_vs_brasil <- tibble(
  periodo_ref = periodo_recente$periodo_ref,
  valor_pe_12m_bilhoes = pe_recente$valor_12m_bilhoes,
  crescimento_pe_yoy = pe_recente$crescimento_yoy,
  crescimento_brasil_yoy = brasil_recente$crescimento_yoy,
  crescimento_mediana_ufs_yoy = mediana_recente$mediana_crescimento_yoy,
  diferenca_pe_brasil_pontos_percentuais = 100 * (pe_recente$crescimento_yoy - brasil_recente$crescimento_yoy),
  ranking_pe_entre_ufs = pe_recente$ranking_crescimento,
  total_ufs = nrow(comparacao_recente_ufs)
)

serie_indice <- bind_rows(
  total_12m |>
    filter(uf == "PE") |>
    transmute(exercicio, periodo, periodo_ref, serie = "PE", valor = valor_12m),
  brasil_12m |>
    transmute(exercicio, periodo, periodo_ref, serie = "Brasil", valor = valor_12m),
  mediana_ufs |>
    transmute(exercicio, periodo, periodo_ref, serie = "Mediana das UFs", valor = mediana_valor_12m)
) |>
  arrange(serie, exercicio, periodo) |>
  group_by(serie) |>
  mutate(indice_base_100 = 100 * valor / first(valor)) |>
  ungroup()

readr::write_csv(cobertura, file.path(dir_saida, "cobertura_periodos.csv"))
readr::write_csv(total_12m, file.path(dir_saida, "total_12m_uf_periodo.csv"))
readr::write_csv(valor_bimestre, file.path(dir_saida, "valor_bimestre_uf_periodo.csv"))
readr::write_csv(crescimento_yoy_uf, file.path(dir_saida, "crescimento_yoy_uf.csv"))
readr::write_csv(crescimento_bimestre_yoy_uf, file.path(dir_saida, "crescimento_bimestre_yoy_uf.csv"))
readr::write_csv(crescimento_yoy_nordeste, file.path(dir_saida, "crescimento_bimestre_yoy_nordeste.csv"))
readr::write_csv(comparacao_recente_ufs, file.path(dir_saida, "comparacao_recente_ufs.csv"))
readr::write_csv(resumo_pe_vs_brasil, file.path(dir_saida, "resumo_pe_vs_brasil.csv"))

grafico_serie <- ggplot(serie_indice, aes(x = reorder(periodo_ref, exercicio + periodo / 10), y = indice_base_100, color = serie, group = serie)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = c("PE" = "#C43E3E", "Brasil" = "#2A6F97", "Mediana das UFs" = "#5F6F52")) +
  labs(
    title = "ICMS: PE contra Brasil e mediana das UFs",
    subtitle = "Indice do total acumulado em 12 meses, base 100 no primeiro periodo disponivel",
    x = NULL,
    y = "Indice base 100",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(dir_saida, "serie_indice_pe_brasil_mediana.png"), grafico_serie, width = 9, height = 5, dpi = 150)

grafico_recente <- ggplot(comparacao_recente_ufs, aes(x = reorder(uf, crescimento_yoy), y = crescimento_yoy, fill = destaque)) +
  geom_col(width = 0.75) +
  geom_hline(yintercept = brasil_recente$crescimento_yoy, linetype = "dashed", color = "#2A6F97") +
  geom_hline(yintercept = mediana_recente$mediana_crescimento_yoy, linetype = "dotted", color = "#5F6F52") +
  coord_flip() +
  scale_y_continuous(labels = \(x) paste0(round(100 * x, 1), "%")) +
  scale_fill_manual(values = c("PE" = "#C43E3E", "Demais UFs" = "#B8B8B8")) +
  labs(
    title = paste0("Crescimento do ICMS no periodo mais recente: ", periodo_recente$periodo_ref),
    subtitle = "Variacao do total acumulado em 12 meses contra o mesmo bimestre do ano anterior",
    x = NULL,
    y = "Crescimento anual",
    fill = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

ggsave(file.path(dir_saida, "crescimento_recente_ufs.png"), grafico_recente, width = 8, height = 7, dpi = 150)

grafico_nordeste <- ggplot(
  crescimento_yoy_nordeste,
  aes(
    x = reorder(periodo_ref, exercicio + periodo / 10),
    y = crescimento_yoy,
    color = uf,
    group = uf,
    linewidth = destaque,
    alpha = destaque
  )
) +
  geom_hline(yintercept = 0, color = "#5F5F5F", linewidth = 0.3) +
  geom_line() +
  geom_point(size = 2) +
  scale_y_continuous(labels = \(x) paste0(round(100 * x, 1), "%")) +
  scale_linewidth_manual(values = c("PE" = 1.3, "Demais estados do Nordeste" = 0.7)) +
  scale_alpha_manual(values = c("PE" = 1, "Demais estados do Nordeste" = 0.65)) +
  labs(
    title = "Crescimento do ICMS no Nordeste",
    subtitle = "Variacao do valor do bimestre contra o mesmo bimestre do ano anterior",
    x = NULL,
    y = "Crescimento anual",
    color = "UF",
    linewidth = NULL,
    alpha = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "right"
  )

ggsave(file.path(dir_saida, "serie_yoy_nordeste.png"), grafico_nordeste, width = 10, height = 5.8, dpi = 150)

comparacao_recente_nordeste <- crescimento_yoy_nordeste |>
  semi_join(periodo_recente, by = c("exercicio", "periodo", "periodo_ref")) |>
  mutate(ranking_crescimento_ne = min_rank(desc(crescimento_yoy))) |>
  arrange(desc(crescimento_yoy))

readr::write_csv(comparacao_recente_nordeste, file.path(dir_saida, "comparacao_recente_nordeste.csv"))

pe_recente_nordeste <- comparacao_recente_nordeste |> filter(uf == "PE")

grafico_recente_nordeste <- ggplot(comparacao_recente_nordeste, aes(x = reorder(uf, crescimento_yoy), y = crescimento_yoy, fill = destaque)) +
  geom_col(width = 0.75) +
  coord_flip() +
  scale_y_continuous(labels = \(x) paste0(round(100 * x, 1), "%")) +
  scale_fill_manual(values = c("PE" = "#C43E3E", "Demais estados do Nordeste" = "#B8B8B8")) +
  labs(
    title = paste0("Crescimento do ICMS no Nordeste: ", periodo_recente$periodo_ref),
    subtitle = "Variacao do valor do bimestre contra o mesmo bimestre do ano anterior",
    x = NULL,
    y = "Crescimento anual",
    fill = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

ggsave(file.path(dir_saida, "crescimento_recente_nordeste.png"), grafico_recente_nordeste, width = 8, height = 5, dpi = 150)

interpretacao <- case_when(
  resumo_pe_vs_brasil$diferenca_pe_brasil_pontos_percentuais > 1 ~ "PE cresce acima do agregado nacional no periodo mais recente.",
  resumo_pe_vs_brasil$diferenca_pe_brasil_pontos_percentuais < -1 ~ "PE cresce abaixo do agregado nacional no periodo mais recente.",
  TRUE ~ "PE se move proximo ao agregado nacional no periodo mais recente."
)

linhas_md <- c(
  "# Analise exploratoria inicial do ICMS",
  "",
  paste0("Arquivo analisado: `", arquivo_icms, "`."),
  paste0("Cobertura: ", min(total_12m$periodo_ref), " a ", max(total_12m$periodo_ref), ", com ", n_distinct(total_12m$uf), " UFs."),
  "",
  "## Leitura principal",
  "",
  paste0("- Periodo mais recente: **", resumo_pe_vs_brasil$periodo_ref, "**."),
  paste0("- PE arrecadou R$ ", fmt_num(resumo_pe_vs_brasil$valor_pe_12m_bilhoes), " bilhoes no total acumulado em 12 meses."),
  paste0("- Crescimento de PE contra o mesmo bimestre do ano anterior: **", fmt_pct(resumo_pe_vs_brasil$crescimento_pe_yoy), "**."),
  paste0("- Crescimento do agregado Brasil: **", fmt_pct(resumo_pe_vs_brasil$crescimento_brasil_yoy), "**."),
  paste0("- Crescimento mediano entre UFs: **", fmt_pct(resumo_pe_vs_brasil$crescimento_mediana_ufs_yoy), "**."),
  paste0("- Diferenca PE - Brasil: **", fmt_num(resumo_pe_vs_brasil$diferenca_pe_brasil_pontos_percentuais), " p.p.**."),
  paste0("- Ranking de PE entre UFs no crescimento anual recente: **", resumo_pe_vs_brasil$ranking_pe_entre_ufs, " de ", resumo_pe_vs_brasil$total_ufs, "**."),
  "",
  "## Interpretacao inicial",
  "",
  paste0("- ", interpretacao),
  "- A comparacao usa a linha de total acumulado em 12 meses do RREO, pois ela evita duplicar as 12 linhas mensais existentes em cada bimestre informado.",
  "- Para a comparacao regional, foi gerada uma serie historica do crescimento anual do valor do bimestre para MA, PI, CE, RN, PB, PE, AL, SE e BA.",
  paste0(
    "- Na comparacao regional mais recente, PE cresceu **",
    fmt_pct(pe_recente_nordeste$crescimento_yoy),
    "** no valor do bimestre e ficou na posicao **",
    pe_recente_nordeste$ranking_crescimento_ne,
    " de ",
    nrow(comparacao_recente_nordeste),
    "** entre os estados do Nordeste."
  ),
  "- Os graficos e tabelas gerados nesta pasta permitem verificar se a diferenca de PE e persistente ou concentrada no periodo mais recente.",
  "",
  "## Arquivos gerados",
  "",
  "- `cobertura_periodos.csv`",
  "- `total_12m_uf_periodo.csv`",
  "- `valor_bimestre_uf_periodo.csv`",
  "- `crescimento_yoy_uf.csv`",
  "- `crescimento_bimestre_yoy_uf.csv`",
  "- `crescimento_bimestre_yoy_nordeste.csv`",
  "- `comparacao_recente_ufs.csv`",
  "- `comparacao_recente_nordeste.csv`",
  "- `resumo_pe_vs_brasil.csv`",
  "- `serie_indice_pe_brasil_mediana.png`",
  "- `crescimento_recente_ufs.png`",
  "- `serie_yoy_nordeste.png`",
  "- `crescimento_recente_nordeste.png`"
)

writeLines(linhas_md, file.path(dir_saida, "analise_exploratoria_inicial.md"), useBytes = TRUE)

print(comparacao_recente_nordeste |> select(uf, periodo_ref, valor_bimestre_bilhoes, crescimento_yoy_pct, ranking_crescimento_ne))
message("Analise salva em: ", normalizePath(dir_saida, winslash = "/"))
