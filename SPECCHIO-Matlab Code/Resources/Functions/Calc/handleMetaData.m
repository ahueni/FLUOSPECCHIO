function handleMetaData(user_data, prov_ids, metaData, fnames)
import ch.specchio.types.*;
% Attributes:
saturation = metaData.Saturation_Count;
E_stability = metaData.Irradiance_Instability;
metaDataList = java.util.ArrayList;
f = waitbar(0, 'Updating Metadata', 'Name', 'Please wait...');
count = 1;
for i=0:prov_ids.size()-1
    waitbar(((i+1)/prov_ids.size()), f, 'Please wait...');
    md = Metadata(); 
    mps = java.util.ArrayList;
    satu = user_data.specchio_client.getAttributesNameHash().get('Saturation Count');
    satu = MetaParameter.newInstance(satu);
    stab = user_data.specchio_client.getAttributesNameHash().get('Irradiance Instability');
    stab = MetaParameter.newInstance(stab);
    targ = user_data.specchio_client.getAttributesNameHash().get('Target/Reference Designator');
    targ = MetaParameter.newInstance(targ);
    specId = prov_ids.get(i);
    % Target and Stability:
    if(contains(fnames.get(i), "WR"))
       targ.setValue(93);
       mps.add(targ);
%        user_data.specchio_client.updateOrInsertEavMetadata(targ, specId);
    else
       targ.setValue(92);
       stab.setValue(E_stability(:,count));
       mps.add(targ);
       mps.add(stab);
%        user_data.specchio_client.updateOrInsertEavMetadata(targ, specId)
%        user_data.specchio_client.updateOrInsertEavMetadata(stab, specId)
       count = count + 1;
    end
    
    % Saturation:
    satu.setValue(saturation(:,i+1));
    mps.add(satu);
    md.setEntries(mps);
    metaDataList.add(md);
%     user_data.specchio_client.updateOrInsertEavMetadata(satu, specId);
end
user_data.specchio_client.updateOrInsertEavMetadata(metaDataList, prov_ids, 14);
close(f);
end
