function insertL1(user_data, provenance_spectrum_ids, saturation, E_stability, L)
import ch.specchio.types.*
% Saturation:
attribute = user_data.specchio_client.getAttributesNameHash().get('Saturation Count');
sv = saturation;

for i=1:length(sv)
    ids = java.util.ArrayList();
    ids.add(java.lang.Integer(provenance_spectrum_ids.get(i-1)));
    
    e = MetaParameter.newInstance(attribute);
    e.setValue(sv(i));
    user_data.specchio_client.updateOrInsertEavMetadata(e, ids); % <-- BUG?
end

% Stability:
attribute = user_data.specchio_client.getAttributesNameHash().get('Irradiance Instability');
ids = java.util.ArrayList();
ids.add(java.lang.Integer(provenance_spectrum_ids.get(1)));

e = MetaParameter.newInstance(attribute);
e.setValue(E_stability);
user_data.specchio_client.updateOrInsertEavMetadata(e, ids);

% Target Property:
attribute = user_data.specchio_client.getAttributesNameHash().get('Target/Reference Designator');
fnames = user_data.specchio_client.getMetaparameterValues(provenance_spectrum_ids, 'File Name');

for i=0:size(fnames)-1
    ids = java.util.ArrayList();
    ids.add(java.lang.Integer(provenance_spectrum_ids.get(i)));
    
    if(contains(fnames.get(i), "WR"))
       tr_rf = MetaParameter.newInstance(attribute);
       tr_rf.setValue(93);
       user_data.specchio_client.updateOrInsertEavMetadata(tr_rf, ids);
    else
       tr_rf = MetaParameter.newInstance(attribute);
       tr_rf.setValue(92);
       user_data.specchio_client.updateOrInsertEavMetadata(tr_rf, ids);
    end
end

%% Radiance:
new_spectrum_ids = java.util.ArrayList();

for i=0:provenance_spectrum_ids.size()-1
    % copy the spectrum to new hierarchy
    new_spectrum_id = user_data.specchio_client.copySpectrum...
        (provenance_spectrum_ids.get(i), user_data.processed_hierarchy_id);
    
    % replace spectral data
    user_data.specchio_client.updateSpectrumVector(new_spectrum_id, L(:,i+1));
    new_spectrum_ids.add(java.lang.Integer(new_spectrum_id));
end

% change EAV entry to new Processing Level by removing old and inserting new
attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Level');

user_data.specchio_client.removeEavMetadata(attribute, new_spectrum_ids, 0);
e = MetaParameter.newInstance(attribute);
e.setValue(1.0);
user_data.specchio_client.updateEavMetadata(e, new_spectrum_ids);

% set unit to radiance
category_values = user_data.specchio_client.getMetadataCategoriesForNameAccess(Spectrum.MEASUREMENT_UNIT);
L_id = category_values.get('Radiance');
user_data.specchio_client.updateSpectraMetadata(new_spectrum_ids, 'measurement_unit', L_id);


% set Processing Atttributes
processing_attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Algorithm');
e = MetaParameter.newInstance(processing_attribute);
e.setValue('FluoSpecchio');
user_data.specchio_client.updateEavMetadata(e, new_spectrum_ids);

end