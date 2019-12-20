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
%% PREPARING HIERARCHIES:

% Reflectance
user_data.ref_id =  createHierarchy(user_data, 'Reflectance', user_data.parent_id);
% SIF
user_data.SIF_id = createHierarchy(user_data, 'SIF', user_data.parent_id);
% Apparent Reflectance
user_data.refApp_id = createHierarchy(user_data, 'Apparent Reflectance', user_data.ref_id);
% True Reflectance
user_data.refTru_id = createHierarchy(user_data, 'True Reflectance', user_data.ref_id);
% SpecFit
user_data.SpecFit_id = createHierarchy(user_data, 'SpecFit', user_data.SIF_id);
% SFM
user_data.SFM_id = createHierarchy(user_data, 'SFM', user_data.SIF_id);

%% PROCESSING
for i=1:length(user_data.spaces)
    ids = user_data.postIds{i};
    vectors = user_data.postVectors{i};
    space = user_data.spaces{i};
    fnames = user_data.fileNames{i};
    [R, specFit] = processSpace(user_data, ids, vectors, space, fnames);
end

end

%% processSpace()
function [R, specFit] =  processSpace(user_data, ids, vectors, space, fnames)

instrName = convertCharsToStrings(space.getInstrument.getInstrumentName.get_value);
isFLUO = false;
if(contains(instrName, "Fluo"))
   isFLUO = true; 
end

R = zeros(double(space.getDimensionality()), size(ids)/3);
prov_ids = java.util.ArrayList();

L0 = zeros(double(space.getDimensionality()), size(ids)/3);
L  = zeros(double(space.getDimensionality()), size(ids)/3);

wvl = space.getAverageWavelengths();
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
    
    prov_ids.add(java.lang.Integer(ids.get(i+1)));
    
    count = count + 1;

end


if(isFLUO)
    specFit = 'Fluorescence';
    [out_table,outF_SFM,outR_SFM,outF_SpecFit,outR_SpecFit] = ...
    FLOX_SpecFit_master_FLUOSPECCHIO(wvl,L0,L); 
    % SpecFit
    metaData = [out_table{:,15:26}];
    metaData = array2table(metaData);
    metaData.Properties.VariableNames = {out_table.Properties.VariableNames{1,15:26}};
    user_data.processed_hierarchy_id = user_data.SpecFit_id;
    insertL1(user_data, prov_ids, metaData, outR_SpecFit, 2.0, 'Reflectance');
%     SFM
    metaData = out_table{:,[3:7, 10:14]};
    metaData = array2table(metaData);
    metaData.Properties.VariableNames = {out_table.Properties.VariableNames{1,[3:7 10:14]}};
    user_data.processed_hierarchy_id = user_data.SFM_id;
    insertL1(user_data, prov_ids, metaData);
else
    specFit = 'Broadrange';
    metaData = computeVIs(wvl, R);
    user_data.processed_hierarchy_id = user_data.refApp_id;
    insertL1(user_data, prov_ids, metaData, R, 2.0, 'Reflectance');
end
% insertL1(user_data, prov_ids, metaData, spectra, level, unit)

% insertVI(provenanceIds, ids, qualityOrVeg);
end


% %% PROCESSING
% % Process FULL
% [R_FULL, provenance_FLAME_ids] = processFULL(user_data, ids_FULL, space_FULL, spectra_FULL, filenames_FULL);
% 
% 
% % Process FLUO
% [out_table, outF_SFM, outR_SFM, outF_SpecFit, outR_SpecFit, R_FLUO, provenance_QEpro_ids] =  ...
%          processFLUO(user_data, ids_FLUO, space_FLUO, spectra_FLUO, filenames_FLUO);
% 
% user_data.out_table = out_table;

%% INSERT INTO DB
% Insert R_app
% insertReflectances(R_FULL, provenance_FLAME_ids, user_data, 'Reflectance', user_data.processed_hierarchy_id_AppRef);
% insertReflectances(R_FLUO, provenance_QEpro_ids, user_data, 'Reflectance', user_data.processed_hierarchy_id_AppRef);
% % Insert R_true
% insertReflectances(outR_SpecFit, provenance_QEpro_ids, user_data, 'Reflectance', user_data.processed_hierarchy_id_TruRef);
% % Insert SIF_SpecFit
% insertReflectances(outF_SpecFit, provenance_QEpro_ids, user_data, 'SIF', user_data.processed_hierarchy_id_SpecFit);
% % Insert SIF_SFM
% insertReflectances(outF_SFM, provenance_QEpro_ids, user_data, 'SIF', user_data.processed_hierarchy_id_SFM);
