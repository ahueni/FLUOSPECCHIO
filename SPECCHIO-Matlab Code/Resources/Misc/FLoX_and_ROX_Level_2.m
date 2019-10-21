%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   FLoX_Level_2 - SPECCHIO Database Centric Processing
%   Level 1 (DN) --> Level 2 (Reflectance)
%
%   Code to process all data within a Radiance hierarchy to Reflectance.
%   Currently only supports ROX (full spectrum) because FLoX (SIF) requires
%   a different retrieval process.
%
% 
%
function FLOXBOX_Level_2(hierarchy_id
%% Function FLOX_and_ROX_Level_2
%   INPUT:
%   hierarchy_id        : hierarchy_id of the SPECCHIO Radiance hierarchy
%   specchio_pathname   : path to local SPECCHIO Java installation
%   db_connector_id     : index into the list of known database connection (identical to SPECCHIO client app)
% 
%   OUTPUT:
%   Stores Reflectance in SPECCHIO DB
%   
%   MISC:   
%   user_data           : A structure array used to store all specchio-related functionality. 
%   Structure array     : is a data type that groups related data using data containers called fields. Each field 
%                         can contain any type of data. Access data in a field using dot notation of the form structName.fieldName.
%   Specchio API        : https://specchio.ch/javadoc/
%   Java class path     : \MATLAB\R2019a\toolbox\local\classpath.txt
%   SpectralSpace       : A Specchio-Class 
%   getSpaces()          : Space[] getSpaces(java.util.ArrayList<java.lang.Integer> ids, java.lang.String order_by)
%                   
%
%   AUTHORS:
%   Andreas Hueni, RSL, University of Zurich
%   Bastian Buman, RSWS, University of Zurich
%
%   EDITOR:
%   Bastian Buman, RSWS, University of Zurich
%
%   DATE:
%   16-Sep-2019
%


%% CONNECT TO DB
% debugging settings: used if no arguments are supplied to function
%     if nargin() == 0
hierarchy_id = 54; %
index = 2;
%         specchio_pathname = '/Applications/SPECCHIO_G4/SPECCHIO.app/Contents/Java/';
%     end


user_data.settings.reflectance_hierarchy_level = 1; % controls the level where the radiance folder is created

user_data.switch_channels_for_rox = true; % set to true if up and downwelling channels were switched during construction

% this path setting is sufficient on MacOS with Matlab2017b
%      javaaddpath ({
%          [specchio_pathname 'rome-0.8.jar'],...
%          [specchio_pathname 'jettison-1.3.8.jar'],...
%          [specchio_pathname 'specchio-client.jar'], ...
%          [specchio_pathname 'specchio-types.jar']});
%
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
addpath(genpath('FLoX_FLUO_retrieval'));
addpath(genpath('Helper'));
% addpath(genpath('Misc'));

% connect to SPECCHIO
user_data.cf = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list = user_data.cf.getAllServerDescriptors();
user_data.specchio_client = user_data.cf.createClient(user_data.db_descriptor_list.get(index));

%% GET DATA
% get spectra ids for this hierarchy
node = hierarchy_node(hierarchy_id, "", "");
all_ids = user_data.specchio_client.getSpectrumIdsForNode(node);

% restrict to rox and flox respectively and order data by 
% spectrum number (this should only ever be a single space ...)
[ids_ROX, space_ROX, spectra_ROX, filenames_ROX] = restrictToSensor(user_data, 'ROX', all_ids);
[ids_FLOX, space_FLOX, spectra_FLOX, filenames_FLOX] = restrictToSensor(user_data, 'FloX', all_ids);


%% PROCESSING
% Process ROX
[R, provenance_ROX_ids] = processROX(user_data, ids_ROX, space_ROX, spectra_ROX, filenames_ROX);

% prepare target sub hierarchy
% get directory of first spectrum
s = user_data.specchio_client.getSpectrum(provenance_ROX_ids.get(0), false);  % load first spectrum to get the hierarchy
current_hierarchy_id = s.getHierarchyLevelId();

% move within the hierarchy according to user_data.settings.reflectance_hierarchy_level
for i=1:user_data.settings.reflectance_hierarchy_level
    parent_id = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
    current_hierarchy_id = parent_id;
end

campaign = user_data.specchio_client.getCampaign(s.getCampaignId());
user_data.processed_hierarchy_id = user_data.specchio_client.getSubHierarchyId(campaign, 'Reflectance', parent_id);

% Process FLOX
wvl = space_FLOX.getAverageWavelengths();
% L0 = spectra_ROX';
% L = spectra_FLOX';
[out_arr,outF_SFM,outR_SFM,outF_SpecFit,outR_SpecFit, provenance_FLOX_ids] =  processFLOX(user_data, ids_FLOX, space_FLOX, spectra_FLOX, filenames_FLOX);

%% INSERT INTO DB
% Insert R
insert_reflectances(R, provenance_ROX_ids, user_data);
insert_reflectances(outF_SpecFit, provenance_FLOX_ids, user_data);




%%    
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
