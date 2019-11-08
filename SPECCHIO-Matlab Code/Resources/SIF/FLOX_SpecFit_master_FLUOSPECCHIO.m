function [out_table,outF_SFM,outR_SFM,outF_SpecFit,outR_SpecFit] = FLOX_SpecFit_master_FLUOSPECCHIO(wvl,L0,L)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  FUNCTION to process FLOX data with new matlab algorithms within FLUOSPECCHIO %%%%%%%%
%
%   INPUT:
%   wvl - wavelength vector (nX1) in nanometer (nm)
%   L0 - downwelling radiance (can be a column or a matrix where each column is a measurement) [W.m-2.sr-1.nm-1]
%   L - upwelling radiance (can be a column or a matrix where each column is a measurement) [W.m-2.sr-1.nm-1]
%
%   OUTPUT:
%   out_table - a matlab table (m x v) where each line corresponds to a measurement, and each column to an output variable (e.g., f_SFM_A: fluorescence at 760nm retrieved Spectral Fitting Methods at the O2-A oxygen band)
%   outF_SFM - fluorescence spectrum retrieved with SFM at the oxygen bands (n x m) array where the retrieved fluorescence is interpolated to the original wavelength vector [mW.m-2.sr-1.nm-1]
%   outR_SFM - true reflectance spectrum retrieved with SFM at the oxygen bands (n x m) array where the retrieved reflectance is interpolated to the original wavelength vector [-]
%   outF_SpecFit - fluorescence spectrum retrieved with up-to-date version of SpecFit over the full emission range (n x m) array where the retrieved fluorescence is interpolated to the original wavelength vector [mW.m-2.sr-1.nm-1]
%   outR_SpecFit - true reflectance spectrum retrieved with up-to-date version of SpecFit over the full emission range (n x m) array where the retrieved reflectance is interpolated to the original wavelength vector [-]
%
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
%
%   DATE: Nov/2019
%


%% STEPS

%% ADJUST VARIABLES BEFORE RUN THE PROGRAM
wvlRet = [670 780];

rng = 4;
%SETS THE SF model used                   %
opt_alg = 'tr';                 %optimization algorithm 'lm'= Levemberg-Marquard; 'tr'=trust region reflective
weights = 1;                    % 1) w=1; 2) w=1/Lup^2; 3) w=Lup^2
stio = 'off';                 %'off';'iter';'final'

%%

%% DEFINITION OF GLOBAL VARIABLES
global wvl_def
wvl_definition(rng); % with enlarged dx range for SFM A up to 780


%% Selects imput files
n_files = size(L0,2);

%% OUTPUT FILE
% [~, lb] = min(abs(wvl-wvlRet(1))); [~, ub] = min(abs(wvl-wvlRet(2)));

%% Spectral subset of input spectra to min_wvl - max_wvl range
% and convert to mW
[wvlF,~,sub_ind_F] = subset_2d_array(wvl,wvl,wvlRet(1),wvlRet(2));
Lin_F = L0(sub_ind_F(1):sub_ind_F(2),:)*1e3;
Lup_F = L(sub_ind_F(1):sub_ind_F(2),:)*1e3;

[wvl_A,Lin_A,sub_ind_A] = subset_2d_array(wvl, L0, wvl_def.sfm_low_wl_A, wvl_def.sfm_up_wl_A);
[~,Lup_A] = subset_2d_array(wvlF, L, wvl_def.sfm_low_wl_A, wvl_def.sfm_up_wl_A);
[~,iwvl_A_760] = min(abs(wvl_A-760));

[wvl_B,Lin_B,sub_ind_B] = subset_2d_array(wvl, L0, wvl_def.sfm_low_wl_B, wvl_def.sfm_up_wl_B);
[~,Lup_B] = subset_2d_array(wvlF, L, wvl_def.sfm_low_wl_B, wvl_def.sfm_up_wl_B);
[~,iwvl_B_687] = min(abs(wvl_B-687));

% define output wvl for SpecFit
owvl = wvl;

[~,iowvl_760] = min(abs(owvl-760));
[~,iowvl_687] = min(abs(owvl-687));

% creates the output variables
out_hdr = {                                                                                                     ...
    'f_FLD_A' 'r_FLD_A' 'f_SFM_A' 'r_SFM_A' 'resnorm_SFM_A' 'exitflag_SFM_A' 'n_it_SFM_A'                       ...
    'f_FLD_B' 'r_FLD_B' 'f_SFM_B' 'r_SFM_B' 'resnorm_SFM_B' 'exitflag_SFM_B' 'n_it_SFM_B'                       ...
    'f_SpecFit_A' 'r_SpecFit_A' 'f_SpecFit_B' 'r_SpecFit_B' 'resnorm_SpecFit' 'exitflag_SpecFit' 'n_it_SpecFit' ...
    'f_max_FR' 'f_max_FR_wvl' 'f_max_R' 'f_max_R_wvl' 'f_int'                                                     ...
    };

out_arr = nan(n_files,size(out_hdr,2));
outF_SpecFit = nan(numel(owvl),n_files);
outR_SpecFit = nan(numel(owvl),n_files);
% save spectra from SFM too
outF_SFM_A = nan(numel(wvl_A),n_files);
outR_SFM_A = nan(numel(wvl_A),n_files);
outF_SFM_B = nan(numel(wvl_B),n_files);
outR_SFM_B = nan(numel(wvl_B),n_files);

%% weighting scheme
switch weights
    case 1
        w_A = ones(size(Lup_A,1),1);  w_A(:) = 1.0;
        w_B = ones(size(Lup_B,1),1);  w_B(:) = 1.0;
        w_F = ones(size(Lup_F,1),1);  w_F(:) = 1.0;
    case 2
        w_A= (1./Lup_A.^2);
        w_B= (1./Lup_B.^2);
        w_F= (1./Lup_F);
    case 3
        w_A= (Lup_A.^2);
        w_B= (Lup_B.^2);
        w_F= (Lup_F.^2);
    otherwise
end

for i = 1:n_files
        
    % Processing
        
        %
        try
            
        [~,f_wvl_A,r_wvl_A,resnorm_A,exitflag_A,output_A,f_FLD_A,r_FLD_A]=NBFret_VPSPLINE...
            (wvl_A,Lin_A(:,i),Lup_A(:,i),'A',0,w_A,opt_alg,stio);
        
        [~,f_wvl_B,r_wvl_B,resnorm_B,exitflag_B,output_B,f_FLD_B,r_FLD_B]=NBFret_VPSPLINE...
            (wvl_B,Lin_B(:,i),Lup_B(:,i),'B',0,w_B,opt_alg,stio);
        
        [~,f_wvl_F,r_wvl_F,resnorm_F,exitflag_F,output_F]=FLOX_SpecFit_6C(...
            wvlF,Lin_F(:,i),Lup_F(:,i),[1,1],w_F,opt_alg,stio,owvl);
        
        [f_R_max, f_R_wl, ~, f_FR_max, f_FR_wl, ~, fint] = sif_parms(owvl,f_wvl_F);
        
        out_arr(i,:) = [ ...
            f_FLD_A r_FLD_A f_wvl_A(iwvl_A_760) r_wvl_A(iwvl_A_760) resnorm_A exitflag_A output_A.iterations                     ...
            f_FLD_B r_FLD_B f_wvl_B(iwvl_B_687) r_wvl_B(iwvl_B_687) resnorm_B exitflag_B output_B.iterations                     ...
            f_wvl_F(iowvl_760) r_wvl_F(iowvl_760) f_wvl_F(iowvl_687) r_wvl_F(iowvl_687) resnorm_F exitflag_F output_F.iterations ...
            f_FR_max f_FR_wl f_R_max f_R_wl fint];
        
        %
        outF_SFM_A(:,i) = f_wvl_A;
        outF_SFM_B(:,i) = f_wvl_B;
        outF_SpecFit(:,i) = f_wvl_F;
        %
        outR_SFM_A(:,i) = r_wvl_A;
        outR_SFM_B(:,i) = r_wvl_B;
        outR_SpecFit(:,i) = r_wvl_F;
        
        catch
            
        end
        
        %
end

%% resample at original wavelength vector (wvl)
outF_SFM_A = interp1(wvl_A,outF_SFM_A,owvl);
outR_SFM_A = interp1(wvl_A,outR_SFM_A,owvl);
outF_SFM_B = interp1(wvl_B,outF_SFM_B,owvl);
outR_SFM_B = interp1(wvl_B,outR_SFM_B,owvl);

% and put together both oxygen bands
outF_SFM = outF_SFM_A; outF_SFM(sub_ind_B(1):sub_ind_B(2),:) = outF_SFM_B(sub_ind_B(1):sub_ind_B(2),:);
outR_SFM = outR_SFM_A; outR_SFM(sub_ind_B(1):sub_ind_B(2),:) = outR_SFM_B(sub_ind_B(1):sub_ind_B(2),:);

out_table = array2table(out_arr);
out_table.Properties.VariableNames = out_hdr;

end

