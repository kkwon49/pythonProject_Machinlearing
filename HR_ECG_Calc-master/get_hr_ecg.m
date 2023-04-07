function [HR_t, HR, HR_smooth, HRV, ecg, peaks]= get_hr_ecg(ecg, fs, smoothing, offset, plotOn, scale, denoise)
%% Initialize variables

delay = 0;
skip = 0;                                                                  % becomes one when a T wave is detected
m_selected_RR = 0;
mean_RR = 0;
ser_back = 0; 
ax = zeros(1,6);


%% Filtering
% Pre-process to remove bad values
ecg= ecg(isfinite(ecg));
ecg(abs(ecg) >= 1) = 0;

% Remove the mean
ecg_data = ecg;
ecg = ecg - mean(ecg);

% low pass filter
Wn = 12*2/fs;
N = 3;
[a,b] = butter(N,Wn,'low');

if isempty(ecg)
    ME = MException('MATLAB:conv:AorBNotVector', ...
        'Not able to filter the given ECG data.');
    throw(ME)
end
ecg_l = filtfilt(a,b,ecg);
ecg_l = ecg_l/ max(abs(ecg_l));

% high pass filter
Wn = 5*2/fs;
N = 3;
[a,b] = butter(N,Wn,'high');
ecg_h = filtfilt(a,b,ecg_l);


%bandpass filter
f1=5;
f2=15;
Wn=[f1 f2]*2/fs;
N = 3;
[a,b] = butter(N,Wn);
ecg_h = filtfilt(a,b,ecg);
ecg_h = ecg_h/ max( abs(ecg_h));
raw_ecg = ecg_h;


% noise rejection
if denoise == 1
    M = movmean(abs(ecg_h),1000);
    ecg_noise_idxs = mean(abs(ecg_h)) <= M;
    ecg_noise = ecg_h(ecg_noise_idxs);
    ecg_h(ecg_noise_idxs) = 0;

    max_val = max(abs(ecg_h));
    ecg_h = ecg_h/max_val;
    raw_ecg = raw_ecg/max_val;
end


%% derivitive filter
b = [1 2 0 -2 -1].*(1/8)*fs;   

ecg_d = filtfilt(b,1,ecg_h);
ecg_d = ecg_d/max(ecg_d);

%% Squaring the signal

ecg_s = ecg_d.^2;

%% Moving average

ecg_m = conv(ecg_s ,ones(1 ,round(0.150*fs))/round(0.150*fs));
delay = delay + round(0.150*fs)/2;

%% Remove large noise sections

[yup, ~] = envelope(ecg_h, 30, 'rms');

% figure
% plot(yup)
% title('envelope')
% 
% % figure
% figure
% plot(ecg_m)
% title('original ecg')

% norm_yup = normalize(yup);
norm_yup = yup;

[p, t]  = periodicity(norm_yup, fs, 10, 0.9);
for i = 2:length(p)
    periodicity_value = p(i);
    i1 = int32(t(i-1)*fs);
    i2 = int32(t(i)*fs);
    if p < 0.66
        norm_yup(i1:i2) = NaN;
    end
end
idx = isnan(norm_yup);
ecg_m(idx) = 0;
ecg_h(idx)= 0;


% figure
% plot(ecg_m)
% title('new ecg')

%% ===================== Fiducial Marks ============================== %% 
[pks,locs] = findpeaks(ecg_m,'MINPEAKDISTANCE',round(0.2*fs));
%% =================== Initialize Some Other Parameters =============== %%
LLp = length(pks);
% ---------------- Stores QRS wrt Sig and Filtered Sig ------------------%
qrs_c = zeros(1,LLp);           % amplitude of R
qrs_i = zeros(1,LLp);           % index
qrs_i_raw = zeros(1,LLp);       % amplitude of R
qrs_amp_raw= zeros(1,LLp);      % Index
% ------------------- Noise Buffers ---------------------------------%
nois_c = zeros(1,LLp);
nois_i = zeros(1,LLp);
% ------------------- Buffers for Signal and Noise ----------------- %
SIGL_buf = zeros(1,LLp);
NOISL_buf = zeros(1,LLp);
SIGL_buf1 = zeros(1,LLp);
NOISL_buf1 = zeros(1,LLp);
THRS_buf1 = zeros(1,LLp);
THRS_buf = zeros(1,LLp);


%% initialize the training phase (2 seconds of the signal) to determine the THR_SIG and THR_NOISE
%THR_SIG = max(ecg_m(1:2*fs))*1/3;                                          % 0.25 of the max amplitude 
THR_SIG = max(ecg_m(1:2*fs))*1/3; 
THR_NOISE = mean(ecg_m(1:2*fs))*1/2;                                       % 0.5 of the mean signal is considered to be noise
SIG_LEV= THR_SIG;
NOISE_LEV = THR_NOISE;


%% Initialize bandpath filter threshold(2 seconds of the bandpass signal)
THR_SIG1 = max(ecg_h(1:2*fs))*1/3;                                          % 0.25 of the max amplitude 
THR_NOISE1 = mean(ecg_h(1:2*fs))*1/2; 
SIG_LEV1 = THR_SIG1;                                                        % Signal level in Bandpassed filter
NOISE_LEV1 = THR_NOISE1;                                                    % Noise level in Bandpassed filter
%% ============ Thresholding and desicion rule ============= %%
Beat_C = 0;                                                                 % Raw Beats
Beat_C1 = 0;                                                                % Filtered Beats
Noise_Count = 0;                                                            % Noise Counter
for i = 1 : LLp  
   %% ===== locate the corresponding peak in the filtered signal === %%
    if locs(i)-round(0.150*fs)>= 1 && locs(i)<= length(ecg_h)
          [y_i,x_i] = max(ecg_h(locs(i)-round(0.150*fs):locs(i)));
       else
          if i == 1
            [y_i,x_i] = max(ecg_h(1:locs(i)-1));
            ser_back = 1;
          elseif locs(i)>= length(ecg_h)
            [y_i,x_i] = max(ecg_h(locs(i)-round(0.150*fs):end));
          end       
    end       
  %% ================= update the heart_rate ==================== %% 
    if Beat_C >= 9        
        diffRR = diff(qrs_i(Beat_C-8:Beat_C));                                   % calculate RR interval
        mean_RR = mean(diffRR);                                            % calculate the mean of 8 previous R waves interval
        comp =qrs_i(Beat_C)-qrs_i(Beat_C-1);                                     % latest RR
    
        if comp <= 0.92*mean_RR || comp >= 1.16*mean_RR
     % ------ lower down thresholds to detect better in MVI -------- %
                THR_SIG = 0.5*(THR_SIG);
                THR_SIG1 = 0.5*(THR_SIG1);               
        else
            m_selected_RR = mean_RR;                                       % The latest regular beats mean
        end 
          
    end
    
 %% == calculate the mean last 8 R waves to ensure that QRS is not ==== %%
       if m_selected_RR
           test_m = m_selected_RR;                                         %if the regular RR availabe use it   
       elseif mean_RR && m_selected_RR == 0
           test_m = mean_RR;   
       else
           test_m = 0;
       end
        
    if test_m
          if (locs(i) - qrs_i(Beat_C)) >= round(1.66*test_m)                  % it shows a QRS is missed 
              [pks_temp,locs_temp] = max(ecg_m(qrs_i(Beat_C)+ round(0.200*fs):locs(i)-round(0.200*fs))); % search back and locate the max in this interval
              locs_temp = qrs_i(Beat_C)+ round(0.200*fs) + locs_temp -1;      % location 
             
              if pks_temp > THR_NOISE
               Beat_C = Beat_C + 1;
               qrs_c(Beat_C) = pks_temp;
               qrs_i(Beat_C) = locs_temp;      
              % ------------- Locate in Filtered Sig ------------- %
               if locs_temp <= length(ecg_h)
                  [y_i_t,x_i_t] = max(ecg_h(locs_temp-round(0.150*fs):locs_temp));
               else
                  [y_i_t,x_i_t] = max(ecg_h(locs_temp-round(0.150*fs):end));
               end
              % ----------- Band pass Sig Threshold ------------------%
               if y_i_t > THR_NOISE1 
                  Beat_C1 = Beat_C1 + 1;
                  qrs_i_raw(Beat_C1) = locs_temp-round(0.150*fs)+ (x_i_t - 1);% save index of bandpass 
                  qrs_amp_raw(Beat_C1) = y_i_t;                               % save amplitude of bandpass 
                  SIG_LEV1 = 0.25*y_i_t + 0.75*SIG_LEV1;                      % when found with the second thres 
               end
               
               not_nois = 1;
               SIG_LEV = 0.25*pks_temp + 0.75*SIG_LEV ;                       % when found with the second threshold             
             end             
          else
              not_nois = 0;         
          end
    end
  
    %% ===================  find noise and QRS peaks ================== %%
    if pks(i) >= THR_SIG      
      % ------ if No QRS in 360ms of the previous QRS See if T wave ------%
       if Beat_C >= 3
          if (locs(i)-qrs_i(Beat_C)) <= round(0.3600*fs)
              Slope1 = mean(diff(ecg_m(locs(i)-round(0.075*fs):locs(i))));       % mean slope of the waveform at that position
              Slope2 = mean(diff(ecg_m(qrs_i(Beat_C)-round(0.075*fs):qrs_i(Beat_C)))); % mean slope of previous R wave
              if abs(Slope1) <= abs(0.5*(Slope2))                              % slope less then 0.5 of previous R
                 Noise_Count = Noise_Count + 1;
                 nois_c(Noise_Count) = pks(i);
                 nois_i(Noise_Count) = locs(i);
                 skip = 1;                                                 % T wave identification
                 % ----- adjust noise levels ------ %
                 NOISE_LEV1 = 0.125*y_i + 0.875*NOISE_LEV1;
                 NOISE_LEV = 0.125*pks(i) + 0.875*NOISE_LEV; 
              else
                 skip = 0;
              end
            
           end
        end
        %---------- skip is 1 when a T wave is detected -------------- %
        if skip == 0    
          Beat_C = Beat_C + 1;
          qrs_c(Beat_C) = pks(i);
          qrs_i(Beat_C) = locs(i);
        
        %--------------- bandpass filter check threshold --------------- %
          if y_i >= THR_SIG1  
              Beat_C1 = Beat_C1 + 1;
              if ser_back 
                 qrs_i_raw(Beat_C1) = x_i;                                 % save index of bandpass 
              else
                 qrs_i_raw(Beat_C1)= locs(i)-round(0.150*fs)+ (x_i - 1);   % save index of bandpass 
              end
              qrs_amp_raw(Beat_C1) =  y_i;                                 % save amplitude of bandpass 
              SIG_LEV1 = 0.125*y_i + 0.875*SIG_LEV1;                       % adjust threshold for bandpass filtered sig
          end
         SIG_LEV = 0.125*pks(i) + 0.875*SIG_LEV ;                          % adjust Signal level
        end
              
    elseif (THR_NOISE <= pks(i)) && (pks(i) < THR_SIG)
         NOISE_LEV1 = 0.125*y_i + 0.875*NOISE_LEV1;                        % adjust Noise level in filtered sig
         NOISE_LEV = 0.125*pks(i) + 0.875*NOISE_LEV;                       % adjust Noise level in MVI       
    elseif pks(i) < THR_NOISE
        Noise_Count = Noise_Count + 1;
        nois_c(Noise_Count) = pks(i);
        nois_i(Noise_Count) = locs(i);    
        NOISE_LEV1 = 0.125*y_i + 0.875*NOISE_LEV1;                         % noise level in filtered signal    
        NOISE_LEV = 0.125*pks(i) + 0.875*NOISE_LEV;                        % adjust Noise level in MVI     
    end
               
    %% ================== adjust the threshold with SNR ============= %%
    if NOISE_LEV ~= 0 || SIG_LEV ~= 0
        THR_SIG = NOISE_LEV + 0.25*(abs(SIG_LEV - NOISE_LEV));
        if THR_SIG > 0.2e-5
            THR_SIG = 0.2e-5;
        end
        THR_NOISE = 0.5*(THR_SIG);
    end
    
    %------ adjust the threshold with SNR for bandpassed signal -------- %
    if NOISE_LEV1 ~= 0 || SIG_LEV1 ~= 0
        THR_SIG1 = NOISE_LEV1 + 0.25*(abs(SIG_LEV1 - NOISE_LEV1));
        THR_NOISE1 = 0.5*(THR_SIG1);
    end
    
    
%--------- take a track of thresholds of smoothed signal -------------%
SIGL_buf(i) = SIG_LEV;
NOISL_buf(i) = NOISE_LEV;
THRS_buf(i) = THR_SIG;

%-------- take a track of thresholds of filtered signal ----------- %
SIGL_buf1(i) = SIG_LEV1;
NOISL_buf1(i) = NOISE_LEV1;
THRS_buf1(i) = THR_SIG1;
% ----------------------- reset parameters -------------------------- % 
skip = 0;                                                   
not_nois = 0; 
ser_back = 0;    
end
%% ======================= Adjust Lengths ============================ %%
qrs_i_raw = qrs_i_raw(1:Beat_C1);
qrs_amp_raw = qrs_amp_raw(1:Beat_C1);
qrs_c = qrs_c(1:Beat_C);
qrs_i = qrs_i(1:Beat_C);

%% ======================= Calculate HR ============================ %%

% remove double counting 
% filtered_idxs = find(qrs_amp_raw >= median(qrs_amp_raw) - std(qrs_amp_raw));
% setup
x_ticks = [1:length(ecg_h)];
sq_signal = ecg_h.^2;
sq_amps = qrs_amp_raw.^2;

% smooth, find peaks, and interpolate squared filtered signal (ecg_h) to 
% form a moving threshold level
smooth_sq_signal = smoothdata(sq_signal, 'gaussian', 100);
[peaks, locs] = findpeaks(smooth_sq_signal);
thresholds = interp1(x_ticks(locs), peaks, x_ticks);

% Take another rounds of peaks to smooth: this time of the threshold level itself
% Also add a small offset to better group the detected peaks
[new_peaks, new_locs] = findpeaks(thresholds);
new_thresholds = interp1(x_ticks(new_locs), new_peaks, x_ticks) + ...
                    offset*interp1(qrs_i_raw, movmean(sq_amps,7), x_ticks);

accepts = sq_amps >= new_thresholds(qrs_i_raw);
denies = sq_amps < new_thresholds(qrs_i_raw);
filtered_idxs = qrs_i_raw(accepts);

% begin counting
N = length(filtered_idxs);
bpm = zeros(1, N);
HR_t = filtered_idxs;
HRV = zeros(1,N);


if length(HR_t) < 2
    HR = [];
    HR_t = [];
    HRV = [];
    HR_smooth = [];
else
    for i = 2:length(HR_t)
        % timing parameters
        i1 = HR_t(i-1);
        i2 = HR_t(i);
        time_between_beats = i2/fs - i1/fs;
        HRV(i) = time_between_beats;
        zero_ratio = nnz(~ecg_h(i1:i2))/length(ecg_h(i1:i2));
        drop_out_time = time_between_beats*zero_ratio;

        % HR parameters 
        nominal_bpm = 60/time_between_beats;
        bpm_diff_ratio = abs(1 - nominal_bpm/bpm(i-1));
        if i > 6 % check if too close to beginning to get 5-term mean
           recent_mean_bpm = mean(bpm(i-5:i-1));
        else
           recent_mean_bpm = mean(bpm(2:i-1)); 
        end

        % Assign HR
        if drop_out_time > 10 % seconds
            bpm(i) = NaN;
        elseif drop_out_time > 1 || time_between_beats < 0.33
            bpm(i) = recent_mean_bpm;
        elseif bpm_diff_ratio >= 0.15 && i >= 5
            bpm(i) = mean([bpm(i-4:i-1) nominal_bpm]);
        else
            bpm(i) = nominal_bpm;
        end 
    end

    % Post-processing
    bpm(1) = bpm(2); % roll back to cover first samples
    nans = isnan(bpm);

    %HR
    HR = bpm;

    % HRV
    HRV(1) = HR_t(1);
    HRV(nans) = NaN;

    % HR_smooth
    HR_smooth = HR; % if no smoothing, HR_smooth = HR
    if smoothing > 0
        HR_smooth = smoothdata(HR, 'gaussian', smoothing);
        HR_smooth(nans) = NaN;
    end
end


%% ================== overlay on the signals ========================= %%
% if plotOn
%     figure;
%     az(1)=subplot(411);
%     plot(ecg_h);
%     title('QRS on Filtered Signal');
%     axis tight;
%     hold on,scatter(qrs_i_raw,qrs_amp_raw,'m');
%     hold on,plot(locs,NOISL_buf1,'LineWidth',2,'Linestyle','--','color','k');
%     hold on,plot(locs,SIGL_buf1,'LineWidth',2,'Linestyle','-.','color','r');
%     hold on,plot(locs,THRS_buf1,'LineWidth',2,'Linestyle','-.','color','g');
%     az(2)=subplot(412);plot(ecg_m);
%     title('QRS on MVI signal and Noise level(black),Signal Level (red) and Adaptive Threshold(green)');axis tight;
%     hold on,scatter(qrs_i,qrs_c,'m');
%     hold on,plot(locs,NOISL_buf,'LineWidth',2,'Linestyle','--','color','k');
%     hold on,plot(locs,SIGL_buf,'LineWidth',2,'Linestyle','-.','color','r');
%     hold on,plot(locs,THRS_buf,'LineWidth',2,'Linestyle','-.','color','g');
%     az(3)=subplot(413);
%     plot(ecg-mean(ecg));
%     title('Pulse train of the found QRS on ECG signal');
%     axis tight;
%     line(repmat(qrs_i_raw,[2 1]),...
%        repmat([min(ecg-mean(ecg))/2; max(ecg-mean(ecg))/2],size(qrs_i_raw)),...
%        'LineWidth',2.5,'LineStyle','-.','Color','r');
%     linkaxes(az,'x');
%     zoom on;
% end

time_factor = 1;
label = 'Samples';
switch scale
   case 'seconds'
      time_factor = 1/fs;
      label = 'Time (s)';
   case 'minutes'
      time_factor = 1/(60*fs);
      label = 'Time (min)';
   case 'hours'
      time_factor = 1/(3600*fs);
      label = 'Time (hr)';
end


HR_t = HR_t*time_factor;
x_ticks = [1:length(ecg)]*time_factor;
peaks = qrs_amp_raw(accepts);
ecg = ecg_h;

    

if plotOn
    plot_handle = figure("Name", "ECG Output", 'NumberTitle','off');
   
    % upper plot
    az(1)=subplot(411);
    plot(x_ticks, raw_ecg)
    hold on, scatter(filtered_idxs*time_factor, raw_ecg(filtered_idxs), 2, 'o', 'm');
    axis tight;
    title('Filtered Signal with Final Peaks');

    % middle plots
    az(2)=subplot(412);
    plot(x_ticks, ecg_h, 'LineWidth', 0.1);
    hold on, scatter(qrs_i_raw*time_factor, qrs_amp_raw, 5, 'o', 'm');
    if denoise == 1
        title('All Peaks of Filtered Signal with Noise Rejection');
    else
        title('Peaks of Filtered Signal')
    end
    axis tight;
    yl = ylim;
    az(1).YLim = yl;


    az(3) =subplot(413);
    plot(x_ticks, ecg_h, 'LineWidth', 0.1); 
    hold on, plot(x_ticks, new_thresholds.^(0.5), 'k')
    hold on, scatter(qrs_i_raw(accepts)*time_factor, qrs_amp_raw(accepts), 5, 'o', 'g');
    hold on, scatter(qrs_i_raw(denies)*time_factor, qrs_amp_raw(denies), 5, 'x', 'r');
    title('Thresholding to Obtain Final Peaks');
    axis tight;


    % lower plot
    az(4)=subplot(414);
    hold on, plot(HR_t, HR, '--','LineWidth', 0.8);
    if smoothing > 0
        hold on, plot(HR_t, HR_smooth, 'LineWidth', 2, 'color', 'r')
        title('Calculated Heart Rate from Final Peaks');
    end
    xlabel(label)
    axis tight;

    linkaxes(az, 'x');
    linkaxes([az(1), az(2), az(3)], 'y')
end
end
