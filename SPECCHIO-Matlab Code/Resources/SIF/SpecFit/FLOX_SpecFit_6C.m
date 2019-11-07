%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to retrieve F spectrum from ground-based spectrometer (ie.,FLOX)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% FLOX_SpecFit_6C uses peak function to model red and far-red F spectrum and
% aditionally the overall spectrum behaviour is modified on the base of 1-R


% INPUTS:
%
%   wvl     = wavelength array (suggested spectral window 670-780 nm);
%   L0      = downwelling radiance (mW m-2 sr-1 nm-1)
%   LS      = upward radiance from the canopy (mW m-2 sr-1 nm-1)
%   fsPeak  = first guess for red and far-red fluorescence (not used for the moment...)
%   w       = vector with same size as wvl which contains weights for the
%             optimization algorithm; 
%             no weigths are used for the moment therefore all elements values are = 1
%   alg     = "tr" uses the matlab trust region optimization algorithm
%   stio    = verbosity level of optimization algorithm. It can be 'off', iter etc... according Matlab documentation
%   oWVL    = output wavelength; 
%             Fluorescence/Reflectance spectra are computed according oWVL.
%             For example, to reduce the data volume of results, typically F/R are computed at 1 nm sampling


% OUTPUTS:
%
%   f_wvl   = Fluorescence spectrum (sampled according oWVL)
%   r_wvl   = Reflectance  spectrum (sampled according oWVL)
%   resnorm = norm of residuals



% -------------------------------------------------------------------------
%   Sergio Cogliati, Ph.D
%
%   Remote Sensing of Environmental Dynamics Lab.
%   University of Milano-Bicocca
%   Milano, Italy
%   email: sergio.cogliati@unimib.it
% -------------------------------------------------------------------------



function [x, f_wvl, r_wvl, resnorm, exitflag, output] = FLOX_SpecFit_6C(wvl, L0, LS, fsPeak, w, alg, stio, oWVL)


%% --- INITIALIZATION

    % Apparent Reflectance - ARHO -
    ARHO          = (LS) ./ L0;

    % Excluding O2 absorption bands
    id0           = find(wvl>686 & wvl<692); 
    id1           = find(wvl>758 & wvl<773.0);
    id            = [id0; id1];

    wvlnoABS      = wvl; 
    wvlnoABS(id)  = [];
    ARHOnoABS     = ARHO; 
    ARHOnoABS(id) = [];

    % knots vector for piecewise spline
    knots         = aptknt(wvlnoABS(round(linspace(1,numel(wvlnoABS),20-1+4))),4);

    % piece wise cubic spline
    sp            = fastBSpline.lsqspline(knots,3,wvlnoABS,ARHOnoABS);
    p_r           = sp.weights';




%% --- FIRST GUESS VECTOR

    x0            = [fsPeak(1),fsPeak(2),p_r];
    
    
    
%% --- WEIGHTING SCHEME

    LS_w          = LS .* w;   % with weight



%% --- OPTIMIZATION

    switch alg
    
        case 'tr'
            % -- objective f(x)
            Fw          = @(x, Lin) w.*FLOX_SpecFit_6C_funct(x,L0,wvl,sp);
         
            options     = optimoptions('lsqcurvefit','Display',stio,'MaxIter',6);
        
            [x,resnorm,residual,exitflag,output,lambda,jacobian] = lsqcurvefit(Fw,x0,L0,LS_w,[],[], options);
        
            funcCount   = output.funcCount;
            iterations  = output.iterations;
            
            if exitflag == -2
                resnorm = nan(1);
            end
        
        case 'lm'
            options     = optimset('Display',stio);
            options     = optimset('Algorithm','levenberg-marquardt', 'Display','iter');
            [x,resnorm,residual,exitflag,output] = lsqcurvefit(Fw,x0,Lin,LupW,[],[],options);
        
        otherwise
            disp('check the Optimization algorithm');
        
    end

    

%% --- OUTPUT SPECTRA

    % -- Reflectance 
    sp.weights   = x(3:end);
    RHO          = sp.evalAt(oWVL);
    r_wvl        = RHO;


    % -- Sun-Induced Fluorescence
        % - FAR-RED 
        u2       = (oWVL - 735)./25;
        FFAR_RED = x(2)./(u2.^2 + 1);

        % - RED 
        u2       = (oWVL - 684)./10;
        FRED     = x(1)./(u2.^2 + 1);

        % - FULL SPECTRUM
        f_wvl    = (FFAR_RED + FRED) .* (1-(1-RHO));


    % -- At-sensor modeled radiance
    LSmod        = FLOX_SpecFit_6C_funct(x,L0,wvl,sp);


    % --  RETRIEVAL STATS
    residual     = LSmod - LS;
    rmse         = sqrt(sum((LSmod - LS).^2)/numel(LS));
    rrmse        = sqrt(sum(((LSmod - LS) ./ LS).^2)/numel(LS))*1e2;


end