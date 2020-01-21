function ids = insert(user_data)
    prov_ids = updateOrInsertMetaData(user_data);
    ids = updateSpectra(user_data, prov_ids);
    updateNewSpectraMetaData(user_data, ids);
end

%% FUNCTION insertMetaData
function prov_ids = updateOrInsertMetaData(user_data)
import ch.specchio.types.*;
metaDataList = java.util.ArrayList;
prov_ids = java.util.ArrayList(java.util.Arrays.asList(user_data.MetaData.keySet().toArray()));
java.util.Collections.sort(prov_ids);

for i=0:prov_ids.size()-1
    if(user_data.MetaData.get(uint32(prov_ids.get(i))).isEmpty() == false)
        md = Metadata(); % Metadata object, stores several MPs and respective spectrum id
        md.setEntries(user_data.MetaData.get(uint32(prov_ids.get(i))));
        metaDataList.add(md);
    end
end

if(user_data.MetaData.get(uint32(prov_ids.get(i))).isEmpty() == false)
    user_data.starterContext.specchioClient.updateOrInsertEavMetadata(metaDataList, prov_ids, user_data.starterContext.campaignId);
end

end

%% FUNCTION updateSpectra
function ids = updateSpectra(user_data, prov_ids)
%% Radiance:
map = java.util.HashMap();
ids = user_data.starterContext.specchioClient.copySpectra(prov_ids,...
    cell2mat(values(user_data.starterContext.hierarchyIdMap, {user_data.newFolderName})), user_data.starterContext.currentHierarchyId);

% Populate the hashmap
for i=0:prov_ids.size()-1
    % add to hashmap
    map.put(uint32(ids.get(i)), user_data.ValuesToUpdate.get(uint32(prov_ids.get(i))));
end

% Update the vectors:
user_data.starterContext.specchioClient.updateSpectrumVectors(map);
% vectors = spectra;
end

%% FUNCTION updateNewSpectraMetaData
function updateNewSpectraMetaData(user_data, new_ids)
import ch.specchio.types.*
% ################ 
% Other attributes
% ################

% processing level
attribute = user_data.starterContext.specchioClient.getAttributesNameHash().get('Processing Level');

user_data.starterContext.specchioClient.removeEavMetadata(attribute, new_ids, 0);
e = MetaParameter.newInstance(attribute);
e.setValue(user_data.level);
user_data.starterContext.specchioClient.updateEavMetadata(e, new_ids);

% set unit
category_values = user_data.starterContext.specchioClient.getMetadataCategoriesForNameAccess(Spectrum.MEASUREMENT_UNIT);
L_id = category_values.get(user_data.unit);
user_data.starterContext.specchioClient.updateSpectraMetadata(new_ids, 'measurement_unit', L_id);

% processing algorithm
% processing_attribute = user_data.starterContext.specchioClient.getAttributesNameHash().get('Processing Algorithm');
% e = MetaParameter.newInstance(processing_attribute);
% e.setValue(['FluoSpecchio Matlab ' datestr(datetime)]);
% user_data.starterContext.specchioClient.updateEavMetadata(e, new_ids);
end

