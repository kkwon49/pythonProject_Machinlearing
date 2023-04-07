clr;
A = fopen('DATA.DAT'); 
B = fread(A,'int16'); 
for i=1:length(B)/2
    C(i, 1) = B(2*i - 1);
    C(i, 2) = B(2*i);
end
% B = reshape(B, [length(B)/2, 2]); 

fclose(A); 

plot(C); legend('GSR ADC Output', 'Temperature'); 

figure(2); plot(C(:, 1)); ylabel('GSR Output'); xlabel('Sample #');