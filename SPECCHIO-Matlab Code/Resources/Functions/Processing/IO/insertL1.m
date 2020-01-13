function ids = insertL1(user_data, level, unit)
    prov_ids = updateOrInsertMetaData(user_data);
    ids = updateSpectra(user_data, prov_ids, unit);
    updateNewSpectraMetaData(user_data, ids, level, unit);
end

%% FUNCTION insertMetaData
function prov_ids = updateOrInsertMetaData(user_data)
import ch.specchio.types.*;
metaDataList = java.util.ArrayList;
prov_ids = java.util.ArrayList(java.util.Arrays.asList(user_data.currentMetaData.keySet().toArray()));

for i=0:prov_ids.size()-1
    md = Metadata(); % Metadata object, stores several MPs and respective spectrum id
    md.setEntries(user_data.currentMetaData.get(java.lang.Integer(prov_ids.get(i))));
    metaDataList.add(md);
end

user_data.specchioClient.updateOrInsertEavMetadata(metaDataList, prov_ids, user_data.campaignId);

end

%% FUNCTION updateSpectra
function ids = updateSpectra(user_data, prov_ids, unit)
%% Radiance:
map = java.util.HashMap();
ids = user_data.specchioClient.copySpectra(prov_ids,...
    cell2mat(values(user_data.hierarchyIdMap, {unit})), user_data.currentHierarchyId);

% Populate the hashmap
for i=0:prov_ids.size()-1
    % add to hashmap
    map.put(java.lang.Integer(ids.get(i)), user_data.currentValuesToUpdate.get(java.lang.Integer(prov_ids.get(i))));
end

% Update the vectors:
user_data.specchioClient.updateSpectrumVectors(map);
% vectors = spectra;
end

%% FUNCTION updateNewSpectraMetaData
function updateNewSpectraMetaData(user_data, new_ids, level, unit)
import ch.specchio.types.*
% ################ 
% Other attributes
% ################

% processing level
attribute = user_data.specchioClient.getAttributesNameHash().get('Processing Level');

user_data.specchioClient.removeEavMetadata(attribute, new_ids, 0);
e = MetaParameter.newInstance(attribute);
e.setValue(level);
user_data.specchioClient.updateEavMetadata(e, new_ids);

% set unit
category_values = user_data.specchioClient.getMetadataCategoriesForNameAccess(Spectrum.MEASUREMENT_UNIT);
L_id = category_values.get(unit);
user_data.specchioClient.updateSpectraMetadata(new_ids, 'measurement_unit', L_id);

% processing algorithm
processing_attribute = user_data.specchioClient.getAttributesNameHash().get('Processing Algorithm');
e = MetaParameter.newInstance(processing_attribute);
e.setValue(['FluoSpecchio Matlab ' datestr(datetime)]);
user_data.specchioClient.updateEavMetadata(e, new_ids);
end

