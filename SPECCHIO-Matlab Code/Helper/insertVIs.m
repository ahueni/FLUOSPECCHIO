function insertVIs(user_data, ids, VIs)
    import ch.specchio.client.*;
    import ch.specchio.types.*;

    new_spectrum_ids = java.util.ArrayList();
    for k=1:height(VIs)
        %      smd = ch.specchio.types.Metadata();^
        new_spectrum_ids.clear();
        new_spectrum_ids.add(java.lang.Integer(ids.get(k-1)));
        for j=1:width(VIs)
%             attribute = user_data.specchio_client.getAttributesNameHash().get(VIs.Properties.VariableNames{j});
            mp = MetaParameter.newInstance(user_data.specchio_client.getAttributesNameHash().get(VIs.Properties.VariableNames{j}));
            user_data.specchio_client.removeEavMetadata(mp);
            val = VIs{k,j};
            mp.setValue(val);
            user_data.specchio_client.updateEavMetadata(mp, new_spectrum_ids);
            %         smd.addEntry(mp);
        end
        %     disp(smd.get_all_metadata_as_text())
    end

     user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'SR680800');
end
