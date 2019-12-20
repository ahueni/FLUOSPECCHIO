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
%             disp([ 'Row number = ' num2str(k) ', VI = ' VIs.Properties.VariableNames{j} ' = ' num2str(val) ' and Spectrum = ' num2str(ids.get(k-1)) ])
            user_data.specchio_client.updateOrInsertEavMetadata(mp, spectrum_ids); 
        end
    end
    close(f);
end