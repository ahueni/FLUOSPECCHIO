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
spaces = user_data.specchio_client.getSpaces(selectedIds, 'File Name');

user_data.spaces = {};
user_data.postIds = {};
user_data.postVectors = {};
user_data.fileNames = {};
% calibrate each space
for i=1:length(spaces)
%     calibrate_space(user_data, spaces(i));
    space = user_data.specchio_client.loadSpace(spaces(i));
    [ids, vectors, fnames] = calibrate_space(user_data, space);
    user_data.spaces(i) = {spaces(i)};
    user_data.fileNames(i) = {fnames};
%     user_data.tables(i) = table(postIds', postVectors', filenames');
    user_data.postIds(i) = {ids};
    user_data.postVectors(i) = {vectors};
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

function [ids, vectors, fnames] = calibrate_space(user_data, space)
[user_data.up_coef, user_data.dw_coef, ...
    user_data.curr_instr_type] = getCalCoefs(user_data, space);

wl1 = 748;
range = 2;
    
user_data.start_band_ind = space.get_nearest_band(java.lang.Double(wl1));
user_data.end_band_ind = space.get_nearest_band(java.lang.Double(wl1 + range));

% group spectra
group_collection = user_data.specchio_client.sortByAttributes...
    (space.getSpectrumIds, 'Acquisition Time');

groups           = group_collection.getSpectrum_id_lists;

% prepare target sub hierarchy 'Radiance'
user_data.processed_hierarchy_id = user_data.specchio_client.getSubHierarchyId...
    (user_data.campaign, 'Radiance', user_data.parent_id);


f = waitbar(0, 'L0 to L1', 'Name', 'L0 Processor'); % progress or waitbar
% wvl = space.getAverageWavelengths;
batchUpdate = java.util.ArrayList();
[WR_L_all, VEG_L_all, WR2_L_all] = deal(zeros(double(space.getDimensionality()),groups.size)); 
[sv_E_all, sv_L_all, sv_E2_all, E_stab_all] = deal(zeros(1,groups.size));

% Iterate over the groups
for i=1:groups.size % was i=1:size-1, check and see
    
    waitbar((i/groups.size), f, 'Please wait...');
    
    [sv_E, sv_L, sv_E2, E_stability, WR_L, WR2_L, VEG_L,...
        provenance_spectrum_ids] = calibrate_group(user_data, space, groups.get(i-1));

    for j=0:provenance_spectrum_ids.size()-1
        batchUpdate.add(java.lang.Integer(provenance_spectrum_ids.get(j)));
    end
    
    WR_L_all(:,i)   = WR_L;
    WR2_L_all(:,i)  = WR2_L;
    VEG_L_all(:,i)  = VEG_L;
    sv_E_all(:,i)   = sv_E;
    sv_L_all(:,i)   = sv_L;
    sv_E2_all(:,i)  = sv_E2;
    E_stab_all(:,i) = E_stability;
    
end

metaData = table([sv_E_all, sv_L_all, sv_E2_all], E_stab_all);
metaData.Properties.VariableNames = {'Saturation_Count', 'Irradiance_Instability'};
spectra = [WR_L_all, VEG_L_all, WR2_L_all];
[ids, vectors, fnames] = insertL1(user_data, batchUpdate, metaData, spectra, 1.0, 'Radiance');
waitbar(1, f, 'Processing finished', 'Name', 'L0 Processor');

close(f);
end


%% FUCNTION getCalCoefs()
function [up_coef, dw_coef, curr_instr_type] = getCalCoefs(user_data, space)
up_coef = [];
dw_coef = [];

% get instrument and calibration
if(space.get_wvl_of_band(0) < 500)
    curr_instr_type = 1; % Broadband
else
    curr_instr_type = 2; % Fluorescence
end

instr_id            = space.getInstrumentId();
CalibrationMetadata = user_data.specchio_client.getInstrumentCalibrationMetadata(instr_id);

for i=1:length(CalibrationMetadata)
    
    cal = CalibrationMetadata(i);
    if(strcmp(cal.getName(), 'up_coef'))
        up_coef = cal.getFactors();
    end
    if(strcmp(cal.getName(), 'dw_coef'))
        dw_coef = cal.getFactors();
    end
    
end

% special switches to deal with the problem of switched coefficients
% for upwelling and downwelling channels
if user_data.switch_channels_for_flox == true && curr_instr_type == 2
    up_coef_tmp = dw_coef;
    dw_coef_tmp = up_coef;
    
    dw_coef = dw_coef_tmp;
    up_coef = up_coef_tmp;
end

if user_data.switch_channels_for_rox == true && curr_instr_type == 1
    up_coef_tmp = dw_coef;
    dw_coef_tmp = up_coef;
    
    dw_coef = dw_coef_tmp;
    up_coef = up_coef_tmp;
end
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
    provenance_spectrum_ids] = calibrate_group(user_data, space, group)

    % order this group by file name to always have the same sequence of
    % measured spectra, e.g.:
    % [2-DC_VEG (F060050.CSV), 2-DC_WR (F060050.CSV), 2-VEG (F060050.CSV), 
    % 2-WR (F060050.CSV), 2-WR2 (F060050.CSV)]
%     spaces = user_data.specchio_client.getSpaces(group.getSpectrumIds, 'File Name');
%     space = spaces(1);
%     ordered_ids = space.getSpectrumIds();
%     filenames = user_data.specchio_client.getMetaparameterValues(ordered_ids, 'File Name');
    
    % Define the indices
%     DC_VEG_ind = 0; DC_WR_ind = 1; VEG_ind = 2; WR_ind = 3; WR2_ind = 4;
    WR_ind      = 0; 
    VEG_ind     = 1; 
    WR2_ind     = 2; 
    DC_WR_ind   = 3; 
    DC_VEG_ind  = 4;
    ordered_ids = group.getSpectrumIds();
    
    % get vectors	getSpectrum(int spectrum_id, boolean load_metadata)
    WR      = space.getVector(ordered_ids.get(WR_ind));
    VEG     = space.getVector(ordered_ids.get(VEG_ind));
    WR2     = space.getVector(ordered_ids.get(WR2_ind));
    DC_WR   = space.getVector(ordered_ids.get(DC_WR_ind));
    DC_VEG  = space.getVector(ordered_ids.get(DC_VEG_ind));
    
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
    E_stability = illumination_QC(WR, WR2, user_data);
        
    % get integration time of the group
    IT = user_data.specchio_client.getMetaparameterValues(ordered_ids, 'Integration Time');

    % dark current correction and radiometeric calibration
    WR_L  = rad_cal(WR, DC_WR, IT.get(WR_ind)/1000, user_data.up_coef);
    WR2_L = rad_cal(WR2, DC_WR, IT.get(WR2_ind)/1000, user_data.up_coef);
    VEG_L = rad_cal(VEG, DC_VEG, IT.get(VEG_ind)/1000, user_data.dw_coef);
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

function E_stability = illumination_QC(WR, WR2, user_data)


    % QC3. Illumination condition stability. (E_stability)
    % QC3 evaluates if the illumination condition between the consecutive upward measurements are stable.
    % This is evaluated according to the percentage of error between the 2 upwards record on a 2 nm average.
    % QC3 values vary between 0 and 100.  
    
    E1 = mean(WR(user_data.start_band_ind:user_data.end_band_ind));
    E2 = mean(WR2(user_data.start_band_ind:user_data.end_band_ind));
    
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


%% Compute spectra statistics
function stats = statsonspectra(wl, wlStart, wlEnd, spectra, dim)
% Calculate statistics for the spectra from wStart to wlEnd using the
% mean. Dim specifies row- or column-wise operation.

subset   = find(wl>=wlStart & wl <= wlEnd);
sub_spec = spectra(subset);
stats    = mean(sub_spec, dim);
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



%  STATS ON SPECTRA (R-PACKAGE)   
%     sza = zenith(solar(UTC_time), lon, lat);
%     WR_750  = statsonspectra(wvl, 748, 750, WR_L, 1);
%     WR2_750 = statsonspectra(wvl, 748, 750, WR2_L, 1);
%     VEG_760 = statsonspectra(wvl, 759, 760, VEG_L, 1);
%     VEG_687 = statsonspectra(wvl, 687, 688, VEG_L, 1);
%     VEG_750 = statsonspectra(wvl, 748, 750, VEG_L, 1);
    
    % insert into database
%     insertL1(user_data, provenance_spectrum_ids, [sv_E, sv_L, sv_E2],...
%         E_stability, [WR_L, VEG_L, WR2_L])
    