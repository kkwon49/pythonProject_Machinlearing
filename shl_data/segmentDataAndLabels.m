function [X,Y] = segmentDataAndLabels(data,labels,wlen,whop, PLOT)
%SEGMENTDATAANDLABELS - Assumes no further preprocessing
% Uses semantic segmentation model: 

if nargin < 5
    PLOT = 0;
end

wStart = 1:whop:(length(data)-wlen);
wEnd = wStart + wlen - 1;

X = zeros(length(wStart), wlen, 1);
Y = zeros(length(wStart), wlen, 1);  

for w = 1:length(wStart)
    X(w, :, :) = rescale_minmax(data(wStart(w) : wEnd(w), :)); 
    Y(w, :, :) = labels(wStart(w) : wEnd(w), :); 
    if PLOT
        figure(1); 
        subplot(2,1,1); plot( X(w, :, :) );
        subplot(2,1,2); plot( Y(w, :, :) );
        input('Continue? \n');
    end
end

X = single(X);
Y = single(Y);

end

