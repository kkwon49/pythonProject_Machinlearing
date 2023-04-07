function [Xt, Yt, Xv, Yv] = train_test_split(X,Y,split_frac)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if nargin < 3
    split_frac = 0.8;
end
cut = round(split_frac*size(X, 1));
Xv = X(cut:end, :); 
Yv = Y(cut:end, :); 
Xt = X(1:cut-1, :);
Yt = Y(1:cut-1, :);
end

