function y = FLOX_SpecFit_6C_funct(x,L0,wvl,sp)


%% --- RHO

sp.weights   = x(3:end);
RHO          = sp.evalAt(wvl);



%% --- FLUORESCENCE

    % -- FAR-RED
    u2       = (wvl - 735)./25;
    FFAR_RED = x(2)./(u2.^2 + 1);

    % -- RED
    u2       = (wvl - 684)./10;
    FRED     = x(1)./(u2.^2 + 1);

    % -- FULL SPECTRUM
    F        = (FFAR_RED + FRED) .* (1-(1-RHO));


    % -- UPWARD RADIANCE
    y        = RHO .* L0 + F;



end



