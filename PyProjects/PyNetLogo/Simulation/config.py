import json

CONFIG = {}

def load_config():
    global CONFIG
    if not CONFIG:  # Only load once if CONFIG is still empty
        with open('config.json', 'r') as config_file:
            config = json.load(config_file)

        CONFIG["MODEL_PATH"] = config['Paths']['ModelPath']
        CONFIG["NLOGO_HOME"] = config['Paths']['NetlogoPath']
        CONFIG["LOGGING_PATH"] = config['Paths']['LoggingPath']
        CONFIG["MODEL_DAYS_PER_TICK"] = int(config['Model']['TicksPerDay'])
        CONFIG["USE_STATE_SIMILARITY"] = bool(config['Parameters']['UseStateSimilarity'])
        CONFIG["WRITE_EVERY_N_ROWS"] = int(config['Logging']['WriteEveryNRows'])

        CONFIG["CARIBOU_IDEAL_STATE"] = [1, 1, 2, 8, 2]


    return CONFIG