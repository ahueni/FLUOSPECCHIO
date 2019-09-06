function [VIs] = compute_VIs(wvl,rho_full)
% compute_VIs computes Vegetation Indices (VIs) from reflectance spectra of the VNIR (full) spectrometer (i.e. the FLAME)
% 
%   Authors:    Marco Celesti (marco.celesti@unimib.it)
%               Sergio Cogliati (sergio.cogliati@unimib.it)
%               
%   Created:    20180420    
%   
%   Updates:    20180423    - added ...
% 
%   Usage:      function [VIs] = compute_VIs(wvl,rho_full)
%
%               reflectance-based VIs can be easily added to the function by creating additional sections
%
%   Input:
%   wvl - wavelength vector in nanometer [nm] (column) 
%   rho_full - reflectance spectra of the VNIR (full) spectrometer (i.e. the FLAME) in float [0-1] (can be a column or a matrix where each column is a measurement) 
%   
%   Output:
%   VIs - values of the calculated vegetation indices (a table where each column is a VI, each row a measurement)
%
%   Table of contents of the function:
%   
%   Currently this script computes:
%   
%   1-SR
%   2-NDVI
%   3-NDVIre
%   4-EVI
%   5-REP
%   6-MTCI
%   7-TCARI
%   8-PRI
%   9-cPRI
%   10-WBI
%
%% Initialize structures
VIs = table;
%
%% SR and NDVI 
% NOTE!!! As a test reflectance is defined as average reflectance between min and max wvl 

rho_665_680 = mean(rho_full(wvl >= 665 & wvl <= 680,:),1);
rho_795_810 = mean(rho_full(wvl >= 795 & wvl <= 810,:),1);

VIs.SR680800 = (rho_795_810 ./ rho_665_680).';

VIs.NDVI = ((rho_795_810 - rho_665_680) ./ (rho_795_810 + rho_665_680)).';


%% NDVIre 
% NOTE!!! As a test reflectance is defined as average reflectance between min and max wvl 

rho_695_710 = mean(rho_full(wvl >= 695 & wvl <= 710,:),1);
rho_735_750 = mean(rho_full(wvl >= 735 & wvl <= 750,:),1);

VIs.NDVIre = ((rho_735_750 - rho_695_710) ./ (rho_735_750 + rho_695_710)).';

% NOTE!!! the following is useful ONLY if memory allocation is an issue!!!
clear rho_695_710 rho_735_750

%% EVI
% NOTE!!! As a test reflectance is defined as average reflectance between min and max wvl 

rho_475_490 = mean(rho_full(wvl >= 475 & wvl <= 490,:),1);

VIs.EVI = (2.5 * ( (rho_795_810 - rho_665_680) ./ (rho_795_810 + 6*rho_665_680 - 7.5*rho_475_490 + 1) )).';

clear rho_475_490

%% REP
% NOTE!!! As a test reflectance is defined as average reflectance between min and max wvl 

rho_700 = mean(rho_full(wvl >= 697.5 & wvl <= 702.5,:),1);
rho_740 = mean(rho_full(wvl >= 737.5 & wvl <= 742.5,:),1);

VIs.REP = (700 + 40 * ( (rho_665_680 + rho_795_810) ./ 2 - rho_700) ./ (rho_740 - rho_700)).';

clear rho_700 rho_740 rho_665_680 rho_795_810

%% MTCI
% NOTE!!! As a test reflectance is defined as average reflectance between min and max wvl 

rho_MERIS_681 = mean(rho_full(wvl >= 673.5 & wvl <= 688.5,:),1);
rho_MERIS_709 = mean(rho_full(wvl >= 699.0 & wvl <= 719.0,:),1);
rho_MERIS_754 = mean(rho_full(wvl >= 746.5 & wvl <= 761.5,:),1);

VIs.MTCI = ((rho_MERIS_754 - rho_MERIS_709) ./ (rho_MERIS_709 - rho_MERIS_681)).';

clear rho_MERIS_681 rho_MERIS_709 rho_MERIS_754

%% TCARI
% NOTE!!! As a test reflectance is defined as average reflectance between min and max wvl 

rho_TCARI_550 = mean(rho_full(wvl >= 546 & wvl <= 554,:),1);
rho_TCARI_670 = mean(rho_full(wvl >= 666 & wvl <= 674,:),1);
rho_TCARI_700 = mean(rho_full(wvl >= 696 & wvl <= 704,:),1);

VIs.TCARI = (3 * ( (rho_TCARI_700 - rho_TCARI_670) - 0.2 * (rho_TCARI_700 - rho_TCARI_550) .* rho_TCARI_700 ./ rho_TCARI_670 )).';

clear rho_TCARI_550 rho_TCARI_670 rho_TCARI_700

%% PRI and cPRI
% NOTE!!! As a test reflectance is defined as average reflectance between min and max wvl 

rho_PRI_531 = mean(rho_full(wvl >= 528.5 & wvl <= 533.5,:),1);
rho_PRI_570 = mean(rho_full(wvl >= 567.5 & wvl <= 572.5,:),1);

VIs.PRI = ((rho_PRI_570 - rho_PRI_531) ./ (rho_PRI_570 + rho_PRI_531)).';

VIs.cPRI = VIs.PRI - 0.15 * (1 - exp(-0.5 .* VIs.SR680800));

clear rho_PRI_531 rho_PRI_570

%% WBI
% NOTE!!! As a test reflectance is defined as average reflectance between min and max wvl 

rho_890_905 = mean(rho_full(wvl >= 890 & wvl <= 905,:),1);
rho_955_970 = mean(rho_full(wvl >= 955 & wvl <= 970,:),1);

VIs.WBI = (rho_955_970 ./ rho_890_905).';

clear rho_890_905 rho_955_970

end

