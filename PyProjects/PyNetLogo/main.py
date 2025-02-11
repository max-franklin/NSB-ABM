import os
import pandas as pd
import plotly.graph_objects as go
import pynetlogo
import dash
from dash import dcc, html
from dash.dependencies import Input, Output
import threading
import json


from Simulation.SimController import SimController

with open('config.json', 'r') as config_file:
    config = json.load(config_file)

MODEL_PATH = config['Paths']['ModelPath']
NLOGO_HOME = config['Paths']['NetlogoPath']


current_directory = os.getcwd()

# Global variables to share data between threads
df = pd.DataFrame(columns=['tick', 'mean_bio_energy', 'median_bio_energy', 'max_bio_energy', 'min_bio_energy'])
netlogo = None


def setup_netlogo():
    global netlogo
    absolute_model_path = os.path.abspath(os.path.join(current_directory, MODEL_PATH))

    java_home = os.environ.get('JAVA_HOME')
    if java_home:
        jvm_path = os.path.join(java_home, 'bin', 'server', 'jvm.dll')
    else:
        raise Exception('JAVA_HOME is not set in system environment variables.')

    netlogo = pynetlogo.NetLogoLink(gui=True, jvmargs=["-Xmx20G"])
    netlogo.load_model(absolute_model_path)

    netlogo.command('set scenario "caribou-evolution"')
    netlogo.command("setup")





def run_simulation():
    global df

    # Create a dictionary of DataFrames for storing metrics for the simulation
    sim_data_frames = define_dataframes()


    simulation = SimController(sim_data_frames)
    simulation.setup()
    simulation.run()


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


if __name__ == '__main__':
    # Run the simulation in a separate thread to keep the Dash app responsive
    simulation_thread = threading.Thread(target=run_simulation, daemon=True)
    simulation_thread.start()

    # Run the Dash app
    app.run_server(debug=False)
