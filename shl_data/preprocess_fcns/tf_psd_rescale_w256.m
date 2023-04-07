function [ Y ] = tf_psd_rescale_w256( X )
%tf_psd_rescale_w256 TF Preprocessing
% input should be X = (256, 2), or X = (512, 1);
% X = single(X); 
Fs = 250;
Y = single(zeros(128, 2)); % WAS 2, 128
if numel(X) == 512
    if size(X,1) == 512
        X = reshape(X, [256, 2]);
    elseif size(X,2) == 256
        X = X'; % if input is X = (2, 256), transpose
    end
end
% High Pass Filter at 4Hz:
b = [0.904318734484790,-2.71295620345437,2.71295620345437,-0.904318734484790];
a = [1,-2.79902201467330,2.61773550092223,-0.817792360282780];

X(:, 1) = filtfilt(b, a, X(:, 1)); 
X(:, 2) = filtfilt(b, a, X(:, 2)); 

Y(001:128) = rescale_minmax(tf_welch_psd(X(:, 1), Fs, hannWin(256)));

Y(129:end) = rescale_minmax(tf_welch_psd(X(:, 2), Fs, hannWin(256)));

% for ch = 1:2
%    Y(ch,:) = tf_welch_psd(X(:,ch), Fs, hannWin(256)); %
%    Y(ch,:) = rescale_minmax(Y(ch,:));
% end

end

