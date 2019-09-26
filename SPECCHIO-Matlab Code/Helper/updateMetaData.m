import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;

ser_data.cf                                                = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list                                = user_data.cf.getAllServerDescriptors();
user_data.specchio_client                                   = user_data.cf.createClient(user_data.db_descriptor_list.get(2));
hierarchy_id                                                = reflectanceDataID;
node                                                        = hierarchy_node(hierarchy_id, "", "");
all_ids                                                     = user_data.specchio_client.getSpectrumIdsForNode(node);
[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', all_ids);
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME]    = restrictToSensor(user_data, 'ROX', all_ids);

new_spectrum_ids = java.util.ArrayList();
for k=1:height(VIs)
%      smd = ch.specchio.types.Metadata();
    new_spectrum_ids.clear();
    new_spectrum_ids.add(java.lang.Integer(ids_QEpro.get(k-1)));
%     for j=2:width(VIs)
        mp = MetaParameter.newInstance(user_data.specchio_client.getAttributesNameHash().get(VIs.Properties.VariableNames{2}));
        mp.setValue(VIs{k,2});
        user_data.specchio_client.updateEavMetadata(mp, new_spectrum_ids)
%         smd.addEntry(mp);
%     end
%     disp(smd.get_all_metadata_as_text())
end

user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'NDVI');