import pandas as pd
import glob
import plotly.express as px


all_files = glob.glob(r"F:\Research\NSB\NSB-2024-AUG\DataLogs\graph\*caribou_state*.parquet")



df_list = []
for filename in all_files:
    df_temp = pd.read_parquet(filename)
    df_list.append(df_temp)

df = pd.concat(df_list, ignore_index=True)

# Create a new column 'Sim_Time' = year * 365 + day
df['Sim_Time'] = df['year'] + (df['day'] / 365)

# Group by Sim_Time (sum all behaviors for each Sim_Time)
grouped_df = df.groupby('Sim_Time', as_index=False)[
    ['evade', 'interforage', 'migrate', 'rest', 'intraforage']
].sum()

# Establish Plotly figure
fig = px.area(
    grouped_df,
    x='Sim_Time',
    y=['evade', 'interforage', 'migrate', 'rest', 'intraforage'],
    title='Stacked Area Chart of Behaviors Over Time'
)

fig.show()