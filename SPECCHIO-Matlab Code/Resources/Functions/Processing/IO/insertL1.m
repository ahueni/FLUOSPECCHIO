%% @ FUNCTION = insertL1()
% @param 
% @param
% @param
% @param 
% @param
% @param
function [ids, vectors, fnames] = insertL1(user_data, prov_ids, metaData, spectra, level, unit)
    fnames = updateMetaData(user_data, prov_ids, metaData, level);
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
    %f = waitbar(0, 'Updating Spectra', 'Name', 'Updating Spectra');
    ids = user_data.specchioClient.copySpectra(prov_ids,...
        cell2mat(values(user_data.hierarchyIdMap, {unit})), user_data.currentHierarchyId);
    for i=0:prov_ids.size()-1
        %waitbar(((i+1)/prov_ids.size()), f, 'Updating Spectra');
        % add to hashmap
        map.put(java.lang.Integer(ids.get(i)), spectra.get(unit).get(i));
    end
    %close(f);
    % Update the vectors:
    user_data.specchioClient.updateSpectrumVectors(map);
    vectors = spectra;
end

%% FUNCITON updateNewSpectraMetaData
% @param new_ids the ids of the copied spectra
% @param the processing level 
% @param the measurement unit (Radiance, Reflectance)
function updateNewSpectraMetaData(user_data, new_ids, level, unit)
    import ch.specchio.types.*
    % ################ 
    % Other attributes
    % ################
    %f = waitbar(0, 'Updating Metadata for all Spectra', 'Name', 'Updating Metadata for all Spectra');
    % processing level
    attribute = user_data.specchioClient.getAttributesNameHash().get('Processing Level');

    user_data.specchioClient.removeEavMetadata(attribute, new_ids, 0);
    e = MetaParameter.newInstance(attribute);
    e.setValue(level);
    user_data.specchioClient.updateEavMetadata(e, new_ids);

    %waitbar(1/3, f, 'Updating Metadata for all Spectra');

    % set unit
    category_values = user_data.specchioClient.getMetadataCategoriesForNameAccess(Spectrum.MEASUREMENT_UNIT);
    L_id = category_values.get(unit);
    user_data.specchioClient.updateSpectraMetadata(new_ids, 'measurement_unit', L_id);

    %waitbar(2/3, f, 'Updating Metadata for all Spectra');

    % processing algorithm
    processing_attribute = user_data.specchioClient.getAttributesNameHash().get('Processing Algorithm');
    e = MetaParameter.newInstance(processing_attribute);
    e.setValue(['FluoSpecchio Matlab ' datestr(datetime)]);
    user_data.specchioClient.updateEavMetadata(e, new_ids);

    %waitbar(1, f, 'Updating Metadata for all Spectra');
    %close(f);
end

function handleMetaData(user_data, prov_ids, metaData, fnames)
import ch.specchio.types.*;

%f = waitbar(0, 'Updating Metadata', 'Name', 'Please wait...');
count = 1;
for i=0:metaData.size()-1
    meta = metaData.keySet().toArray;
    meta = meta(i+1);
    for j=0:size(prov_ids)-1
        attr = MetaParameter.newInstance(user_data.specchioClient.getAttributesNameHash().get(meta));
        attr.setValue(metaData.get(meta).get(j));
        user_data.specchioClient.updateOrInsertEavMetadata(attr, prov_ids.get(j));
    end
end
%close(f);
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
