library(httr)
library(jsonlite)
library(readr)
library(fs)

# Função para baixar RREO
baixar_dados_rreo <- function(ano, bimestre, uf) {
  url <- sprintf("https://apidatalake.tesouro.gov.br/ords/siconfi/tt/rreo?an_exercicio=%s&nr_periodo=%s&co_tipo_demonstrativo=RREO&no_anexo=&co_esfera=E&id_ente=%s",
                 ano, bimestre, uf)
  resposta <- GET(url)
  if (status_code(resposta) == 200) {
    conteudo <- content(resposta, as = "text", encoding = "UTF-8")
    dados <- fromJSON(conteudo)
    if (!is.null(dados$items) && length(dados$items) > 0) {
      df <- as.data.frame(dados$items)
      dir_create("csv/rreo")
      caminho <- sprintf("csv/rreo/rreo_%s_b%s_uf%s.csv", ano, bimestre, uf)
      write_csv2(df, caminho)
      message(sprintf("✔️ RREO salvo: %s", caminho))
    } else {
      message(sprintf("⚠️ Nenhum RREO para %s Bim %s UF %s", ano, bimestre, uf))
    }
  } else {
    warning(sprintf("❌ Erro RREO %s Bim %s UF %s", ano, bimestre, uf))
  }
}

# Função para baixar RGF
baixar_dados_rgf <- function(ano, quadrimestre, uf) {
  url <- sprintf("https://apidatalake.tesouro.gov.br/ords/siconfi/tt/rgf?an_exercicio=%s&nr_periodo=%s&co_tipo_demonstrativo=RGF&id_ente=%s",
                 ano, quadrimestre, uf)
  resposta <- GET(url)
  if (status_code(resposta) == 200) {
    conteudo <- content(resposta, as = "text", encoding = "UTF-8")
    dados <- fromJSON(conteudo)
    if (!is.null(dados$items) && length(dados$items) > 0) {
      df <- as.data.frame(dados$items)
      dir_create("csv/rgf")
      caminho <- sprintf("csv/rgf/rgf_%s_q%s_uf%s.csv", ano, quadrimestre, uf)
      write_csv2(df, caminho)
      message(sprintf("✔️ RGF salvo: %s", caminho))
    } else {
      message(sprintf("⚠️ Nenhum RGF para %s Quad %s UF %s", ano, quadrimestre, uf))
    }
  } else {
    warning(sprintf("❌ Erro RGF %s Quad %s UF %s", ano, quadrimestre, uf))
  }
}


ufs <- c(11:17, 21:29, 31:35, 41:43, 50:53)  # Códigos IBGE dos estados
anos <- 2015:2027  # Intervalo de anos
quadrimestres <- 1:3   # Intervalo de quadrimestres (1 a 6)
bimestres <- 1:6 # Intervalo de bimestres (1 a 6)

# Loop para todos os estados (UFs de 11 a 53), todos os períodos
for (ano in anos) {
  for (uf in ufs) {
    for (b in bimestres) {
      baixar_dados_rreo(ano, b, uf)
    }
    for (q in quadrimestres) {
      baixar_dados_rgf(ano, q, uf)
    }
  }
}


