classdef LCT_preprocessing
   methods (Static)
       function [data_1, data_2, data_3] = load_data(filepath)
            % load data
            data_1 = 0;
            data_2 = 0;
            data_3 = 0;
            streams = load_xdf(filepath);
            for i = 1:length(streams)
                struct = streams{1, i};
                info = struct.info;
                if info.type == "EEG"
                     if info.hostname == "DESKTOP-A6I5HI6"
                         data_1 = struct.time_series(7:26, :);
                     elseif info.hostname == "DESKTOP-539136F"
                         data_2 = struct.time_series(7:26, :);  
                     elseif info.hostname == "DESKTOP-U9TEJGM"
                         data_3 = struct.time_series(7:26, :);
                     elseif info.hostname == "DESKTOP-9M4VCHG"
                         data_3 = struct.time_series(7:26, :);
                     end
                end
            end
        end

%         %% define parameters
%         function [eeg_filt] = filt_EEG(eeg_data)
%             eeg_srate = 256;
%             %% Filter EEG Data from 0.5-100 Hz - Butterworth Fourth Order
%             % Design the butterworth filter
%             [bb, aa] = butter(4,[0.5 100]./(eeg_srate/2));
% 
%             for chan = 7:26
%                 eeg_filt(chan-6,:) = filtfilt(bb,aa,double(eeg_data(chan,:)));
%             end
%             fprintf(' band filter done \n')
%             % Notch filter (59.9 ~ 60.1)
%             EEG = pop_eegfiltnew(EEG, 'locutoff',59.9,'hicutoff',60.1,'plotfreqz',1);
%         end
        %%
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
            EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'hicutoff',100,'plotfreqz',1);
            EEG = eeg_checkset( EEG );
            fprintf('band filter done \n')
            % Notch filter at 60Hz
%             notch_filter = designfilt('bandstopiir','FilterOrder',2, ...
%                       'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
%                       'DesignMethod','butter','SampleRate',256);
%             EEG = filtfilt(notch_filter, EEG);
            EEG = pop_eegfiltnew(EEG, 'locutoff',59.9,'hicutoff',60.1,'plotfreqz',1);
            EEG = eeg_checkset( EEG );
            fprintf('filter data')
            %% Remove noisy channel
            % EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',10, 'LineNoiseCriterion',4);
            [EEG, indelect] = pop_rejchan(EEG, 'threshold',3, 'norm','on', 'measure','kurt');
            EEG = eeg_checkset( EEG );
            noischa_save = sprintf('/Users/joannaq/Desktop/LIINC/LCT/processed_data/noisy_channel/%s_%s.mat', time, player_id);
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
            ICA_save_name = sprintf('/Users/joannaq/Desktop/LIINC/LCT/processed_data/ica_weights/%s_%s.mat', time, player_id);
            save(ICA_save_name,'ICA_weights','ICA_sphere');
            %% Export .mat
            preprocessed_EEG = EEG.data;
            zero = zeros(size(preprocessed_EEG(1,:)));
            for i = 1:size(indelect)
                preprocessed_EEG = vertcat(preprocessed_EEG(1:indelect(i)-1, :), ...
                                           zero, ...
                                           preprocessed_EEG(indelect(i)+1:end, :));
            end
            preprocessed_EEG(end+1,:) = EEG.times;
            eeg_save_path = sprintf('/Users/joannaq/Desktop/LIINC/LCT/processed_data/processed/%s_%s.mat', time, player_id);
            save(eeg_save_path, 'preprocessed_EEG', '-v7');
            eeglab redraw;
            fprintf('eeg saved \n')
        end
   end
end


% for team = [23]%14,15,16,17,18,20,21,22,23,24, 25, 26
%     for session = [2,3]% 1,2,3
%         for player = [{'Yaw'}, {'Pitch'}, {'Thrust'}]
%             try
%                 eeg_data = EEG_preprocessing.load_data(team, session, player);
%                 eeg_filt = EEG_preprocessing.filt_EEG(eeg_data);
%                 EEG_preprocessing.process_eeg(eeg_data, eeg_filt, team, session, char(player));
%             catch
%                 continue
%             end
%         end
%     end
% end