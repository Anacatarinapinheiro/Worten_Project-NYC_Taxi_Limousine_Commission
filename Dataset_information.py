import pandas as pd

# Lista dos arquivos CSV convertidos
csv_files = [
    'yellow_tripdata_2015-01.csv', 'yellow_tripdata_2016-01.csv', 'yellow_tripdata_2016-02.csv', 'yellow_tripdata_2016-03.csv',
    'fhv_tripdata_2015-01.csv', 'fhv_tripdata_2016-01.csv', 'fhv_tripdata_2016-02.csv', 'fhv_tripdata_2016-03.csv',
    'green_tripdata_2015-01.csv', 'green_tripdata_2016-01.csv', 'green_tripdata_2016-02.csv', 'green_tripdata_2016-03.csv'
]

# Dicionário para armazenar informações sobre os datasets
datasets_info = {}

# Loop sobre os arquivos CSV
for file in csv_files:
    df = pd.read_csv(file)
    nas_per_column = df.isna().sum() # Retorna a quantidade de valores ausentes por coluna
    nas_columns = nas_per_column[nas_per_column > 0].index.tolist() # Obtém os nomes das colunas com valores ausentes
    datasets_info[file] = {
        'linhas': df.shape[0], # Quantidade de linhas
        'colunas': df.shape[1], # Quantidade de colunas
        'nas': df.isna().sum().sum, # Soma total de valores ausentes (dois sum sum para somar os nas de cada linha, caso contrário mostra a soma de nas por cada variável)
        'nas_colunas': nas_columns, # Nomes das colunas com valores ausentes
        'nomes_colunas': df.columns.tolist() # Nomes de todas as colunas
    }

# Exibir informações sobre cada dataset
for file, info in datasets_info.items():
    print(f'Informações sobre o arquivo: {file}')
    print(f'Quantidade de linhas: {info["linhas"]}')
    print(f'Quantidade de colunas: {info["colunas"]}')
    print(f'Valores ausentes (NAS): {info["nas"]}')
    print(f'Colunas com valores ausentes: {info["nas_colunas"]}')
    print(f'Nomes de todas as colunas: {info["nomes_colunas"]}')
    print('\n')
