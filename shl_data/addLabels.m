function [] = addLabels(ttl, xlab, ylab, font_sz)
% quick function for adding title, xlabel and ylabel to plot
if nargin < 4
    font_sz = 12;
end
    title(ttl, 'FontSize', font_sz); 
    xlabel(xlab, 'FontSize', font_sz);
    ylabel(ylab, 'FontSize', font_sz);
end