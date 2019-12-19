function user_data = processL1ToL2New(user_data)
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

for i=1:length(user_data.spaces)
    ids = user_data.postIds{i};
    vectors = user_data.postVectors{i};
    space = user_data.spaces{i};
    fnames = user_data.fileNames{i};
    [R, specFit] = processSpace(user_data, ids, vectors, space, fnames);
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
function [R, specFit] =  processSpace(user_data, ids, vectors, space, fnames)

instrName = convertCharsToStrings(space.getInstrument.getInstrumentName.get_value);
isFLUO = false;
if(contains(instrName, "Fluo"))
   isFLUO = true; 
end

R = zeros(double(space.getDimensionality()), size(ids)/3);
provenanceIds = java.util.ArrayList();

L0 = zeros(double(space.getDimensionality()), size(ids)/3);
L  = zeros(double(space.getDimensionality()), size(ids)/3);

% filenames = user_data.specchio_client.getMetaparameterValues(ids, 'File Name');
count = 1;
%% Calculation initVal:step:endVal
for i=1:3:size(ids)
    VEG  = vectors(:,i+1);
    WR_mean = mean(vectors(:, [i,i+2]),2);
    if(isFLUO)
       L0(:,count) = WR_mean;
       L(:,count)  = VEG;
    end
    R(:,count) = (VEG ./ WR_mean);
    
    provenanceIds.add(java.lang.Integer(ids.get(i+1)));
    
    count = count + 1;

%     WR_1 = vectors(i);
%     WR_2 = vectors(i+2);

end
wvl = space.getAverageWavelengths();
if(isFLUO)
    specFit = ...
    FLOX_SpecFit_master_FLUOSPECCHIO(wvl,L0,L); 
    out_table = specFit.out_table;
    qualityOrVeg = table(out_table.f_int, out_table.f_max_R, out_table.f_max_FR) ;
    qualityOrVeg.Properties.VariableNames = {'Total_SIF', 'SIF_R_max','SIF_FR_max'};
else
    specFit = 'Broadrange';
    qualityOrVeg = computeVIs(wvl, R);
end

insertL2(user_data);
insertVI(provenanceIds, ids, qualityOrVeg);
end