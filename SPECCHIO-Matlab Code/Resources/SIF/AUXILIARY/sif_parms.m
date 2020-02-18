
function [SIF_R_max, SIF_R_wl, SIF_O2B, ...
    SIF_FR_max, SIF_FR_wl, SIF_O2A, SIFint] = sif_parms(wl, SIF)
% Extracting relevant parameters from the SIF retrieval
%   Sergio Cogliati, Ph.D
%   Remote Sensing of Environmental Dynamics Lab.
%   University of Milano-Bicocca
%   Milano, Italy
%   email: sergio.cogliati@unimib.it
%
%   Marco Celesti, Ph.D
%   Remote Sensing of Environmental Dynamics Lab.
%   University of Milano-Bicocca
%   Milano, Italy
%   email: marco.celesti@unimib.it

%% RED SIF

% max
wl_R = wl<690;

if sum(wl_R) > 0
    [SIF_R_max,p] = max(SIF(wl_R,:));
    
    % lambda
    wl_R = wl(wl<690);
    SIF_R_wl = wl_R(p);
    
    % SIF at O2-B 687nm
    [~, ii] = min(abs(wl-687));
    SIF_O2B = SIF(ii,:);
else
    SIF_R_max = NaN;
    SIF_R_wl = NaN;
    SIF_O2B = NaN;
end

%% FAR-RED SIF
% max
wl_FR = wl>720;

if sum(wl_FR) > 0
    [SIF_FR_max,p] = max(SIF(wl_FR,:));
    
    % lambda
    wl_FR = wl(wl>720);
    SIF_FR_wl = wl_FR(p);
    
    % SIF at O2-A 760nm
    [~, pp] = min(abs(wl-760));
    SIF_O2A = SIF(pp,:);
else
    SIF_FR_max = NaN;
    SIF_FR_wl = NaN;
    SIF_O2A = NaN;
end

%% Spectrally integrated SIF
SIFint = trapz(wl,SIF,1);

end