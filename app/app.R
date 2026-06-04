library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(plotly)
library(DT)
library(scales)

ufs_nordeste <- c("MA", "PI", "CE", "RN", "PB", "PE", "AL", "SE", "BA")

icms <- readRDS("data/icms.rds") |>
  mutate(
    exercicio = as.integer(exercicio),
    periodo = as.integer(periodo),
    valor = as.numeric(valor),
    uf = as.character(uf),
    coluna = as.character(coluna)
  )

valor_bimestre <- icms |>
  filter(coluna %in% c("<MR-1>", "<MR>")) |>
  summarise(
    valor_bimestre = sum(valor, na.rm = TRUE),
    valor_bimestre_bilhoes = valor_bimestre / 1e9,
    .by = c(exercicio, periodo, uf, instituicao, cod_ibge)
  ) |>
  mutate(
    periodo_ref = paste0(exercicio, "B", periodo),
    periodo_ordem = exercicio * 10 + periodo
  ) |>
  arrange(uf, exercicio, periodo)

crescimento_yoy <- valor_bimestre |>
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

periodos_disponiveis <- crescimento_yoy |>
  filter(!is.na(crescimento_yoy)) |>
  distinct(periodo_ref, periodo_ordem) |>
  arrange(desc(periodo_ordem))

period_levels <- crescimento_yoy |>
  distinct(periodo_ref, periodo_ordem) |>
  arrange(periodo_ordem) |>
  pull(periodo_ref)

ufs_disponiveis <- sort(unique(crescimento_yoy$uf))

choices_conjunto <- c(
  "Nordeste" = "nordeste",
  "Todas as UFs" = "todas",
  "Selecionar manualmente" = "manual"
)

ui <- fluidPage(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  tags$head(
    tags$style(HTML("
      body { background: #f7f8fa; }
      .app-title { margin: 18px 0 6px; font-weight: 700; }
      .app-subtitle { color: #5d6978; margin-bottom: 18px; }
      .panel { background: #ffffff; border: 1px solid #dfe4ea; border-radius: 8px; padding: 16px; margin-bottom: 16px; }
      .metric { background: #ffffff; border: 1px solid #dfe4ea; border-radius: 8px; padding: 14px 16px; min-height: 96px; }
      .metric-label { color: #5d6978; font-size: 0.86rem; margin-bottom: 8px; }
      .metric-value { font-size: 1.55rem; font-weight: 700; line-height: 1.15; }
      .metric-note { color: #6c757d; font-size: 0.82rem; margin-top: 6px; }
      .selectize-input, .form-select, .form-control { border-radius: 6px; }
    "))
  ),
  div(class = "app-title h3", "Dashboard ICMS"),
  div(class = "app-subtitle", "Comparacao dinamica do crescimento do valor do bimestre contra o mesmo bimestre do ano anterior."),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("periodo_ref", "Bimestre de referencia", choices = periodos_disponiveis$periodo_ref, selected = periodos_disponiveis$periodo_ref[1]),
      selectInput("uf_foco", "UF em destaque", choices = ufs_disponiveis, selected = "PE"),
      selectInput("conjunto", "Grupo de comparacao", choices = choices_conjunto, selected = "nordeste"),
      conditionalPanel(
        condition = "input.conjunto == 'manual'",
        selectizeInput("ufs_manual", "UFs selecionadas", choices = ufs_disponiveis, selected = ufs_nordeste, multiple = TRUE)
      ),
      checkboxInput("mostrar_mediana", "Mostrar mediana do grupo", value = TRUE),
      checkboxInput("mostrar_barras", "Mostrar ranking do bimestre", value = TRUE),
      helpText("A variacao e calculada como valor do bimestre corrente dividido pelo mesmo bimestre do ano anterior menos 1.")
    ),
    mainPanel(
      width = 9,
      fluidRow(
        column(3, div(class = "metric", div(class = "metric-label", "UF em destaque"), div(class = "metric-value", textOutput("metric_uf")), div(class = "metric-note", textOutput("metric_periodo")))),
        column(3, div(class = "metric", div(class = "metric-label", "Valor do bimestre"), div(class = "metric-value", textOutput("metric_valor")), div(class = "metric-note", "R$ bilhoes"))),
        column(3, div(class = "metric", div(class = "metric-label", "Crescimento anual"), div(class = "metric-value", textOutput("metric_crescimento")), div(class = "metric-note", textOutput("metric_base")))),
        column(3, div(class = "metric", div(class = "metric-label", "Ranking no grupo"), div(class = "metric-value", textOutput("metric_ranking")), div(class = "metric-note", textOutput("metric_grupo"))))
      ),
      div(class = "panel", plotlyOutput("serie_yoy", height = "420px")),
      conditionalPanel(
        condition = "input.mostrar_barras == true",
        div(class = "panel", plotlyOutput("ranking_periodo", height = "420px"))
      ),
      div(class = "panel", DTOutput("tabela_periodo"))
    )
  )
)

server <- function(input, output, session) {
  grupo_ufs <- reactive({
    if (input$conjunto == "nordeste") {
      intersect(ufs_nordeste, ufs_disponiveis)
    } else if (input$conjunto == "todas") {
      ufs_disponiveis
    } else {
      req(input$ufs_manual)
      input$ufs_manual
    }
  })

  dados_grupo <- reactive({
    ufs <- unique(c(input$uf_foco, grupo_ufs()))

    crescimento_yoy |>
      filter(uf %in% ufs, !is.na(crescimento_yoy)) |>
      mutate(
        destaque = if_else(uf == input$uf_foco, input$uf_foco, "Grupo"),
        periodo_ref = factor(periodo_ref, levels = period_levels)
      )
  })

  dados_periodo <- reactive({
    dados_grupo() |>
      filter(as.character(periodo_ref) == input$periodo_ref) |>
      mutate(
        ranking = min_rank(desc(crescimento_yoy)),
        destaque = if_else(uf == input$uf_foco, input$uf_foco, "Grupo")
      ) |>
      arrange(desc(crescimento_yoy))
  })

  dados_foco_periodo <- reactive({
    dados_periodo() |> filter(uf == input$uf_foco) |> slice(1)
  })

  output$metric_uf <- renderText(input$uf_foco)
  output$metric_periodo <- renderText(input$periodo_ref)

  output$metric_valor <- renderText({
    foco <- dados_foco_periodo()
    req(nrow(foco) > 0)
    number(foco$valor_bimestre_bilhoes, accuracy = 0.01, big.mark = ".", decimal.mark = ",")
  })

  output$metric_crescimento <- renderText({
    foco <- dados_foco_periodo()
    req(nrow(foco) > 0)
    percent(foco$crescimento_yoy, accuracy = 0.1, decimal.mark = ",")
  })

  output$metric_base <- renderText({
    foco <- dados_foco_periodo()
    req(nrow(foco) > 0)
    paste0(foco$exercicio, "B", foco$periodo, " / ", foco$exercicio - 1L, "B", foco$periodo)
  })

  output$metric_ranking <- renderText({
    foco <- dados_foco_periodo()
    req(nrow(foco) > 0)
    paste0(foco$ranking, " de ", nrow(dados_periodo()))
  })

  output$metric_grupo <- renderText({
    if (input$conjunto == "nordeste") {
      "Estados do Nordeste"
    } else if (input$conjunto == "todas") {
      "Todas as UFs"
    } else {
      "Selecao manual"
    }
  })

  output$serie_yoy <- renderPlotly({
    dados <- dados_grupo()

    if (isTRUE(input$mostrar_mediana)) {
      mediana <- dados |>
        filter(uf %in% grupo_ufs()) |>
        summarise(
          crescimento_yoy = median(crescimento_yoy, na.rm = TRUE),
          .by = c(periodo_ref, periodo_ordem)
        ) |>
        mutate(uf = "Mediana do grupo", destaque = "Mediana")

      dados_plot <- bind_rows(dados, mediana)
    } else {
      dados_plot <- dados
    }

    p <- ggplot(dados_plot, aes(
      x = periodo_ref,
      y = crescimento_yoy,
      color = uf,
      group = uf,
      text = paste0(
        "UF: ", uf,
        "<br>Bimestre: ", periodo_ref,
        "<br>Crescimento: ", percent(crescimento_yoy, accuracy = 0.1, decimal.mark = ",")
      )
    )) +
      geom_hline(yintercept = 0, color = "#59636f", linewidth = 0.3) +
      geom_line(aes(linewidth = destaque, alpha = destaque)) +
      geom_point(aes(size = destaque)) +
      scale_y_continuous(labels = label_percent(accuracy = 0.1, decimal.mark = ",")) +
      scale_linewidth_manual(values = setNames(c(0.7, 1.1, 1.4), c("Grupo", "Mediana", input$uf_foco)), guide = "none") +
      scale_alpha_manual(values = setNames(c(0.55, 0.9, 1), c("Grupo", "Mediana", input$uf_foco)), guide = "none") +
      scale_size_manual(values = setNames(c(1.5, 1.8, 2.4), c("Grupo", "Mediana", input$uf_foco)), guide = "none") +
      labs(
        title = "Serie historica da variacao anual do ICMS por bimestre",
        subtitle = "Valor do bimestre contra o mesmo bimestre do ano anterior",
        x = NULL,
        y = "Crescimento anual",
        color = "Serie"
      ) +
      theme_minimal(base_size = 12) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))

    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "v"))
  })

  output$ranking_periodo <- renderPlotly({
    dados <- dados_periodo()

    p <- ggplot(dados, aes(
      x = reorder(uf, crescimento_yoy),
      y = crescimento_yoy,
      fill = destaque,
      text = paste0(
        "UF: ", uf,
        "<br>Bimestre: ", input$periodo_ref,
        "<br>Valor: R$ ", number(valor_bimestre_bilhoes, accuracy = 0.01, big.mark = ".", decimal.mark = ","), " bi",
        "<br>Crescimento: ", percent(crescimento_yoy, accuracy = 0.1, decimal.mark = ","),
        "<br>Ranking: ", ranking
      )
    )) +
      geom_col(width = 0.75) +
      coord_flip() +
      scale_y_continuous(labels = label_percent(accuracy = 0.1, decimal.mark = ",")) +
      scale_fill_manual(values = setNames(c("#aeb7c2", "#c43e3e"), c("Grupo", input$uf_foco)), guide = "none") +
      labs(
        title = paste0("Ranking do crescimento no bimestre ", input$periodo_ref),
        subtitle = "Valor do bimestre contra o mesmo bimestre do ano anterior",
        x = NULL,
        y = "Crescimento anual"
      ) +
      theme_minimal(base_size = 12)

    ggplotly(p, tooltip = "text")
  })

  output$tabela_periodo <- renderDT({
    dados_periodo() |>
      transmute(
        Ranking = ranking,
        UF = uf,
        Bimestre = as.character(periodo_ref),
        `Valor do bimestre (R$ bi)` = round(valor_bimestre_bilhoes, 2),
        `Valor ano anterior (R$ bi)` = round(valor_bimestre_ano_anterior / 1e9, 2),
        `Crescimento anual` = percent(crescimento_yoy, accuracy = 0.1, decimal.mark = ",")
      ) |>
      datatable(
        rownames = FALSE,
        options = list(pageLength = 15, order = list(list(0, "asc")), dom = "tip")
      )
  })
}

shinyApp(ui, server)
