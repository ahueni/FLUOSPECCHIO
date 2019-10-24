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
import ch.specchio.file.reader.campaign.*;
%% transfer raw data to DB
% Define connection
connectionID    = 0;

% Connect
user_data.cf              = SPECCHIOClientFactory.getInstance();
user_data.descriptor_list = user_data.cf.getAllServerDescriptors();
user_data.specchio_client = user_data.cf.createClient(user_data.descriptor_list.get(connectionID));

% set up a campaign data loader
user_data.cdl = SpecchioCampaignDataLoader(user_data.specchio_client);

% Get campaign to be loaded by its ID (The campaign ID can be selected in
% the SPECCHIO Data Browser GUI using the context sensitive menu in the
% 'matching spectra' field
user_data.campaign = user_data.specchio_client.getCampaign(49);
disp(user_data.campaign.getName());

% Add file path
fileStoragePath = 'C:\Users\bbuman\Documents\GitHub\FLUOSPECCHIO\Example Data\CH-OE2_Oensingen\2019\190611_tinysubset';
fileName        = '190611_tinysubset';
user_data.campaign.addKnownPath(fileStoragePath)

% load campaign data
user_data.cdl.set_campaign(user_data.campaign);
user_data.cdl.start();

delay = 0.1;  % 10 milliseconds
while user_data.cdl.isAlive  
    pause(delay);  % a slight pause before checking again if thread is alive
end

disp(['Number of parsed files: ' num2str(user_data.cdl.getParsed_file_counter)])
disp(['Number of inserted files: ' num2str(user_data.cdl.getSuccessful_file_counter)])


% wait for loading thread to finish: otherwise the number of parsed and
% loaded files will be wrong as thread is still working.

%% Processing L0 -> L1
% Box setup (Laegeren has switched up-and-downwellling channels):
switchedChannels   = false;

% Get Hierarchy of the newly loaded file
rawDataID   = user_data.specchio_client.getSubHierarchyId(fileName, 0);
node        = hierarchy_node(rawDataID, "", "");
DN_ids      = user_data.specchio_client.getSpectrumIdsForNode(node);

% Get spectrum ids:

% Calculate QIs-0

% Write QIs-0 to DB

% Get Radiance
processL0ToL1(user_data, connectionID, switchedChannels, DN_ids);
% Visualize Radiance
% Get Hierarchy of the Radiance
radianceHierarchy   = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Radiance', rawDataID);
node                = hierarchy_node(radianceHierarchy, "", "");
radianceDataID      = user_data.specchio_client.getSpectrumIdsForNode(node);
visualizeLevel(user_data, radianceDataID, 1);
%% Process L1 --> L2

% Calculate QIs-1

% Write QIs-1 to DB

% Get Reflection 
processL1ToL2(user_data, radianceDataID, switchedChannels);
% Visualize Reflectance
% Get Hierarchy of the Radiance
reflectanceHierarchy   = user_data.specchio_client.getSubHierarchyId(user_data.campaign, 'Reflectance', rawDataID);
node                   = hierarchy_node(reflectanceHierarchy, "", "");
reflectanceDataID      = user_data.specchio_client.getSpectrumIdsForNode(node);
visualizeLevel(user_data, reflectanceDataID, 2);
% Calculate QIs-2

% Write QIs-2 to DB

