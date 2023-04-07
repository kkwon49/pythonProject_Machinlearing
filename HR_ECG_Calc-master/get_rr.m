function [RR_t, RR] = get_rr(HR_t, HR, fs)
    fs = 250;
    T = 1/fs; 
    N = length(HR)-1;
    t = (0:N-1)*T;
    
    HR_fft = fft(HR);
    P2 = abs(HR_fft/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = fs*(0:(N/2))/N;
    plot(f,P1) 
    xlim([0 10])
end