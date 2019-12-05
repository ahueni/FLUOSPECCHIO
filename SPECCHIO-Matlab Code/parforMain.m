%% JDBC MYSQL 
% configureJDBCDataSource
tic
datasource = "SpecchioDB";
username = "sdb_admin";
password = "specchio";
conn = database(datasource,username,password);
tablename = "unprocessed_hierarchies";
data = sqlread(conn,tablename);
pool = parpool;

% addAttachedFiles(pool, {'getUserData.m'})
% %% Update only certain stuff 
% % addpath(genpath('Resources'));
% 
% %% Imports
% import ch.specchio.client.*;
% import ch.specchio.queries.*;
% import ch.specchio.types.*;
% import ch.specchio.gui.*;
% 
% % javaaddpath ({'C:\Program Files\SPECCHIO\specchio-client.jar'})
parfor i=1:2
%% Imports
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.types.*;
import ch.specchio.gui.*;
%% Connection
addpath(genpath('Resources'));
connectionID              = 3;
campaignID                = 14;
user_data = getUserData(connectionID, campaignID, false);

%% Processing L0 -> L1
% Get Hierarchy of the newly loaded file
% rawDataID   = user_data.specchio_client.getSubHierarchyId(fileName, 1);
parent_id   = user_data.specchio_client.getHierarchyParentId(data{i,1});
node        = getNode(data{i,1});
DN_ids      = user_data.specchio_client.getSpectrumIdsForNode(node);

% Visualize Raw
% visualizeLevel(user_data, DN_ids, 0);
% Get spectrum ids:

% Calculate QIs-0

% Write QIs-0 to DB

% Get Radiance
temp_userdata = user_data;
% user_data     = processL0ToL1(temp_userdata, DN_ids);
% Visualize Radiance
% Get Hierarchy of the Radiance
radianceHierarchy   = user_data.specchio_client.getSubHierarchyId('Radiance', parent_id);
node                = getNode(radianceHierarchy);
Rad_ids             = user_data.specchio_client.getSpectrumIdsForNode(node);
% visualizeLevel(user_data, radianceDataID, 1);
%% Process L1 --> L2

% Calculate QIs-1
% E
% Write QIs-1 to DB

% Get Reflection
user_data = processL1ToL2(user_data, Rad_ids);
%     toc
% Visualize L2
% Reflectance
reflectanceHierarchy = user_data.specchio_client.getSubHierarchyId('Reflectance', parent_id);
% True reflectance
tru_ref              = user_data.specchio_client.getSubHierarchyId('True Reflectance', reflectanceHierarchy);
node_tru_ref         = getNode(tru_ref);
tru_ref_ids          = user_data.specchio_client.getSpectrumIdsForNode(node_tru_ref);
% visualizeLevel(user_data, tru_ref_ids, 2, true);
% Apparent reflectance
app_ref              = user_data.specchio_client.getSubHierarchyId('Apparent Reflectance', reflectanceHierarchy);
node_app_ref         = getNode(app_ref);
app_ref_ids          = user_data.specchio_client.getSpectrumIdsForNode(node_app_ref);
% visualizeLevel(user_data, app_ref_ids, 2, false);
% SIF
sif_hierarchy        = user_data.specchio_client.getSubHierarchyId('SIF', parent_id);
% SFM
sfm_hierarchy        = user_data.specchio_client.getSubHierarchyId('SFM', sif_hierarchy);
node_sfm             = getNode(sfm_hierarchy);
sfm_ids              = user_data.specchio_client.getSpectrumIdsForNode(node_sfm);
% visualizeLevel(user_data, sfm_ids, 2, true);
% SpecFit
specfit_hierarchy    = user_data.specchio_client.getSubHierarchyId('SpecFit', sif_hierarchy);
node_specfit         = getNode(specfit_hierarchy);
specfit_ids          = user_data.specchio_client.getSpectrumIdsForNode(node_specfit);
% visualizeLevel(user_data, specfit_ids, 2, true);
% Calculate VIs and SIF metrics:
processProperties(user_data, app_ref_ids, specfit_ids);
end
toc