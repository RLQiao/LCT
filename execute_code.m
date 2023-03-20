% python get file names: import os
% path = "/Users/joannaq/Desktop/LIINC/LCT/raw_data"
% dir_list = os.listdir(path)
% dir_list = str(dir_list).replace("'", '"')
% print(dir_list)
session = ["0826_1000", "0825_1300", "0830_1300", "0819_1400", ...
    "0817_1000", "0831_1300", "0901_1300", "0827_1000", "0811_1000", ...
    "0920_1600", "0823_1400", "1005_1600", "0828_1300", "0818_1000", ...
    "0816_1400", "0930_1700", "0917_1030", "0727_1400", "0928_1600", ...
    "0818_1600", "0802_1400", "0927_0930", "0915_1000", "0825_1000", ...
    "0824_1600", "0826_1300", "0813_1000", "0924_1000", "0806_1000", ...
    "0923_1000", "0901_1000", "0824_1000", "0831_1000", "0731_1000", ...
    "0923_1600", "0922_1000", "0924_1600", "0813_1600"];
% player matching desktop
player_id = ["A6I5HI6", "539136F", "U9TEJGM", "9M4VCHG"];
% set up variables
str_size = size(session);
shape = str_size(2);
% create class
eeg_preprocess = LCT_preprocessing();
% open txt file
fid = fopen('/Users/joannaq/Desktop/LIINC/LCT/processed_data/report.txt','a');
% loop
for i = 31:38
    % filepath
    xdf_filepath = sprintf('/Users/joannaq/Desktop/LIINC/LCT/data/raw_data/%s%s', ...
                           session(i), '_LCT.xdf');
    % read xdf and extract eegdata
    [data_1, data_2, data_3, data_4] = eeg_preprocess.load_data(xdf_filepath);
    data = {data_1, data_2, data_3, data_4};
    % find unempty sets
    count = find(~cellfun(@isempty, data));
    % preprocess eegdata with LCT_preprocessing class
    desktop = string();
    for j=1:length(count)
        % input: data, session, player desktop name
        eeg_preprocess.process_eeg(data(count(j)), session(i), player_id(count(j)))
        desktop = append(desktop, player_id(count(j)), ',');
    end
    % report number of players with eegdata in each session
    str = sprintf('Session %s contains EEG data from %.f players on desktop %s\n', ...
                  session(i), length(count), desktop);
    fprintf(fid, str);
end
fclose(fid);
%%
filename = "0818_1000_LCT.xdf";
xdf_filepath = '/Users/joannaq/Desktop/LIINC/LCT/data/raw_data/' + filename;
eeg_preprocess = LCT_preprocessing();
[data_1, data_2, data_3, data_4] = eeg_preprocess.load_data(xdf_filepath);
%%
data = {data_1, data_2, data_3, data_4};
count = find(~cellfun(@isempty, data));
for i=1:length(count)
    eeg_preprocess.process_eeg(data(count(i)), "0818_1000", string(i))
end