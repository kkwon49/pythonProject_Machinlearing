function [X,Y] = segmentFFTandLabels(data,Fs,labels,wlen,whop,PLOT)
%SEGMENTDATAANDLABELS - Assumes no further preprocessing
% Uses semantic segmentation model: 

if nargin < 6
    PLOT = 0;
end

wStart = 1:whop:(length(data)-wlen);
wEnd = wStart + wlen - 1;

X = zeros(length(wStart), wlen/2, 1);
Y = zeros(length(wStart), 1);  

for w = 1:length(wStart)
    tmp = data(wStart(w) : wEnd(w), :);
%     tmp2 = rescale_minmax(exfft2(tmp, Fs, PLOT)); 
    tmp2 = rescale_linear(exfft2(tmp, Fs, PLOT), 50);
    X(w, :, :) = tmp2(1:wlen/2);
    Y(w, :) = labels;
    if PLOT
        figure(1); 
        subplot(2,1,1); plot( tmp );
        subplot(2,1,2); plot( X(w, :, :)  );
        input('Continue? \n');
    end
end

X = single(X);
Y = single(Y);

end

