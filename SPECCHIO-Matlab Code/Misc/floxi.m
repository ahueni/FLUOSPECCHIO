%  FLOX L1
function floxi(connectionID, channelswitched, hierarchyID)
%% Start connection
% Import specchio functionality:
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
import ch.specchio.*;

% Connect to SPECCHIO
user_data.cf                    = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list    = user_data.cf.getAllServerDescriptors();
user_data.specchio_client       = user_data.cf.createClient(user_data.db_descriptor_list.get(connectionID));

%% Get IDS and also prepare the folder for the processed data
% Have a look at the selected data
node    = hierarchy_node(hierarchyID, "", "");
ids     = user_data.specchio_client.getSpectrumIdsForNode(node);

% Channel switching (true if up and downwelling was switched  --> LAEGEREN)
user_data.switch_channels_for_flox  = channelswitched;
user_data.switch_channels_for_rox   = channelswitched;

% controls the level where the radiance folder is created in the DB
user_data.settings.radiance_hierarchy_level = 1;

% Prepare the folder to store the data
% load first spectrum to get the hierarchy
spaces                  = user_data.specchio_client.getSpaces(ids, 'Acquisition Time');
s                       = user_data.specchio_client.getSpectrum(spaces(1).getSpectrumIds.get(1), false); 
current_hierarchy_id    = s.getHierarchyLevelId(); 

% move within hierarchy to the level where the new directory is to be
% created
for i=1:user_data.settings.radiance_hierarchy_level
    parent_id               = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
    current_hierarchy_id    = parent_id;
end

% Get the campaign 
campaign                            = user_data.specchio_client.getCampaign(s.getCampaignId());
% Creates the folder if not already there
user_data.processed_hierarchy_id    = user_data.specchio_client.getSubHierarchyId(campaign, 'Radiance', parent_id);

%% Calibration

% Radiance      = ((DN-DC_DN) / IT) * GAIN;     where GAIN = up/down coef
% Illumination  = (abs(E1-E2))/E1*100;          the percentage of error between the 2 upwards record on a 2 nm average.
% Saturation    = sum(WR == max_count);         Sum over a certain threshold  
for i=1:size(spaces)
    sp = spaces(i);
    
    user_data.up_coef = [];
    user_data.dw_coef = [];
    
    % get instrument and calibration
    if(sp.get_wvl_of_band(0) < 500)
        user_data.curr_instr_type = 1; % Broadband
    else
        user_data.curr_instr_type = 2; % Fluorescence
    end
    
    instr_id = sp.getInstrumentId();
    CalibrationMetadata = user_data.specchio_client.getInstrumentCalibrationMetadata(instr_id);

    for j=1:length(CalibrationMetadata)
        
        cal = CalibrationMetadata(j);
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
    try
        user_data.sp =  user_data.specchio_client.loadSpace(sp);
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
    group_collection    = user_data.specchio_client.sortByAttributes(sp.getSpectrumIds, 'Acquisition Time');
    groups              = group_collection.getSpectrum_id_lists;
    
    
    
%     wvl  = sp.getAverageWavelengths();
    % CHECK:
    % user_data.specchio_client.getMetaparameterValues(groups.get(0).getSpectrumIds, 'File Name'):
    
%     not always true --> ordered ids required
    orderedSpace    = user_data.specchio_client.getSpaces(sp.getSpectrumIds, 'File Name');
    orderedSpace    = orderedSpace(1);
    ordered_ids     = orderedSpace.getSpectrumIds();
    
    group_collection    = user_data.specchio_client.sortByAttributes(ordered_ids, 'Acquisition Time');
    groups              = group_collection.getSpectrum_id_lists;
    
    [WR, VEG, WR2, DC_WR, DC_VEG] =  deal(zeros(size(user_data.sp.getVector(groups.get(0).getSpectrumIds.get(0)),1), size(groups)));
    % Integration time is required for the calibration
    IT = zeros(size(groups),size(groups.get(0)));
         
    DC_VEG_ind = 0; 
    DC_WR_ind = 1; 
    VEG_ind = 2; 
    WR_ind = 3; 
    WR2_ind = 4;
    
    provenance_spectrum_ids = java.util.ArrayList;
    for n=1:size(groups)
         disp(user_data.specchio_client.getMetaparameterValues(groups.get(n-1).getSpectrumIds, 'File Name'));
    end
        DC_VEG(:,n)     = user_data.sp.getVector(groups.get(n-1).getSpectrumIds.get(DC_VEG_ind));
        DC_WR(:,n)      = user_data.sp.getVector(groups.get(n-1).getSpectrumIds.get(DC_WR_ind));
        VEG(:,n)        = user_data.sp.getVector(groups.get(n-1).getSpectrumIds.get(VEG_ind));
        WR(:,n)         = user_data.sp.getVector(groups.get(n-1).getSpectrumIds.get(WR_ind));
        WR2(:,n)        = user_data.sp.getVector(groups.get(n-1).getSpectrumIds.get(WR2_ind)); 
        
%         Provenance Spectrum IDS required for updating EAV Metadata
        provenance_spectrum_ids.add(java.lang.Integer(groups.get(n-1).getSpectrumIds.get(VEG_ind)));
        provenance_spectrum_ids.add(java.lang.Integer(groups.get(n-1).getSpectrumIds.get(WR_ind)));
        provenance_spectrum_ids.add(java.lang.Integer(groups.get(n-1).getSpectrumIds.get(WR2_ind)));
%         get integration time of group
        IT(n,1)         = user_data.specchio_client.getMetaparameterValues(groups.get(n-1).getSpectrumIds, 'Integration Time');
    end
    
%     Radiance      = ((DN-DC_DN) / IT) * GAIN;     where GAIN = up/down coef
    
    
    
end



    

