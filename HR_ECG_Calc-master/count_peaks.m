function PR = count_peaks(t, y)

    assert (length(t) > 2, 'Too short of a time vector.');
    assert (length(t) == length(y), 'Vectors x and y are have different lengths.');

    bpm = zeros(1,length(y));
    PR_t = t;

    for i = 2:length(PR_t)
        % timing parameters
        t1 = PR_t(i-1);
        t2 = PR_t(i);
        time_between_beats = t2 - t1;
%         time_between_beats = i2/fs - i1/fs;
%         PRV(i) = time_between_beats;
        zero_ratio = nnz(~y(i-1:i))/length(y(i-1:i));
        drop_out_time = time_between_beats*zero_ratio;

        % PR parameters 
        nominal_bpm = 60/time_between_beats;
        bpm_diff_ratio = abs(1 - nominal_bpm/bpm(i-1));
        if i > 6 % check if too close to beginning to get 5-term mean
           recent_mean_bpm = mean(bpm(i-5:i-1));
        else
           recent_mean_bpm = mean(bpm(2:i-1)); 
        end

        % Assign PR
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

    %PR
    PR = bpm;
end

