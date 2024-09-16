# https://pynetlogo.readthedocs.io/en/latest/_docs/introduction.html

import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import pynetlogo

MODEL_PATH = '../../NSB-ABM.nlogo'
NLOGO_HOME = 'C:\\Program Files\\NetLogo 6.4.0'

current_directory = os.getcwd()

sns.set_style("white")
sns.set_context("talk")


def main():

    absolute_model_path = os.path.abspath(os.path.join(current_directory, MODEL_PATH))

    java_home = os.environ.get('JAVA_HOME')
    if java_home:
        jvm_path = os.path.join(java_home, 'bin', 'server', 'jvm.dll')
    else:
        raise Exception('JAVA_HOME is not set in system environment variables.')

    netlogo = pynetlogo.NetLogoLink(
        gui=True,
        jvmargs=["-Xmx20G"]
    )


    netlogo.load_model(absolute_model_path)

    netlogo.command("setup")
    simulation_loop(netlogo)


def simulation_loop(netlogo):
    # Create a DataFrame to store the data
    df = pd.DataFrame(columns=['tick', 'mean_bio_energy', 'median_bio_energy'])

    plt.ion()  # Turn on interactive mode
    fig, ax = plt.subplots(figsize=(10, 6))  # Create the figure for plotting

    while True:
        netlogo.command("go")

        # Get the current year
        current_year = int(netlogo.report("year"))

        # Monitor the bio-energy of caribou
        bio_energy_values = netlogo.report("map [caribou -> [bio-energy] of caribou] sort caribou")

        # Calculate mean and median
        mean_bio_energy = pd.Series(bio_energy_values).mean()
        median_bio_energy = pd.Series(bio_energy_values).median()

        # Log data
        tick = netlogo.report("ticks")
        df = df.append({'tick': tick, 'mean_bio_energy': mean_bio_energy, 'median_bio_energy': median_bio_energy},
                       ignore_index=True)

        # If the year is a multiple of 20, save and plot the data
        if current_year % 20 == 0:
            save_and_plot(df, current_year, ax)

        # Terminate the loop if the current year reaches 1000
        if current_year >= 1000:
            print("Simulation ended at year 1000.")
            break

    netlogo.kill_workspace()


def save_and_plot(df, current_year, ax):
    # Clear the previous plot
    ax.clear()

    # Plot the mean and median as a filled solid line chart
    sns.lineplot(x='tick', y='mean_bio_energy', data=df, label='Mean Bio-Energy', color='blue', ax=ax)
    sns.lineplot(x='tick', y='median_bio_energy', data=df, label='Median Bio-Energy', color='orange', ax=ax)

    # Fill the area under the curves
    ax.fill_between(df['tick'], df['mean_bio_energy'], alpha=0.2, color='blue')
    ax.fill_between(df['tick'], df['median_bio_energy'], alpha=0.2, color='orange')

    # Set titles and labels
    ax.set_title(f'Bio-Energy of Caribou at Year {current_year}')
    ax.set_xlabel('Tick')
    ax.set_ylabel('Bio-Energy')
    ax.legend()

    # Redraw the plot dynamically
    plt.draw()
    plt.pause(0.1)  # Brief pause to allow the plot to update

    # Save the plot
    plt.savefig(f'bio_energy_plot_year_{current_year}.png')

    print(f'Report and plot saved for year {current_year}')


if __name__ == "__main__":
    main()