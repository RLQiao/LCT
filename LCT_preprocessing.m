classdef LCT_preprocessing
   methods (Static)
       function [data_1, data_2, data_3, data_4] = load_data(filepath)
            % load data
            data_1 = [];
            data_2 = [];
            data_3 = [];
            data_4 = [];
            streams = load_xdf(filepath);
            for i = 1:length(streams)
                struct = streams{1, i};
                info = struct.info;
                data = struct.time_series;
                if info.type == "EEG"
                    if info.hostname == "DESKTOP-A6I5HI6" && ~isempty(data)
                        data_1 = struct.time_series(7:26, :);
                    elseif info.hostname == "DESKTOP-539136F" && ~isempty(data)
                        data_2 = struct.time_series(7:26, :);
                    elseif info.hostname == "DESKTOP-U9TEJGM" && ~isempty(data)
                        data_3 = struct.time_series(7:26, :);
                    elseif info.hostname == "DESKTOP-9M4VCHG" && ~isempty(data)
                        data_4 = struct.time_series(7:26, :);
                    end
                end
            end
       end
       %% preprocess function
       function [] = process_eeg(eeg_data, time, player_id)
           eeglab redraw;
           EEG = pop_importdata('dataformat','array','nbchan',20,'data', eeg_data,'srate',256,'pnts',0,'xmin',0, ...
                                'chanlocs', '/Users/joannaq/Desktop/LIINC/LCT/pre_code/BAlert_x24.ced');
           EEG = eeg_checkset(EEG);
           fprintf('load data')
           %% Rereference and remove base line
           EEG = pop_rmbase( EEG, [],[]);
           EEG = eeg_checkset( EEG );
           EEG = pop_reref( EEG, []);
           EEG = eeg_checkset( EEG );
           fprintf('reference and remove base line done \n')
           %% Filters
           % Band filter 0.5-100
           EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'hicutoff',100);
           EEG = eeg_checkset( EEG );
           fprintf('band filter done \n')
           % Notch filter at 60Hz
           [b,a] = notch(256, 60);
           for i = 1:size(EEG.data)
               EEG.data(i) = filter(b, a, EEG.data(i));
           end
           fprintf('notch filter done \n')
           %% Remove noisy channel
           [EEG, indelect] = pop_rejchan(EEG, 'threshold',3, 'norm','on', 'measure','kurt');
           EEG = eeg_checkset( EEG );
           noischa_save = sprintf('/Users/joannaq/Desktop/LIINC/LCT/data/processed_data/noisy_channel/%s_%s.mat', time, player_id);
           save(noischa_save, 'indelect');
           %% Run ICA
           EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');
           EEG = eeg_checkset( EEG );
           %% Reject componet
           EEG = pop_icflag(EEG, [NaN NaN;0.9 1;0.9 1;0.95 1;0.95 1;0.95 1;0.95 1]);
           EEG = eeg_checkset( EEG );
           %% Save the ICA weights and sphere
           ICA_weights = EEG.icaweights;
           ICA_sphere = EEG.icasphere;
           ICA_save_name = sprintf('/Users/joannaq/Desktop/LIINC/LCT/data/processed_data/ica_weights/%s_%s.mat', time, player_id);
           save(ICA_save_name,'ICA_weights','ICA_sphere');
           %% Export .mat
           preprocessed_EEG = EEG.data;
           if indelect~=0
               zero = zeros(size(preprocessed_EEG(1,:)));
               for i = 1:length(indelect)
                   if indelect(i)==1
                       preprocessed_EEG = vertcat(zero, preprocessed_EEG);
                   end
                   if indelect(i)==20
                       preprocesssed_EEG = vertcat(preprocessed_EEG, zero);
                   end
                   preprocessed_EEG = vertcat(preprocessed_EEG(1:indelect(i)-1, :), ...
                                              zero, ...
                                              preprocessed_EEG(indelect(i):end, :));
               end
           end
           preprocessed_EEG(end+1,:) = EEG.times;
           eeg_save_path = sprintf('/Users/joannaq/Desktop/LIINC/LCT/data/processed_data/processed/%s_%s.mat', time, player_id);
           save(eeg_save_path, 'preprocessed_EEG', '-v7');
           eeglab redraw;
           fprintf('eeg saved \n')
       end
   end
end

function [b, a] = notch(fs,notch_freq)
    DT_notch_freq = 2*pi*notch_freq/fs;
    r = 0.7;
    notchzeros = [exp(1i*DT_notch_freq) exp(-1i*DT_notch_freq)];
    notchpoles = [r*exp(1i*DT_notch_freq) r*exp(-1i*DT_notch_freq)];
    b = poly(notchzeros);
    a = poly(notchpoles);
end