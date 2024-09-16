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

    netlogo.kill_workspace()



def simulation_loop():


if __name__ == "__main__":
    main()
