import pandas as pd
import glob
import plotly.express as px

# Load all caribou_energy parquet files
all_files = glob.glob(r"F:\Research\NSB\NSB-2024-AUG\DataLogs\graph\*caribou_energy*.parquet")

df_list = []
for filename in all_files:
    df_temp = pd.read_parquet(filename)
    df_list.append(df_temp)

df = pd.concat(df_list, ignore_index=True)

# Calculate Sim_Time
df['Sim_Time'] = df['year'] + (df['day'] / 365)

# --- Chart 1: Average bioenergy (Total / 50 agents) ---
grouped_avg = df.groupby('Sim_Time', as_index=False)['bioenergy'].sum()
grouped_avg['avg_bioenergy'] = grouped_avg['bioenergy'] / 50

fig_avg = px.area(
    grouped_avg,
    x='Sim_Time',
    y='avg_bioenergy',
    title='Average Bioenergy Over Time (Per Agent)'
)
fig_avg.show()


# --- Chart 2: Min, Max, Median bioenergy ---
grouped_stats = df.groupby('Sim_Time')['bioenergy'].agg(
    min='min',
    max='max',
    median='median'
).reset_index()

fig_stats = px.line(
    grouped_stats,
    x='Sim_Time',
    y=['min', 'median', 'max'],
    title='Min, Median, and Max Bioenergy Over Time'
)
fig_stats.show()
