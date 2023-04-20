fs = 256;
[b, a] = notch(256, 60);
[db,mag,pha,grd,w] = freqz_m(b,a);
figure
plot(w*fs/(2*pi), db);

%% function notch filter
function [b, a] = notch(fs,notch_freq)
    DT_notch_freq = 2*pi*notch_freq/fs;
    r = 0.7;
    notchzeros = [exp(1i*DT_notch_freq) exp(-1i*DT_notch_freq)];
    notchpoles = [r*exp(1i*DT_notch_freq) r*exp(-1i*DT_notch_freq)];
    b = poly(notchzeros);
    a = poly(notchpoles);
end

%%
function [db,mag,pha,grd,w] = freqz_m(b,a)

% Modified version of freqz subroutine

% ------------------------------------

% [db,mag,pha,grd,w] = freqz_m(b,a);

%  db = Relative magnitude in dB computed over 0 to pi radians

% mag = absolute magnitude computed over 0 to pi radians 

% pha = Phase response in radians over 0 to pi radians

% grd = Group delay over 0 to pi radians

%   w = 501 frequency samples between 0 to pi radians

%   b = numerator polynomial of H(z)   (for FIR: b=h)

%   a = denominator polynomial of H(z) (for FIR: a=[1])

%

[H,w] = freqz(b,a,1000,'whole');

    H = (H(1:1:501))'; w = (w(1:1:501))';

  mag = abs(H);

   db = 20*log10((mag+eps)/max(mag));

  pha = angle(H);

%  pha = unwrap(angle(H));

  grd = grpdelay(b,a,w);

%  grd = diff(pha);

%  grd = [grd(1) grd];

%  grd = [0 grd(1:1:500); grd; grd(2:1:501) 0];

%  grd = median(grd)*500/pi;
end