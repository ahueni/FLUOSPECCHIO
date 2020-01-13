function [ids, vectors, fnames] = insertL1(user_data, prov_ids, metaData, spectra, level, unit)
    updateMetaData(user_data, prov_ids, metaData, level);
    [ids, vectors] = updateSpectra(user_data, prov_ids, spectra, unit);
    updateNewSpectraMetaData(user_data, ids, level, unit);
end
%% FUNCTION insertMetaData
% @param prov_ids ids of the the spectra to be updated
% @param metaData matlab table, header = attribute name, value 
% @param level the processing level
function fnames = updateMetaData(user_data, prov_ids, metaData, level)
    import ch.specchio.types.*
    % file names
    fnames = user_data.specchioClient.getMetaparameterValues(prov_ids, 'File Name');
    
    if(level < 2)
        handleMetaData(user_data, prov_ids, metaData, fnames)
    else
        insertMetaData(user_data, prov_ids, metaData);
    end
end

%% FUNCTION updateSpectra
function [ids, vectors] = updateSpectra(user_data, prov_ids, spectra, unit)
    %% Radiance:
    map = java.util.HashMap();
    ids = user_data.specchioClient.copySpectra(prov_ids,...
        cell2mat(values(user_data.hierarchyIdMap, {unit})), user_data.currentHierarchyId);
    % Populate the hashmap
    for i=0:prov_ids.size()-1
        % add to hashmap
        map.put(java.lang.Integer(ids.get(i)), spectra.get(unit).get(i));
    end
    
    % Update the vectors:
    user_data.specchioClient.updateSpectrumVectors(map);
    vectors = spectra;
end

%% FUNCTION updateNewSpectraMetaData
% @param new_ids the ids of the copied spectra
% @param the processing level 
% @param the measurement unit (Radiance, Reflectance)
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

function handleMetaData(user_data, prov_ids, metaData, fnames, campaignId)
import ch.specchio.types.*;

metaDataList = java.util.ArrayList;
% count = 1;

for i=0:prov_ids.size()-1
    md = Metadata(); % Metadata object, stores several MPs and respective spectrum ids
    mps = java.util.ArrayList;
    
    % MANUAL PARAMETERS DUE TO DIFFERENT NATURE:
%     stab = user_data.specchio_client.getAttributesNameHash().get('Irradiance Instability');
%     stab = MetaParameter.newInstance(stab);
    targ = user_data.specchioClient.getAttributesNameHash().get('Target/Reference Designator');
    targ = MetaParameter.newInstance(targ);

    if(contains(fnames.get(i), "WR"))
       targ.setValue(93);
       mps.add(targ);
    else
       targ.setValue(92);
%        stab.setValue(E_stability(:,count));
       mps.add(targ);
%        mps.add(stab);
%        count = count + 1;
    end

%     for j=0:metaData.size()-1
%         meta = metaData.keySet().toArray;
%         meta = meta(i+1);
%         attr = MetaParameter.newInstance(user_data.specchioClient.getAttributesNameHash().get(meta));
%         attr.setValue(metaData.get(meta).get(j));
%         mps.add(attr);
%     end

    md.setEntries(mps);
    metaDataList.add(md);
end
user_data.specchioClient.updateOrInsertEavMetadata(metaDataList, prov_ids, user_data.campaignId);


% for i=0:metaData.size()-1
%     meta = metaData.keySet().toArray;
%     meta = meta(i+1);
%     for j=0:size(prov_ids)-1
%         attr = MetaParameter.newInstance(user_data.specchioClient.getAttributesNameHash().get(meta));
%         attr.setValue(metaData.get(meta).get(j));
%         user_data.specchioClient.updateOrInsertEavMetadata(attr, prov_ids.get(j));
%     end
% end

end

function insertMetaData(user_data, ids, metaData)
import ch.specchio.types.*;
    spectrum_ids = java.util.ArrayList();
    f = waitbar(0, 'Insert Index', 'Name', 'VI/QI/TI insert');
    for k=1:height(metaData)
        waitbar((k/height(metaData)), f, 'Please wait...');
        
        spectrum_ids.clear();
        spectrum_ids.add(java.lang.Integer(ids.get(k-1)));
                
        for j=1:width(metaData)
            
            if(isfinite(metaData{k,j}))
                mp = MetaParameter.newInstance(user_data.specchio_client.getAttributesNameHash().get(metaData.Properties.VariableNames{j}));
                val = metaData{k,j};
                mp.setValue(val);
            else
                mp = MetaParameter.newInstance(user_data.specchio_client.getAttributesNameHash().get('Garbage Flag'));
                val = 1;
                mp.setValue(val);
            end
            user_data.specchio_client.updateOrInsertEavMetadata(mp, spectrum_ids); 
        end
    end
    close(f);
end
