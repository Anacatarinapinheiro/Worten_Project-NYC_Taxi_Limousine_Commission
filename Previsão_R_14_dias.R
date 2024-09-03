# bibliotecas
library(DBI)
library(dplyr)
library(lubridate)
library(forecast)

# ligação ao servidor
con <- dbConnect(odbc::odbc(), 
                 driver = "SQL Server", 
                 server = "CATS-VERSION\\SQLEXPRESS",
                 database = "WortenTaxi") 

# ler Yellow_dates
yellow_data <- dbGetQuery(con, "
SELECT CAST(tpep_pickup_datetime AS DATE) AS pickup_date, 
       COUNT(*) AS trips,
       DATENAME(dw, tpep_pickup_datetime) AS pickup_day_of_week
FROM Yellow_dates
WHERE CAST(tpep_pickup_datetime AS DATE) >= '2016-01-01'
GROUP BY CAST(tpep_pickup_datetime AS DATE), DATENAME(dw, tpep_pickup_datetime)
")

# fecha ligação
dbDisconnect(con)

# Converte a coluna pickup_date para o tipo de data
yellow_data$pickup_date <- as.Date(yellow_data$pickup_date)

yellow_data <- yellow_data[, !(names(yellow_data) %in% c("pickup_day_of_week"))]

# Ordena os dados por data
yellow_data <- yellow_data[order(yellow_data$pickup_date), ]

#-------------------------------------------
#  ARIMA model
arima_model <- auto.arima(yellow_data$trips)

# Previsão para os próximos 14 dias
forecast_next_14_days <- forecast(arima_model, h = 14)

# Converter o objeto de previsão num DataFrame
forecast_table <- as.data.frame(forecast_next_14_days)

# Visualizar a tabela de previsão
print(forecast_table)

# Calcular a média de cada dia com base nos valores previstos
forecast_means <- rep(mean(forecast_next_14_days$`mean`), 14)

# Gerar uma sequência de datas para os próximos 14 dias
next_14_days_dates <- seq(max(yellow_data$pickup_date) + 1, length.out = 14, by = "day")

# Criar um data frame para armazenar os valores previstos
forecast_df <- data.frame(date = next_14_days_dates, forecast_arima = forecast_means)

# Plotar os dados observados
plot(yellow_data$pickup_date, yellow_data$trips, type = "l", col = "black", xlab = "Date", ylab = "Number of Trips")

# Adiciona os valores previstos para os próximos 14 dias (ARIMA)
lines(forecast_df$date, forecast_df$forecast_arima, col = "blue")

# Adiciona título e rótulos
title("Volume de Viagem de Janeiro a Março e Previsão para Abril", line = 2)
xlabel <- c(as.character(yellow_data$pickup_date[nrow(yellow_data)]), as.character(forecast_df$date))
axis(1, at = c(1:length(xlabel)), labels = xlabel)

# Adiciona legenda
legend("bottomright", legend = c("Observed", "Forecast (ARIMA)"), 
       col = c("black", "blue"), lty = c(1, 1))

#-----------------------------------------
#modelo de regressão linear
lm_model <- lm(trips ~ pickup_date, data = yellow_data)

#os 14 dias
prediction_range <- seq(min(yellow_data$pickup_date), max(yellow_data$pickup_date) + 14, by = "day")

#lê os valores e preve para 14 dias seguintes
forecast_values_lm <- predict(lm_model, newdata = data.frame(pickup_date = prediction_range))
#mete num dataframe
forecast_df_lm <- data.frame(date = prediction_range, forecast_lm = forecast_values_lm)

#background transparente
par(bg = "transparent")

#grafico com arima e regressão
plot(yellow_data$pickup_date, yellow_data$trips, type = "l", col = "yellow", 
     xlab = "Date", ylab = "Número de Viagens", 
     main = "Volume de Viagens de Janeiro a Março e Previsão para 14 primeiros dias de Abril", 
     lwd = 2,              # Define a largura da linha
     lty = 1,              # Define o tipo de linha
     xlim = c(min(yellow_data$pickup_date), max(forecast_df$date)),  # Define os limites do eixo x
     ylim = c(0, max(yellow_data$trips, na.rm = TRUE) * 1.1),         # Define os limites do eixo y
     col.axis = "white",   # Define a cor dos rótulos dos eixos
     col.lab = "white",     # Define a cor dos rótulos dos eixos
     col.main = "white"  
)

#preenchimento com cor abaixo da linha 
polygon(c(yellow_data$pickup_date, rev(yellow_data$pickup_date)), 
        c(yellow_data$trips, rep(0, length(yellow_data$trips))),
        col = rgb(1, 0.7, 0, alpha = 0.2), border = NA)

polygon(c(forecast_df$date, rev(forecast_df$date)), 
        c(forecast_df$forecast_arima, rep(0, length(forecast_df$forecast_arima))),
        col = rgb(0, 1, 0, alpha = 0.2), border = NA)

#cor das linhas
lines(forecast_df$date, forecast_df$forecast_arima, col = "green")  # Green
lines(forecast_df_lm$date, forecast_df_lm$forecast_lm, col = "red")   # Vermelho

#legendas
xlabel <- c(as.character(yellow_data$pickup_date[nrow(yellow_data)]), as.character(forecast_df$date))
axis(1, at = c(1:length(xlabel)), labels = xlabel, col.axis = "white")
legend("bottomright", legend = c("Observado", "Previsão (ARIMA)", "Previsão (Regressão Linear)"), 
       col = c("yellow", "green", "red"), lty = c(1, 1, 1), text.col = "white") 