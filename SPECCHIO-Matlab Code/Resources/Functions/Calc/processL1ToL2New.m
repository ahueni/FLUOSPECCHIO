function user_data = processL1ToL2New(user_data, selectedIds)
%% Function Process Level 1 (Radiance) to Level 2 (Reflectance)
%   INPUT:
%   user_data           : variable containing connection, client, etc.
%   channelswitched     : if channels of sensors were switched during
%                         construction
%   selectedIds         : spectrum ids to process
% 
%   OUTPUT:
%   Stores Reflectance in SPECCHIO DB
%              
%
%   AUTHORS:
%   Andreas Hueni, RSL, University of Zurich
%   Bastian Buman, RSWS, University of Zurich
%
%   EDITOR:
%   Bastian Buman, RSWS, University of Zurich
%
%   DATE:
%   16-Sep-2019 V1.0
%   24-Oct-2019 V1.1
%%
user_data.settings.reflectance_hierarchy_level = 1;

% spaces = user_data.specchio_client.getSpaces(user_data.ids, true, false, 'File Name');

for i=1:length(user_data.ids)
    processSpace(user_data.ids(:,i), user_data.vectors(:,i), user_data.spaces(i));
end

%% PROCESSING
% Process FULL
[R_FULL, provenance_FLAME_ids] = processFULL(user_data, ids_FULL, space_FULL, spectra_FULL, filenames_FULL);


% Process FLUO
[out_table, outF_SFM, outR_SFM, outF_SpecFit, outR_SpecFit, R_FLUO, provenance_QEpro_ids] =  ...
         processFLUO(user_data, ids_FLUO, space_FLUO, spectra_FLUO, filenames_FLUO);

user_data.out_table = out_table;
     
% prepare target sub hierarchy
% get directory of first spectrum
s  = user_data.specchio_client.getSpectrum(provenance_FLAME_ids.get(0), false);  % load first spectrum to get the hierarchy
current_hierarchy_id = s.getHierarchyLevelId();

% move within the hierarchy according to user_data.settings.reflectance_hierarchy_level
for i=1:user_data.settings.reflectance_hierarchy_level
    parent_id = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
    current_hierarchy_id = parent_id;
end

% Prepare Reflectance Hierarchy:
user_data.processed_hierarchy_id_Reflectance = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Reflectance', parent_id);

% Prepare SIF Hierarchy:
user_data.processed_hierarchy_id_SIF = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'SIF', parent_id);

% Prepare Reflectance Subhierarchies:
user_data.processed_hierarchy_id_AppRef = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign,...
    'Apparent Reflectance', user_data.processed_hierarchy_id_Reflectance);
user_data.processed_hierarchy_id_TruRef = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign,...
    'True Reflectance', user_data.processed_hierarchy_id_Reflectance);

% Prepare SIF Subhierarchies:
user_data.processed_hierarchy_id_SpecFit = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign,...
    'SpecFit', user_data.processed_hierarchy_id_SIF);

user_data.processed_hierarchy_id_SFM = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign,...
    'SFM', user_data.processed_hierarchy_id_SIF);


%% TESTING NEW FUNCTIONALITY 

%% INSERT INTO DB
% Insert R_app
insertReflectances(R_FULL, provenance_FLAME_ids, user_data, 'Reflectance', user_data.processed_hierarchy_id_AppRef);
insertReflectances(R_FLUO, provenance_QEpro_ids, user_data, 'Reflectance', user_data.processed_hierarchy_id_AppRef);
% Insert R_true
insertReflectances(outR_SpecFit, provenance_QEpro_ids, user_data, 'Reflectance', user_data.processed_hierarchy_id_TruRef);
% Insert SIF_SpecFit
insertReflectances(outF_SpecFit, provenance_QEpro_ids, user_data, 'SIF', user_data.processed_hierarchy_id_SpecFit);
% Insert SIF_SFM
insertReflectances(outF_SFM, provenance_QEpro_ids, user_data, 'SIF', user_data.processed_hierarchy_id_SFM);

% Insert SIF metrics
% TBD


%% Visual Analysis
% wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
% wvl_FLAME                                                   = space_FLAME.getAverageWavelengths();

end

%% processSpace()
function processSpace(ids, vectors, space)

instrName = convertCharsToStrings(space.getInstrument.getInstrumentName.get_value);
isFLUO = false;
if(contains(instrName, "Fluo"))
   isFLUO = true; 
end


%% Calculation
for i=0:groups.size-1
   
    WR_indices = false(ids.size, 1);
    TGT_indices = WR_indices;
    WR_indices(group_start+1:group_start+1+2) = WR_pos;
    TGT_indices(group_start+1:group_start+1+2) = ~WR_pos;
    
    % calculate average WR and TGT, but only if there is more than 1
    % spectrum
    WR_arr = spectra(WR_indices, :);
%     WR_avg = WR_arr(1,:);
    
    if(sum(WR_indices) > 1)
        WR_avg = mean(WR_arr);
    else
        WR_avg = WR_arr;
    end
    
    % calculate average TGT (just in case the channels were switched)
    TGT_arr = spectra(TGT_indices, :);
    
    if(sum(TGT_indices) > 1)
        TGT_avg = mean(TGT_arr);
    else
        TGT_avg = TGT_arr;
    end
   
    
    % calculate R
    
    if user_data.switch_channels_for_rox == false
        R(:,i+1) = (TGT_avg ./ WR_avg);
    else
        R(:,i+1) = (WR_avg ./ TGT_avg);
    end
    
    if 1==0
        figure
        plot(space.getAverageWavelengths(), R, 'b')
    end
    
    
    % compile provenance_spectrum_ids: get target id by using
    % TGT_indices logical vector
    provenance_spectrum_ids.add(java.lang.Integer(ids.get(find(TGT_indices, 1) - 1)));
    
end
end