function [outF_SpecFit, outR_SpecFit, SIF_R_max, SIF_R_wl,     ...
   SIF_FR_max, SIF_FR_wl, SIFint, outF_SFM, outR_SFM] = FLOX_SpecFit_master(wvl,L0,L)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  FUNCTION to process FLOX data with new matlab algorithms within FLUOSPECCHIO %%%%%%%%
%
%   INPUT:
%   wvl - wavelength vector (nX1) in nanometer (nm)
%   L0 - downwelling radiance (can be a column or a nxm array where each column is a measurement) [W.m-2.sr-1.nm-1]
%   L - upwelling radiance (can be a column or a nxm array where each column is a measurement) [W.m-2.sr-1.nm-1]
%
%   OUTPUT:
%   outF_SpecFit    - nxm array with spectral fluorescence retrieved in the full fitting window by SpecFit
%   outR_SpecFit    - nxm array with spectral true reflectance retrieved in the full fitting window by SpecFit
%   SIF_R_max       - max Reflectance of red SIF
%   SIF_R_wl        - wavelength of the red SIF max
%   SIF_FR_max      - max Reflectance of far-red SIF
%   SIF_FR_wl       - wavelength of the far-red SIF
%   SIFint          - total SIF emission (integrated using trapz())
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
%   DATE: Nov/2018
%   
%   UPDATE: Oct/2019

%% ADJUST VARIABLES BEFORE RUN THE PROGRAM
% Adjust variables
wvlRet    = [670 780];

% Set options
opt_alg   = 'tr';    % optimization algorithm 
                       % 1) 'lm'= Levemberg-Marquard; 
                       % 2) 'tr'=trust region reflective
weights   = 1;       % weight options: 
                       % 1) w = 1;
                       % 2) w = (1/Lup)^2; 
                       % 3) w = (Lup)^2
stio      = 'off';   % options: 
                       % 1) 'off';
                       % 2) 'iter';
                       % 3) 'final'
%% DEFINITION OF GLOBAL VARIABLES
global wvl_def
wvl_definition(4); % with enlarged dx range for SFM A up to 780

%% Selects imput files
n_files = size(L0,2);

%% -- Wavelength definition
[~, lb]         = min(abs(wvl-wvlRet(1)));
[~, ub]         = min(abs(wvl-wvlRet(2)));

%% -- Some basic filtering WHAT KIND OF FILTERING?
L0_filter       = L(500,:)>=0.01;

%% Spectral subset of input spectra to min_wvl - max_wvl range
% and convert to mW
wvlF            = wvl(lb:ub);
Lin             = L0(lb:ub,:)*1e3;
Lup             = L(lb:ub,:)*1e3;

% O2A
[wvl_A, Lin_A, sub_ind_A]   = subset_2d_array(wvl, L0, wvl_def.sfm_low_wl_A, wvl_def.sfm_up_wl_A);
[~, Lup_A]                  = subset_2d_array(wvlF, L, wvl_def.sfm_low_wl_A, wvl_def.sfm_up_wl_A);
[~, iwvl_A_760]             = min(abs(wvl_A-760));

% O2B
[wvl_B, Lin_B, sub_ind_B]   = subset_2d_array(wvl, L0, wvl_def.sfm_low_wl_B, wvl_def.sfm_up_wl_B);
[~, Lup_B]                  = subset_2d_array(wvlF, L, wvl_def.sfm_low_wl_B, wvl_def.sfm_up_wl_B);
[~, iwvl_B_687]             = min(abs(wvl_B-687));

% define output wvl for SpecFit
owvl            = wvlF;
[~,iowvl_760]   = min(abs(owvl-760));
[~,iowvl_687]   = min(abs(owvl-687));

outF_SpecFit    = nan(numel(owvl),n_files);
outR_SpecFit    = nan(numel(owvl),n_files);

outF_SFM_A      = nan(numel(wvl_A),n_files);
outR_SFM_A      = nan(numel(wvl_A),n_files);
outF_SFM_B      = nan(numel(wvl_B),n_files);
outR_SFM_B      = nan(numel(wvl_B),n_files);

%% weighting scheme

switch weights
    case 1
        w_A     = ones(size(Lup_A,1),1);  
        w_A(:)  = 1.0;
        w_B     = ones(size(Lup_B,1),1);  
        w_B(:)  = 1.0;
        w_F     = ones(size(Lup,1),1);  
        w_F(:)  = 1.0;   
    case 2
        w_A     = (1./Lup_A.^2);
        w_B     = (1./Lup_B.^2);
        w_F     = (1./Lup); 
    case 3
        w_A     = (Lup_A.^2);
        w_B     = (Lup_B.^2);
        w_F     = (Lup.^2);        
    otherwise
end
        
% errorbar inside the parfor loop
hbar = parfor_progressbar(n_files-1,'Please wait...');

parfor i = 1:n_files
% for i = 1:n_files
%     disp(num2str(i));
    % -- process only filtered data
    if L0_filter(i) == 1
   
        % Processing
        
        % SFM O2A:
        [x_A,f_wvl_A,r_wvl_A,resnorm_A,exitflag_A,output_A,f_FLD_A,r_FLD_A]=NBFret_VPSPLINE...
            (wvl_A,Lin_A(:,i),Lup_A(:,i),'A',0,w_A,opt_alg,stio);
        
        % SFM O2B:
        [x_B,f_wvl_B,r_wvl_B,resnorm_B,exitflag_B,output_B,f_FLD_B,r_FLD_B]=NBFret_VPSPLINE...
            (wvl_B,Lin_B(:,i),Lup_B(:,i),'B',0,w_B,opt_alg,stio);
        
        % SIF (SFM): 
        outF_SFM_A(:,i) = f_wvl_A;
        outF_SFM_B(:,i) = f_wvl_B;
        
        % REFLECTANCE (SFM):
        outR_SFM_A(:,i) = r_wvl_A;
        outR_SFM_B(:,i) = r_wvl_B;
        
        % SPECFIT:       
        [x_F,f_wvl_F,r_wvl_F,resnorm_F,exitflag_F,output_F] = FLOX_SpecFit_6C...
            (owvl,Lin(:,i),Lup(:,i),[1,1],w_F,opt_alg,stio,owvl);

        % spectral output from SpecFit
        outF_SpecFit(:,i) = f_wvl_F;
        outR_SpecFit(:,i) = r_wvl_F;
        
        hbar.iterate(1)
        %
    end
end

close(hbar);
%% resample at original wavelength vector (wvl)
outF_SFM_A = interp1(wvl_A,outF_SFM_A,wvl);
outR_SFM_A = interp1(wvl_A,outR_SFM_A,wvl);
outF_SFM_B = interp1(wvl_B,outF_SFM_B,wvl);
outR_SFM_B = interp1(wvl_B,outR_SFM_B,wvl);

% and put together both oxygen bands
outF_SFM = outF_SFM_A; 
outF_SFM(sub_ind_B(1):sub_ind_B(2),:) = outF_SFM_B(sub_ind_B(1):sub_ind_B(2),:);
outR_SFM = outR_SFM_A; 
outR_SFM(sub_ind_B(1):sub_ind_B(2),:) = outR_SFM_B(sub_ind_B(1):sub_ind_B(2),:);
%% compute FLEX metrics
[SIF_R_max,SIF_R_wl,~,SIF_FR_max,SIF_FR_wl,~,SIFint] = sif_parms(owvl,outF_SpecFit); 
    
end
