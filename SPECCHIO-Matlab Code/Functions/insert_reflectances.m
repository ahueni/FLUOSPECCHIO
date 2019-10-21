function insert_reflectances(R, provenance_spectrum_ids, user_data, spectrumType, hierarchy_id)

import ch.specchio.types.*;
new_spectrum_ids = java.util.ArrayList();

if 1==0
    figure
    plot(R, 'b')
    ylim([0 1]);
end


for i=0:provenance_spectrum_ids.size()-1
    
    % copy the spectrum to new hierarchy
    new_spectrum_id = user_data.specchio_client.copySpectrum(provenance_spectrum_ids.get(i), hierarchy_id);
    
    % replace spectral data
    user_data.specchio_client.updateSpectrumVector(new_spectrum_id, R(:,i+1));
    new_spectrum_ids.add(java.lang.Integer(new_spectrum_id));
    
    disp(',');
end



% change EAV entry to new Processing Level by removing old and inserting new
attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Level');

user_data.specchio_client.removeEavMetadata(attribute, new_spectrum_ids, 0);


e = MetaParameter.newInstance(attribute);
e.setValue(2.0);
user_data.specchio_client.updateEavMetadata(e, new_spectrum_ids);

% set unit to reflectance

category_values = user_data.specchio_client.getMetadataCategoriesForNameAccess(Spectrum.MEASUREMENT_UNIT);
R_id = category_values.get(spectrumType);
user_data.specchio_client.updateSpectraMetadata(new_spectrum_ids, 'measurement_unit', R_id);


% set Processing Atttributes
%     processing_attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Algorithm');
%
%     e = MetaParameter.newInstance(processing_attribute);
%     e.setValue('Radiance calculation in Matlab');
%     user_data.specchio_client.updateEavMetadata(e, new_spectrum_ids);



end