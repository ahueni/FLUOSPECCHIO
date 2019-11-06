function user_data = processL0ToL1(user_data, selectedIds)
%% Function Process Level 0 (Raw, DN) to Level 1 (Radiance)
%   INPUT:
%   user_data           : variable containing connection, client, etc.
%   channelswitched     : if channels of sensors were switched during
%                         construction
%   selectedIds         : spectrum ids to process
% 
%   OUTPUT:
%   Stores Radiance [W.m-2.sr-1.nm-1] in SPECCHIO DB
%   
%
%   AUTHOR:
%   Andreas Hueni, RSL, University of Zurich
%   Bastian Buman, RSWS, University of Zurich
% 
%   EDITOR:
%   Bastian Buman, RSWS, University of Zurich
%
%   DATE:
%   12-Sep-2019 V1.0
%   24-Oct-2019 V1.1

%% 
% controls the level where the radiance folder is created in the DB
user_data.settings.radiance_hierarchy_level = 1;

% group by instrument and calibration: use space factory
spaces = user_data.specchio_client.getSpaces(selectedIds, 'Acquisition Time');

% calibrate each space
for i=1:length(spaces)
    calibrate_space(user_data, spaces(i));
end
end

%% Function Calibrate_space()
%   DESCRIPTION:
%   Main function that handles the calibration of the measured signal from
%   DN to Radiance. 
%
%   INPUT:
%   user_data   :   Struct containing switch_channels_for_flox/rox, settings,
%                   clientfactory instance (cf), db_descriptor_list,
%                   specchio client
%   space       :   sensor and instrument space (specchio)
%

function calibrate_space(user_data, space)

user_data.up_coef = [];
user_data.dw_coef = [];

% get instrument and calibration
if(space.get_wvl_of_band(0) < 500)
    user_data.curr_instr_type = 1; % Broadband
else
    user_data.curr_instr_type = 2; % Fluorescence
end

instr_id            = space.getInstrumentId();
CalibrationMetadata = user_data.specchio_client.getInstrumentCalibrationMetadata(instr_id);

for i=1:length(CalibrationMetadata)
    
    cal = CalibrationMetadata(i);
    if(strcmp(cal.getName(), 'up_coef'))
        user_data.up_coef = cal.getFactors();
    end
    if(strcmp(cal.getName(), 'dw_coef'))
        user_data.dw_coef = cal.getFactors();
    end
    
end

% special switches to deal with the problem of switched coefficients
% for upwelling and downwelling channels
if user_data.switch_channels_for_flox == true && user_data.curr_instr_type == 2
    up_coef_tmp = user_data.dw_coef;
    dw_coef_tmp = user_data.up_coef;
    
    user_data.dw_coef = dw_coef_tmp;
    user_data.up_coef = up_coef_tmp;
end

if user_data.switch_channels_for_rox == true && user_data.curr_instr_type == 1
    up_coef_tmp = user_data.dw_coef;
    dw_coef_tmp = user_data.up_coef;
    
    user_data.dw_coef = dw_coef_tmp;
    user_data.up_coef = up_coef_tmp;
end

% load space into memory
try
    user_data.space =  user_data.specchio_client.loadSpace(space);
catch e
    e.message
    if(isa(e,'matlab.exception.JavaException'))
        ex = e.ExceptionObject;
        assert(isjava(ex));
        ex.printStackTrace;
    end
end

% group spectra by spectral number: but as the spectral number can be
% repeated within a day, it is better to group by UTC or Acquisition time
% group_collection = user_data.specchio_client.sortByAttributes(user_data.space.getSpectrumIds, 'Spectrum Number');
group_collection = user_data.specchio_client.sortByAttributes...
    (user_data.space.getSpectrumIds, 'Acquisition Time');

groups           = group_collection.getSpectrum_id_lists;

% prepare target sub hierarchy 'Radiance'
% get directory and campaign of first spectrum, then use this to navigate within
% hierarchy and
s                    = user_data.specchio_client.getSpectrum...
    (user_data.space.getSpectrumIds.get(1), false);  % load first spectrum to get the hierarchy
current_hierarchy_id = s.getHierarchyLevelId(); % essentially the same as hierarchy_id parameter of this matlab function

% move within hierarchy to the level where the new directory is to be created
for i=1:user_data.settings.radiance_hierarchy_level
    parent_id            = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
    current_hierarchy_id = parent_id;
end

campaign                         = user_data.specchio_client.getCampaign...
    (s.getCampaignId());

user_data.processed_hierarchy_id = user_data.specchio_client.getSubHierarchyId...
    (campaign, 'Radiance', parent_id);


% process each group (a group is a set of WR, WR2, WR_DC, VEG_DC and
% VEG spectra)

f = waitbar(0, 'L0 to L1', 'Name', 'L0 Processer'); % progress or waitbar

for i=1:groups.size % was i=1:size-1, check and see
    
    waitbar((i/groups.size), f, 'Please wait...');
    
    [sv_E, sv_L, sv_E2, E_stability, WR_L, WR2_L, VEG_L,...
        provenance_spectrum_ids] = calibrate_group(user_data, groups.get(i-1));
    
    % insert into database
    insertL1(user_data, provenance_spectrum_ids, [sv_E, sv_L, sv_E2],...
        E_stability, [WR_L, VEG_L, WR2_L])
end
waitbar(1, f, 'Processing finished', 'Name', 'L0 Processer');
close(f);
end

%% FUNCTION calibrate_group()
%   INPUT:
%   user_data   :   Struct containing switch_channels_for_flox/rox, settings,
%                   clientfactory instance (cf), db_descriptor_list,
%                   specchio client, up_coef, dw_coef, curr_instr_type,
%                   space, processed_hierarchy_id
%   group       :   a group of spectra matched by acquisition time
%

function [sv_E, sv_L, sv_E2, E_stability, WR_L, WR2_L, VEG_L,...
    provenance_spectrum_ids] = calibrate_group(user_data, group)

    % order this group by file name to always have the same sequence of
    % measured spectra, e.g.:
    % [2-DC_VEG (F060050.CSV), 2-DC_WR (F060050.CSV), 2-VEG (F060050.CSV), 
    % 2-WR (F060050.CSV), 2-WR2 (F060050.CSV)]
    % names = user_data.specchio_client.getMetaparameterValues(ordered_ids, 'File Name')

    spaces = user_data.specchio_client.getSpaces(group.getSpectrumIds, 'File Name');
    space = spaces(1);
    ordered_ids = space.getSpectrumIds();
    
    % Define the indices
    DC_VEG_ind = 0; DC_WR_ind = 1; VEG_ind = 2; WR_ind = 3; WR2_ind = 4;
    
    % get vectors from space
    WR = user_data.space.getVector(ordered_ids.get(WR_ind));
    VEG = user_data.space.getVector(ordered_ids.get(VEG_ind));
    WR2 = user_data.space.getVector(ordered_ids.get(WR2_ind));
    DC_WR = user_data.space.getVector(ordered_ids.get(DC_WR_ind));
    DC_VEG = user_data.space.getVector(ordered_ids.get(DC_VEG_ind));
    
    % store non-DC spectra ids: provenance data (explicit conversion to
    % integer is needed here, otherwise it will be an arraylist of doubles
    % Ids are stored in the following order: WR, VEG, WR2
    provenance_spectrum_ids = java.util.ArrayList;
    provenance_spectrum_ids.add(java.lang.Integer(ordered_ids.get(WR_ind)));
    provenance_spectrum_ids.add(java.lang.Integer(ordered_ids.get(VEG_ind)));
    provenance_spectrum_ids.add(java.lang.Integer(ordered_ids.get(WR2_ind)));
    
    % QC 1: Saturation
    [sv_E, sv_L, sv_E2] = saturation_QC(WR, VEG, WR2, user_data);
        
    % QC 3: Irradiance stability
    E_stability = illumination_QC(WR, WR2, user_data.space);
    
    
    % get integration time of the group
    IT = user_data.specchio_client.getMetaparameterValues(ordered_ids, 'Integration Time');

    % dark current correction and radiometeric calibration
    WR_L  = rad_cal(WR, DC_WR, IT.get(WR_ind)/1000, user_data.dw_coef);
    WR2_L = rad_cal(WR2, DC_WR, IT.get(WR2_ind)/1000, user_data.dw_coef);
    VEG_L = rad_cal(VEG, DC_VEG, IT.get(VEG_ind)/1000, user_data.up_coef);
       
end

%% saturation_QC -- Check the sensor saturation
%   INPUT:
%   WR                          :   Downwelling before 
%   WR2                         :   Downwelling after
%   VEG                         :   Upwelling
%   user_data                   :   Struct containing switch_channels_for_flox/rox, settings,
%                                   clientfactory instance (cf), db_descriptor_list,
%                                   specchio client, up_coef, dw_coef, curr_instr_type,
%                                   space, processed_hierarchy_id.

function [sv_E, sv_L, sv_E2] = saturation_QC(WR, VEG, WR2, user_data)

    if user_data.curr_instr_type == 2
        %FLUO
        max_count = 200000;
    else
        %FULL
        max_count = 54000;
    end
   
    sv_E = sum(WR == max_count);
    sv_L = sum(VEG == max_count);
    sv_E2 = sum(WR2 == max_count);
    
end

%% illumination_QC -- Illumination Condition Stability (E_stability) 
%   DESCRIPTION:
%   evaluates if the illumination condition between the consecutive upward measurements are stable.
%   This is evaluated according to the percentage of error between the 2 upwards record on a 2 nm average.
%   QC3 values vary between 0 and 100.  
%
%   INPUT:
%   WR    : Downwelling before
%   WR2   : Downwelling after
%   space : Data restricted to a certain sensor.
% 

function E_stability = illumination_QC(WR, WR2, space)


    % QC3. Illumination condition stability. (E_stability)
    % QC3 evaluates if the illumination condition between the consecutive upward measurements are stable.
    % This is evaluated according to the percentage of error between the 2 upwards record on a 2 nm average.
    % QC3 values vary between 0 and 100.  
    
    wl1 = 748;
    range = 2;
    
    start_band_ind = space.get_nearest_band(java.lang.Double(wl1));
    end_band_ind = space.get_nearest_band(java.lang.Double(wl1 + range));
    
    E1 = mean(WR(start_band_ind:end_band_ind));
    E2 = mean(WR2(start_band_ind:end_band_ind));
    
    E_stability = (abs(E1-E2))/E1*100;
    
end

%% rad_cal -- Radiometric Calibration
%   DESCRIPTION:
%   converts digital numbers to radiance (i.e. intensities [mW m-2 nm-1]).
%
%   INPUT:
%   DN      :   Digital Number of a certain measurement
%   DN_DC   :   Digital Number of the Dark Current measurement
%   IT      :   Integration Time 
%   gain    :   dw_coef, uw_coef
%
%   OUTPUT:
%   L       :   Radiometrically calibrated radiance values.

function L = rad_cal(DN, DN_DC, IT, gain)

    DN_dc = DN - DN_DC;
    DN_dc_it = DN_dc / IT;
    L = DN_dc_it .* gain;

end

%% CODE CHUNKS DELETE LATER
% 
%     % Plot for the evaluation of assignments:
%     if 1 == 0 
%         figure
%         plot(user_data.space.getAverageWavelengths, WR);
%         hold
%         plot(user_data.space.getAverageWavelengths, VEG);
%         plot(user_data.space.getAverageWavelengths, WR2);
%         plot(user_data.space.getAverageWavelengths, DC_WR);
%         plot(user_data.space.getAverageWavelengths, DC_VEG);
%         
%         legend({'WR','VEG','WR2','DC\_WR','DC\_VEG',});
%     end


% % Plot for the evaluation of the calibration.
%     if 1 == 0
%         
%         figure
%         plot(user_data.space.getAverageWavelengths, WR_L);
%         hold
%         plot(user_data.space.getAverageWavelengths, WR2_L);
%         plot(user_data.space.getAverageWavelengths, VEG_L, 'g');
%         legend({'WR\_L','WR2\_L','VEGL',});
%         
%         % compare gains of up and downwelling channels
%         figure
%         plot(user_data.space.getAverageWavelengths, user_data.dw_coef, 'r');
%         hold
%         plot(user_data.space.getAverageWavelengths, user_data.up_coef, 'g');
%         
%         
%     end