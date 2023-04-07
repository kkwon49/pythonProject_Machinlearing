clr;
cm = ...
[[881   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0]
 [  0 654   0   0   0   0   0   0   0   0   0   0   0   0   9   0   0   4  0   0]
 [  0   0 526   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0]
 [  0   0   0 877   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0]
 [  0   0   0   0 879   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0]
 [  0   0   0   0   0 885   0   0   0   0   0   0   0   0   0   0   0   0  0   0]
 [  0   0   0   0   0   0 876   0   0   0   0   0   0   0   0   0   0   0  0   0]
 [  0   0   7   0   0   0   0 872   0   0   0   0   0   0   0   0   0   0  0   0]
 [  0   0   0   0   0   0   0   0 916   0   0   0   0   0   0   0   0   0  0   0]
 [  0   0   0   0   0   0   0   0   0 881   0   0   0   0   0   0   0   0  0   0]
 [  0   0   0   0   0   0   0   0   0   0 876   0   0   0   0   0   0   0  0   0]
 [  0   0   0   0   0   0   0   0   0   0   0 868   0   0   0   0   0   0  0   0]
 [  0   0   0   0   0   0   0   0   0   0   0   0 883   0   0   0   0   0  0   0]
 [  0   0   0   0   0   0   0   0   0   0   0   0   0 876   0   0   0   0  0   0]
 [  0   0   0   0   0   0   0   0   0   0   0   0   0   0 876   0   0   0  0   0]
 [  0   3   0   0   0   0   0   0   0   0   0   0   0   0   0 873   0   0  0   0]
 [  0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 885   0  0   0]
 [  0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 837  0   0]
 [ 53   0   0   0   1   0   0   0   0   0   0   0   0   0   0   0   0   0  822   0]
 [  0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0 927]];

% cm = rot90(cm,2);
 
c0 = sum(diag(cm)); % Sum of diagonal
tot_sum = sum(sum(cm)); % Total Sum
accuracy = c0/tot_sum;

cms = size(cm, 1); 

cm2 = cm./sum(cm, 1);
h = figure(1); 
h.Position = [10 10 800*1.5 720*1.5];
generate_confmat(cm2(1:cms, 1:cms).*100, 7);
colorbar;
% cm3=cm2(1:cms, 1:cms);
% mean(diag(cm3))

%%
%% Classification Comparison
%{
clr; figure(2);
% 2 sec windows, FFT+SVM
classifAcc(1) = 63.17
classStdErr(1) = 5.41
% 4 sec windows, FFT+SVM
classifAcc(2) = 70.05
classStdErr(2) = 3.91
% 2 sec windows, FILT+CNN
classifAcc(3) = 88.73
classStdErr(3) = 2.33
% 4 sec windows, FILT+CNN
classifAcc(4) = 94.78
classStdErr(4) = 0.97
h2 = figure(2); 
barwitherr(classStdErr, classifAcc); ylim([0, 100]); xlim([0 5]);
set(gca, 'fontsize', 11); h2.Position = [100 100 270 215];
%}