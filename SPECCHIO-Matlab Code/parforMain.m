%% JDBC MYSQL 
% configureJDBCDataSource
tic
datasource = "SpecchioDB";
username = "sdb_admin";
password = "specchio";
conn = database(datasource,username,password);
tablename = "unprocessed_hierarchies";
data = sqlread(conn,tablename);

parfor i=1:4
%% Update only certain stuff 
addpath(genpath('Resources'));

%% Imports
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.types.*;
import ch.specchio.gui.*;
%% Connection
connectionID              = 3;
user_data.cf              = SPECCHIOClientFactory.getInstance();
user_data.descriptor_list = user_data.cf.getAllServerDescriptors();
user_data.specchio_client = user_data.cf.createClient(user_data.descriptor_list.get(connectionID));

% Box setup (Laegeren has switched up-and-downwelling channels):
% Channel switching (true if up and downwelling was switched)
user_data.switch_channels_for_flox = false;
user_data.switch_channels_for_rox  = false;

%% Processing L0 -> L1
% Get Hierarchy of the newly loaded file
% rawDataID   = user_data.specchio_client.getSubHierarchyId(fileName, 1);
node          = hierarchy_node(data{i,1}, "", "");
DN_ids        = c.specchio_client.getSpectrumIdsForNode(node);
% Visualize Raw
% visualizeLevel(user_data, DN_ids, 0);
% Get spectrum ids:

% Calculate QIs-0

% Write QIs-0 to DB

% Get Radiance
user_data = processL0ToL1(c, DN_ids);
% Visualize Radiance
% Get Hierarchy of the Radiance
radianceHierarchy   = user_data.specchio_client.getSubHierarchyId(campaign, 'Radiance', rawDataID);
node                = hierarchy_node(radianceHierarchy, "", "");
Rad_ids             = user_data.specchio_client.getSpectrumIdsForNode(node);
% visualizeLevel(user_data, radianceDataID, 1);
%% Process L1 --> L2

% Calculate QIs-1
% E
% Write QIs-1 to DB

% Get Reflection
user_data = processL1ToL2(c, Rad_ids);
%     toc
% Visualize L2
% Reflectance
reflectanceHierarchy = c.specchio_client.getSubHierarchyId(user_data.campaign, 'Reflectance', rawDataID);
% True reflectance
tru_ref              = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'True Reflectance', reflectanceHierarchy);
node_tru_ref         = hierarchy_node(tru_ref, "", "");
tru_ref_ids          = user_data.specchio_client.getSpectrumIdsForNode(node_tru_ref);
% visualizeLevel(user_data, tru_ref_ids, 2, true);
% Apparent reflectance
app_ref              = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Apparent Reflectance', reflectanceHierarchy);
node_app_ref         = hierarchy_node(app_ref, "", "");
app_ref_ids          = user_data.specchio_client.getSpectrumIdsForNode(node_app_ref);
% visualizeLevel(user_data, app_ref_ids, 2, false);
% SIF
sif_hierarchy        = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'SIF', rawDataID);
% SFM
sfm_hierarchy        = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'SFM', sif_hierarchy);
node_sfm             = hierarchy_node(sfm_hierarchy, "", "");
sfm_ids              = user_data.specchio_client.getSpectrumIdsForNode(node_sfm);
% visualizeLevel(user_data, sfm_ids, 2, true);
% SpecFit
specfit_hierarchy    = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'SpecFit', sif_hierarchy);
node_specfit         = hierarchy_node(specfit_hierarchy, "", "");
specfit_ids          = user_data.specchio_client.getSpectrumIdsForNode(node_specfit);
% visualizeLevel(user_data, specfit_ids, 2, true);
% Calculate VIs and SIF metrics:
processProperties(user_data, app_ref_ids, specfit_ids);
end
toc