function [wvl_sub, s_sub] = subset_1d_array(wvl, s, low_wl, up_wl)
%% Extract the subset of spectra (s) according to the lower/upper wavelength 
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

%%
%subscript of the lower bound
%[res, low_sub] = min(abs(wvl-low_wl));
low_sub = find(wvl>=low_wl,1);

%subscript of the upper bound
%[res, up_sub] = min(abs(wvl-up_wl));
up_sub = find(wvl<=up_wl,1,'last');

wvl_sub = wvl(low_sub:up_sub);

s_sub = s(low_sub:up_sub,:);

end