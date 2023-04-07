% Jared Matthews and Nathan Zavanelli
% Last Updated March 2, 2022
%
% INSTRUCTIONS:
% Place data files or the root of a folder hierarchy containing data 
% in the same directory as this file. The organization and names of the 
% files and/or folders do not matter; the only constraint is that the 
% files of interest must be of type .csv. The files should contain columns
% of data, with the left-most column containing the ECG data.
%
% Fill in the inputs below and then run this script. Feel free to interact
% with the struct "results" after the main loop has exected; the data at 
% position i in results corresponds to the file at position i of the array
% "csv_files".

clear, close all

%% Inputs ====================================================
sample_frequency = 250; % Hz
offset = 0.1; % offset multiplier to apply to threshold. Recommended values in [-0.5,0.5]
smoothing = 15; % gaussian window size for smooting on final output; larger = more smoothing, 0 = none
plot_on = 1; % set to 0 to disable plotting
denoise = 0; % set to 1 to try automatic noise rejection for data with sudden ECG spikes
scale = 'seconds'; % x-axis of plots: use seconds, minutes, hours, or samples 

%% Recursively search all folders reachable from this file's directory
current_directory = pwd;
csv_files = find_files(current_directory, '.csv');

%% Main loop for ecg data
for i = 1:length(csv_files)
    file_name = csv_files(i);
    fprintf("Processing %s\n", file_name)
    data = readtable(csv_files(i));
    [~, cols] = size(data);
    ecg = table2array(data(:,cols));
    start = round(length(ecg)/2);
    [HR_t, HR, HR_smooth, HRV, ecg, HR_peak_amplitudes] = ...
        get_hr_ecg(ecg, sample_frequency, smoothing, offset, plot_on, scale, denoise);
    result.HR_t = HR_t;
    result.HR = HR;
    result.HR_smooth = HR_smooth;
    result.HRV = HRV;
    result.HR_peaks = HR_peak_amplitudes;
    results(i) = result;
end

if plot_on == 0
   close all; 
end
