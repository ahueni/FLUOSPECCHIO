%
%   FLoX_Level_1 - SPECCHIO Database Centric Processing
%
%   Code to process all data within a DN hierarchy to Radiances.
%
%   hierarchy_id: hierarchy_id of the SPECCHIO DN hierarchy
%   specchio_pathname: path to local SPECCHIO Java installation
%
%   (c) 2018 ahueni, RSL, University of Zurich
%
%

function FLoX_Level_1(hierarchy_id, specchio_pathname)

    % debugging settings: used if no arguments are supplied to function
    if nargin() == 0
        hierarchy_id = 832 %747 [82600] 
        specchio_pathname = '/Applications/SPECCHIO_G4/SPECCHIO.app/Contents/Java/';
    end


    user_data.switch_channels_for_flox = true; % set to true if up and downwelling channels were switched during construction
    user_data.switch_channels_for_rox = true; % set to true if up and downwelling channels were switched during construction

    user_data.settings.radiance_hierarchy_level = 1; % controls the level where the radiance folder is created


    % this path setting is sufficient on MacOS with Matlab2017b
     javaaddpath ({
         [specchio_pathname 'rome-0.8.jar'],...
         [specchio_pathname 'jettison-1.3.8.jar'],...
         [specchio_pathname 'specchio-client.jar'], ...   
         [specchio_pathname 'specchio-types.jar']});

     import ch.specchio.client.*;
     import ch.specchio.queries.*;
     import ch.specchio.gui.*;
     import ch.specchio.types.*;

     % connect to SPECCHIO 
     user_data.cf = SPECCHIOClientFactory.getInstance();
     user_data.db_descriptor_list = user_data.cf.getAllServerDescriptors();
     index = 0; % index into the list of known database connection, identical to the one seen in the SPECCHIO client app
     user_data.specchio_client = user_data.cf.createClient(user_data.db_descriptor_list.get(index));
     
     % get spectra ids for this hierarchy
     node = hierarchy_node(hierarchy_id, "", "");
     DN_ids = user_data.specchio_client.getSpectrumIdsForNode(node);
     
     % group by instrument and calibration: use space factory
     spaces = user_data.specchio_client.getSpaces(DN_ids, 'Acquisition Time');
     
     % calibrate each space
     for i=1:length(spaces)
        calibrate_space(user_data, spaces(i));
     end
 
end


function calibrate_space(user_data, space)

    user_data.up_coef = [];
    user_data.dw_coef = [];
    
    % get instrument and calibration
    
    if(space.get_wvl_of_band(0) < 500)
        user_data.curr_instr_type = 1; % Broadband
    else
        user_data.curr_instr_type = 2; % Fluorescence
    end
    
    instr_id = space.getInstrumentId();
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
        up_coef = user_data.dw_coef;
        dw_coef = user_data.up_coef;
        
        user_data.dw_coef = dw_coef;
        user_data.up_coef = up_coef;
    end
    
     if user_data.switch_channels_for_rox == true && user_data.curr_instr_type == 1
        up_coef = user_data.dw_coef;
        dw_coef = user_data.up_coef;
        
        user_data.dw_coef = dw_coef;
        user_data.up_coef = up_coef;
    end
   
    

    % load space into memory
    user_data.space =  user_data.specchio_client.loadSpace(space);
    
    % group spectra by spectral number: but as the spectral number can be
    % repeated within a day, it is better to group by UTC or Acquisition time 
    % group_collection = user_data.specchio_client.sortByAttributes(user_data.space.getSpectrumIds, 'Spectrum Number');
    group_collection = user_data.specchio_client.sortByAttributes(user_data.space.getSpectrumIds, 'Acquisition Time');
    
    groups = group_collection.getSpectrum_id_lists;
    
    % prepare target sub hierarchy 'Radiance'
    % get directory and campaign of first spectrum, then use this to navigate within
    % hierarchy and 
    s = user_data.specchio_client.getSpectrum(user_data.space.getSpectrumIds.get(1), false);  % load first spectrum to get the hierarchy
    current_hierarchy_id = s.getHierarchyLevelId(); % essentially the same as hierarchy_id parameter of this matlab function

    % move within hierarchy to the level where the new directory is to be
    % created
    for i=1:user_data.settings.radiance_hierarchy_level
        parent_id = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
        current_hierarchy_id = parent_id;
    end
       
    campaign = user_data.specchio_client.getCampaign(s.getCampaignId());
    
    user_data.processed_hierarchy_id = user_data.specchio_client.getSubHierarchyId(campaign, 'Radiance', parent_id);
    
    
    % process each group (a group is a set of WR, WR2, WR_DC, VEG_DC and
    % VEG spectra)
    for i=1:groups.size - 1
        [WR_L, WR2_L, VEG_L, provenance_spectrum_ids] = calibrate_group(user_data, groups.get(i));
        
        
        % insert into database
        insert_radiances([WR_L, VEG_L, WR2_L], provenance_spectrum_ids, user_data);
        
        disp('.');
        
    end
    

end


function [WR_L, WR2_L, VEG_L, provenance_spectrum_ids] = calibrate_group(user_data, group)

    % order this group by file name to always have the same sequence of
    % measured spectra, e.g.:
    % [2-DC_VEG (F060050.CSV), 2-DC_WR (F060050.CSV), 2-VEG (F060050.CSV), 2-WR (F060050.CSV), 2-WR2 (F060050.CSV)]
    DC_VEG_ind = 0; DC_WR_ind = 1; VEG_ind = 2; WR_ind = 3; WR2_ind = 4;

    spaces = user_data.specchio_client.getSpaces(group.getSpectrumIds, 'File Name');
    space = spaces(1);
    ordered_ids = space.getSpectrumIds();
    names = user_data.specchio_client.getMetaparameterValues(ordered_ids, 'File Name')

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
    
    % QC 1: saturation
    saturation_QC(WR, VEG, WR2, provenance_spectrum_ids, user_data);
    
    % QC 3: Irradiance stability
    illumination_QC(WR, WR2, user_data.space, provenance_spectrum_ids, user_data)
    

    if 1 == 0
        % check that vectors were correctly assigned
        figure
        plot(user_data.space.getAverageWavelengths, WR);
        hold
        plot(user_data.space.getAverageWavelengths, VEG);
        plot(user_data.space.getAverageWavelengths, WR2);
        plot(user_data.space.getAverageWavelengths, DC_WR);
        plot(user_data.space.getAverageWavelengths, DC_VEG);
        
        legend({'WR','VEG','WR2','DC\_WR','DC\_VEG',});
    end
    
    % get integration time of group
    IT = user_data.specchio_client.getMetaparameterValues(ordered_ids, 'Integration Time');

    
    % dark current correction and radiometeric calibration
    WR_L = rad_cal(WR, DC_WR, IT.get(WR_ind)/1000, user_data.dw_coef);
    WR2_L = rad_cal(WR2, DC_WR, IT.get(WR2_ind)/1000, user_data.dw_coef);
    VEG_L = rad_cal(VEG, DC_VEG, IT.get(VEG_ind)/1000, user_data.up_coef);
     
    if 1 == 0
        
        figure
        plot(user_data.space.getAverageWavelengths, WR_L);
        hold
        plot(user_data.space.getAverageWavelengths, WR2_L);
        plot(user_data.space.getAverageWavelengths, VEG_L, 'g');
        legend({'WR\_L','WR2\_L','VEGL',});
        
        % compare gains of up and downwelling channels
        figure
        plot(user_data.space.getAverageWavelengths, user_data.dw_coef, 'r');
        hold
        plot(user_data.space.getAverageWavelengths, user_data.up_coef, 'g');
        
        
    end

end


function L = rad_cal(DN, DN_DC, IT, gain)

    DN_dc = DN - DN_DC;
    DN_dc_it = DN_dc / IT;
    L = DN_dc_it .* gain;

end

function insert_radiances(L, provenance_spectrum_ids, user_data)
    
    import ch.specchio.types.*;
    new_spectrum_ids = java.util.ArrayList();
    
    
    for i=0:provenance_spectrum_ids.size()-1
        
        % copy the spectrum to new hierarchy
        new_spectrum_id = user_data.specchio_client.copySpectrum(provenance_spectrum_ids.get(i), user_data.processed_hierarchy_id);

        % replace spectral data
        user_data.specchio_client.updateSpectrumVector(new_spectrum_id, L(:,i+1));       
        new_spectrum_ids.add(java.lang.Integer(new_spectrum_id));

    end
    

    
    % change EAV entry to new Processing Level by removing old and inserting new
    attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Level');
    
    user_data.specchio_client.removeEavMetadata(attribute, new_spectrum_ids, 0);
    
    
    e = MetaParameter.newInstance(attribute);
    e.setValue(1.0);
    user_data.specchio_client.updateEavMetadata(e, new_spectrum_ids);
    
    % set unit to radiance
    
    category_values = user_data.specchio_client.getMetadataCategoriesForNameAccess(Spectrum.MEASUREMENT_UNIT);
    L_id = category_values.get('Radiance');
    user_data.specchio_client.updateSpectraMetadata(new_spectrum_ids, 'measurement_unit', L_id);
    
    
    % set Processing Atttributes
%     processing_attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Algorithm');
%    
%     e = MetaParameter.newInstance(processing_attribute);
%     e.setValue('Radiance calculation in Matlab');
%     user_data.specchio_client.updateEavMetadata(e, new_spectrum_ids);
 


end



function saturation_QC(WR, VEG, WR2, provenance_spectrum_ids, user_data)

    if user_data.curr_instr_type == 2
        %Fluo Range
        max_count = 200000;
    else
        %Full Range
        max_count = 54000;
    end

    
    sv_E = sum(WR == max_count);
    sv_L = sum(VEG == max_count);
    sv_E2 = sum(WR2 == max_count);
    
    % insert saturation data 
    insert_QC_data(user_data, provenance_spectrum_ids.get(0), java.lang.Integer(sv_E), 'Saturation Count');
    insert_QC_data(user_data, provenance_spectrum_ids.get(1), java.lang.Integer(sv_L), 'Saturation Count');
    insert_QC_data(user_data, provenance_spectrum_ids.get(2), java.lang.Integer(sv_E2), 'Saturation Count');
    
end


function illumination_QC(WR, WR2, space, provenance_spectrum_ids, user_data)


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
    
    % insert E stability as target metadata (the VEG spectrum id is always
    % at position 1 in the list)
    insert_QC_data(user_data, provenance_spectrum_ids.get(1), java.lang.Double(E_stability), 'Irradiance Instability');
    
end

function insert_QC_data(user_data, spectrum_id, value, attribute_name)

    import ch.specchio.types.*;
       
    attribute = user_data.specchio_client.getAttributesNameHash().get(attribute_name);
    
    ids = java.util.ArrayList();
    ids.add(java.lang.Integer(spectrum_id));
   
    e = MetaParameter.newInstance(attribute);
    e.setValue(value);
    user_data.specchio_client.updateOrInsertEavMetadata(e, ids);

end






