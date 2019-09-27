%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   QEpro_Level_2 - SPECCHIO Database Centric Processing
%   Level 1 (DN) --> Level 2 (Reflectance)
%
%   Code to process all data within a Radiance hierarchy to Reflectance.
%   Currently only supports flame (full spectrum) because QEpro (SIF) requires
%   a different retrieval process.
%
% 
%
function FLOXBOX_Level_2(hierarchy_id, db_connector_id, channelswitched)
%% Function QEpro_and_FLAME_Level_2
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
index = db_connector_id;

user_data.settings.reflectance_hierarchy_level = 1; % controls the level where the radiance folder is created

user_data.switch_channels_for_rox = channelswitched; % set to true if up and downwelling channels were switched during construction

import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
addpath(genpath('FLoX_FLUO_retrieval'));
addpath(genpath('Helper'));

% connect to SPECCHIO
user_data.cf = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list = user_data.cf.getAllServerDescriptors();
user_data.specchio_client = user_data.cf.createClient(user_data.db_descriptor_list.get(index));

%% GET DATA
% get spectra ids for this hierarchy
node = hierarchy_node(hierarchy_id, "", "");
all_ids = user_data.specchio_client.getSpectrumIdsForNode(node);

% restrict to flame and QEpro respectively and order data by 
% spectrum number (this should only ever be a single space ...)
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME] = restrictToSensor(user_data, 'ROX', all_ids);
[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro] = restrictToSensor(user_data, 'FloX', all_ids);




%% PROCESSING
% Process FLAME
 [R, provenance_FLAME_ids] = processFLAME(user_data, ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME);

% prepare target sub hierarchy
% get directory of first spectrum
s = user_data.specchio_client.getSpectrum(provenance_FLAME_ids.get(0), false);  % load first spectrum to get the hierarchy
current_hierarchy_id = s.getHierarchyLevelId();

% move within the hierarchy according to user_data.settings.reflectance_hierarchy_level
for i=1:user_data.settings.reflectance_hierarchy_level
    parent_id = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
    current_hierarchy_id = parent_id;
end

campaign = user_data.specchio_client.getCampaign(s.getCampaignId());
user_data.processed_hierarchy_id_Reflectance = user_data.specchio_client.getSubHierarchyId(campaign, 'Reflectance', parent_id);
% user_data.processed_hierarchy_id_outF_SFM = user_data.specchio_client.getSubHierarchyId(campaign, 'outF_SFM', parent_id);
% user_data.processed_hierarchy_id_outR_SFM = user_data.specchio_client.getSubHierarchyId(campaign, 'outR_SFM', parent_id);
% user_data.processed_hierarchy_id_outF_SpecFit = user_data.specchio_client.getSubHierarchyId(campaign, 'outF_SpecFit', parent_id);
% user_data.processed_hierarchy_id_outR_SpecFit = user_data.specchio_client.getSubHierarchyId(campaign, 'outR_SpecFit', parent_id);

% Process QEpro
% wvl = space_QEpro.getAverageWavelengths();
% L0 = spectra_FLAME';
% L = spectra_QEpro';
[out_arr,outF_SFM,outR_SFM,outF_SpecFit,outR_SpecFit, provenance_QEpro_ids] =  processQEpro(user_data, ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro);

%% INSERT INTO DB
% Insert R
insert_reflectances(R, provenance_FLAME_ids, user_data, 'Reflectance', user_data.processed_hierarchy_id_Reflectance);
insert_reflectances(outF_SpecFit, provenance_QEpro_ids, user_data, 'Reflectance', user_data.processed_hierarchy_id_Reflectance);
% insert_reflectances(outF_SFM, provenance_QEpro_ids, user_data, 'outF_SFM', user_data.processed_hierarchy_id_outF_SFM);
% insert_reflectances(outR_SFM, provenance_QEpro_ids, user_data, 'outR_SFM', user_data.processed_hierarchy_id_outR_SFM );
% insert_reflectances(outF_SpecFit, provenance_QEpro_ids, user_data, 'outF_SpecFit', user_data.processed_hierarchy_id_outF_SpecFit);
% insert_reflectances(outR_SpecFit, provenance_QEpro_ids, user_data, 'outR_SpecFit', user_data.processed_hierarchy_id_outR_SpecFit);
% 

end
