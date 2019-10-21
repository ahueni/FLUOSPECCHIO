function [out_mat,outF_SpecFit,outR_SpecFit, SIF_R_max, SIF_R_wl, SIF_FR_max, SIF_FR_wl, SIFint] = matlab_SpecFit_oo_FLOX_v4_FLUOSPECCHIO(wvl,L0,L)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  FUNCTION to process FLOX data with new matlab algorithms within FLUOSPECCHIO %%%%%%%%
%
%   INPUT:
%   wvl - wavelength vector (nX1) in nanometer (nm)
%   L0 - downwelling radiance (can be a column or a nxm array where each column is a measurement) [W.m-2.sr-1.nm-1]
%   L - upwelling radiance (can be a column or a nxm array where each column is a measurement) [W.m-2.sr-1.nm-1]
%
%   OUTPUT:
%   out_mat_all - mxi array where i is the number of output metrics of the SFM/SpecFit retrieval
%   outF_SFM_all - nxm array with spectral fluorescence retrieved in the oxygen bands by SFM
%   outR_SFM_all - nxm array with spectral true reflectance retrieved in the oxygen bands by SFM
%   outF_SpecFit_all - nxm array with spectral fluorescence retrieved in the full fitting window by SpecFit
%   outR_SpecFit_all nxm array with spectral true reflectance retrieved in the full fitting window by SpecFit

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


%% STEPS

%% --- INITIALIZE LOG FILE

proc_time_all = datestr(now,'yyyymmdd_HH_MM_SS');
Logfile       = fullfile(pwd,strcat(proc_time_all,'_logfile.txt'));
diary(Logfile)

% suppress warnings
warning('off','all')

addpath(genpath(pwd));

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

%% --- INITIALIZE PARPOOL

profile      = 'local'; 
n_cores      = feature('numcores');        % automatically select the max number of available cores
p            = gcp('nocreate');            % If no pool, do not create new one.

if isempty(p)
    ppool    = parpool(profile,n_cores);   % ok<NOPTS>
else
    delete(p);
    ppool    = parpool(profile,n_cores);   % ok<NOPTS>
end

%% Selects imput files
n_files = size(L0,2);

%% -- Wavelength definition
[~, lb]         = min(abs(wvl-wvlRet(1)));
[~, ub]         = min(abs(wvl-wvlRet(2)));

%% -- Some basic filtering WHAT KIND OF FILTERING?
L0_filter       = L(500,:)>=0.01;

%% Spectral subset of input spectra to min_wvl - max_wvl range
% and convert to mW
wvl             = wvl(lb:ub);
Lin             = L0(lb:ub,:)*1e3;
Lup             = L(lb:ub,:)*1e3;

% define output wvl for SpecFit
owvl            = wvl;
[~,iowvl_760]   = min(abs(owvl-760));
[~,iowvl_687]   = min(abs(owvl-687));

% create the output arrays
out_hdr         = { 'filenum''f_SpecFit_A' 'r_SpecFit_A' 'f_SpecFit_B'  ...
    'r_SpecFit_B' 'resnorm_SpecFit' 'exitflag_SpecFit'                  ...
    'n_it_SpecFit''f_max_A' 'f_max_A_wvl' 'f_max_B'                     ...
    'f_max_B_wvl' 'f_int'                                               ...
    };
              
out_mat         = nan(n_files,size(out_hdr,2)-8);
outF_SpecFit    = nan(numel(owvl),n_files);
outR_SpecFit    = nan(numel(owvl),n_files);

%% weighting scheme

 switch weights  
            case 1
                w_F     = ones(size(Lup,1),1);  
                w_F(:)  = 1.0;
                
            case 2
                w_F     = (1./Lup);
                
            case 3
                w_F     = (Lup.^2);
                
            otherwise        
 end
        
% errorbar inside the parfor loop
hbar = parfor_progressbar(n_files-1,'Please wait...');

parfor i = 1:n_files
    % -- process only filtered data
    if L0_filter(i) == 1
   
        % Processing
        [x_F,f_wvl_F,r_wvl_F,resnorm_F,exitflag_F,output_F] = FLOX_SpecFit_6C...
            (wvl,Lin(:,i),Lup(:,i),[1,1],w_F,opt_alg,stio,wvl);
        %
        out_mat(i,:) = [f_wvl_F(iowvl_760) r_wvl_F(iowvl_760)           ...
            f_wvl_F(iowvl_687) r_wvl_F(iowvl_687) resnorm_F exitflag_F  ...
            output_F.iterations                                         ...
            ];
        
        % spectral output from SpecFit
        outF_SpecFit(:,i) = f_wvl_F;
        outR_SpecFit(:,i) = r_wvl_F;
        
        hbar.iterate(1)
        %
    end
end

close(hbar);

%% compute FLEX metrics
[SIF_R_max,SIF_R_wl,~,SIF_FR_max,SIF_FR_wl,~,SIFint] = sif_parms(owvl,outF_SpecFit); 
    
%% CLOSE PARPOOL
delete(ppool);

%% STOP LOGGING
diary off;
disp('Finished!');
end
