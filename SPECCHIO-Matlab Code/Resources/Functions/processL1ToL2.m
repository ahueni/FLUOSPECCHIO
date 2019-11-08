function user_data = processL1ToL2(user_data, selectedIds)
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
%% GET DATA
% restrict to flame and QEpro respectively and order data by 
% spectrum number (this should only ever be a single space ...)
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME] = restrictToSensor(user_data, 'ROX', selectedIds);
[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro] = restrictToSensor(user_data, 'FloX', selectedIds);


%% PROCESSING
% Process FLAME
[R, provenance_FLAME_ids] = processFULL(user_data, ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME);

% prepare target sub hierarchy
% get directory of first spectrum
s  = user_data.specchio_client.getSpectrum(provenance_FLAME_ids.get(0), false);  % load first spectrum to get the hierarchy
current_hierarchy_id = s.getHierarchyLevelId();

% move within the hierarchy according to user_data.settings.reflectance_hierarchy_level
for i=1:user_data.settings.reflectance_hierarchy_level
    parent_id = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
    current_hierarchy_id = parent_id;
end

% Reflectance Hierarchies:
user_data.processed_hierarchy_id_Reflectance = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Reflectance', parent_id);
user_data.processed_hierarchy_id_ApparentReflectance = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Apparent Reflectance', parent_id);
user_data.processed_hierarchy_id_outR_SpecFit = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'True Reflectance', parent_id);
% Fluorescence Hierarchies:
user_data.processed_hierarchy_id_outF_SpecFit = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'F_SpecFit', parent_id);
user_data.processed_hierarchy_id_outF_SFM = ...
    user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'F_SFM', parent_id);




% Process QEpro
[R_app, out_table, outF_SFM, outR_SFM, outF_SpecFit, outR_SpecFit, provenance_QEpro_ids] =  ...
         processFLUO(ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro);
     
%% TESTING NEW FUNCTIONALITY 

%% INSERT INTO DB
% Insert R and R_app
insertReflectances(R, provenance_FLAME_ids, user_data, 'Reflectance', user_data.processed_hierarchy_id_Reflectance);
insertReflectances(R_app, provenance_QEpro_ids, user_data, 'Apparent Reflectance', user_data.processed_hierarchy_id_ApparentReflectance);
% Insert R_true
insertReflectances(outR_SpecFit, provenance_QEpro_ids, user_data, 'True Reflectance', user_data.processed_hierarchy_id_outR_SpecFit);
% Insert SpecFit
insertReflectances(outF_SpecFit, provenance_QEpro_ids, user_data, 'F_SpecFit', user_data.processed_hierarchy_id_outF_SpecFit);
% Insert SFM
insertReflectances(outF_SFM, provenance_QEpro_ids, user_data, 'F_SFM', user_data.processed_hierarchy_id_outF_SFM);

% Insert SIF metrics
% TBD
end
