function wvl_definition(rng)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% DEFINITION OF GLOBAL VARIABLE
global wvl_def


switch rng
    case 1
        wvl_def = struct('fld_out_A',759.08,...
            'fld_in_A',760.36,...
            'fld_width_out_A',0.1,...
            'fld_width_in_A',0.1,...
            'fld_out_B',686.3,...
            'fld_in_B',687.0,...
            'fld_width_out_B',0.05,...
            'fld_width_in_B',0.05,...
            'sfm_low_wl_A',759.0,...
            'sfm_up_wl_A',770.0,...
            'sfm_low_wl_B',686.0,...
            'sfm_up_wl_B',691.0,...
            'floris_low',660.0,...
            'floris_up',780.0);
    case 2
        wvl_def = struct('fld_out_A',759.08,...
            'fld_in_A',760.36,...
            'fld_width_out_A',0.1,...
            'fld_width_in_A',0.1,...
            'fld_out_B',686.3,...
            'fld_in_B',687.0,...
            'fld_width_out_B',0.05,...
            'fld_width_in_B',0.05,...
            'sfm_low_wl_A',750.0,...
            'sfm_up_wl_A',770.0,...
            'sfm_low_wl_B',684.0,...
            'sfm_up_wl_B',696.0,...
            'floris_low',660.0,...
            'floris_up',780.0);
    case 3
        wvl_def = struct('fld_out_A',759.08,...
            'fld_in_A',760.36,...
            'fld_width_out_A',0.1,...
            'fld_width_in_A',0.1,...
            'fld_out_B',686.3,...
            'fld_in_B',687.0,...
            'fld_width_out_B',0.05,...
            'fld_width_in_B',0.05,...
            'sfm_low_wl_A',740.0,...
            'sfm_up_wl_A',780.0,...
            'sfm_low_wl_B',677.0,...
            'sfm_up_wl_B',696.0,...
            'floris_low',660.0,...
            'floris_up',780.0);
    case 4
        wvl_def = struct('fld_out_A',759.08,...
            'fld_in_A',760.36,...
            'fld_width_out_A',0.1,...
            'fld_width_in_A',0.1,...
            'fld_out_B',686.3,...
            'fld_in_B',687.0,...
            'fld_width_out_B',0.05,...
            'fld_width_in_B',0.05,...
            'sfm_low_wl_A',750.0,...
            'sfm_up_wl_A',780.0,...
            'sfm_low_wl_B',684.0,...
            'sfm_up_wl_B',696.0,...
            'floris_low',660.0,...
            'floris_up',780.0);
end
end



%FLORIS NBS
%range1
%     'sfm_low_wl_A',759.0,...
%     'sfm_up_wl_A',769.0,...
%     'sfm_low_wl_B',686.0,...
%     'sfm_up_wl_B',691.0,...

%range2
%     'sfm_low_wl_A',750.0,...
%     'sfm_up_wl_A',770.0,...
%     'sfm_low_wl_B',686.0,...
%     'sfm_up_wl_B',697.0,...

%range3
%     'sfm_low_wl_A',740.0,...
%     'sfm_up_wl_A',780.0,...
%     'sfm_low_wl_B',677.0,...
%     'sfm_up_wl_B',697.0,...