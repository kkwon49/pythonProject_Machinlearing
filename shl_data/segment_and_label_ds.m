%% Downsample Example: 
clr;
fDir = 'shl_labeled\';
fileList = {'S1S2Labels.mat', 'Participant9Labeled.mat'};
Fs = 4000/2/2;
file2List = 3:10;
wlen = 2*Fs; whop = round(Fs/31.25);
NUM_CLASSES = 3;
fDirOut = 'shl_labeled_seg_ds\';
PLOT = 0;
for f = 1:length(fileList)
    load([fDir fileList{f}]);
    clc;
    if f == 1
        data = ls.Source{1,1}.Participant1Filtered(:, 2);
%         data = rescale_linear(data, 25);
        labels_roi = ls.Labels.s1s2{1, 1}.ROILimits;
        labels_val = ls.Labels.s1s2{1, 1}.Value; % convert to labels: 
        labels = convertLabels(size(data, 1), Fs, labels_roi, labels_val);
        %% Resample data and labels: 
%         data = downsampleMulti(data, 2);
%         data = downsampleMulti(data, 2);
%         labels = label_resample(labels);
%         labels = label_resample(labels);
        figure(1); subplot(2,1,1); plot(data); subplot(2,1,2); plot(labels); 
        [X, Y] = segmentDataAndLabels(data, labels, wlen, whop, PLOT);
        % TODO: Convert labels to 
        Y = ind2vecPoint(Y, NUM_CLASSES); 
        % TODO: Downsample [2x];
        mkdir(fDirOut); 
        save([fDirOut 'file1.mat'], 'X', 'Y');
        clear X Y labels
        % load only file 1
    elseif f==2
        for ff = file2List
            data = ls.Source{ff,1}(:, 2); 
            labels_roi = ls.Labels.S1S2{ff, 1}.ROILimits;
            labels_val = ls.Labels.S1S2{ff, 1}.Value;
            labels = convertLabelsV2(size(data, 1), labels_roi, labels_val); 
            data = downsampleMulti(data, 2);
            data = downsampleMulti(data, 2);
            labels = label_resample(labels);
            labels = label_resample(labels);
            figure(1); subplot(2,1,1); plot(data); subplot(2,1,2); plot(labels);
            [X, Y] = segmentDataAndLabels(data, labels, wlen, whop, PLOT);
            Y = ind2vecPoint(Y, NUM_CLASSES); 
            mkdir(fDirOut); 
            save([fDirOut 'file' num2str(ff) '.mat'], 'X', 'Y');
            clear X Y labels
        end
    end
end

function y = label_resample(x) 
    y = x(1:2:end, :);
end