%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   FLUOSPECCHIO - MAIN PROCESSING SCRIPT
%
%
%   INPUT:
%   fileStoragePath     : Path to the folder(s) containing the .CSV(s)
%   db_connector_id     : Index of the database connection to use
% 
%   OUTPUT:
%   Fully check, filter, process and transfer your FloX data.
%   
%   MISC:   
%   Specchio API        : https://specchio.ch/javadoc/
%   
% 
%   AUTHOR:
%   Bastian Buman, RSWS, University of Zurich
%
%   DATE:
%   12-Sep-2019 V1
%   23-Oct-2019 V2
%% Add Path
addpath(genpath('Resources'));

%% Imports
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.types.*;
import ch.specchio.gui.*;

%% Transfer raw data to DB
% Define connection
connectionID    = 3;
campaignID      = 14;

% Connect
user_data.cf              = SPECCHIOClientFactory.getInstance();
user_data.descriptor_list = user_data.cf.getAllServerDescriptors();
user_data.specchio_client = user_data.cf.createClient(user_data.descriptor_list.get(connectionID));
user_data.campaign        = user_data.specchio_client.getCampaign(campaignID);
% Box setup (Laegeren has switched up-and-downwelling channels):
% Channel switching (true if up and downwelling was switched)
user_data.switch_channels_for_flox = false;
user_data.switch_channels_for_rox  = false;
unpr_hierarchies          = user_data.specchio_client.getUnprocessedHierarchies(num2str(campaignID));
for i=1:1
%% Processing L0 -> L1
% Get Hierarchy of the newly loaded file
% rawDataID   = user_data.specchio_client.getSubHierarchyId(fileName, 1);
% tic
user_data.current_id  = unpr_hierarchies.get(i-1);
user_data.parent_id   = user_data.specchio_client.getHierarchyParentId(unpr_hierarchies.get(i-1));
node        = hierarchy_node(unpr_hierarchies.get(i-1), "", "");
DN_ids      = user_data.specchio_client.getSpectrumIdsForNode(node);
% Visualize Raw
% visualizeLevel(user_data, DN_ids, 0);
% Get spectrum ids:

% Calculate QIs-0

% Write QIs-0 to DB

% Get Radiance
user_data = processL0ToL1(user_data, DN_ids);
% Visualize Radiance
% Get Hierarchy of the Radiance
radianceHierarchy   = user_data.specchio_client.getSubHierarchyId('Radiance', user_data.parent_id);
node                = hierarchy_node(radianceHierarchy, "", "");
Rad_ids             = user_data.specchio_client.getSpectrumIdsForNode(node);
% visualizeLevel(user_data, radianceDataID, 1);
%% Process L1 --> L2

% Calculate the angles Zenit and Azimuth
% user_data.specchio_client.calculateSunAngle(Rad_ids);
% Calculate QIs-1
% E
% Write QIs-1 to DB

% Get Reflection
user_data = processL1ToL2New(user_data);
%     toc
% Visualize L2
% Reflectance
reflectanceHierarchy = user_data.specchio_client.getSubHierarchyId('Reflectance', parent_id);
% True reflectance
tru_ref              = user_data.specchio_client.getSubHierarchyId('True Reflectance', reflectanceHierarchy);
node_tru_ref         = hierarchy_node(tru_ref, "", "");
tru_ref_ids          = user_data.specchio_client.getSpectrumIdsForNode(node_tru_ref);
% visualizeLevel(user_data, tru_ref_ids, 2, true);
% Apparent reflectance
app_ref              = user_data.specchio_client.getSubHierarchyId('Apparent Reflectance', reflectanceHierarchy);
node_app_ref         = hierarchy_node(app_ref, "", "");
app_ref_ids          = user_data.specchio_client.getSpectrumIdsForNode(node_app_ref);
% visualizeLevel(user_data, app_ref_ids, 2, false);
% SIF
sif_hierarchy        = user_data.specchio_client.getSubHierarchyId('SIF', parent_id);
% SFM
sfm_hierarchy        = user_data.specchio_client.getSubHierarchyId('SFM', sif_hierarchy);
node_sfm             = hierarchy_node(sfm_hierarchy, "", "");
sfm_ids              = user_data.specchio_client.getSpectrumIdsForNode(node_sfm);
% visualizeLevel(user_data, sfm_ids, 2, true);
% SpecFit
specfit_hierarchy    = user_data.specchio_client.getSubHierarchyId('SpecFit', sif_hierarchy);
node_specfit         = hierarchy_node(specfit_hierarchy, "", "");
specfit_ids          = user_data.specchio_client.getSpectrumIdsForNode(node_specfit);
% visualizeLevel(user_data, specfit_ids, 2, true);
% Calculate VIs and SIF metrics:
processProperties(user_data, app_ref_ids, specfit_ids);
% toc
end

% Calculate QIs-2

% Write QIs-2 to DB
% bandTimeVis(user_data, 760);