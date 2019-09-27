function insertVIs(user_data, ids, VIs)
    import ch.specchio.client.*;
    import ch.specchio.types.*;

    new_spectrum_ids = java.util.ArrayList();
    for k=1:height(VIs)
        %      smd = ch.specchio.types.Metadata();^
        new_spectrum_ids.clear();
        new_spectrum_ids.add(java.lang.Integer(ids.get(k-1)));
        for j=1:width(VIs)
            mp = MetaParameter.newInstance(user_data.specchio_client.getAttributesNameHash().get(VIs.Properties.VariableNames{j}));
            val = VIs{k,j};
            if(isfinite(VIs{k,j}))
                mp.setValue(val);
            else
                break
            end
            disp([ 'Row number = ' num2str(k) ', VI = ' VIs.Properties.VariableNames{j} ' = ' num2str(val) ' and Spectrum = ' num2str(ids.get(k-1)) ])
            user_data.specchio_client.updateOrInsertEavMetadata(mp, new_spectrum_ids);           
        end
        %     disp(smd.get_all_metadata_as_text())
    end

     user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'NDVI');
end