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
tic
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

filePath = 'C:\Users\bbuman\Documents\Data\OE2_Oensingen\2019\raw\3_months\190715';
fileName = '190715';
user_data = autoLoadCampaignData(user_data, filePath);

%% Processing L0 -> L1
% Box setup (Laegeren has switched up-and-downwelling channels):
% Channel switching (true if up and downwelling was switched)
user_data.switch_channels_for_flox = false;
user_data.switch_channels_for_rox  = false;

% Get Hierarchy of the newly loaded file
rawDataID   = user_data.specchio_client.getSubHierarchyId(fileName, 0);
node        = hierarchy_node(rawDataID, "", "");
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
radianceHierarchy   = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Radiance', rawDataID);
node                = hierarchy_node(radianceHierarchy, "", "");
radianceDataID      = user_data.specchio_client.getSpectrumIdsForNode(node);
% visualizeLevel(user_data, radianceDataID, 1);
%% Process L1 --> L2

% Calculate QIs-1
% E
% Write QIs-1 to DB

% Get Reflection
user_data = processL1ToL2(user_data, radianceDataID);
%     toc
% Visualize L2
% Reflectance
reflectanceHierarchy = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Reflectance', rawDataID);
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
toc
% Calculate QIs-2

% Write QIs-2 to DB








%% Update only certain stuff 
for i=1:3
    % Load data into db
    path     = 'C:\Users\bbuman\Documents\Data\OE2_Oensingen\2019\raw\3_months\';
    if(i<=9)
        fileName = ['19070' num2str(i)];
    else
        fileName = ['190' num2str(i)];
    end
    filePath = [path fileName];
    
    % filePath = 'C:\Users\bbuman\Documents\Data\OE2_Oensingen\2019\raw\1_week\190504';
    % fileName = '190504';
    user_data = autoLoadCampaignData(user_data, filePath);
    
    %% Processing L0 -> L1
    % Box setup (Laegeren has switched up-and-downwelling channels):
    % Channel switching (true if up and downwelling was switched)
    user_data.switch_channels_for_flox = false;
    user_data.switch_channels_for_rox  = false;
    
    % Get Hierarchy of the newly loaded file
    rawDataID   = user_data.specchio_client.getSubHierarchyId(fileName, 0);
    node        = hierarchy_node(rawDataID, "", "");
    DN_ids      = user_data.specchio_client.getSpectrumIdsForNode(node);
    % Visualize Raw
    % visualizeLevel(user_data, DN_ids, 0);
    % Get spectrum ids:
    
    % Calculate QIs-0
    
    % Write QIs-0 to DB
    
    % Get Radiance
    % user_data = processL0ToL1(user_data, DN_ids);
    % Visualize Radiance
    % Get Hierarchy of the Radiance
    radianceHierarchy   = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Radiance', rawDataID);
    node                = hierarchy_node(radianceHierarchy, "", "");
    radianceDataID      = user_data.specchio_client.getSpectrumIdsForNode(node);
    % visualizeLevel(user_data, radianceDataID, 1);
    %% Process L1 --> L2
    
    % Calculate QIs-1
    
    % Write QIs-1 to DB
    
    % Get Reflection
    user_data = processL1ToL2(user_data, radianceDataID);
%     toc
    % Visualize L2
    % Reflectance
    reflectanceHierarchy = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Reflectance', rawDataID);
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
