import os
import pandas as pd
import plotly.graph_objects as go
import dash
from dash import dcc, html
from dash.dependencies import Input, Output
import threading
import json
from line_profiler_pycharm import profile
import atexit
import signal

shutdown_flag = threading.Event()

def sigint_handler(sig, frame):
    print("\n[!] Ctrl+C received — setting shutdown flag.")
    shutdown_flag.set()

signal.signal(signal.SIGINT, sigint_handler)
signal.signal(signal.SIGTERM, sigint_handler)


from Simulation.SimManager import SimController

print(os.getcwd())

with open('./config.json', 'r') as config_file:
    config = json.load(config_file)

MODEL_PATH = config['Paths']['ModelPath']
NLOGO_HOME = config['Paths']['NetlogoPath']


current_directory = os.getcwd()

# Global variables to share data between threads
df = pd.DataFrame(columns=['tick', 'mean_bio_energy', 'median_bio_energy', 'max_bio_energy', 'min_bio_energy'])
netlogo = None



@atexit.register
def save_results():
    print("Exiting...")
    # Used so that profiling and other analytic tools can close gracefully


@profile
def run_simulation():
    global df

    # Create a dictionary of DataFrames for storing metrics for the simulation
    sim_data_frames = define_dataframes()

    try:
        simulation = SimController(sim_data_frames, shutdown_flag)
        simulation.setup()
        simulation.run()

    except KeyboardInterrupt:
        print("Ctrl-C pressed, exiting...")



# Dash app layout
app = dash.Dash(__name__)

app.layout = html.Div([
    html.H1("Caribou Bio-Energy Simulation"),
    dcc.Graph(id='live-graph'),
    dcc.Interval(
        id='interval-component',
        interval=2 * 1000,  # Updates every 2 seconds
        n_intervals=0
    )
])


def define_dataframes() -> dict[str, object]:
    # Capture Energy Data
    df_energy = pd.DataFrame(columns=['tick', 'mean_bio_energy', 'median_bio_energy', 'max_bio_energy', 'min_bio_energy'])

    # Capture State Data
    df_state = pd.DataFrame(columns=['day', 'evade', 'interforage', 'migrate', 'rest', 'intraforage'])

    sim_data_frames = {"energy" : df_energy,
                       "state" : df_state }

    return sim_data_frames

@app.callback(
    Output('live-graph', 'figure'),
    Input('interval-component', 'n_intervals')
)
def update_graph_live(n):
    global df
    fig = go.Figure()

    if not df.empty:
        fig.add_trace(go.Scatter(x=df['tick'], y=df['mean_bio_energy'], mode='lines', name='Mean Bio-Energy',
                                 line=dict(color='blue')))
        fig.add_trace(go.Scatter(x=df['tick'], y=df['median_bio_energy'], mode='lines', name='Median Bio-Energy',
                                 line=dict(color='orange')))
        fig.add_trace(go.Scatter(x=df['tick'], y=df['max_bio_energy'], mode='lines', name='Max Bio-Energy',
                                 line=dict(color='green')))
        fig.add_trace(go.Scatter(x=df['tick'], y=df['min_bio_energy'], mode='lines', name='Min Bio-Energy',
                                 line=dict(color='red')))

    fig.update_layout(
        title='Bio-Energy of Caribou',
        xaxis_title='Tick',
        yaxis_title='Bio-Energy',
        showlegend=True
    )

    return fig



@profile
def main():
    # Run the simulation in a separate thread to keep the Dash app responsive
    run_simulation()


if __name__ == '__main__':
        main()
