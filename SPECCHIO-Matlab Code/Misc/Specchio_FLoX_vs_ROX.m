%%%%%%%%%%%%%%%%%%%%%
% Bastian Buman
% Testing Matlab - Specchio - FLoX -> Processing
% 10-Sep-2019 14:32:15
% Version 1.0
%%%%%%%%%%%%%%%%%%%%%

%% Connect to DB and get spectra
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
addpath(genpath('FLoX_FLUO_retrieval'));

hierarchy_id = 27; % Current id of flox data in specchio, can change, should be auto-detectable
user_data.switch_channels_for_ROX = true; % set to true if up and downwelling channels were switched during construction

% create client connection
user_data.cf = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list = user_data.cf.getAllServerDescriptors();
index = 2;
user_data.specchio_client = user_data.cf.createClient(user_data.db_descriptor_list.get(index));

% get spectra ids for this hierarchy
node = hierarchy_node(hierarchy_id, "", "");
ids = user_data.specchio_client.getSpectrumIdsForNode(node);

% order data by spectrum number (this should only ever be a single space ...)
spaces = user_data.specchio_client.getSpaces(ids, 'Spectrum Number');
idsROX = spaces(1).getSpectrumIds(); % get ids sorted by  'Spectrum Number'
idsFLOX = spaces(2).getSpectrumIds();
spaceROX = spaces(1);
spaceFLOX = spaces(2);

% load space
spaceROX = user_data.specchio_client.loadSpace(spaceROX);
spectraROX = spaceROX.getVectorsAsArray();
spaceFLOX = user_data.specchio_client.loadSpace(spaceFLOX);
spectraFLOX = spaceFLOX.getVectorsAsArray();

% get file name vector
filenamesROX = user_data.specchio_client.getMetaparameterValues(idsROX, 'File Name');
filenamesFLOX = user_data.specchio_client.getMetaparameterValues(idsFLOX, 'File Name');


%% Spectral Fitting to get SIF and true reflectance
%   INPUT:
%   wvl     - wavelength vector (nX1) in nanometer (nm)
%   L0      - downwelling radiance (can be a column or a nxm array where each column is a measurement) [W.m-2.sr-1.nm-1]
%   L       - upwelling radiance (can be a column or a nxm array where each column is a measurement) [W.m-2.sr-1.nm-1]
%
%   OUTPUT:
%   out_arr_all         - mxi array where i is the number of output metrics of the SFM/SpecFit retrieval
%   outF_SFM_all        - nxm array with spectral fluorescence retrieved in the oxygen bands by SFM
%   outR_SFM_all        - nxm array with spectral true reflectance retrieved in the oxygen bands by SFM
%   outF_SpecFit_all    - nxm array with spectral fluorescence retrieved in the full fitting window by SpecFit
%   outR_SpecFit_all    - nxm array with spectral true reflectance retrieved in the full fitting window by SpecFit


L0 = spectraROX';
L = spectraFLOX';
wvl = spaceROX.getAverageWavelengths();

[out_arr,outF_SFM,outR_SFM,outF_SpecFit,outR_SpecFit] = matlab_SpecFit_oo_FLOX_v4_FLUOSPECCHIO(wvl, L0, L);

%% Plot Spectra

% Get the unit of the spectra:
unit = char(spaceROX.getMeasurementUnit.getUnitName);

% Full plot of ROX and FLOX
figure
% ROX
subplot(221)
plot(wvl, spectraROX)
xlabel('Wavelength [nm]')
ylabel(unit)
ylim([0 0.2])
title('ROX')
clear legend
% for i=1:size(filenamesROX)
%     legend_str{i} = filenamesROX.get(i-1);
% end
% legend (legend_str)

% FLOX
subplot(222)
plot(wvl, spectraFLOX)
xlabel('Wavelength [nm]')
ylabel(unit)
ylim([0 0.2])
title('FLOX')
clear legend
% for i=1:size(filenamesFLOX)
%     legend_str{i} = filenamesFLOX.get(i-1);
% end
% legend (legend_str)


% True Reflectance:
subplot(223)
plot(wvl, outR_SpecFit)
xlabel('Wavelength [nm]')
title('True Reflectance')

% SIF:
subplot(224)
plot(wvl, outF_SpecFit)
xlabel('Wavelength [nm]')
title('SIF')

%% Put True Reflectance and SIF into DB
% prepare target sub hierarchy

% get directory of first spectrum
s = user_data.specchio_client.getSpectrum(idsFLOX.get(0), false);  % load first spectrum to get the hierarchy
current_hierarchy_id = s.getHierarchyLevelId();
user_data.settings.reflectance_hierarchy_level = 1;

% move within the hierarchy according to user_data.settings.reflectance_hierarchy_level
for i=1:user_data.settings.reflectance_hierarchy_level
    parent_id = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
    current_hierarchy_id = parent_id;
end

campaign = user_data.specchio_client.getCampaign(s.getCampaignId());
user_data.processed_hierarchy_id = user_data.specchio_client.getSubHierarchyId(campaign, 'Reflectance', parent_id);


% Insert R
insert_reflectances(outR_SpecFit, idsROX, user_data);
insert_reflectances(outF_SpecFit, idsFLOX, user_data);

%% insert_reflectances -- Insert values into DB
%   INPUT:
%   R                           :
%   provenance_spectrum_ids     :   
%   user_data                   :
function insert_reflectances(R, provenance_spectrum_ids, user_data)
    
    import ch.specchio.types.*;
    new_spectrum_ids = java.util.ArrayList();
    
     if 1==0
         figure
         plot(R, 'b')
         ylim([0 1]);
     end    
    
    
    for i=0:provenance_spectrum_ids.size()-1
        
        % copy the spectrum to new hierarchy
        new_spectrum_id = user_data.specchio_client.copySpectrum(provenance_spectrum_ids.get(i), user_data.processed_hierarchy_id);

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
    R_id = category_values.get('Reflectance');
    user_data.specchio_client.updateSpectraMetadata(new_spectrum_ids, 'measurement_unit', R_id);
    
    
    % set Processing Atttributes
%     processing_attribute = user_data.specchio_client.getAttributesNameHash().get('Processing Algorithm');
%    
%     e = MetaParameter.newInstance(processing_attribute);
%     e.setValue('Radiance calculation in Matlab');
%     user_data.specchio_client.updateEavMetadata(e, new_spectrum_ids);
 


end