clr; 
folders = {'Crackle', 'Rhonchi', 'Stridor', 'Wheeze', 'Clean'};
labels = [1, 2, 3, 4, 0];
Fs = 4000; h = 1/Fs; 
start = 1; 
whop = round(0.25*Fs); 
wlen = 2*Fs; 
% Filters: 
HIGH_PASS_FILTER = true;
HPFCUT = 4.0;
% LPFCUT = 100.0;
[bh, ah] = butter(3, HPFCUT/(Fs/2), 'high');
% [bl, al] = butter(3, LPFCUT/(Fs/2), 'low'); 
PLOT = 1;
SAVE = 0;
for s = 5:length(folders)
    allFiles = dir(['raw\' folders{s} '\*.wav']); 
    for f = 1:length(allFiles)
        data = audioread(['raw\' folders{s} '\' allFiles(f).name]);
        disp(allFiles(f).name); 
        % TODO: Segment:
        wStart = 1:whop:(length(data)-wlen); wEnd = wStart + wlen - 1; 
        windows_raw = zeros(length(wStart), wlen, 1); 
        X = zeros(length(wStart), wlen, 1); 
        Y = zeros(length(wStart), 1); 
        for w = 1:4:length(wStart)
%             windows_raw(w, :, :) = data(wStart(w) : wEnd(w), :);
            % Process: 
%             tmp = data(wStart(w) : wEnd(w), :);
            tmp = filtfilt(bh, ah, data(wStart(w) : wEnd(w), :));
            X(w, :, 1) = rescale_linear(tmp, 1); %filtfilt(bl, al, tmp)
            if PLOT
%                 figure(1); subplot(2,1,1); plot(data(wStart(w) : wEnd(w), :)); 
%                 subplot(2,1,2); plot(X(w, :, 1));
                figure(1); plot(squeeze(X(w, :, 1))); 
                fprintf('Class: %d \n', labels(s)); 
                input('Continue? \n');
            end
            p2p(w) = peak2peak(X(w, :, 1));
            Y(w) = labels(s); 
        end
        X = single(X); 
        Y = single(Y);
        p2p_avg = mean(p2p)
        % Save:
        if SAVE
            out_dir = 'out_data_2s\'; mkdir(out_dir); 
            out_fn = [out_dir 'dat_s' num2str(s) '_f' num2str(f) '.mat'];
            save(out_fn, 'X', 'Y'); 
        end
        % Clear:
        clear X Y windows_raw p2p
    end
end