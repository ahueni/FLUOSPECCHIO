function [ids, vectors] = insertL1(user_data, provenance_spectrum_ids, saturation, E_stability, L)
import ch.specchio.types.*
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

%% Radiance:
% Attributes:
satu = user_data.specchio_client.getAttributesNameHash().get('Saturation Count');
satu = MetaParameter.newInstance(satu);
stab = user_data.specchio_client.getAttributesNameHash().get('Irradiance Instability');
stab = MetaParameter.newInstance(stab);
targ = user_data.specchio_client.getAttributesNameHash().get('Target/Reference Designator');
targ = MetaParameter.newInstance(targ);

ids = java.util.ArrayList();
map = java.util.HashMap();
fnames = user_data.specchio_client.getMetaparameterValues(provenance_spectrum_ids, 'File Name');
count = 1;
for i=0:provenance_spectrum_ids.size()-1
    specId = provenance_spectrum_ids.get(i);
    % Target and Stability:
    if(contains(fnames.get(i), "WR"))
       targ.setValue(93);
       user_data.specchio_client.updateOrInsertEavMetadata(targ, specId);
    else
       targ.setValue(92);
       stab.setValue(E_stability(:,count));
       user_data.specchio_client.updateOrInsertEavMetadata(targ, specId);
       user_data.specchio_client.updateOrInsertEavMetadata(stab, specId);
       count = count + 1;
    end
    
    % Saturation:
    satu.setValue(saturation(:,i+1));
    user_data.specchio_client.updateOrInsertEavMetadata(satu, specId);
    
    % copy the spectrum to new hierarchy
    new_spectrum_id = user_data.specchio_client.copySpectrum...
        (provenance_spectrum_ids.get(i), user_data.processed_hierarchy_id);
    ids.add(java.lang.Integer(new_spectrum_id));
    
    % add to hashmap
    map.put(java.lang.Integer(ids.get(i)), L(:,i+1));
end
% Update the vectors:
user_data.specchio_client.updateSpectrumVectors(map);

% change EAV entry to new Processing Level by removing old and inserting new
attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Level');

user_data.specchio_client.removeEavMetadata(attribute, ids, 0);
e = MetaParameter.newInstance(attribute);
e.setValue(1.0);
user_data.specchio_client.updateEavMetadata(e, ids);

% set unit to radiance
category_values = user_data.specchio_client.getMetadataCategoriesForNameAccess(Spectrum.MEASUREMENT_UNIT);
L_id = category_values.get('Radiance');
user_data.specchio_client.updateSpectraMetadata(ids, 'measurement_unit', L_id);

% 
% set Processing Atttributes
processing_attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Algorithm');
e = MetaParameter.newInstance(processing_attribute);
e.setValue('FluoSpecchio');
user_data.specchio_client.updateEavMetadata(e, ids);
vectors = L;
end


%% BACKUP
% 
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