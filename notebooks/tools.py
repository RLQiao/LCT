import json
import scipy.io
import os
import numpy as np
import pandas as pd
import re
import math
import matplotlib.pyplot as plt

def get_report(session):
    report = open('../data/processed_data/try2/report.txt', 'r')
    desktop = None
    for line in report.readlines():
        if session in line:
            desktops = line.partition('desktop ')[-1]
            desktop = desktops.split(',')[:-1]
    if desktop is None:
        raise ValueError('Unable to fetch desktop information')
        
    return desktop

def eeg_all_timestamps():
    sessions = ["0826_1000", "0825_1300", "0830_1300", "0819_1400", 
    "0817_1000", "0831_1300", "0901_1300", "0827_1000", "0811_1000", 
    "0920_1600", "0823_1400", "1005_1600", "0828_1300", "0818_1000", 
    "0816_1400", "0930_1700", "0917_1030", "0727_1400", "0928_1600", 
    "0818_1600", "0802_1400", "0927_0930", "0915_1000", "0825_1000", 
    "0824_1600", "0826_1300", "0813_1000", "0924_1000", "0806_1000", 
    "0923_1000", "0901_1000", "0824_1000", "0831_1000", "0731_1000", 
    "0923_1600", "0922_1000", "0924_1600", "0813_1600"];

    all_timestamps = scipy.io.loadmat('../data/processed_data/all_timestamps.mat')
    all_timestamps2 = scipy.io.loadmat('../data/processed_data/all_timestamps2.mat')
    
    EEG_ALL_Timestamps = dict()
    for i in range(13):
        session_timestamps = dict()
        num_desktop = len(all_timestamps['all_timestamps'][0][i][1][0])
        for j in range(num_desktop):
            desktop = all_timestamps['all_timestamps'][0][i][1][0][j][0][0]
            timestamp = [float(all_timestamps['all_timestamps'][0][i][1][0][j][1][0]), 
                         float(all_timestamps['all_timestamps'][0][i][1][0][j][2][0])]
            session_timestamps[desktop] = timestamp
        EEG_ALL_Timestamps[sessions[i]] = session_timestamps

    for i in range(24):
        session_timestamps = dict()
        num_desktop = len(all_timestamps2['all_timestamps'][0][i][1][0])
        for j in range(num_desktop):
            desktop = all_timestamps2['all_timestamps'][0][i][1][0][j][0][0]
            timestamp = [float(all_timestamps2['all_timestamps'][0][i][1][0][j][1][0]), 
                         float(all_timestamps2['all_timestamps'][0][i][1][0][j][2][0])]
            session_timestamps[desktop] = timestamp
        EEG_ALL_Timestamps[sessions[14+i]] = session_timestamps
    
    return EEG_ALL_Timestamps

def eeg_timestamp(session, desktop):
    EEG_ALL_Timestamps = eeg_all_timestamps()
    for key in EEG_ALL_Timestamps.keys():
        if key == session:
            desktops = EEG_ALL_Timestamps[session]
            for value in desktops.keys():
                if value == "DESKTOP-" + desktop:
                    EEG_start_time = desktops[value][0]
                    EEG_end_time = desktops[value][1]
    return EEG_start_time, EEG_end_time

def load_data(session, desktop):
    '''
    Parameter: a string that specifies the session that we want to look at
    return: json_data and eeg_data corresponding to the session
    '''  
    json_path = '../data/json'
    eeg_path = '../data/processed_data/try2/processed'
    json_list = os.listdir(json_path)
    eeg_list = os.listdir(eeg_path)
    json_data = eeg_data = None
    
    for file in json_list:
        if session in file and desktop in file:
            json_data = json.load(open(os.path.join(json_path, file)))
    for file in eeg_list:
        if session in file and desktop in file:
            eeg_data = scipy.io.loadmat(os.path.join(eeg_path, file))['preprocessed_EEG']
    if json_data is None:
        raise ValueError('No behavioral data for session', session, ' or', desktop)
    if eeg_data is None:
        raise ValueError('No eeg data for session', session, ' or', desktop)   
    # cropp eeg data
    eeg_first_timestamp, eeg_last_timestamp = eeg_timestamp(session, desktop)
    json_start_time = json_data['details']['initial timestamp']
    json_end_time = json_data['details']['final timestamp']
    if (abs(eeg_first_timestamp - json_start_time) > 10e-2) & (eeg_first_timestamp < json_start_time):
        init_offset = abs(eeg_first_timestamp - json_start_time)
        eeg_data = eeg_data[:20, round(init_offset*256):]
        print('Inital offset applied')
    else:
        print('No initial offset')
    if (abs(eeg_last_timestamp - json_end_time) > 10e-2) & (eeg_last_timestamp > json_end_time):
        end_offset = abs(eeg_last_timestamp - json_end_time)
        end = eeg_data.shape[1]
        eeg_data = eeg_data[:20, :round(end-end_offset*256)] # without timescroll
        print('End offset applied')
    else:
        print('No end offset')    
    return json_data, eeg_data

def extract_trial_timestamps(json_data):
    presented_timestamps = [] # 2sec before trial was presented
    submission_timestamps = [] # 2sec before the next trial was presented
    gamble_number = []
    ambiguity = []
    condition = []
    num_trials = len(json_data['trials'])
    for i in range(num_trials):
        if len(json_data['trials'][i]['lct']) >= 3:
            presented_timestamps.append(json_data['trials'][i]['lct'][0]['time']-2)
            submission_timestamps.append(json_data['trials'][i]['lct'][-1]['time']+2)
            gamble_number.append(json_data['trials'][i]['lct'][0]['event']['parameters']['gamble']['gamble number'])
            ambiguity.append(json_data['trials'][i]['lct'][0]['event']['parameters']['gamble']['ambiguity'])
            condition.append(json_data['trials'][i]['lct'][0]['event']['parameters']['gamble']['condition'])
        else:
            gamble = json_data['trials'][i]['lct'][0]['event']['parameters']['gamble']['gamble number']
            trial = json_data['trials'][i]['lct'][0]['event']['parameters']['trial number']
            print('Trial', trial, 'gamble', gamble, 'not submitted at this round')
    if (submission_timestamps - presented_timestamps < 10 for i in range(132)): print('Timestamps ready')
    else: print('Error: Decision time exceeds 10 seconds.')
    
    return presented_timestamps, submission_timestamps, gamble_number, ambiguity, condition

def create_dataframe(session, desktop, json_data, eeg_data):
    json_start_time = json_data['details']['initial timestamp']
    json_end_time = json_data['details']['final timestamp']
    presented_timestamps, submission_timestamps, gamble_number, ambiguity, condition = extract_trial_timestamps(json_data)
    eeg = []
    for i in range(132):
        start_idx = math.floor((presented_timestamps[i] - json_start_time) * 256)
        end_idx = start_idx + math.ceil((submission_timestamps[i] - presented_timestamps[i]) * 256)
        trial_eeg = eeg_data[:, start_idx:end_idx]
        eeg.append(trial_eeg)
    
    result = {'desktop': [desktop] * 132,
              'session' : [session] * 132,
              'gamble number': gamble_number,
              'condition' : condition,
              'ambiguity' : ambiguity,
              'eeg' : eeg}
    return pd.DataFrame(result)