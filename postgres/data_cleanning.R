library(dplyr)

df <- readRDS("compara_estados.rds")
contas <- unique(df$conta)
write.csv2(contas, "contas.csv", )
cod_conta <- unique(df$cod_conta)
write.csv2(cod_conta, "cod_conta.csv")


df <- df |> mutate(  mês = case_when(
  quadrimestre == 1 ~ 1, # Se quadrimestre é 1, novo_valor será 1
  quadrimestre == 2 ~ 5, # Se quadrimestre é 2, novo_valor será 5
  quadrimestre == 3 ~ 9, # Se quadrimestre é 3, novo_valor será 9
  TRUE ~ NA_real_ # Caso contrário, será NA (opcional)
            )) |> mutate(
              data.ano = lubridate::dmy(paste0("01/",mês,"/",exercicio ))
            )
coluna = which(colnames(df) %in% "mês")
df <- df[,-coluna]


# Definir a função que retorna o total de investimentos
investimento_total <- function(data) {
  data %>%
    filter(
      conta %in% c("INVESTIMENTOS", "INVERSÕES FINANCEIRAS") & 
        cod_conta %in% c("Investimentos", "InversoesFinaceiras")
    ) %>%
    summarise(total = sum(valor, na.rm = TRUE)) %>%
    pull(total) # Extrai o valor numérico do resultado
}

# Definir a função que retorna o total da receita corrente
rc_total <- function(data) {
  data %>%
    filter(
      conta %in% c("RECEITAS CORRENTES") & 
        cod_conta %in% c("ReceitasCorrentes") &
        coluna %in% c("No Bimestre (b)") 
        
    ) %>%
    summarise(total = sum(valor, na.rm = TRUE)) %>%
    pull(total) # Extrai o valor numérico do resultado
}

# Definir a função que retorna o total da receita corrente liquida
rcl_total <- function(data) {
  data %>%
    filter(
      conta %in% c("RECEITA CORRENTE LÍQUIDA (III) = (I - II)") 
      
    ) %>%
    summarise(total = sum(valor, na.rm = TRUE)) %>%
    pull(total) # Extrai o valor numérico do resultado
}

# RCL ajustada para despesas compessoal
rcl_pessoal <- function(data) {
  data %>%
    filter(
      cod_conta %in% c("RREO3ReceitaCorrenteLiquidaAjustadaParaCalculoDosLimitesDaDespesaComPessoal") 
      
    ) %>%
    summarise(total = sum(valor, na.rm = TRUE)) %>%
    pull(total) # Extrai o valor numérico do resultado
}

# RCL ajustada para o Serviço da divida
rcl_serv_divida <- function(data) {
  data %>%
    filter(
      conta %in% c("RECEITA CORRENTE LÍQUIDA AJUSTADA PARA CÁLCULO DOS LIMITES DE ENDIVIDAMENTO (V) = (III - IV)") 
      
    ) %>%
    summarise(total = sum(valor, na.rm = TRUE)) %>%
    pull(total) # Extrai o valor numérico do resultado
}



# Total da População no quadrimestre
populacao_total_quadrimestre <- function(data) {
  data %>%
    filter(
      data.ano == max(data.ano)
      
    ) %>%
    summarise(total = sum(valor, na.rm = TRUE)) %>%
    pull(total) # Extrai o valor numérico do resultado
}



# Definir a função que retorna o total da receita corrente
pessoal_total <- function(data) {
  data %>%
    filter(
      coluna %in% c("VALOR")  & 
        cod_conta %in% c("DespesaTotalComPessoalDemonstrativoSimplificado") 
       ) %>%
    summarise(total = sum(valor, na.rm = TRUE)) %>%
    pull(total) # Extrai o valor numérico do resultado
}


pessoal_encargos_total <- function(data) {
  data %>%
    filter(
      conta %in% c("PESSOAL E ENCARGOS SOCIAIS") & 
      cod_conta %in% c("PessoalEEncargosSociais") & 
      coluna %in% c("DESPESAS LIQUIDADAS NO BIMESTRE")
    ) %>%
    summarise(total = sum(valor, na.rm = TRUE)) %>%
    pull(total) # Extrai o valor numérico do resultado
}





