function [wvl_sub, s_sub, sub_ind] = subset_2d_array(wvl, s, low_wvl, up_wvl)
% Extract the subset of spectra (s) according to the lower/upper wavelength 
%   
%   INPUT:
%   wvl - a vector containing wavelength
%   s - an array where each column is a spectrum 
%   low_wvl - a scalar with the lower limit of wvl 
%   up_wvl - a scalar with the upper limit of wvl
%
%   OUTPUT:
%   wvl_sub - cut wavelenght vector
%   s_sub - cut spectral array
%   sub_ind - a 2x1 vector containing indices of lower and upper wavelength
%
%   Marco Celesti, Ph.D
%   Remote Sensing of Environmental Dynamics Lab.
%   University of Milano-Bicocca
%   Milano, Italy
%   email: marco.celesti@unimib.it
%
%   DATE: Apr/2015

%subscript of the lower bound
%[res, low_sub] = min(abs(wvl-low_wvl));
low_sub = find(wvl>=low_wvl,1);

%subscript of the upper bound
%[res, up_sub] = min(abs(wvl-up_wvl));
up_sub = find(wvl<=up_wvl,1,'last');

wvl_sub = wvl(low_sub:up_sub);

s_sub = s(low_sub:up_sub,:);

sub_ind = [low_sub,up_sub];
end
