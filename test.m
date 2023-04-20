eeglab redraw;
EEG = pop_importdata('dataformat','array','nbchan',20,'data',data_3,'srate',256,'pnts',0,'xmin',0, ...
                     'chanlocs', '/Users/joannaq/Desktop/LIINC/LCT/pre_code/BAlert_x24.ced');
EEG = eeg_checkset(EEG);
fprintf('load data')
pop_eegplot(EEG,256)
%% Rereference and remove base line
EEG = pop_rmbase( EEG, [],[]);
EEG = eeg_checkset( EEG );
EEG = pop_reref( EEG, []);
EEG = eeg_checkset( EEG );
fprintf('reference and remove base line done \n')
pop_eegplot(EEG,256)
%% Filters
% Band filter 0.5-100
EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'hicutoff',100);
EEG = eeg_checkset( EEG );
fprintf('band filter done \n')
%% Notch filter at 60Hz
% [b,a] = notch(256, 60);
for i=size(EEG.data)
    EEG.data(i) = filter(b, a, EEG.data(i));
end
EEG = eeg_checkset( EEG );
fprintf('notch filter at 60Hz done \n')
pop_eegplot(EEG,256)
%% Remove noisy channel
[EEG, indelect] = pop_rejchan(EEG, 'threshold',3, 'norm','on', 'measure','kurt');
EEG = eeg_checkset( EEG );
disp(['removed channel', indelect]);
pop_eegplot(EEG,256)
%% Run ICA
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');
EEG = eeg_checkset( EEG );
%% Reject componet
EEG = pop_icflag(EEG, [NaN NaN;0.9 1;0.9 1;0.95 1;0.95 1;0.95 1;0.95 1]);
EEG = eeg_checkset( EEG );