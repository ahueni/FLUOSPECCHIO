%% @ FUNCTION = insertL1()
% @param 
% @param
% @param
% @param 
% @param
% @param

function [ids, vectors, fnames] = insertL1(user_data, prov_ids, metaData, spectra, level, unit)

fnames = updateMetaData(user_data, prov_ids, metaData, level);

[ids, vectors] = updateSpectra(user_data, prov_ids, spectra);

updateNewSpectraMetaData(user_data, ids, level, unit);
end
%% FUNCTION insertMetaData
% @param prov_ids ids of the the spectra to be updated
% @param metaData matlab table, header = attribute name, value 
% @param level the processing level

function fnames = updateMetaData(user_data, prov_ids, metaData, level)
import ch.specchio.types.*
% ################
% Main attributes
% ################

% file names
fnames = user_data.specchio_client.getMetaparameterValues(prov_ids, 'File Name');

if(level < 2)
    handleMetaData(user_data, prov_ids, metaData, fnames)
else
    insertMetaData(user_data, prov_ids, metaDat);
end

end


%% FUNCTION updateSpectra
function [ids, vectors] = updateSpectra(user_data, prov_ids, spectra)
%% Radiance:
% Attributes:

% ids = java.util.ArrayList();
map = java.util.HashMap();
f = waitbar(0, 'Updating Spectra', 'Name', 'Updating Spectra');
ids = user_data.specchio_client.copySpectra(prov_ids,...
    user_data.processed_hierarchy_id, user_data.current_id);
for i=0:prov_ids.size()-1
    waitbar(((i+1)/prov_ids.size()), f, 'Updating Spectra');
    % copy the spectrum to new hierarchy
%     new_spectrum_id = user_data.specchio_client.copySpectrum...
%         (prov_ids.get(i), user_data.processed_hierarchy_id);
%     ids.add(java.lang.Integer(new_spectrum_id));
    
    % add to hashmap
    map.put(java.lang.Integer(ids.get(i)), spectra(:,i+1));
end
close(f);
% Update the vectors:
user_data.specchio_client.updateSpectrumVectors(map);
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
f = waitbar(0, 'Updating Metadata for all Spectra', 'Name', 'Updating Metadata for all Spectra');
% processing level
attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Level');

user_data.specchio_client.removeEavMetadata(attribute, new_ids, 0);
e = MetaParameter.newInstance(attribute);
e.setValue(level);
user_data.specchio_client.updateEavMetadata(e, new_ids);

waitbar(1/3, f, 'Updating Metadata for all Spectra');

% set unit
category_values = user_data.specchio_client.getMetadataCategoriesForNameAccess(Spectrum.MEASUREMENT_UNIT);
L_id = category_values.get(unit);
user_data.specchio_client.updateSpectraMetadata(new_ids, 'measurement_unit', L_id);

waitbar(2/3, f, 'Updating Metadata for all Spectra');

% processing algorithm
processing_attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Algorithm');
e = MetaParameter.newInstance(processing_attribute);
e.setValue(['FluoSpecchio Matlab ' datestr(datetime)]);
user_data.specchio_client.updateEavMetadata(e, new_ids);

waitbar(1, f, 'Updating Metadata for all Spectra');
close(f);
end


%% BACKUP
% 
% Saturation:
% attribute = user_data.specchio_client.getAttributesNameHash().get('Saturation Count');
% sv = saturation;
% for i=1:length(sv)
%     ids.add(java.lang.Integer(provenance_spectrum_ids.get(i-1)));
%     
%     e = MetaParameter.newInstance(attribute);
%     e.setValue(sv(i));
%     user_data.specchio_client.updateOrInsertEavMetadata(e, ids); % <-- BUG?
%     ids.clear();
% end
% 
% % Stability:
% attribute = user_data.specchio_client.getAttributesNameHash().get('Irradiance Instability');
% 
% ids.add(java.lang.Integer(provenance_spectrum_ids.get(1)));
% 
% e = MetaParameter.newInstance(attribute);
% e.setValue(E_stability);
% user_data.specchio_client.updateOrInsertEavMetadata(e, ids);
% ids.clear();
% 
% % Target Property:
% attribute = user_data.specchio_client.getAttributesNameHash().get('Target/Reference Designator');
% fnames = user_data.specchio_client.getMetaparameterValues(provenance_spectrum_ids, 'File Name');
% 
% for i=0:size(fnames)-1
%     ids.add(java.lang.Integer(provenance_spectrum_ids.get(i)));
%     
%     if(contains(fnames.get(i), "WR"))
%        tr_rf = MetaParameter.newInstance(attribute);
%        tr_rf.setValue(93);
%        user_data.specchio_client.updateOrInsertEavMetadata(tr_rf, ids);
%     else
%        tr_rf = MetaParameter.newInstance(attribute);
%        tr_rf.setValue(92);
%        user_data.specchio_client.updateOrInsertEavMetadata(tr_rf, ids);
%     end
%     ids.clear();
% end
% new_spectrum_ids = java.util.ArrayList();
% 
% for i=0:provenance_spectrum_ids.size()-1
%     % copy the spectrum to new hierarchy
%     new_spectrum_id = user_data.specchio_client.copySpectrum...
%         (provenance_spectrum_ids.get(i), user_data.processed_hierarchy_id);
%     
%     % replace spectral data
%     user_data.specchio_client.updateSpectrumVector(new_spectrum_id, L(:,i+1));
%     new_spectrum_ids.add(java.lang.Integer(new_spectrum_id));
% end